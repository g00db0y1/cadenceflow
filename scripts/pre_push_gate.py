#!/usr/bin/env python3
"""
CadenceFlow Local Pre-Push & CI Verification Gate (`scripts/pre_push_gate.py`).

Ensures NO broken code, invalid imports, uppercase Icon typos, missing test suites,
or AndroidManifest AGP 8+ incompatibilities ever leave local to GitHub.
"""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

REQUIRED_FIVE_TEST_SUITES = [
    "test/cadence_calculator_test.dart",
    "test/models_and_repository_test.dart",
    "test/clerk_auth_service_test.dart",
    "test/productivity_controller_test.dart",
    "test/widget_test.dart",
]

ALLOWED_PACKAGES = {
    "flutter",
    "flutter_test",
    "cupertino_icons",
    "supabase_flutter",
    "http",
    "shared_preferences",
    "sqflite",
    "path",
    "flutter_local_notifications",
    "android_alarm_manager_plus",
    "timezone",
    "google_fonts",
    "intl",
    "uuid",
    "cadenceflow",
}


def fail(msg: str) -> None:
    print(f"❌ [PRE-PUSH GATE FAILED] {msg}", file=sys.stderr)
    sys.exit(1)


def check_five_test_suites() -> None:
    for rel_path in REQUIRED_FIVE_TEST_SUITES:
        p = ROOT / rel_path
        if not p.exists():
            fail(f"Missing required test suite: {rel_path}")
        text = p.read_text(encoding="utf-8")
        if "void main(" not in text:
            fail(f"Test suite {rel_path} is missing `void main()` entrypoint.")
        if "package:material_ui/" in text or "MyApp(" in text:
            fail(
                f"Test suite {rel_path} contains broken template references (`material_ui` or `MyApp`)."
            )
    print(f"✅ All 5 required test suites verified ({len(REQUIRED_FIVE_TEST_SUITES)}/5).")


def check_dart_files() -> None:
    dart_files = sorted(
        list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart"))
    )
    if not dart_files:
        fail("No Dart files found in lib/ or test/.")

    import_re = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
    icon_re = re.compile(r"\bIcons\.([A-Za-z0-9_]+)")
    print_re = re.compile(r"(?<![a-zA-Z0-9_])print\s*\(")

    for df in dart_files:
        rel = df.relative_to(ROOT)
        text = df.read_text(encoding="utf-8")

        # 1. Check imports resolve
        for match in import_re.finditer(text):
            uri = match.group(1)
            if uri.startswith("dart:"):
                continue
            elif uri.startswith("package:"):
                pkg_and_path = uri[len("package:") :]
                pkg, _, subpath = pkg_and_path.partition("/")
                if pkg not in ALLOWED_PACKAGES:
                    fail(f"{rel}: Disallowed or undeclared package import `{uri}`")
                if pkg == "cadenceflow":
                    target = ROOT / "lib" / subpath
                    if not target.exists():
                        fail(f"{rel}: Broken package import `{uri}` (missing {target})")
            else:
                target = (df.parent / uri).resolve()
                if not target.exists():
                    fail(f"{rel}: Broken relative import `{uri}` (resolved to {target})")

        # 2. Check Icons.<identifier> lowercase naming convention
        for match in icon_re.finditer(text):
            icon_name = match.group(1)
            if not icon_name[0].islower():
                fail(
                    f"{rel}: Invalid icon identifier `Icons.{icon_name}` (must start with lowercase letter)."
                )

        # 3. Check no raw print() calls (avoid_print lint rule)
        if print_re.search(text):
            fail(f"{rel}: Raw `print(...)` detected; use `debugPrint(...)` instead.")

        # 4. Check balanced delimiters (stripping comments & string literals roughly)
        pairs = {"(": ")", "[": "]", "{": "}"}
        closing = {")", "]", "}"}
        stack: list[str] = []
        in_single = False
        in_double = False
        in_line_comment = False
        i = 0
        while i < len(text):
            ch = text[i]
            nxt = text[i + 1] if i + 1 < len(text) else ""
            if in_line_comment:
                if ch == "\n":
                    in_line_comment = False
            elif in_single:
                if ch == "\\":
                    i += 1
                elif ch == "'":
                    in_single = False
            elif in_double:
                if ch == "\\":
                    i += 1
                elif ch == '"':
                    in_double = False
            else:
                if ch == "/" and nxt == "/":
                    in_line_comment = True
                    i += 1
                elif ch == "'":
                    in_single = True
                elif ch == '"':
                    in_double = True
                elif ch in pairs:
                    stack.append(pairs[ch])
                elif ch in closing:
                    if not stack or stack[-1] != ch:
                        fail(f"{rel}: Unbalanced delimiter `{ch}` near char {i}")
                    stack.pop()
            i += 1
        if stack:
            fail(f"{rel}: Unclosed delimiters remaining at EOF: {stack}")

    print(f"✅ All {len(dart_files)} Dart files passed import, Icon, lint, and syntax verification.")


def check_analysis_options_and_manifest() -> None:
    analysis = (ROOT / "analysis_options.yaml").read_text(encoding="utf-8")
    if "deprecated_member_use: ignore" not in analysis:
        fail("analysis_options.yaml must ignore `deprecated_member_use` for Flutter 3.50+.")

    manifest_path = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        fail("Missing AndroidManifest.xml")
    tree = ET.parse(manifest_path)
    root_el = tree.getroot()
    if "package" in root_el.attrib:
        fail(
            "AndroidManifest.xml must not include `package=...` attribute on <manifest> (AGP 8+ incompatibility)."
        )
    print("✅ analysis_options.yaml and AndroidManifest.xml passed AGP 8+ & Flutter 3.50 checks.")


def run_flutter_if_available() -> None:
    flutter_bin = shutil.which("flutter")
    if not flutter_bin:
        print("ℹ️ Flutter SDK not installed in local shell; static gate checks passed.")
        return

    print("🚀 Running local `flutter analyze --no-fatal-infos` and `flutter test`...")
    subprocess.run([flutter_bin, "analyze", "--no-fatal-infos"], cwd=ROOT, check=True)
    subprocess.run([flutter_bin, "test"], cwd=ROOT, check=True)
    print("✅ Local Flutter analyze & test passed.")


def main() -> None:
    check_five_test_suites()
    check_dart_files()
    check_analysis_options_and_manifest()
    run_flutter_if_available()
    print("🎉 [PRE-PUSH GATE PASSED] Repository is clean and ready for GitHub.")


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
CadenceFlow 7-Layer Local Pre-Push & CI Verification Gate (`scripts/pre_push_gate.py`).

Enforces strict quality & security gates before any commit or push leaves local to GitHub:
  - Gate 1: All 5 Required Test Suites Present & Valid
  - Gate 2: Dart Import & Package Dependency Resolution Gate
  - Gate 3: Flutter `Icons.*` Casing, Balanced Syntax & No-Print Lint Gate
  - Gate 4: Custom App Icon Asset & Android Adaptive/Mipmap Launcher Icon Gate
  - Gate 5: In-App Brand Icon Usage & Responsive AppBar Overflow Gate
  - Gate 6: Supabase PostgreSQL & Clerk JWT `sub` RLS Security Gate
  - Gate 7: CI Resource & Protected-Main Manual APK Workflow Policy Gate
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

REQUIRED_ICON_ASSETS = [
    "assets/icons/cadenceflow_icon.png",
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png",
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png",
    "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml",
    "android/app/src/main/res/values/ic_launcher_background.xml",
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


def gate_1_five_test_suites() -> None:
    for rel_path in REQUIRED_FIVE_TEST_SUITES:
        p = ROOT / rel_path
        if not p.exists():
            fail(f"Gate 1: Missing required test suite: {rel_path}")
        text = p.read_text(encoding="utf-8")
        if "void main(" not in text:
            fail(f"Gate 1: Test suite {rel_path} is missing `void main()` entrypoint.")
        if "package:material_ui/" in text or "MyApp(" in text:
            fail(
                f"Gate 1: Test suite {rel_path} contains broken template references (`material_ui` or `MyApp`)."
            )
    print(f"✅ [Gate 1/7] All 5 required test suites verified ({len(REQUIRED_FIVE_TEST_SUITES)}/5).")


def gate_2_and_3_dart_files() -> None:
    dart_files = sorted(
        list((ROOT / "lib").rglob("*.dart")) + list((ROOT / "test").rglob("*.dart"))
    )
    if not dart_files:
        fail("Gate 2: No Dart files found in lib/ or test/.")

    import_re = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]", re.MULTILINE)
    icon_re = re.compile(r"\bIcons\.([A-Za-z0-9_]+)")
    print_re = re.compile(r"(?<![a-zA-Z0-9_])print\s*\(")

    for df in dart_files:
        rel = df.relative_to(ROOT)
        text = df.read_text(encoding="utf-8")

        # Gate 2: Import & Package resolution
        for match in import_re.finditer(text):
            uri = match.group(1)
            if uri.startswith("dart:"):
                continue
            elif uri.startswith("package:"):
                pkg_and_path = uri[len("package:") :]
                pkg, _, subpath = pkg_and_path.partition("/")
                if pkg not in ALLOWED_PACKAGES:
                    fail(f"Gate 2 ({rel}): Disallowed or undeclared package import `{uri}`")
                if pkg == "cadenceflow":
                    target = ROOT / "lib" / subpath
                    if not target.exists():
                        fail(f"Gate 2 ({rel}): Broken package import `{uri}` (missing {target})")
            else:
                target = (df.parent / uri).resolve()
                if not target.exists():
                    fail(f"Gate 2 ({rel}): Broken relative import `{uri}` (resolved to {target})")

        # Gate 3: Icons.<identifier> lowercase naming convention + no print() + balanced delimiters
        for match in icon_re.finditer(text):
            icon_name = match.group(1)
            if not icon_name[0].islower():
                fail(
                    f"Gate 3 ({rel}): Invalid icon identifier `Icons.{icon_name}` (must start with lowercase letter)."
                )

        if print_re.search(text):
            fail(f"Gate 3 ({rel}): Raw `print(...)` detected; use `debugPrint(...)` instead.")

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
                        fail(f"Gate 3 ({rel}): Unbalanced delimiter `{ch}` near char {i}")
                    stack.pop()
            i += 1
        if stack:
            fail(f"Gate 3 ({rel}): Unclosed delimiters remaining at EOF: {stack}")

    print(f"✅ [Gate 2/7 & Gate 3/7] All {len(dart_files)} Dart files passed import, Icon, lint, and syntax checks.")


def gate_4_and_5_icons_and_ui() -> None:
    for rel_asset in REQUIRED_ICON_ASSETS:
        p = ROOT / rel_asset
        if not p.exists() or p.stat().st_size == 0:
            fail(f"Gate 4: Missing or empty app icon asset: {rel_asset}")

    pubspec = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    if "assets/icons/cadenceflow_icon.png" not in pubspec:
        fail("Gate 4: `assets/icons/cadenceflow_icon.png` is not registered in pubspec.yaml.")

    scaffold = (ROOT / "lib/ui/screens/main_scaffold.dart").read_text(encoding="utf-8")
    auth_gate = (ROOT / "lib/ui/screens/auth_gate_screen.dart").read_text(encoding="utf-8")
    if "CadenceFlowBrandIcon" not in scaffold or "CadenceFlowBrandIcon" not in auth_gate:
        fail(
            "Gate 5: `CadenceFlowBrandIcon` must be used in both MainScaffold AppBar and ClerkAuthGateScreen."
        )
    print("✅ [Gate 4/7 & Gate 5/7] Custom app icon assets, Android mipmaps, and AppBar brand icon verified.")


def gate_6_supabase_rls_and_manifest() -> None:
    analysis = (ROOT / "analysis_options.yaml").read_text(encoding="utf-8")
    if "deprecated_member_use: ignore" not in analysis:
        fail("Gate 6: analysis_options.yaml must ignore `deprecated_member_use` for Flutter 3.50+.")

    manifest_path = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    if not manifest_path.exists():
        fail("Gate 6: Missing AndroidManifest.xml")
    tree = ET.parse(manifest_path)
    root_el = tree.getroot()
    if "package" in root_el.attrib:
        fail(
            "Gate 6: AndroidManifest.xml must not include `package=...` attribute on <manifest> (AGP 8+)."
        )

    sql_path = ROOT / "supabase" / "migrations" / "001_initial_schema.sql"
    sql = sql_path.read_text(encoding="utf-8")
    for table in ("tasks", "cadence_goals", "appointments"):
        if f"ALTER TABLE public.{table} ENABLE ROW LEVEL SECURITY;" not in sql:
            fail(f"Gate 6: Missing RLS enablement for `public.{table}` in SQL schema.")
    if "auth.jwt() ->> 'sub'" not in sql:
        fail("Gate 6: Missing Clerk `auth.jwt() ->> 'sub'` check in SQL RLS policies.")
    print("✅ [Gate 6/7] Supabase Clerk RLS policies and AndroidManifest AGP 8+ compliance verified.")


def gate_7_ci_workflow_policies() -> None:
    ci_path = ROOT / ".github" / "workflows" / "flutter_ci.yml"
    apk_path = ROOT / ".github" / "workflows" / "build_apk.yml"
    if not ci_path.exists() or not apk_path.exists():
        fail("Gate 7: Both `flutter_ci.yml` and `build_apk.yml` workflows must exist.")

    ci_text = ci_path.read_text(encoding="utf-8")
    if "flutter build apk" in ci_text:
        fail("Gate 7: `flutter_ci.yml` must NOT build APKs automatically on push/PR (save CI resources).")
    if "cancel-in-progress: true" not in ci_text:
        fail("Gate 7: `flutter_ci.yml` must enable `cancel-in-progress: true` concurrency.")

    apk_text = apk_path.read_text(encoding="utf-8")
    if "workflow_dispatch:" not in apk_text or "pull_request:" in apk_text:
        fail("Gate 7: `build_apk.yml` must ONLY trigger manually via `workflow_dispatch`.")
    if 'refs/heads/main' not in apk_text:
        fail("Gate 7: `build_apk.yml` must enforce `refs/heads/main` for `release` builds.")
    print("✅ [Gate 7/7] CI resource conservation & manual APK branch-protection policies verified.")


def run_flutter_if_available() -> None:
    flutter_bin = shutil.which("flutter")
    if not flutter_bin:
        return
    print("🚀 Running local `flutter analyze --no-fatal-infos` and `flutter test`...")
    subprocess.run([flutter_bin, "analyze", "--no-fatal-infos"], cwd=ROOT, check=True)
    subprocess.run([flutter_bin, "test"], cwd=ROOT, check=True)


def main() -> None:
    gate_1_five_test_suites()
    gate_2_and_3_dart_files()
    gate_4_and_5_icons_and_ui()
    gate_6_supabase_rls_and_manifest()
    gate_7_ci_workflow_policies()
    run_flutter_if_available()
    print("🎉 [ALL 7 GATES PASSED] Repository is clean and ready for GitHub.")


if __name__ == "__main__":
    main()

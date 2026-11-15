#!/usr/bin/env python3
"""Configures Android Gradle files for flutter_local_notifications (Java 8+ Core Library Desugaring)."""

from pathlib import Path


def patch_kts(gradle_kts: Path) -> None:
    content = gradle_kts.read_text(encoding="utf-8")
    if "isCoreLibraryDesugaringEnabled" not in content:
        content = content.replace(
            "compileOptions {",
            "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
            1,
        )
    if "desugar_jdk_libs" not in content:
        content += (
            '\ndependencies {\n'
            '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
            '}\n'
        )
    gradle_kts.write_text(content, encoding="utf-8")
    print(f"[configure_android_gradle] Patched {gradle_kts}")


def patch_groovy(gradle_groovy: Path) -> None:
    content = gradle_groovy.read_text(encoding="utf-8")
    if "coreLibraryDesugaringEnabled" not in content:
        content = content.replace(
            "compileOptions {",
            "compileOptions {\n        coreLibraryDesugaringEnabled true",
            1,
        )
    if "desugar_jdk_libs" not in content:
        content += (
            "\ndependencies {\n"
            "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
            "}\n"
        )
    gradle_groovy.write_text(content, encoding="utf-8")
    print(f"[configure_android_gradle] Patched {gradle_groovy}")


def main() -> None:
    root = Path(__file__).resolve().parent.parent
    kts = root / "android" / "app" / "build.gradle.kts"
    groovy = root / "android" / "app" / "build.gradle"
    if kts.exists():
        patch_kts(kts)
    elif groovy.exists():
        patch_groovy(groovy)
    else:
        print("[configure_android_gradle] No android/app/build.gradle(.kts) found yet.")


if __name__ == "__main__":
    main()

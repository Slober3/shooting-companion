# Android release

1. Run formatting, analysis, Flutter tests and all pure Dart package tests.
2. Build a release APK with Android SDK 33 minimum.
3. Inspect the merged manifest and reject `android.permission.INTERNET`.
4. Configure signing through GitHub encrypted secrets; never commit keystores.
5. Generate SHA-256 and an SBOM.
6. Tag with SemVer and attach APK, checksum, SBOM and limitations.

Version 0.3 uses debug signing for local release-mode testing only. Public
GitHub artifacts require a dedicated release key and protected workflow.

## Toolchain note

`share_plus` is pinned to 12.0.2 with Flutter 3.44.8 / AGP 9.0.1. The build is
green, but Flutter reports that this plugin still applies the legacy Kotlin
Gradle Plugin. Re-evaluate this pin before a future Flutter upgrade and move to
a Built-in-Kotlin-compatible release only after the Android release build and
share workflow pass again.

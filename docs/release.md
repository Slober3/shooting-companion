# Android release

1. Run formatting, analysis, Flutter tests and all pure Dart package tests.
2. Build a release APK with Android SDK 33 minimum.
3. Inspect the merged manifest. Require `android.permission.CAMERA` and
   `android.permission.RECORD_AUDIO`; reject `android.permission.INTERNET`,
   location, external-storage and network-state permissions.
4. Configure signing through GitHub encrypted secrets; never commit keystores.
5. Generate SHA-256 and an SBOM.
6. Tag with SemVer and attach APK, checksum, SBOM and limitations.

Version `0.5.1+3` adds the guided acoustic live-firetimer, real native output
signals, visible per-series coach reflections and shorter responsive actions.
Public GitHub artifacts still require a dedicated release key and protected
workflow.

## Acoustic validation gate

The UI describes acoustic timing as a user-reviewed training measurement. Do
not make device- or calibre-specific accuracy claims until all conditions pass:

- at least three recent Android devices including the primary Samsung;
- indoor and outdoor validation reported separately;
- at least 300 independent strings and 3,000 reference shots;
- at least 95% exact event count for supported single-shooter strings;
- median timing error at most 20 ms and P95 at most 50 ms;
- no start-signal double registrations and all questionable events reviewable.

Until then public release notes must preserve the shared-range limitation and
must not describe the phone as certified match equipment.

## Toolchain note

`share_plus` is pinned to 12.0.2 with Flutter 3.44.8 / AGP 9.0.1. The build is
green, but Flutter reports that this plugin still applies the legacy Kotlin
Gradle Plugin. Re-evaluate this pin before a future Flutter upgrade and move to
a Built-in-Kotlin-compatible release only after the Android release build and
share workflow pass again.

# Android release

1. Run formatting, analysis, Flutter tests and all pure Dart package tests.
2. Build a release APK with Android SDK 33 minimum.
3. Inspect the merged manifest and reject `android.permission.INTERNET`,
   `android.permission.RECORD_AUDIO`, external-storage and network-state
   permissions for the stable `0.5.0+1` build.
4. Configure signing through GitHub encrypted secrets; never commit keystores.
5. Generate SHA-256 and an SBOM.
6. Tag with SemVer and attach APK, checksum, SBOM and limitations.

Version `0.5.0+1` includes par, cadence and external timer input. The planned
`0.4.2+3` analysis hotfix was not separately published and is integrated into
this release. Public GitHub artifacts require a dedicated release key and
protected workflow.

## Acoustic release gate

Acoustic live fire is disabled by default through
`SC_ENABLE_ACOUSTIC_TIMER=false` and is absent from the release manifest. It may
be enabled only for internal debug/profile validation with:

```powershell
flutter run --profile --dart-define=SC_ENABLE_ACOUSTIC_TIMER=true
```

Do not enable it in a stable release until all conditions pass:

- at least three recent Android devices including the primary Samsung;
- indoor and outdoor validation reported separately;
- at least 300 independent strings and 3,000 reference shots;
- at least 95% exact event count for supported single-shooter strings;
- median timing error at most 20 ms and P95 at most 50 ms;
- no start-signal double registrations and all questionable events reviewable.

Until then CI must reject `RECORD_AUDIO` in the release APK. Debug/profile
manifests may contain the permission solely for the gated validation flow.

## Toolchain note

`share_plus` is pinned to 12.0.2 with Flutter 3.44.8 / AGP 9.0.1. The build is
green, but Flutter reports that this plugin still applies the legacy Kotlin
Gradle Plugin. Re-evaluate this pin before a future Flutter upgrade and move to
a Built-in-Kotlin-compatible release only after the Android release build and
share workflow pass again.

# Shooting Companion mobile

Flutter Android client for Shooting Companion `0.8.0+1`. The app is volledig
offline, targets Android 13+ and declares no internet, location or external
storage permission. Camera access belongs to photos and the experimental score
assistant; microphone access is requested only inside the visible live-fire
timer and raw audio is never persisted.

## Toolchain

- Flutter 3.44.8 / Dart 3.12.2;
- Java 17 and Android SDK;
- OpenCV Android SDK 4.13.0 for a vision-enabled arm64 APK.

From this directory:

```powershell
flutter pub get
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Build the validated arm64 release from the repository root:

```powershell
$env:OPENCV_ANDROID_SDK = & .\tools\setup_opencv_android.ps1
cd apps/mobile
flutter build apk --release --target-platform android-arm64
cd ../..
python tools/verify_release_contract.py --apk `
  apps/mobile/build/app/outputs/flutter-apk/app-release.apk `
  --apkanalyzer "$env:ANDROID_HOME/cmdline-tools/latest/bin/apkanalyzer.bat"
```

The app owns presentation, Drift persistence and Android integration. Domain
validation, deterministic scoring, target profiles, photo geometry, analysis,
training content, timer logic and vision contracts live in sibling packages.
The learning hub contains 18 lessons, 12 guided drills and four resumable paths.
Experimental OpenCV candidates always require user review and retain a fully
manual fallback.

See the repository [README](../../README.md), [test strategy](../../docs/testing.md),
[release procedure](../../docs/release.md), [training contract](../../docs/training-tools.md)
and [Graphify guide](../../docs/graphify.md).

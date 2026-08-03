# Shooting Companion mobile

Flutter Android client for the fully offline Shooting Companion. The app targets
Android 13+ and declares no internet permission.

From this directory:

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

The app owns presentation and Android integration. Domain rules, scoring, target
profiles and photo homography live in the sibling packages under `packages/`.
See the repository root README and `docs/` for architecture, migration, backup,
privacy and release details.

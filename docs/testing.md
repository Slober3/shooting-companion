# Test strategy

The local quality gate is:

```powershell
dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test packages
cd apps/mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter build apk --release
```

Pure Dart packages are also tested independently. Acceptance covers:

- scoring boundaries, non-ten target maxima, misses and multiplicity;
- v1-to-v2 migration and both backup manifest versions;
- one-active-session and one-draft-series invariants;
- draft autosave, confirm/edit replacement and sequence renumbering;
- image staging, missing-file deletion and primary-image replacement;
- homography identity, rotation, perspective and roundtrip precision;
- 320, 360 and 412 dp widths at 1.0, 1.3 and 2.0 text scales;
- bottom system insets, open keyboard, portrait and landscape;
- absence of internet, audio and external-storage permissions in the built APK.

Device-only camera permission and navigation-mode checks are documented as a
manual gate when no Android device is connected to CI.

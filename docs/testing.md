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
- BR50 A3 geometry, 25 record bulls, sighters, duplicate shots, X ties,
  incomplete cards, multiplicity, fixed maximum and excess-shot penalties;
- v1/v2/v3-to-v4 migration and all four backup manifest versions;
- built-in library protection, unused deletion, referenced archiving, restore,
  dependent-ammunition transactions and immutable target versioning;
- one-active-session and one-draft-series invariants;
- draft autosave, confirm/edit replacement and sequence renumbering;
- image staging, missing-file deletion and primary-image replacement;
- homography identity, rotation, perspective and roundtrip precision;
- place/edit hit testing at 0, 5, 15 and 25 dp, exact overlaps, zoomed inverse
  transforms, precision placement and one-step drag undo;
- 320, 360 and 412 dp widths at 1.0, 1.3 and 2.0 text scales;
- bottom system insets, open keyboard, portrait and landscape;
- Unicode PDF extraction and Poppler rendering with repeated table headers;
- all four palettes in light/dark mode and persisted appearance fallbacks;
- floating notice dismissal/deduplication, one-line action labels, joined
  material metadata and route/keyboard/layout stress variants;
- absence of internet, audio and external-storage permissions in the built APK.

Device-only camera permission and navigation-mode checks are documented as a
manual gate when no Android device is connected to CI.

# Test strategy

The local quality gate is:

```powershell
dart format --output=none --set-exit-if-changed apps/mobile/lib apps/mobile/test packages
python tools/verify_docs.py
python tools/verify_graphify.py
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
- v1/v2/v3/v4/v5/v6/v7-to-v8 migration and all eight backup manifest versions;
- contextual series, session and historical-comparison analysis, including
  strict cohorts, visit-date chronology and archived material references;
- metric explanation and chart accessibility at narrow widths and large text;
- built-in library protection, unused deletion, referenced archiving, restore,
  dependent-ammunition transactions and immutable target versioning;
- one-active-session and one-draft-series invariants;
- draft autosave, confirm/edit replacement and sequence renumbering;
- image staging, missing-file deletion and primary-image replacement;
- four-corner and ring-assisted homography identity, all quarter-turns,
  perspective, conditioning, anchor/matrix cross-checking and roundtrip
  precision;
- place/edit hit testing at 0, 5, 15 and 25 dp, exact overlaps, zoomed inverse
  transforms, precision placement and one-step drag undo;
- 320, 360 and 412 dp widths at 1.0, 1.3 and 2.0 text scales;
- bottom system insets, open keyboard, portrait and landscape;
- Unicode PDF extraction and Poppler rendering with repeated table headers;
- all four palettes in light/dark mode and persisted appearance fallbacks;
- floating notice dismissal/deduplication, one-line action labels, joined
  material metadata and route/keyboard/layout stress variants;
- photo captions, live viewer updates, contextual long-press actions and
  primary-photo deletion that preserves impacts and scores;
- target-aware group metrics, potential score, coaching thresholds, typed
  goals, post-series reflections and v5 relationship validation;
- absence of internet and external-storage permissions in the built APK;
- just-in-time microphone permission, foreground-only capture and proof that no
  raw audio enters storage, diagnostics, export or backup.
- vision contract/ABI compatibility, cancellation, manual candidate
  reprojection, low-confidence defaults and atomic reviewed-scan commit;
- v8 vision draft/analysis/media/alignment backup roundtrips, legacy adapters,
  runtime target/impact validation and invalid provenance;
- independent ISSF boundary goldens for both built-in pistol profiles and
  .22 LR, 9x19 mm, .38 Special and .357 Magnum, including exact tangency and
  +/-0.01 mm in every axis and diagonal direction;
- release-contract source and APK checks, private-data leak prevention and a
  Windows native build from checkout and build paths containing spaces;
- documentation-link/version checks and a deterministic Graphify graph that
  contains current training, scoring and vision entrypoints but no generated
  SDK, build, artifact or private-validation paths;

Device-only camera permission and navigation-mode checks are documented as a
manual gate when no Android device is connected to CI.

## Independent package gate

CI resolves, analyzes and tests every pure-Dart boundary separately from the
Flutter app:

```bash
for package in \
  packages/domain \
  packages/target_profiles \
  packages/scoring \
  packages/photo_geometry \
  packages/analysis \
  packages/coaching \
  packages/training \
  packages/shot_timer \
  packages/vision_api \
  packages/vision_research; do
  (cd "$package" && dart pub get && dart analyze && dart test)
done
```

This catches accidental Flutter, database or platform coupling in modules that
must remain deterministic and reusable. Package tests cover analysis metrics,
BR50-local coordinates, cautious coaching thresholds, built-in drills,
experiment planning, sight corrections, vision wire contracts and encrypted
research-export validation.

`packages/vision_ffi` is resolved, analyzed and tested separately as a Flutter
FFI package.

## Native vision gates

Linux CI always builds one native configuration with OpenCV forcibly disabled:

```bash
cmake -S native/vision_core -B native/vision_core/build_ci \
  -DSC_VISION_ENABLE_OPENCV=OFF \
  -DSC_VISION_BUILD_TESTS=ON \
  -DSC_VISION_WARNINGS_AS_ERRORS=ON \
  -DCMAKE_BUILD_TYPE=Release
cmake --build native/vision_core/build_ci --config Release --parallel
ctest --test-dir native/vision_core/build_ci \
  --build-config Release \
  --output-on-failure
```

The fallback CLI assertion checks structured JSON, including an empty candidate
list. A successful build therefore proves fallback honesty and ABI portability,
not registration or hole-detection accuracy. OpenCV-enabled results remain
research-gated until the real-photo release criteria in
`docs/vision-foundation.md` are met. CI additionally downloads the pinned
official OpenCV 4.13.0 Android SDK, verifies its SHA-256, builds an arm64 release
APK and asserts that `libshooting_companion_vision.so` is packaged.

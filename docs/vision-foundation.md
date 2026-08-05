# Experimental vision foundation

## Status and safety boundary

The vision foundation is an offline experiment. It proposes image geometry and
impact candidates; it never writes a `ShotImpact`, score, series or database
record. The existing manual editor remains the only confirmation boundary.

There is no model, network access, model download or on-device training. A
candidate is not a confirmed hit. An engine or target-profile update must never
rewrite a confirmed historical score.

The default CI verification deliberately disables OpenCV. This keeps the
fallback contract continuously buildable on Linux and proves that a release
cannot accidentally turn an unavailable detector into fabricated candidates.
The current Windows development environment also does not contain OpenCV, so
the locally verified build is the same honest geometry-only backend:

- PGM pixels can be evaluated for deterministic resolution, contrast, clipping
  and Laplacian-variance quality metrics.
- JPEG and PNG dimensions can be probed without decoding their pixels.
- Homographies can be calculated and tested from four explicit point pairs.
- Registration and impact detection return `unsupported` or `notAnalyzed`.
- Unsupported results always contain an empty `candidateImpacts` list.

`src/opencv_backend.cpp` is an optional, compile-time research prototype. It
is included only when CMake finds OpenCV `core`, `imgproc` and `imgcodecs`.
Its presence is exposed through capabilities and provenance; it must be
validated on real target fixtures before it may be enabled in an application
release.

The repository does not yet contain a Dart FFI adapter, a scan/review screen or
database persistence for a vision analysis. `packages/vision_api` and the C ABI
define and test the boundary only. This is intentional: application integration
starts after the registration proof and closed validation set exist.

## Boundaries

```text
mobile or vision_cli
        |
        v
packages/vision_api        immutable schema-v1 JSON contracts
        |
        v
stable C ABI v1            version, capabilities, request struct, owned JSON
        |
        v
native/vision_core         quality, geometry, optional OpenCV backend
        |
        v
candidate review           explicit user confirmation in the manual editor
```

`packages/vision_api` may use domain `TargetProfile` snapshots but has no
Flutter, database, file-writing or FFI dependency. Native output uses the same
enum names and JSON fields. The checked-in native unsupported-result fixture is
parsed by the Dart contract tests to catch wire-format drift.

## Provenance

Every result records:

- contract schema version;
- C ABI version;
- engine version;
- backend (`geometryOnly` or `openCv`);
- advertised capabilities;
- version per algorithm stage;
- optional model version, which is `null` in this foundation;
- quality, registration, warnings and diagnostic metrics;
- a confidence band and evidence reasons for every candidate.

The application must persist provenance alongside an accepted experimental
analysis if database integration is added later. Reanalysis creates new
provenance; it does not replace an earlier confirmed result.

## Build and test

With CMake:

```powershell
cmake -S native/vision_core -B native/vision_core/build_verify_test `
  -DSC_VISION_ENABLE_OPENCV=OFF `
  -DSC_VISION_BUILD_TESTS=ON `
  -DSC_VISION_WARNINGS_AS_ERRORS=ON `
  -DCMAKE_BUILD_TYPE=Release
cmake --build native/vision_core/build_verify_test --config Release --parallel
ctest --test-dir native/vision_core/build_verify_test `
  --build-config Release `
  --output-on-failure
```

Without CMake, the geometry-only sources are standard C++17 and can be compiled
directly with MinGW. Native tests deliberately use only a synthetic PGM
checkerboard. The fixture demonstrates quality/probing behavior only; it is not
registration or detection evidence.

The CLI is deterministic and prints a single JSON result:

```powershell
vision_cli analyze `
  --image synthetic.pgm `
  --card-width-mm 550 `
  --card-height-mm 550 `
  --projectile-diameter-mm 5.6 `
  --minimum-long-side-px 2000
```

Exit code `0` includes honest `unsupported` and `notAnalyzed` outcomes, because
these are valid analysis results. Invalid arguments return `2`; unreadable
input returns `3` and a structured failed result.

CI performs three independent checks on Ubuntu:

- C++ unit and homography/quality tests;
- a C-only ABI consumer linked to the shared library;
- a CLI JSON assertion that the forced fallback reports backend
  `geometryOnly`, status `unsupported`, warning `openCvUnavailable` and zero
  candidates.

The Dart contract tests also parse a checked-in unsupported native-result
fixture. The native CI job verifies the live executable separately; the fixture
is not treated as proof that the current binary was executed.

## Experimental release gates

The OpenCV adapter must remain disabled in stable UI until an independent,
closed test set demonstrates all applicable gates:

- at least 99% registration success for images accepted by quality control;
- median impact-position error at most 0.75 mm;
- P95 impact-position error at most 1.5 mm;
- at least 98% precision and recall for isolated supported holes;
- at least 95% exact visible-shot count on supported clean targets;
- at least 97% exact series score in supported non-overlapping cases;
- every remaining potential scoring-line error is marked uncertain;
- no low-confidence candidate is silently confirmed;
- P95 processing time at most eight seconds on the reference mid-range device;
- manual correction remains available for every result.

Required evidence includes real ISSF 25 m Precision / 50 m Pistol targets,
.22 LR holes in white and black regions, several Android cameras, varied light
and perspective, line cases and a sealed test split. Synthetic images may test
geometry and regressions but never replace real validation data.

If any gate fails, the backend remains an explicitly experimental assistant.
Documentation and UI must not describe it as automatic or reliable scoring.

## Research export, data and copyright

No personal target photographs, exports or production backups belong in the
repository. `packages/vision_research` implements the explicit local
`.scvision` research container. It:

- accepts an already selected target crop, never an unrestricted gallery;
- decodes and re-encodes supported JPEG/PNG input to remove EXIF and GPS;
- uses an allow-listed manifest without session names, notes, locations or
  firearm identifiers;
- includes profile geometry, calibre, confirmed manual impacts, alignment,
  quality labels and an explicit consent record;
- authenticates every entry hash and encrypts the container with AES-256-GCM
  using an Argon2id password-derived key;
- never uploads, syncs or requests network access.

The current service is deliberately bounded in memory and rejects oversized
input. It is not yet connected to app UI, consent presentation, dataset intake
or annotation tooling. The crop must already be chosen by the caller. Those
integration steps require a separate privacy and re-identification review.

## Research-gated gaps

The following roadmap work is explicitly not claimed by this foundation:

- validated ISSF card/ring registration across real cameras and lighting;
- production-quality white- and black-zone hole detection;
- EXIF rotation, reflection, multiple-card and clipped-ring handling in the
  native pipeline;
- a sealed dataset, annotation workflow and measured accuracy/latency report;
- Flutter FFI, review UI and persisted `VisionAnalysis` provenance;
- BR50 detection, OCR-based checks or an ONNX/ML fallback.

Until these gaps and the gates above are satisfied, OpenCV output is a research
proposal only and manual point placement remains the product path.

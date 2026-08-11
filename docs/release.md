# Android release 0.8.0+1

The release source is one clean commit on a branch based on the current GitHub
`main`. Database schema and encrypted backup manifest both remain version 8.

1. Run documentation, Graphify, privacy and release-contract source checks.
2. Run formatting, Flutter analysis/tests, every package test, Kotlin timer
   tests and native C++/C-ABI tests.
3. Install the pinned OpenCV 4.13.0 Android SDK and verify its published
   SHA-256 before compiling.
4. Build one arm64 APK with `--dart-define=GIT_COMMIT=<full commit sha>`.
5. Validate package ID, version, native ABI/library and merged permissions from
   that exact APK.
6. Name the artifact
   `shooting-companion-0.8.0+1-<short-sha>-arm64-release.apk` and generate its
   SHA-256 and SBOM.
7. Configure production signing only through protected GitHub secrets. Never
   commit keystores, APKs, OpenCV archives or private validation media.
8. Attach limitations: acoustic timing is not certified and OpenCV photo
   scoring remains experimental with mandatory human review.

Required permissions are `CAMERA`, `RECORD_AUDIO` and `VIBRATE`. Reject
`INTERNET`, network-state, location and external-storage permissions. The
canonical machine-readable gate is
[`apps/mobile/assets/release_contract.json`](../apps/mobile/assets/release_contract.json).

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

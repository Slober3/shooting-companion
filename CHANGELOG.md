# Changelog

All notable changes follow [Semantic Versioning](https://semver.org/).

## 0.2.0 - 2026-08-03

### Changed

- Replaced the five-tab large-title shell with compact Start, Logboek, Analyse
  and Meer destinations.
- Added one-tap session start, persistent draft autosave and save-and-next.
- Made sessions and confirmed series directly editable and removable.
- Based shot count and maximum score on recorded impacts, multiplicity and misses.
- Added session media, series media and manual four-point photo alignment.
- Updated CSV, PDF and encrypted backup formats while retaining v1 import.

### Removed

- Automatic impact detection, scan workflows, vision API, native vision core and
  dataset/training tooling.
- Expected-shot input and validation from the public domain and scoring APIs.

### Known limitations

- Every impact must be placed or marked as a miss by the user.
- Android release signing still requires repository secrets.

## 0.1.0 - 2026-08-03

### Added

- Offline Flutter Android application shell and Drift schema.
- Session, series, firearm, ammunition, range and target libraries.
- Deterministic integer and inner-ten scoring with line-breaking rules.
- Manual target editor, camera/gallery intake, history and analytics.
- CSV, PDF and encrypted backup creation and full replacement restore.
- Versioned ISSF 2026 target geometry.
- Vision API, safe native fallback and dataset evaluation tooling.

### Known limitations

- Automatic impact detection is disabled pending a representative labelled dataset.
- Android release signing still requires repository secrets.

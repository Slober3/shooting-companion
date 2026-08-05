# Changelog

All notable changes follow [Semantic Versioning](https://semver.org/).

## 0.4.0 - 2026-08-04

### Added

- Added a pure Dart analysis engine for centroid, bias, extreme spread, mean
  radius, sample deviation, R50/R90, covariance ellipses and angular spread.
- Added target-aware BR50 normalization, reliability tiers, stable subgroup
  suggestions and deterministic potential-score analysis.
- Added `Overzicht`, `Groepen` and `Coach` sections without adding another
  primary navigation destination.
- Added evidence-gated coach cards that always separate observation, evidence,
  possible explanations, an experiment and the next measurement.
- Added optional one-tap post-series reflection with at most three context tags.
- Added typed personal goals for score, group size, bias and training frequency.
- Added an offline drill library, balanced A-B-B-A experiment planner and a
  direction-confirmed MOA/milliradian sight calculator.
- Added privacy-safe, encrypted `.scvision` research exports with explicit
  consent, metadata stripping, hashes and strict payload limits.
- Added versioned vision contracts and a native C++/C-ABI command-line
  foundation that fails closed when the optional OpenCV backend is absent.

### Changed

- Upgraded the Drift database and encrypted backup manifest to version 5 while
  preserving v1-v4 import compatibility.
- Analysis compares only compatible target versions and distances by default;
  material variants are merged only when explicitly requested.
- Large-text metric grids and analysis controls now switch to layouts that do
  not sacrifice readable values or overflow on narrow devices.

### Safety boundaries

- Coaching remains deterministic and descriptive; it does not diagnose
  technique, fatigue or equipment causes from impact positions alone.
- Vision candidates are research-only contracts. No automatic score is exposed
  in the app and no candidate can become a confirmed impact without review.
- Training and vision content remain completely local, with no account,
  telemetry, model download or newly declared Android permission.

## 0.3.0 - 2026-08-04

### Added

- Added live photo viewers, source badges and long-press photo action menus for
  session and series photo strips.
- Added a built-in WRABF 50 m Rimfire Benchrest profile with a neutral A3
  training renderer, 25 record bulls, sighters, per-bull scoring and X-count.
- Added multi-bull scoring with lowest-shot duplicate handling, fixed 250
  maximum, incomplete-card confirmation and excess-shot penalties.
- Added compact, dismissible and themed application notices with live-region
  semantics and explicit close controls.
- Added firearm and ammunition names to session/series detail, CSV and PDF.
- Added an 8x transformable scoring viewport with pinch zoom, pan, visible zoom
  controls and a crosshair-based precision mode.
- Added explicit Place and Edit tools, a complete points/misses list and a
  50-step editor-local undo history.
- Added persistent System/Light/Dark appearance modes and Range Orange, Steel
  Blue, Forest Green and High Contrast palettes.
- Added atomic save-confirm-complete and photo-realignment repository use cases.
- Added embedded Noto Sans regular/bold fonts and Unicode PDF regression output.
- Added complete create, detail, edit, duplicate, archive, restore and safe
  delete flows for the firearm, ammunition, range and target libraries.
- Added editable custom cartridges and immutable versioning for custom targets
  after their first historical use.

### Changed

- Shortened visible action labels to `Foto` and `Beëindigen`, while preserving
  complete accessibility descriptions and responsive action stacking.
- Standardized independent form-field spacing and migrated session and series
  detail actions to the detached action dock.
- Moved Logbook filters into one safe filter surface and calculate list
  aggregates and filters in one parameterized SQLite query.
- Hardened sheets, forms, keyboard handling, system insets and landscape editor
  layouts for edge-to-edge Android.
- Replaced the free-form custom-target ring syntax with a validated three-step
  wizard and preview.
- Session completion is visible from Start, Logbook, session detail and the
  series editor without relying on long press.
- Replaced long edit sheets with top-aligned full-screen forms, shared
  high-contrast selectors and a detached inset-safe action dock.
- Upgraded the database and encrypted backup manifest to schema/version 4 while
  retaining v1, v2 and v3 import compatibility.

### Fixed

- Photo descriptions now appear below thumbnails and inside both ordinary and
  score-photo viewers, and update immediately after editing.
- Photo deletion now uses a contextual confirmation that explains how primary
  photo removal preserves confirmed impacts and scores.
- Replaced all direct default SnackBars with floating notices that no longer
  attach visually to the bottom navigation.
- Historical series material is resolved in joined detail queries, including
  archived firearms and ammunition profiles.
- Nearby or overlapping markers no longer steal taps while placing a shot.
- Dragging a marker no longer pans the zoomed scoring viewport underneath it.
- Drafts containing only notes or changed settings are never silently discarded.
- Range distances entered with a Dutch decimal comma retain their exact value.
- Bottom actions remain above gesture and three-button navigation bars.
- PDF bullets, accents, smart apostrophes and en/em dashes render correctly.
- Selected values remain readable in every palette and multiline labels stay
  at the top-left instead of floating in the middle of their field.
- Undo preserves the scoring viewport and action positions, including during
  rapid repeated input on compact screens.
- A long press selects an existing marker for editing without moving it or
  creating an additional impact.
- Expanded form sections no longer clip labels and focused fields stay visible
  above the keyboard and detached action dock.
- Photo choices now use compact, content-sized sheets without a redundant
  full-width cancel action.

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

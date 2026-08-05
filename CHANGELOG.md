# Changelog

All notable changes follow [Semantic Versioning](https://semver.org/).

## 0.5.0 - 2026-08-05

### Added

- Added structured offline shot-timer activities with public par, cadence and
  external-manual modes, reviewed events, local history and optional links to
  a series.
- Added the pure Dart timer state machine, statistics, presets and fake clock.
  The native Android AudioRecord/AudioTrack engine remains development-only
  behind a compile-time gate that is disabled in this release.
- Added timer-run and timer-event CSV exports and compact linked-run summaries
  to the PDF training report.
- Added one shared group plot with a deterministic extreme-spread segment,
  data-basis summary, overlay controls, legend and accessible explanations.
- Added one sendable potential-score compute service shared by global and
  single-series analysis routes.

### Changed

- Clarified that the standard blue covariance ellipse is a 1-sigma spread
  indicator rather than an outline and that valid distant impacts remain part
  of all group calculations.
- Replaced the remaining divided group-metric expansion with the shared
  divider-free expandable component.
- Upgraded the Drift database and encrypted backup manifest to version 6 while
  preserving imports from versions 1 through 5.
- Integrated the planned 0.4.2 analysis hotfix into 0.5.0; version 0.4.2 was
  not published as a separate build.

### Privacy and validation boundaries

- The stable 0.5.0+1 release does not expose acoustic timing and does not
  declare microphone permission. Par, cadence and external input remain fully
  available without microphone access.
- Acoustic timing can be compiled into internal development/profile builds for
  validation, but is not a public feature or reliability claim in this release.
- Public acoustic support requires at least three Android devices including the
  primary Samsung, indoor and outdoor testing, at least 300 independent strings
  and 3,000 reference shots, at least 95% exact event counts, median timing
  error at most 20 ms and P95 error at most 50 ms.
- The release still declares no internet, location or external-storage
  permission.

## 0.4.1 - 2026-08-05

### Added

- Added a full single-series analysis screen with target, normalized group and
  heatmap views, advanced group metrics, data-quality warnings, potential score
  and previous/next navigation within the same range visit.
- Added session analysis that compares individual series from one visit and
  keeps incompatible target, distance, firearm and ammunition contexts apart.
- Added an explicit historical-series picker and a configurable comparison set
  of up to five compatible series in the Analyse tab.
- Added tappable metric explanations with the current value, data basis,
  calculation, interpretation, minimum-data guidance and limitations.
- Added accessible chart summaries and structured non-visual data surfaces for
  future analysis charts.

### Changed

- Renamed the Analyse section `Groepen` to `Vergelijken` and made its selected
  source series and comparison composition explicit.
- Series chronology and period filters now use the parent range-visit time,
  with series sequence as the stable order inside a visit.
- Series and session detail now provide direct analysis entry points; analysis
  is no longer reachable only through the global Analyse tab.
- Archived firearm and ammunition names remain part of historical analysis
  contexts without introducing query-per-row loading.
- Strict comparison cohorts now also include cartridge and projectile diameter,
  preventing calibre mixes when no ammunition lot was selected.

### Safety boundaries

- Combined metrics are calculated only for exactly compatible target version,
  distance, firearm and ammunition contexts.
- Every explanation is descriptive: it does not infer technique or modify a
  historical score, impact or target snapshot.

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

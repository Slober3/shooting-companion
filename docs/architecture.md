# Architecture

The app follows feature-first clean boundaries:

```text
Flutter UI -> use cases/repositories -> Drift/SQLite
          -> pure scoring package
          -> pure analysis package -> pure coaching rules
          -> pure training definitions and calculators
          -> photo geometry package -> immutable local media
          -> experimental vision API -> native vision core -> candidate review
          -> local encrypted vision-research export
```

The scoring and photo-geometry packages have no Flutter, database or camera
dependency. Scoring accepts only explicit user impacts. Photo geometry converts
between normalized image coordinates and physical target millimetres using a
stored four-corner homography. Neither package writes session data.

SQLite stores target JSON snapshots, impacts, media metadata and alignments.
Original images are immutable files in internal app storage. UI, persistence,
scoring and geometry communicate through typed contracts rather than sharing
Drift rows or Flutter widgets.

Analysis is derived from confirmed impacts and never becomes authoritative
score data. `packages/analysis` owns physical group metrics, strict comparable
cohorts, BR50 bull-local normalization, subgroup suggestions and deterministic
potential-score searches. `packages/coaching` consumes those observations using
versioned, safety-filtered rules. `packages/training` contains immutable drill
definitions, A/B assignment plans and sight-correction mathematics. These
packages have no Flutter or Drift dependency and cannot mutate a session.

Derived analysis caches, coach cards and experiment calculations are disposable
and are not written into historical target snapshots. Persisted goals,
reflections or user feedback belong to repositories as user data; they must not
be confused with regenerated conclusions.

The experimental vision packages are outside the confirmed-score path. Native
analysis returns immutable JSON candidates plus provenance; only explicit user
review in the manual editor may later convert a candidate into an impact. A
build without an available image backend returns `unsupported` or
`notAnalyzed` and never fabricates candidates.

`packages/vision_research` is a separate privacy boundary, not a normal backup
format. It creates a password-encrypted `.scvision` container from an explicit,
metadata-stripped target crop and a strict consent manifest. It performs no
upload and is not connected to the production UI yet.

## Data lifecycle

1. Quick start atomically creates one active session and one draft series.
2. Every draft change is debounced and saved atomically within about 300 ms.
3. Imported images are staged, normalized and attached to the draft or session.
4. Optional four-point alignment maps image taps to target millimetres.
5. Score calculation is deterministic and synchronous.
6. Confirm and edit replace impacts and aggregates inside one transaction.
7. Analytics read confirmed series only; drafts remain resumable.

## Library lifecycle

Active selection streams exclude archived records. Historical detail, filters,
exports and reports use all-record streams so names remain resolvable. Series
overview/detail queries resolve firearm, ammunition and cartridge metadata in
the repository instead of starting a query per visible row. Removing
an unused custom item hard-deletes it; removing a referenced item archives it in
the same transaction as its usage check. Built-in cartridges and official ISSF
targets are repository-protected and can only be duplicated. Editing a used
custom target creates a new `profileVersion`; confirmed series retain their
original target JSON snapshot and geometry.

## Precision viewport

`TransformableScoringViewport` is the single coordinate boundary for drawn
targets, aligned photos, read-only series previews and four-point alignment.
Viewport gestures are temporary UI state. Every placement is converted through
the inverse transform to normalized scene coordinates and then to physical
millimetres; zoom and pan therefore never mutate persisted impacts.

Place mode deliberately ignores marker hit areas. Edit mode ranks candidates by
screen distance and then newest-first, with a fixed 24 dp radius independent of
zoom. Photo-dependent impacts retain both normalized image coordinates and
physical millimetres so a new alignment can recompute only the affected points
inside one transaction.

## Presentation and exports

Appearance choices are key/value preferences and require no database migration.
Semantic marker/status colours live in a `ThemeExtension`. PDF report data,
font loading and document composition are separate contracts; Noto Sans is
bundled locally so report generation remains offline and Unicode-safe.
Application feedback is routed through one floating, dismissible notice layer;
forms use shared spacing tokens and detached, inset-safe action docks.

## Multi-bull targets

Target schema 2 adds physical bull centres, record/sighter roles and a stored
multi-bull scoring policy. The BR50 renderer draws a neutral A3 training view;
it does not embed the official target artwork. Impacts retain `targetBullId`,
their raw ring value and counting disposition. Confirmed series store the
penalty and scored-bull count so historical totals are never silently changed.

## Versioning

- App: SemVer.
- Database: Drift `schemaVersion` and explicit migrations.
- Target: `profileId@profileVersion`; snapshots are stored per series.
- Photo alignment: algorithm version stored with corners and matrix.
- Backup: binary `SCB1` container with manifest v5; v1-v4 stay importable.

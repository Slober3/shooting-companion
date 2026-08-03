# Architecture

The app follows feature-first clean boundaries:

```text
Flutter UI -> use cases/repositories -> Drift/SQLite
          -> pure scoring package
          -> photo geometry package -> immutable local media
```

The scoring and photo-geometry packages have no Flutter, database or camera
dependency. Scoring accepts only explicit user impacts. Photo geometry converts
between normalized image coordinates and physical target millimetres using a
stored four-corner homography. Neither package writes session data.

SQLite stores target JSON snapshots, impacts, media metadata and alignments.
Original images are immutable files in internal app storage. UI, persistence,
scoring and geometry communicate through typed contracts rather than sharing
Drift rows or Flutter widgets.

## Data lifecycle

1. Quick start atomically creates one active session and one draft series.
2. Every draft change is debounced and saved atomically within about 300 ms.
3. Imported images are staged, normalized and attached to the draft or session.
4. Optional four-point alignment maps image taps to target millimetres.
5. Score calculation is deterministic and synchronous.
6. Confirm and edit replace impacts and aggregates inside one transaction.
7. Analytics read confirmed series only; drafts remain resumable.

## Versioning

- App: SemVer.
- Database: Drift `schemaVersion` and explicit migrations.
- Target: `profileId@profileVersion`; snapshots are stored per series.
- Photo alignment: algorithm version stored with corners and matrix.
- Backup: binary `SCB1` container with a versioned manifest; v1 stays importable.

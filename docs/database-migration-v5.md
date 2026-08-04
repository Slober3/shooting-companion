# Database schema 5: goals, reflections and coach feedback

Schema 5 adds local, optional coaching context without changing confirmed shot
geometry or historical scores.

## Changes

- The previous percentage-only `Goals` table is rebuilt as a typed metric table
  with cohort target, distance, optional firearm/ammunition, comparison and
  active state.
- Existing goals migrate to `scorePercentage` with comparison `atLeast`.
- `SeriesReflections` stores one optional perceived-quality response and at most
  three validated context tags per series.
- `CoachFeedback` stores the response to a versioned insight fingerprint and an
  optional snooze date.
- Indexes support active cohort goals, recent reflections and rule-versioned
  feedback lookups.

## Invariants

- A reflection belongs to an existing series and is removed with that series.
- Goal target, firearm and ammunition references must exist before save or
  restore.
- Goal values must be finite and non-negative.
- Reflection quality, tags and coach responses use allow-listed enum values.
- Duplicate reflection series IDs or coach insight fingerprints are rejected
  during backup validation.
- None of these records may rewrite an impact, target snapshot or score.

## Upgrade and rollback

The migration renames the old goal table, creates the typed replacement, copies
all rows with deterministic defaults, drops the old table and creates the two
new tables. `PRAGMA foreign_key_check` runs before the upgraded database is
accepted. Drift performs the upgrade transactionally; any error leaves the
previous schema intact.

Encrypted backup manifest 5 mirrors the typed goals, reflections and feedback.
Manifests 1 through 4 remain importable and receive empty collections for the
new optional records. Restore validates all v5 relationships before replacing
any local data.

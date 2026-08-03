# Database schema 2 and v1 migration

Schema 2 makes drafts, actual shot counts and media first-class and removes all
scan tables. The exported Drift schema-1 snapshot in
`apps/mobile/drift_schemas/drift_schema_v1.json` is the migration contract.

## Invariants

- At most one session has status `active`.
- At most one `draft` series exists per session.
- At most one `primaryScoringPhoto` exists per series.
- An alignment references an existing image and disappears with that image.
- Deleting an image sets optional impact source references to null.
- Series and session children cascade on deletion.

These are enforced by foreign keys plus partial unique SQLite indexes, not only
by UI state.

## Upgrade mapping

1. Preserve libraries and target profiles.
2. Copy sessions and add `updatedAtUtc`; if corrupt legacy data contains several
   active sessions, keep the newest active and complete the others.
3. Copy series snapshots and compute shot count from impact multiplicity.
4. Only when a legacy series has no impacts, use its legacy expected count.
5. Compute maximum from actual count and the maximum ring in the stored target
   snapshot; never assume ten.
6. Copy impacts without automatic origin or confidence metadata.
7. Map legacy `after` images to primary scoring photos and `baseline` images to
   attachments; derive their session through the series relation.
8. Drop scan and scan-edit records.
9. Create indexes and run `PRAGMA foreign_key_check`.

Every step runs in the Drift upgrade transaction. A thrown error leaves schema 1
unchanged. Migration tests cover empty, populated, miss/multiplicity and legacy
image cases.

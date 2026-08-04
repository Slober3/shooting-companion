# Database schema 4 and multi-bull scoring

Schema 4 adds reproducible multi-bull results without recalculating historical
ISSF series.

`shot_impacts` adds:

- nullable `target_bull_id`;
- `raw_score_value`;
- `score_disposition` (`counted`, `duplicateNotCounted` or `miss`).

`shooting_series` adds:

- `score_penalty`, default zero;
- nullable `scored_bull_count`.

During v3 → v4 migration, the existing `score_value` is copied to
`raw_score_value`, every existing impact is marked `counted`, penalties remain
zero and bull identifiers remain null. Existing totals and target snapshots are
not recalculated. The v1 rebuild already creates the current series/impact
tables directly and supplies the legacy raw score while copying impacts.

The generated schema fixture validates v1, v2 and v3 upgrades to v4 and runs
`PRAGMA foreign_key_check`. Encrypted back-up manifest 4 mirrors the new fields;
older manifests receive the same safe defaults through the payload adapter.

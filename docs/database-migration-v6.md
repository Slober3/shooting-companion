# Database schema 6: training activities and shot timer

Schema 6 adds training data without rewriting any historical session, series,
impact, target snapshot, score, reflection or coach record.

New tables:

- `training_activities` stores activity kind, state, immutable configuration
  and summary snapshots, session context and timestamps;
- `training_activity_series_links` connects an activity to series without
  adding timer fields to authoritative score rows;
- `shot_timer_events` stores relative microseconds, source, disposition and
  optional detector quality;
- `timer_presets` stores built-in and custom versioned configurations;
- `acoustic_calibration_profiles` stores local detector settings, never audio.

The v5-to-v6 upgrade only creates new tables and indexes. It then runs
`PRAGMA foreign_key_check` inside the migration transaction. A failure aborts
the complete upgrade. Existing v1-to-v5 migration paths run before this additive
step.

Backup manifest 6 serializes the five new record sets. V1-v5 adapters supply
empty collections. Restore validates identifiers, one-series timer linking,
same-session multi-series activities, strictly increasing counted event times
and calibration bounds before replacing current data. Raw audio is not a backup
asset and no schema field can refer to one.

# Database schema 3 and library lifecycle

Schema 3 adds `builtIn` and `archived` to cartridges and `archived` to
ammunition profiles, ranges and target profiles. The existing firearm archive
flag is preserved. During v2 migration every existing cartridge is marked as
built-in because v2 did not support user-created cartridges; all new archive
flags start as false.

The migration adds active-record indexes and a unique target
`(profile_id, profile_version)` index. It finishes with `foreign_key_check` and
is covered by generated schema-2 fixtures. A direct v1 upgrade first performs
the lossless session/media schema-2 conversion, then adds the schema-3 library
fields before indexes are created.

Removal is a repository transaction:

- unused custom records are deleted;
- referenced records are archived;
- built-in cartridges and targets are blocked;
- a custom cartridge with active ammunition requires explicit dependent
  archiving, after which cartridge and profiles are archived together;
- ammunition can only be restored after its cartridge is active;
- editing a used custom target archives the old version and inserts the next
  version without changing historical series snapshots or score aggregates.

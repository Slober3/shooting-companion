# `.scbackup` format

The encrypted container remains binary-compatible at its outer layer:

```text
SCB1 | 16-byte salt | 12-byte nonce | 16-byte GCM tag | ciphertext
```

The key is derived with Argon2id using 19 MiB, two iterations, parallelism one
and a 32-byte result. Ciphertext is an AES-256-GCM encrypted ZIP containing
`manifest.json`, `database.json` and `media/<asset-id>.<extension>`.

Manifest version 7 contains sessions, confirmed and draft series, reviewed
impacts, media metadata, photo alignments and preferences. Every file has a
SHA-256 hash and byte size. It also stores `builtIn` and `archived` library
states, target-bull identifiers, raw ring values, counting dispositions,
multi-bull penalties and scored-bull counts. Version 5 additionally stores typed
goals, optional series reflections and local coach-feedback preferences.
Derived analysis/coaching output, caches, drill assets and temporary vision
results are omitted.

Version 6 adds structured training activities, timer events, presets and local
calibration settings. Version 7 adds resumable vision-scan drafts and their
private photos, linked vision analyses, review decisions, engine versions,
placement method and positional uncertainty. Canonical warps, masks and debug
overlays are derived data and are not included.

Manifest versions 1 through 6 stay importable. A v2 adapter marks existing
cartridges as built-in and initializes the new archive flags as false. The v1
`expectedShots` value is used only
when no impact rows exist; scan and scan-edit records are ignored. Existing
after-images become primary scoring photos and baseline-images become ordinary
attachments when their parent series can be resolved.

Creation, authenticated inspection and restore are implemented. Restoration
stages and hashes every image, creates a safety backup, replaces records in one
database transaction and deletes staged files on failure. Current local images
are removed only after the replacement transaction succeeds.
Cartridge/ammunition dependencies, bull references, insight/training
relationships and all vision series/image/analysis references are validated
before any replacement begins. Unknown analysis references, malformed vision
JSON and missing draft media reject the restore before replacement.

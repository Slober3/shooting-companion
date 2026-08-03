# `.scbackup` format

The encrypted container remains binary-compatible at its outer layer:

```text
SCB1 | 16-byte salt | 12-byte nonce | 16-byte GCM tag | ciphertext
```

The key is derived with Argon2id using 19 MiB, two iterations, parallelism one
and a 32-byte result. Ciphertext is an AES-256-GCM encrypted ZIP containing
`manifest.json`, `database.json` and `media/<asset-id>.<extension>`.

Manifest version 2 contains sessions, confirmed and draft series, manual
impacts, media metadata, photo alignments and preferences. Every file has a
SHA-256 hash and byte size. Thumbnails and other derived caches are omitted.

Manifest version 1 stays importable. Its `expectedShots` value is used only
when no impact rows exist; scan and scan-edit records are ignored. Existing
after-images become primary scoring photos and baseline-images become ordinary
attachments when their parent series can be resolved.

Creation, authenticated inspection and restore are implemented. Restoration
stages and hashes every image, creates a safety backup, replaces records in one
database transaction and deletes staged files on failure. Current local images
are removed only after the replacement transaction succeeds.

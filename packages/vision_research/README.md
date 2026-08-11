# Vision research export

`shooting_companion_vision_research` in Shooting Companion `0.8.0+1` creates and validates the offline
`.scvision` research container. It deliberately has no database, UI, network or
session dependency.

The authenticated outer container is:

```text
SCV1 | 16-byte Argon2id salt | 12-byte AES-GCM nonce |
16-byte authentication tag | ciphertext
```

The encrypted payload contains canonical JSON records and one re-encoded target
crop. Both have a SHA-256 digest and exact size in the canonical manifest.
JPEG and PNG inputs are decoded and re-encoded before export; EXIF, XMP, text
chunks and ICC metadata are not retained.

Only the following research data can enter the records DTO:

- target-profile snapshot and version;
- projectile diameter;
- confirmed manual impacts without database or image IDs;
- manual target alignment;
- closed-vocabulary quality labels;
- explicit, versioned consent choices.

Names, notes, range locations, device identifiers, GPS, serial numbers and
uncropped source images have no field in the format. Exports are never uploaded
by this package.

The implementation enforces crop, pixel, metadata, impact and container size
limits before expensive operations where possible. File writes are chunked and
refuse to replace an existing destination.

This research format is separate from encrypted application backup manifest 8.
It never grants automatic candidates authority over a score: only reviewed,
confirmed impacts can enter an export. Real validation photos remain in the
Git-ignored `.local/vision-validation/` workspace.

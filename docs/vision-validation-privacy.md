# Private vision-validation workspace

Real target photographs and annotations are private research material. Keep all
local validation work below:

```text
.local/vision-validation/
  incoming/       untouched local imports
  cropped/        EXIF-free target crops
  annotations/    local ground truth
  reports/        local metrics and rendered overlays
  exports/        encrypted research exports
```

The complete tree is explicitly ignored by Git. CI also runs
`tools/check_privacy_leaks.py`, which rejects any force-tracked file below this
tree, private dataset directories, backups, APKs, signing keys, camera-style
personal filenames and unreviewed photo/audio/video fixtures.

Do not copy the supplied practical-test photos into `test/fixtures`. Automated
tests must use synthetic fixtures or media with explicit redistribution rights.
A committed media fixture must live below a `test/fixtures` directory and have
an adjacent `<filename>.fixture.json` file documenting at minimum:

```json
{
  "origin": "synthetic",
  "license": "CC0-1.0",
  "privacyReviewed": true,
  "containsPersonalData": false
}
```

The leak check validates the presence of that sidecar. Reviewers must still
verify its truthfulness; CI cannot infer consent or copyright ownership from
pixels.

Research exports remain opt-in, EXIF-free and encrypted as documented in the
vision research module. No private validation directory is bundled into the app
or full application backup.

## Local annotation wizard

Open `tools/vision_validation_wizard.html` directly in a current Chromium-based
browser. The single-file tool has no external scripts and performs no network
requests. A restrictive content-security policy also blocks network connections
if code is accidentally added later. It supports quarter-turn rotation, an
explicit target crop, physical card grouping, target/calibre metadata and point
labels for isolated holes, clusters, overlaps, patches, damage and uncertain
observations.

Rotation and later crop adjustments preserve annotation positions in source
image coordinates. Annotations outside a newly tightened crop are removed with
an explicit status message; they are never silently shifted to another part of
the target. The exported coordinates are normalized relative to the top-left of
the final crop. Review the crop before export: re-encoding removes metadata, but
it cannot remove a serial number, face or other identifying pixels that remain
inside the selected target area.

Choose `.local/vision-validation/` as the output directory when the browser
supports local directory access. The wizard creates `cropped/` and
`annotations/`; otherwise it downloads the two files for manual placement.
Every JPEG is created from a canvas and therefore contains pixels only, not the
source EXIF block. The JSON sidecar records source/crop SHA-256 hashes and the
privacy transformations. It contains no original filename or filesystem path.
The source hash is non-reversible but can correlate an export with an identical
original held elsewhere, so sidecars remain private research data as well.
The wizard's JPEG and JSON files are **not encrypted at rest**. Write them only
below the ignored `.local/vision-validation/` tree. Encryption applies to an
explicit `.scvision` research export leaving that private workspace, not to the
working annotation files themselves. Use a pseudonymous card-group label rather
than a name, range location or other personal identifier.

Only reusable target, distance and calibre defaults are remembered in local
browser storage. Physical card groups, shot counts and condition flags are not
persisted. A card group must be entered for each new selection; the explicit
`Zelfde groep voor alle gekozen foto's` action may be used when all selected
views genuinely show the same physical card. This prevents unrelated cards from
being grouped through a stale browser default.

Exports include a source-hash prefix in their generated name, preventing two
views exported in the same second from overwriting each other without exposing
the original filename. Never move the untouched source photographs into the
repository checkout.

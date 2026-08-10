# Manual photo alignment

## Coordinate systems

Original images are orientation-corrected and re-encoded without EXIF before
storage. Coordinates persisted with an image are normalized to `[0, 1]`, with
`(0, 0)` at its top-left. Target coordinates are millimetres relative to target
centre, with positive x to the right and positive y down.

The four selected image points map to the physical card rectangle:

```text
TL -> (-width/2, -height/2)
TR -> (+width/2, -height/2)
BR -> (+width/2, +height/2)
BL -> (-width/2, +height/2)
```

Schema 8 stores image coordinates against the immutable, EXIF-normalized
original. A persisted `rotationQuarterTurns` rotates only the displayed source
before it is mapped to card millimetres. Rotating a photo therefore never
rewrites or re-encodes the original image and never changes its source
coordinates.

`manual-homography-v2` uses normalized coordinates and solves the projective
transform in a numerically stable way. The ordered inferred card corners,
matrix, rotation, alignment mode, complete anchor evidence, residuals,
condition estimate and algorithm version are serialized. On load, the matrix
is recomputed from the stored anchors and cross-checked, so a stale or tampered
matrix cannot silently alter a score. Legacy `manual-homography-v1` records
remain readable.

Two alignment modes are available:

- **Full card** maps the four visible card corners.
- **Ring-assisted** maps a marked aiming point, the card's top direction and
  four cardinal observations on each of two known scoring rings. This permits
  alignment when the physical card corners are outside the photo.

Both editors project the complete target geometry back onto the photo before
confirmation: card boundary, axes, scoring rings, black-zone boundary, aiming
point, anchors and any shot/projectile circles. The user must explicitly choose
`Uitlijning klopt`.

## Validation

Before confirmation, the full-card editor rejects non-finite or out-of-image
points, duplicates, crossings, near-collinearity, incorrect winding and edges
that are too short. Ring-assisted alignment requires two distinct known rings,
four ordered cardinal observations per ring and a stable top direction. Its
inferred card corners may lie outside the crop, but the observed ring evidence
must remain inside the image.

Repository code is authoritative. It rebuilds the transform and assigns one of
these quality states from residuals and conditioning:

- `accepted`: RMS <= 0.75 mm and maximum residual <= 1.5 mm;
- `manualReviewOnly`: RMS <= 1.5 mm and maximum <= 3.0 mm;
- `rejected`: worse, incomplete or numerically unstable.

Rejected geometry is never used to create photo-dependent millimetre points.
The photo remains an attachment and scoring can continue on the drawn target.
Four-corner fits have no independent overdetermined residual; their projected
overlay and explicit user confirmation remain essential.

## Edit rules

- A target change invalidates the existing alignment and requires realignment.
- A calibre change keeps coordinates and recalculates scores.
- A distance change affects physical spread analytics, not ring score.
- Replacing the primary photo demotes the old photo to attachment.
- Removing the primary photo clears impact source-image references but preserves
  physical coordinates and scores them on the drawn target.
- Realignment first previews the resulting coordinates and scores. The
  repository then recalculates every photo-dependent point from its immutable
  normalized source coordinate and rejects a UI preview that differs by more
  than 0.05 mm. Alignment, points and score aggregates are committed in one
  transaction only after explicit confirmation.
- Manual points without a source photo remain byte-for-byte unchanged.

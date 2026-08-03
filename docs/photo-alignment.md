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

`manual-homography-v1` solves one 3x3 projective transform and its inverse. The
ordered points, matrix, card dimensions and algorithm version are serialized.
This lets a restored backup render the same overlay without recalibration.

## Validation

Before confirmation, the editor rejects non-finite or out-of-image points,
duplicates, a self-intersecting or non-convex quadrilateral, incorrect winding,
and an area below 20% of the image. Rejection never deletes the photo: it can be
kept as an attachment and scoring can continue on the drawn target.

## Edit rules

- A target change invalidates the existing alignment and requires realignment.
- A calibre change keeps coordinates and recalculates scores.
- A distance change affects physical spread analytics, not ring score.
- Replacing the primary photo demotes the old photo to attachment.
- Removing the primary photo clears impact source-image references but preserves
  physical coordinates and scores them on the drawn target.
- Realignment first previews the resulting coordinates and scores; persistence
  occurs only on explicit confirmation.

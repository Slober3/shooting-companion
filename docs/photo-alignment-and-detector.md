# Photo alignment and experimental detector

Version `0.8.0+1` keeps two separate responsibilities:

1. alignment maps a visible point in the immutable source photo to physical
   target millimetres;
2. the detector proposes visible hole candidates that the user may accept,
   edit or reject.

The deterministic Dart score engine is the only component that assigns ring
values. Neither OpenCV nor the alignment UI confirms a score.

## Alignment workflow

Use four-corner alignment when the complete card is visible. Use ring-assisted
alignment for a central crop or when paper corners cannot be placed reliably.
If residual quality is rejected, keep the image as an attachment and score on
the drawn target.

Before confirming, the projected overlay shows the card boundary, axes, target
centre, black-zone boundary, scoring rings, anchors and projectile circles.
Fine tuning changes the real anchors and recalculates the homography; it is not
a cosmetic transform. Available controls are:

- drag the overlay or use directional nudges for translation;
- pinch the overlay or use scale buttons for uniform scale;
- rotate in quarter-degree steps or with a two-finger gesture;
- edit individual anchors for local correction;
- adjust opacity, blink the comparison and reset to the detected solution;
- rotate the displayed source in quarter turns without mutating the original.

Fine tuning cannot correct a non-planar fold or a strongly curved sheet. Ring
residuals remain authoritative: a visually plausible overlay with unstable or
excessive residuals is not accepted for photo-derived scoring.

## Classical OpenCV pipeline

The bundled candidate algorithm is `dual-zone-evidence-v3` on OpenCV 4.13.0.
It uses locally adaptive evidence rather than one global threshold:

- separate dark-core evidence on light paper and fibre/top-hat evidence in the
  black target zone;
- theoretical masks for printed ring lines;
- suppression of long print, large uniform sticker/patch edges and weak
  components;
- physical diameter, circularity, raggedness and morphology response;
- distance-transform evidence for a possible merged cluster, without
  inventing multiplicity.

The review screen exposes proposal counts, raw structures, rejection counters,
confidence distribution and warnings. A zero-candidate result is therefore an
explainable result, not proof that no holes exist. Fully manual placement stays
one action away.

The current automatic slice remains ISSF Precision with a user-selected `.22
LR` projectile profile and one after-photo. It cannot infer calibre, old versus
new holes, misses outside the paper or exact multiplicity of an overlap.

## Validation boundary

Synthetic native tests cover light/dark zones, rings, print, stickers,
illumination gradients, overlap warnings, deterministic IDs and evidence JSON.
They do not establish real-world accuracy.

A public accuracy claim still requires the private, card-grouped gate:

- at least 100 independent photos and 500 annotated `.22` holes;
- at least three Android camera models;
- registration success at least 95% on accepted photos;
- isolated-hole precision at least 90% and recall at least 85%;
- median positional error at most 1.5 mm;
- P95 processing at most eight seconds on the primary Samsung device.

Personal source photos and annotations remain in the Git-ignored
`.local/vision-validation/` folder. The research wizard re-encodes the target
crop without source EXIF/GPS and writes a pseudonymous JSON sidecar.

## Technical references

- [OpenCV thresholding](https://docs.opencv.org/4.13.0/d7/d4d/tutorial_py_thresholding.html)
- [OpenCV watershed](https://docs.opencv.org/4.12.0/d3/db4/tutorial_py_watershed.html)
- [OpenCV ECC image alignment](https://docs.opencv.org/4.x/dc/d6b/group__video__track.html)
- [TargetScan quick start](https://targetshootingapp.com/wiki/Quick_Start/)
- [Computer Vision Pipeline for Iterative Bullet Hole Tracking](https://arxiv.org/abs/2601.17062)

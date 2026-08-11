# Vision fixtures

Only synthetic, non-photographic fixtures belong here. `checkerboard.pgm`
exercises image probing and deterministic grayscale quality metrics. It is not a
target image and must never be used as evidence that registration or impact
detection works.

OpenCV detector regressions generate their target image in memory at test time.
No photographed targets or user-supplied images are committed here. See
[`DETECTOR.md`](../../DETECTOR.md) for covered failure modes and limitations.

This restriction also applies to patched targets, crops, screenshots, EXIF
sidecars and debug masks derived from personal photos. Device and stand
validation belongs exclusively in the Git-ignored local validation workspace.

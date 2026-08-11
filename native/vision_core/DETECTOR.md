# Classical candidate detector

The OpenCV backend proposes visible impact locations for review. It deliberately
does **not** determine calibre, multiplicity, shot count or score. Those remain
explicit profile/user inputs and deterministic Dart-domain decisions.

## Pipeline (`dual-zone-evidence-v3`)

1. Correct slow illumination changes by subtracting a large Gaussian background
   estimate, then apply conservative local contrast equalisation.
2. Estimate the central dark target zone from a strongly smoothed image. Light
   and dark target areas use separate evidence paths:
   - light area: local adaptive dark seed plus dark-core / black-hat response;
   - dark area: local adaptive bright seed plus torn-fibre / top-hat response,
     optionally supported by a darker core.
3. Build a theoretical ring-line mask from the selected target profile. Printed
   ring responses are measured and suppressed when no independent hole evidence
   exists.
4. Detect edges of large, uniform regions (patches, stickers and target-zone
   boundaries). Their edges are negative evidence; a genuine dark core or fibre
   edge can still override that negative signal.
5. Reject long, line-like and weak printed components using aspect ratio,
   circularity, ring overlap and independent local evidence.
6. Measure every surviving component:
   - local contrast;
   - dark-core contrast;
   - bright fibre-edge contrast;
   - diameter ratio versus the **user-selected** projectile diameter;
   - circularity and contour raggedness;
   - ring-line, patch-edge and black-zone overlap;
   - distance-transform peak count.
7. A large component with multiple distance-transform peaks is marked
   `possibleOverlap`. It remains one low-confidence proposal. The engine never
   invents multiplicity.

Structured measurements are emitted as `detectorEvidence` next to the existing
enum-compatible `reasons`. Older clients may ignore this additive JSON member.
Aggregate suppression counters, adaptive thresholds, seed-pixel counts and
confidence counts are emitted in `diagnosticMetrics`. A zero-proposal result is
therefore observable and explainable instead of being silently indistinguishable
from a disabled or missing detector.

## Safety and limitations

- All candidates require visual user review.
- Low-confidence candidates are suggestions, not confirmed impacts.
- One after-photo cannot distinguish old and new holes.
- Exact overlap cannot be reconstructed.
- A shot outside the photographed paper cannot be detected.
- Large folds, tears, patches and merged clusters may require fully manual
  placement.
- The current supported automatic slice remains the selected ISSF Precision
  profile with `.22 LR`; the detector never infers either from pixels.

## Tests

`opencv_candidate_detector_tests` is built only when OpenCV is present. It uses
a generated, deterministic card image to cover:

- an impact in a light zone under an illumination gradient;
- an impact in a black zone where the fibre edge carries the signal;
- ring and long-print suppression;
- a large uniform sticker that must not become an impact;
- a merged component marked as possible overlap;
- deterministic candidate IDs and coordinates;
- serialized evidence in the JSON contract.

The ordinary geometry-only native test suite remains runnable without OpenCV.
Synthetic tests are regression guards, not release-accuracy evidence. Real
release metrics must come from the private, card-grouped validation set.

# Target profiles

Built-in ISSF profile version 2 follows the ISSF Edition 2025 Second Print
07/2026, effective 1 July 2026, rules 6.3.4.4 and 6.3.4.5:

- 25 m Rapid-Fire Pistol: ring diameters 100, 180, 260, 340, 420 and 500 mm;
  inner ten 50 mm; black through the 5 ring.
- 25 m Precision / 50 m Pistol: 50 mm increments from 50 through 500 mm;
  inner ten 25 mm; black through the 7 ring.

The canonical card is 550 × 550 mm. The rulebook permits a shorter visible
height; that margin does not alter score geometry.

Custom concentric targets are stored as JSON and marked experimental. Published
profiles are immutable: correction means a new profile version.

## WRABF BR50

`wrabf-50m-rimfire-br50@1` uses target schema 2 and is version-bound to WRABF
Rules 2023-2027 V4.4, revised 5 May 2026. The card is A3 landscape (420 × 297
mm), at a fixed 50 m distance. It contains 25 record bulls on a measured 5 × 5
grid plus ten non-scoring sighter bull positions from the current target
reference. Its validation status is `officialGeometryTrainingRendering`:
official score geometry with a deliberately neutral app rendering. Ring
diameters are:

| Zone | Diameter (mm) |
| --- | ---: |
| X | 0.792 |
| 10 | 6.350 |
| 9 | 12.700 |
| 8 | 19.050 |
| 7 | 25.400 |
| 6 | 31.750 |
| 5 | 38.100 |

The app stores physical bull centres and rectangular scoring bounds. It draws a
neutral training representation with record numbers and distinct sighters. No
WRABF/ERABSF logo, federation typography, official target PDF or seller image is
included in source or APK. Sources:

- [WRABF rules](https://www.wrabf.com/WRABF%20Rules.htm)
- [WRABF target page](https://www.wrabf.com/WRABF%20Targets.htm)
- [user-provided product example](https://www.krale.shop/nl/benchrest-schijf-br50-5136/)

# Insights and training foundation

## Implemented pure-Dart boundaries

`packages/analysis` currently provides deterministic calculations for:

- centroid, horizontal/vertical bias, extreme spread and mean radius;
- sample standard deviation, empirical R50/R90 and covariance ellipses;
- MOA and milliradian output when distance is known;
- correct exclusion of misses and weighted multiplicity warnings;
- BR50 positions normalized to each record bull's local centre;
- strict cohorts by target version, distance, firearm and ammunition;
- score trends and consistency across comparable series;
- possible two- or three-group suggestions only after the configured sample,
  silhouette and stability gates;
- reproducible potential-score translation using the production score engine.

`packages/coaching` converts qualifying observations to structured, versioned
coach insights. Its safety policy rejects insufficient evidence and causal
diagnoses that impact coordinates cannot support. A card contains an
observation, evidence, multiple possible explanations, one experiment and the
next measurement. It is not a chatbot.

`packages/training` provides:

- nine versioned offline drill definitions, all explicitly marked experimental
  until coach-reviewed;
- balanced A-B-B-A experiment assignments and minimum-data progress states;
- MOA/milliradian sight calculations that require direction confirmation and
  mark corrections from fewer than five positioned shots as provisional.

All three packages are independent of Flutter, SQLite and network access. Their
tests are run as separate CI gates.

## Product integration

Version 0.4 integrates the analysis and coaching foundations into the existing
offline app:

- `Analyse` contains `Overzicht`, `Groepen` and `Coach` without adding a fifth
  primary navigation destination;
- the group view renders impacts, centroid, covariance ellipse, optional density
  and deterministic potential-score output;
- typed goals, optional series reflections and coach feedback are stored in
  database schema 5 and encrypted backup manifest 5;
- coachmodus is opt-in and the post-series check can always be skipped;
- `Meer > Trainingstools` exposes the built-in drills, an A-B-B-A planner and a
  direction-confirmed sight calculator as local preview tools.

The mathematical foundation does not authorize automatic advice. UI and
repository integration preserve these rules:

- only confirmed series participate in normal analysis;
- cohorts do not silently mix target versions, distances or firearms;
- a subgroup suggestion never removes a shot or changes score;
- potential score is a what-if translation, not an automatic sight adjustment;
- sight directions must be configured and confirmed by the user;
- drill text marked experimental is not presented as coach-certified guidance;
- no calculation changes a historical score or target snapshot.

## Remaining roadmap work

The remaining product and validation work is:

- no versioned in-memory/isolate cache or measured 10,000-series benchmark;
- no full cross-series heatmap/overlay control or inferential effect-size view;
- no persisted user flyer tags or inferential material-comparison claim;
- no custom drill duplication or repository for drill versions;
- no stored experiment results, effect-size analysis or adaptive ordering;
- no persisted sight profiles and no end-to-end verification-group workflow;
- no qualified-coach sign-off on the bundled experimental drill catalogue;
- no maintenance, ammunition inventory, chronograph import or timer module.

These are product and validation gates, not missing behavior that the pure
calculation packages should silently infer.

## Local verification

```powershell
foreach ($package in @(
  "packages/analysis",
  "packages/coaching",
  "packages/training"
)) {
  Push-Location $package
  dart pub get
  dart analyze
  dart test
  Pop-Location
}
```

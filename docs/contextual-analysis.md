# Contextual analysis

## Purpose

Analysis is available at three deliberately different scopes. The app must
always show which scope is active before it presents a group or trend.

1. **Series analysis** describes one confirmed series.
2. **Session analysis** compares series from one range visit.
3. **Global comparison** starts from a user-selected historical series and
   compares an explicit selection of compatible series.

The newest series is only a convenient initial selection. It is never an
implicit permanent data source.

## Entry points

- A confirmed series row exposes `Analyseer`.
- Series detail contains a compact `Trefbeeld` card and `Volledige analyse`.
- Session detail contains `Analyse sessie` when it has confirmed series.
- The Analyse tab contains `Overzicht`, `Vergelijken` and `Coach`.
- `Vergelijken > Kies reeks` opens the historical picker. Date, range-visit
  time, series number, target, distance, firearm, ammunition, positioned-shot
  count and mean radius identify each option.

The series screen supports target, normalized-group and density views, plus
previous/next navigation within the same session. Session analysis lets the
user select up to five series for a readable overlay.

## Comparability

The strict comparison key is:

```text
targetProfileVersionedId
distanceMeters
projectileDiameterMm
cartridgeId
firearmId
ammoLotId
```

Any difference creates a separate cohort. Missing firearm or ammunition is a
real key value rather than a wildcard. Historical names are loaded even when a
library record is archived. Target snapshots and confirmed scores remain
immutable.

Chronology uses the parent session start time. Series within one session are
ordered by sequence number and finally by stable ID. Period filters use that
same session time, so a series created or edited later remains attached to the
date of the actual range visit.

## Metric explanations

Metrics with an information affordance open a safe, large-text explanation
sheet containing:

- the value currently shown;
- the number of selected series and positioned/registered shots;
- a restrained data-quality label;
- what the metric measures;
- how it is calculated;
- how it may be read;
- the minimum useful data basis;
- concrete limitations.

Definitions live in one registry so series, session and global screens use the
same wording. Explanations do not diagnose grip, trigger control, fatigue,
equipment faults or any other cause from impact positions alone.

## Multi-bull targets

For BR50, every positioned record impact is normalized relative to its own bull
centre before group metrics are calculated. Sighters are excluded. A missing or
unknown bull ID excludes only that impact from physical analysis and does not
change the confirmed score.

## Persistence and performance

Analysis is derived data. No new database or backup schema is required for
version 0.4.1. The repository loads confirmed series, parent sessions, impacts,
material names and reflections in bulk. The UI does not open one database stream
per visible series row.

Provider contexts are available for:

- one series;
- one session split into strict cohorts;
- all comparable series for a selected source series.

No analysis action rewrites impacts, aggregate scores or target snapshots.

## Accessibility

- Plots expose a concise semantic summary.
- Colour is supplemented by labels, marker shapes and legends.
- Metric tiles expose their value and explanation action to TalkBack.
- Explanation sheets and scope surfaces remain usable at 320 dp and 200% text.
- Structured chart values are preferred over a horizontally scrolling table.

## Validation

Tests cover parent-session chronology, strict cohort splitting, archived
material names, historical selection, series and session entry points, plot
modes, BR50 normalization, large-text explanation surfaces and previous/next
navigation.

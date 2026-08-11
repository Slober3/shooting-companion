# Shot timer and persisted training activities

## Product boundary

The timer is an offline training aid. It is not certified match equipment.
Version `0.8.0+1` retains acoustic live fire through a guided first-use flow.
The user explicitly activates the microphone, verifies the chosen start signal
and then reviews every detected event before saving. The app does not claim to
isolate one shooter on a busy shared range.

Raw audio is never stored. The Android engine turns microphone frames into
relative impulse timestamps on a native worker thread and sends only states,
levels and candidate events to Flutter. A candidate becomes persisted only
after the user reviews the run.

## Timing modes

- `acousticLiveFire`: native start signal, in-memory microphone capture,
  impulse detection, first shot, last shot, splits, sensitivity and echo
  lockout;
- `par`: fixed or random delay followed by one to three par signals;
- `cadence`: fixed or progressive signal intervals with repetitions and rest;
- `externalManual`: validated times copied from a dedicated external timer.

All modes use relative microseconds as their authoritative timing data. UTC is
stored only to place the activity in the logbook. Timer events never change a
series score, impact count or free-form note.

## Android lifecycle

The native engine uses `AudioTrack` and `AudioRecord` timestamps mapped to a
monotonic clock. It warms the output route before a delayed start and suppresses
the start tone through a configurable blanking window. Acoustic capture stops
and releases its resources when the timer closes, the app becomes inactive, or
the capture pipeline reports an input or permission error. An interrupted run
is not silently completed.

Active audio-route and audio-focus monitoring is not implemented yet. A route
change (for example connecting Bluetooth) therefore requires stopping the run
and testing the device signals again.

The app keeps the screen awake only while a run is active. There is no
foreground service and no background microphone capture.

## Persistence

Database schema 6 stores a generic `TrainingActivity`, optional links to one or
more series, typed timer events, versioned presets and acoustic calibration
profiles. Shot-, par- and cadence-timer activities may link to at most one
series. Drill and experiment activities may link multiple series from the same
session.

Configuration and summary JSON are immutable snapshots with their own schema
version. Individual events remain typed rows so they can be reviewed, excluded,
exported and analysed without parsing user notes. Multiple activities may be
linked to one series.

## Reliability and validation

Device- or calibre-specific accuracy claims require comparison against a
dedicated reference timer with all of these conditions met:

- at least three recent Android devices, including the primary Samsung device;
- indoor and outdoor results reported separately;
- at least 300 independent strings and 3,000 reference shots;
- at least 95% exact event count for supported single-shooter strings;
- median timing difference at most 20 ms;
- P95 timing difference at most 50 ms;
- no start-signal double registration;
- every uncertain or false event remains reviewable.

The first intended validation profiles are `.22 LR` and `9x19 mm`. Results are
reported per device, audio route and environment. Other calibres may be used,
but receive no accuracy claim until the same gate is passed. Every run remains
editable and explicitly labelled as a training measurement.

## Privacy and exports

Backups may preserve imported or development-created configurations, confirmed
event offsets and calibration parameters, never PCM or audio files. CSV export
separates runs and events from the one-row-per-series score table. PDF reports
show a compact human-readable summary. Copying a timer summary into a series
note is an explicit user action.

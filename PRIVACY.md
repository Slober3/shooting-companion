# Privacy

Shooting Companion is local-only. It has no account, cloud backend, telemetry,
advertising SDK or internet permission. It does not automatically collect GPS or
firearm serial numbers.

The stable `0.5.0+1` release does not declare `RECORD_AUDIO` and exposes no
microphone workflow. Par, cadence and manual external-timer modes work without
microphone access.

Acoustic timing exists only in explicitly opted-in development/profile builds
created with `SC_ENABLE_ACOUSTIC_TIMER=true`. In those internal builds,
microphone access is requested only after the acoustic tool is opened. Samples
are analysed in memory while the timer screen is visible. The app stores only
confirmed relative event times, detector-quality flags and the selected
configuration; it never writes raw PCM, a waveform or an audio recording to app
storage, diagnostics, exports or backups. Leaving the timer, backgrounding the
app or revoking permission releases the microphone and marks an active run as
interrupted. This development path is not a public accuracy claim.

Imported photos are decoded, orientation-corrected and re-encoded as JPEG so
source EXIF is not retained. Images and database records live in Android internal
app storage. The app contains no recognition model. The user explicitly initiates
every export or share action.

Deleting a session removes its database records and linked private photo files.
Transactional restore stages and verifies new files before replacing existing
records and removes old files only after the database transaction succeeds.

# Privacy

Shooting Companion is local-only. It has no account, cloud backend, telemetry,
advertising SDK or internet permission. It does not automatically collect GPS or
firearm serial numbers.

Version `0.6.0+1` declares `RECORD_AUDIO` for the live-fire shot timer. Android
asks for microphone access only after the user explicitly opens and activates
that tool. Refusing access does not block scoring, photos, analysis, coaching,
par timing, cadence timing or external timer entry.

During an active live-fire run, Android `AudioRecord` captures microphone
frames and the native detector analyses them in memory. The app stores only
user-reviewed relative event times, detector-quality flags and the selected
configuration. It never writes raw PCM, a waveform or an audio recording to app
storage, diagnostics, exports or backups. Leaving the timer, backgrounding the
app or revoking permission releases the microphone and marks an active run as
interrupted. Acoustic results are training measurements, not certified match
timing or a guarantee that nearby shooters can be distinguished.

Imported photos are decoded, orientation-corrected and re-encoded as JPEG so
source EXIF is not retained. Images and database records live in Android
internal app storage. Experimental photo scoring uses a bundled classical
OpenCV pipeline, not an ML model, and performs no upload or network request.
Unfinished scan photos remain local until the user links or deletes the concept
and are included in encrypted full backups. The user explicitly initiates every
export or share action.

Deleting a session removes its database records and linked private photo files.
Transactional restore stages and verifies new files before replacing existing
records and removes old files only after the database transaction succeeds.

# Privacy

Shooting Companion is local-only. It has no account, cloud backend, telemetry,
advertising SDK or internet permission. It does not automatically collect GPS or
firearm serial numbers.

Version `0.8.0+1` declares `RECORD_AUDIO` for the live-fire shot timer. Android
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

Developer validation photos, annotations and derived reports belong only in
the Git-ignored `.local/vision-validation/` workspace. CI rejects tracked local
validation data, personal camera filenames, unreviewed media fixtures, backups,
APKs and signing material. Only synthetic or explicitly licensed fixtures with
a privacy-review sidecar may enter the public repository.

Lessons, drills, learning paths, personal baseline calculations and generated
training plans are bundled or calculated locally. They do not use a remote
coach, generative model, account or telemetry. Drill and plan history is stored
as versioned training activities and is included in the user-initiated encrypted
backup like the rest of the training diary.

Deleting a session removes its database records and linked private photo files.
Transactional restore stages and verifies new files before replacing existing
records and removes old files only after the database transaction succeeds.

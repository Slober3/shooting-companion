# Privacy

Shooting Companion is local-only. It has no account, cloud backend, telemetry,
advertising SDK or internet permission. It does not automatically collect GPS or
firearm serial numbers.

Imported photos are decoded, orientation-corrected and re-encoded as JPEG so
source EXIF is not retained. Images and database records live in Android internal
app storage. The app contains no recognition model. The user explicitly initiates
every export or share action.

Deleting a session removes its database records and linked private photo files.
Transactional restore stages and verifies new files before replacing existing
records and removes old files only after the database transaction succeeds.

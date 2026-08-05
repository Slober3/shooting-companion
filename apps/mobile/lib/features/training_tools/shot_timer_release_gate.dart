/// Compile-time release gate for the unvalidated acoustic timer.
///
/// Stable builds intentionally use the default `false`. Internal development
/// builds may opt in with
/// `--dart-define=SC_ENABLE_ACOUSTIC_TIMER=true` while physical validation is
/// performed. Enabling the UI does not constitute a reliability claim.
const bool acousticShotTimerEnabled = bool.fromEnvironment(
  'SC_ENABLE_ACOUSTIC_TIMER',
  defaultValue: false,
);

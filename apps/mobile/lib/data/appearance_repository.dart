import 'app_database.dart';

/// Determines whether the app follows Android or forces a light/dark theme.
enum AppearanceMode { system, light, dark }

/// The colour family used by both the light and dark Material themes.
enum AppearancePalette { rangeOrange, steelBlue, forestGreen, highContrast }

class AppearanceSettings {
  const AppearanceSettings({
    this.mode = AppearanceMode.system,
    this.palette = AppearancePalette.rangeOrange,
  });

  final AppearanceMode mode;
  final AppearancePalette palette;

  AppearanceSettings copyWith({
    AppearanceMode? mode,
    AppearancePalette? palette,
  }) => AppearanceSettings(
    mode: mode ?? this.mode,
    palette: palette ?? this.palette,
  );

  @override
  bool operator ==(Object other) =>
      other is AppearanceSettings &&
      other.mode == mode &&
      other.palette == palette;

  @override
  int get hashCode => Object.hash(mode, palette);
}

/// Stores appearance choices in the existing key/value preferences table.
///
/// Unknown values deliberately fall back to safe defaults. The legacy `theme`
/// key is still read so restored v1 backups keep their light/dark choice.
class AppearanceRepository {
  AppearanceRepository(this._database);

  static const modePreferenceKey = 'appearance.mode';
  static const palettePreferenceKey = 'appearance.palette';
  static const _legacyThemePreferenceKey = 'theme';

  final AppDatabase _database;

  Stream<AppearanceSettings> watchSettings() {
    final query = _database.select(_database.preferences)
      ..where(
        (row) => row.key.isIn(const [
          modePreferenceKey,
          palettePreferenceKey,
          _legacyThemePreferenceKey,
        ]),
      );
    return query.watch().map(_decode).distinct();
  }

  Future<AppearanceSettings> readSettings() async {
    final query = _database.select(_database.preferences)
      ..where(
        (row) => row.key.isIn(const [
          modePreferenceKey,
          palettePreferenceKey,
          _legacyThemePreferenceKey,
        ]),
      );
    return _decode(await query.get());
  }

  Future<void> save(AppearanceSettings settings) =>
      _database.transaction(() async {
        await _upsert(modePreferenceKey, settings.mode.name);
        await _upsert(palettePreferenceKey, settings.palette.name);
      });

  Future<void> setMode(AppearanceMode mode) async {
    final current = await readSettings();
    await save(current.copyWith(mode: mode));
  }

  Future<void> setPalette(AppearancePalette palette) async {
    final current = await readSettings();
    await save(current.copyWith(palette: palette));
  }

  Future<void> _upsert(String key, String value) => _database
      .into(_database.preferences)
      .insertOnConflictUpdate(
        PreferencesCompanion.insert(key: key, value: value),
      );

  static AppearanceSettings _decode(List<PreferenceRecord> records) {
    final values = {for (final record in records) record.key: record.value};
    final modeSource =
        values[modePreferenceKey] ?? values[_legacyThemePreferenceKey];
    return AppearanceSettings(
      mode: AppearanceMode.values.firstWhere(
        (mode) => mode.name == modeSource,
        orElse: () => AppearanceMode.system,
      ),
      palette: AppearancePalette.values.firstWhere(
        (palette) => palette.name == values[palettePreferenceKey],
        orElse: () => AppearancePalette.rangeOrange,
      ),
    );
  }
}

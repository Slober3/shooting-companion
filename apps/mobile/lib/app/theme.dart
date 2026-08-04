import 'package:flutter/material.dart';

import '../data/appearance_repository.dart';

/// Semantic colours that remain legible in every supported palette.
///
/// Feature widgets should prefer these tokens over hard-coded green, amber or
/// red values whenever colour conveys a status.
@immutable
class AppContrastTokens extends ThemeExtension<AppContrastTokens> {
  const AppContrastTokens({
    required this.positive,
    required this.onPositive,
    required this.caution,
    required this.onCaution,
    required this.critical,
    required this.onCritical,
    required this.markerOutline,
  });

  final Color positive;
  final Color onPositive;
  final Color caution;
  final Color onCaution;
  final Color critical;
  final Color onCritical;
  final Color markerOutline;

  static AppContrastTokens of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<AppContrastTokens>() ??
        (theme.brightness == Brightness.dark
            ? const AppContrastTokens(
                positive: Color(0xFF79D99A),
                onPositive: Colors.black,
                caution: Color(0xFFF4C95D),
                onCaution: Colors.black,
                critical: Color(0xFFFFB3B5),
                onCritical: Colors.black,
                markerOutline: Colors.white,
              )
            : const AppContrastTokens(
                positive: Color(0xFF176B36),
                onPositive: Colors.white,
                caution: Color(0xFF735C00),
                onCaution: Colors.white,
                critical: Color(0xFF9B1C31),
                onCritical: Colors.white,
                markerOutline: Colors.black,
              ));
  }

  @override
  AppContrastTokens copyWith({
    Color? positive,
    Color? onPositive,
    Color? caution,
    Color? onCaution,
    Color? critical,
    Color? onCritical,
    Color? markerOutline,
  }) => AppContrastTokens(
    positive: positive ?? this.positive,
    onPositive: onPositive ?? this.onPositive,
    caution: caution ?? this.caution,
    onCaution: onCaution ?? this.onCaution,
    critical: critical ?? this.critical,
    onCritical: onCritical ?? this.onCritical,
    markerOutline: markerOutline ?? this.markerOutline,
  );

  @override
  AppContrastTokens lerp(covariant AppContrastTokens? other, double t) {
    if (other == null) return this;
    return AppContrastTokens(
      positive: Color.lerp(positive, other.positive, t)!,
      onPositive: Color.lerp(onPositive, other.onPositive, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      onCaution: Color.lerp(onCaution, other.onCaution, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      onCritical: Color.lerp(onCritical, other.onCritical, t)!,
      markerOutline: Color.lerp(markerOutline, other.markerOutline, t)!,
    );
  }
}

abstract final class AppTheme {
  static ThemeData light([
    AppearancePalette palette = AppearancePalette.rangeOrange,
  ]) => _build(Brightness.light, palette);

  static ThemeData dark([
    AppearancePalette palette = AppearancePalette.rangeOrange,
  ]) => _build(Brightness.dark, palette);

  static ThemeData _build(Brightness brightness, AppearancePalette palette) {
    final highContrast = palette == AppearancePalette.highContrast;
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: _seedFor(palette),
      brightness: brightness,
      contrastLevel: highContrast ? 1 : 0,
      surface: brightness == Brightness.dark
          ? (highContrast ? Colors.black : const Color(0xFF121416))
          : (highContrast ? Colors.white : const Color(0xFFF7F5F1)),
    );
    final scheme = highContrast
        ? generatedScheme.copyWith(
            primary: const Color(0xFFFFD400),
            onPrimary: Colors.black,
            primaryContainer: const Color(0xFFFFE66A),
            onPrimaryContainer: Colors.black,
          )
        : generatedScheme;
    final tokens = _contrastTokens(brightness, highContrast);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      extensions: [tokens],
      focusColor: tokens.markerOutline,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: highContrast ? scheme.outline : scheme.outlineVariant,
            width: highContrast ? 1.5 : 1,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: highContrast ? scheme.outline : scheme.outlineVariant,
        space: 1,
        thickness: highContrast ? 1.5 : 1,
      ),
      listTileTheme: const ListTileThemeData(
        minTileHeight: 56,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          side: highContrast
              ? BorderSide(color: scheme.outline, width: 2)
              : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(Size.square(48)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: highContrast
              ? BorderSide(color: scheme.onSecondaryContainer, width: 2)
              : BorderSide.none,
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, color: scheme.onSurface),
        ),
      ),
    );
  }

  static Color _seedFor(AppearancePalette palette) => switch (palette) {
    AppearancePalette.rangeOrange => const Color(0xFFD07A29),
    AppearancePalette.steelBlue => const Color(0xFF3F6F8F),
    AppearancePalette.forestGreen => const Color(0xFF4E7251),
    AppearancePalette.highContrast => const Color(0xFFFFD400),
  };

  static AppContrastTokens _contrastTokens(
    Brightness brightness,
    bool highContrast,
  ) {
    if (brightness == Brightness.dark) {
      return AppContrastTokens(
        positive: highContrast
            ? const Color(0xFF55FF86)
            : const Color(0xFF79D99A),
        onPositive: Colors.black,
        caution: highContrast
            ? const Color(0xFFFFE100)
            : const Color(0xFFF4C95D),
        onCaution: Colors.black,
        critical: highContrast
            ? const Color(0xFFFF6B70)
            : const Color(0xFFFFB3B5),
        onCritical: Colors.black,
        markerOutline: Colors.white,
      );
    }
    return AppContrastTokens(
      positive: highContrast
          ? const Color(0xFF005C20)
          : const Color(0xFF176B36),
      onPositive: Colors.white,
      caution: highContrast ? const Color(0xFF694E00) : const Color(0xFF735C00),
      onCaution: Colors.white,
      critical: highContrast
          ? const Color(0xFF8A0013)
          : const Color(0xFF9B1C31),
      onCritical: Colors.white,
      markerOutline: Colors.black,
    );
  }
}

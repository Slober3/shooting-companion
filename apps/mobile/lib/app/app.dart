import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/appearance_repository.dart';
import '../features/settings/appearance_providers.dart';
import '../features/shell/home_shell.dart';
import 'providers.dart';
import 'theme.dart';

class ShootingCompanionApp extends ConsumerWidget {
  const ShootingCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialization = ref.watch(initializationProvider);
    final appearance =
        ref.watch(appearanceSettingsProvider).valueOrNull ??
        const AppearanceSettings();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shooting Companion',
      locale: const Locale('nl', 'BE'),
      supportedLocales: const [Locale('nl', 'BE')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(appearance.palette),
      darkTheme: AppTheme.dark(appearance.palette),
      themeMode: switch (appearance.mode) {
        AppearanceMode.system => ThemeMode.system,
        AppearanceMode.light => ThemeMode.light,
        AppearanceMode.dark => ThemeMode.dark,
      },
      builder: (context, child) {
        final theme = Theme.of(context);
        final dark = theme.brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: theme.colorScheme.surface,
            systemNavigationBarDividerColor: theme.colorScheme.outlineVariant,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: initialization.when(
        data: (_) => const HomeShell(),
        loading: () => const _StartupScreen(),
        error: (error, stackTrace) => _StartupError(error: error),
      ),
    );
  }
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.track_changes, size: 72),
          SizedBox(height: 24),
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Lokale gegevens voorbereiden…'),
        ],
      ),
    ),
  );
}

class _StartupError extends ConsumerWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            const Text('De lokale database kon niet worden geopend.'),
            const SizedBox(height: 8),
            Text('$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.invalidate(initializationProvider),
              child: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    ),
  );
}

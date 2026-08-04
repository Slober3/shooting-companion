import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/appearance_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'appearance_providers.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(appearanceSettingsProvider);
    final settings = asyncSettings.valueOrNull ?? const AppearanceSettings();

    return CompactPageScaffold(
      title: 'Weergave',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const _SectionIntro(
            title: 'Thema',
            description:
                'Volg je toestel of kies een vaste lichte of donkere weergave.',
          ),
          const SizedBox(height: 8),
          for (final mode in AppearanceMode.values)
            _AppearanceChoice(
              key: ValueKey('appearance-mode-${mode.name}'),
              icon: _modeIcon(mode),
              title: _modeLabel(mode),
              subtitle: _modeDescription(mode),
              selected: settings.mode == mode,
              enabled: !_saving,
              onTap: () => _save(settings.copyWith(mode: mode)),
            ),
          const SizedBox(height: 24),
          const _SectionIntro(
            title: 'Kleurpalet',
            description:
                'Het palet verandert accenten en statuskleuren, niet de betekenis van gegevens.',
          ),
          const SizedBox(height: 8),
          for (final palette in AppearancePalette.values)
            _PaletteChoice(
              palette: palette,
              selected: settings.palette == palette,
              enabled: !_saving,
              onTap: () => _save(settings.copyWith(palette: palette)),
            ),
          if (asyncSettings.hasError) ...[
            const SizedBox(height: 16),
            Text(
              'De voorkeur kon niet worden gelezen. De standaardweergave blijft actief.',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _save(AppearanceSettings settings) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(appearanceRepositoryProvider).save(settings);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('De weergavevoorkeur kon niet worden bewaard.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _AppearanceChoice extends StatelessWidget {
  const _AppearanceChoice({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, semanticLabel: 'Geselecteerd')
          : const Icon(Icons.circle_outlined),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
    ),
  );
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({
    required this.palette,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final AppearancePalette palette;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: ListTile(
      key: ValueKey('appearance-palette-${palette.name}'),
      enabled: enabled,
      onTap: onTap,
      leading: _PaletteSwatch(palette: palette),
      title: Text(_paletteLabel(palette)),
      subtitle: Text(_paletteDescription(palette)),
      trailing: selected
          ? const Icon(Icons.check_circle, semanticLabel: 'Geselecteerd')
          : const Icon(Icons.circle_outlined),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: selected
          ? Theme.of(context).colorScheme.secondaryContainer
          : null,
    ),
  );
}

class _PaletteSwatch extends StatelessWidget {
  const _PaletteSwatch({required this.palette});

  final AppearancePalette palette;

  @override
  Widget build(BuildContext context) {
    final colors = switch (palette) {
      AppearancePalette.rangeOrange => const [
        Color(0xFFD07A29),
        Color(0xFF5B3210),
      ],
      AppearancePalette.steelBlue => const [
        Color(0xFF3F6F8F),
        Color(0xFF9BC8E7),
      ],
      AppearancePalette.forestGreen => const [
        Color(0xFF4E7251),
        Color(0xFFA8D8B9),
      ],
      AppearancePalette.highContrast => const [Colors.black, Color(0xFFFFD400)],
    };
    return Semantics(
      excludeSemantics: true,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          gradient: LinearGradient(colors: colors),
        ),
      ),
    );
  }
}

IconData _modeIcon(AppearanceMode mode) => switch (mode) {
  AppearanceMode.system => Icons.brightness_auto_outlined,
  AppearanceMode.light => Icons.light_mode_outlined,
  AppearanceMode.dark => Icons.dark_mode_outlined,
};

String _modeLabel(AppearanceMode mode) => switch (mode) {
  AppearanceMode.system => 'Systeem',
  AppearanceMode.light => 'Licht',
  AppearanceMode.dark => 'Donker',
};

String _modeDescription(AppearanceMode mode) => switch (mode) {
  AppearanceMode.system => 'Schakelt mee met het toestel',
  AppearanceMode.light => 'Altijd een lichte achtergrond',
  AppearanceMode.dark => 'Altijd een donkere achtergrond',
};

String _paletteLabel(AppearancePalette palette) => switch (palette) {
  AppearancePalette.rangeOrange => 'Baanoranje',
  AppearancePalette.steelBlue => 'Staalblauw',
  AppearancePalette.forestGreen => 'Bosgroen',
  AppearancePalette.highContrast => 'Hoog contrast',
};

String _paletteDescription(AppearancePalette palette) => switch (palette) {
  AppearancePalette.rangeOrange => 'Warm en herkenbaar',
  AppearancePalette.steelBlue => 'Rustig en technisch',
  AppearancePalette.forestGreen => 'Gedempt en natuurlijk',
  AppearancePalette.highContrast => 'Sterkere randen en kleurverschillen',
};

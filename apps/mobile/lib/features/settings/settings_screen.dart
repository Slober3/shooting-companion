import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/appearance_repository.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'appearance_providers.dart';
import 'appearance_settings_screen.dart';
import 'storage_details_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance =
        ref.watch(appearanceSettingsProvider).valueOrNull ??
        const AppearanceSettings();
    return CompactPageScaffold(
      title: 'Instellingen',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          const _SectionLabel('App'),
          const ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Taal'),
            subtitle: Text('Nederlands (België)'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(_appearanceIcon(appearance.mode)),
            title: const Text('Weergave'),
            subtitle: Text(
              '${_modeSummary(appearance.mode)} · '
              '${_paletteSummary(appearance.palette)}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AppearanceSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Opslag'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Opslagdetails'),
            subtitle: const Text(
              'Bekijk lokaal gegevensgebruik pas wanneer je dit opent',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const StorageDetailsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _appearanceIcon(AppearanceMode mode) => switch (mode) {
  AppearanceMode.system => Icons.brightness_auto_outlined,
  AppearanceMode.light => Icons.light_mode_outlined,
  AppearanceMode.dark => Icons.dark_mode_outlined,
};

String _modeSummary(AppearanceMode mode) => switch (mode) {
  AppearanceMode.system => 'Systeem',
  AppearanceMode.light => 'Licht',
  AppearanceMode.dark => 'Donker',
};

String _paletteSummary(AppearancePalette palette) => switch (palette) {
  AppearancePalette.rangeOrange => 'Baanoranje',
  AppearancePalette.steelBlue => 'Staalblauw',
  AppearancePalette.forestGreen => 'Bosgroen',
  AppearancePalette.highContrast => 'Hoog contrast',
};

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

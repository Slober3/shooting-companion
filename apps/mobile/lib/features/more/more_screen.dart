import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../library/library_screen.dart';
import '../settings/settings_screen.dart';
import '../training_tools/training_tools.dart';
import '../vision/experimental_photo_score_screen.dart';
import 'about_screen.dart';
import 'data_transfer_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactPageScaffold(
      title: 'Meer',
      automaticallyImplyLeading: false,
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _MoreTile(
            icon: Icons.inventory_2_outlined,
            title: 'Bibliotheek',
            subtitle: 'Wapens, munitie, standen en kaarten',
            onTap: () => _open(context, const LibraryScreen()),
          ),
          const Divider(indent: 72),
          _MoreTile(
            icon: Icons.fitness_center_outlined,
            title: 'Trainingstools',
            subtitle: 'Shot timer, par, cadans, drills en viziercalculator',
            onTap: () => _open(context, const TrainingToolsScreen()),
          ),
          const Divider(indent: 72),
          const _VisionPhotoScoreTile(),
          const Divider(indent: 72),
          _MoreTile(
            icon: Icons.tune_outlined,
            title: 'Instellingen',
            subtitle: 'Taal, weergave en opslag',
            onTap: () => _open(context, const SettingsScreen()),
          ),
          const Divider(indent: 72),
          _MoreTile(
            icon: Icons.ios_share_outlined,
            title: 'Export en rapporten',
            subtitle: 'CSV en lokaal PDF-trainingsrapport',
            onTap: () => _open(context, const ExportReportsScreen()),
          ),
          const Divider(indent: 72),
          _MoreTile(
            icon: Icons.lock_outline,
            title: 'Back-up en herstel',
            subtitle: 'Versleutelde volledige gegevenskopie',
            onTap: () => _open(context, const BackupRestoreScreen()),
          ),
          const Divider(indent: 72),
          _MoreTile(
            icon: Icons.info_outline,
            title: 'Over en privacy',
            subtitle: 'Versie, privacy, licentie en gebruiksgrenzen',
            onTap: () => _open(context, const AboutScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _VisionPhotoScoreTile extends StatelessWidget {
  const _VisionPhotoScoreTile();

  @override
  Widget build(BuildContext context) {
    // MoreScreen is also rendered as a standalone layout component in tests
    // and previews. Only subscribe when an application ProviderScope exists.
    try {
      ProviderScope.containerOf(context, listen: false);
    } on StateError {
      return _tile(context, 0);
    }
    return Consumer(
      builder: (context, ref, _) {
        final count = ref.watch(visionScanDraftCountProvider).valueOrNull ?? 0;
        return _tile(context, count);
      },
    );
  }

  Widget _tile(BuildContext context, int draftCount) => _MoreTile(
    icon: Icons.auto_fix_high_outlined,
    title: 'Experimentele fotoscore',
    subtitle: 'Lokaal scorevoorstel uit een ISSF-kaartfoto',
    badgeLabel: draftCount == 0
        ? 'Experimenteel'
        : '$draftCount concept${draftCount == 1 ? '' : 'en'}',
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ExperimentalPhotoScoreScreen()),
    ),
  );
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: ListTile(
        minTileHeight: 68,
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badgeLabel != null) ...[
              Badge(label: Text(badgeLabel!)),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

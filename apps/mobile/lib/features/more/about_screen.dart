import 'package:flutter/material.dart';

import '../../release/release_contract.dart';
import '../../widgets/compact_page_scaffold.dart';
import 'build_information_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactPageScaffold(
      title: 'Over en privacy',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          Icon(
            Icons.track_changes,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Shooting Companion',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          FutureBuilder<ReleaseContract>(
            future: ReleaseContract.load(),
            builder: (context, snapshot) => Text(
              snapshot.data == null
                  ? 'Versie laden…'
                  : 'Versie ${snapshot.data!.displayVersion}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Een volledig offline schietdagboek voor handmatig scoren, '
            'foto’s bewaren en vooruitgang opvolgen.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Volledig offline'),
            subtitle: Text(
              'Geen account, advertenties, telemetrie of internettoegang.',
            ),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.photo_outlined),
            title: Text('Privéfoto’s'),
            subtitle: Text(
              'Foto’s blijven lokaal en EXIF-gegevens worden bij import verwijderd.',
            ),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.mic_none_outlined),
            title: Text('Lokale timerdetectie'),
            subtitle: Text(
              'De microfoon werkt alleen tijdens een zichtbare akoestische '
              'timerrun. Er wordt geen audio-opname bewaard.',
            ),
          ),
          const Divider(),
          ListTile(
            key: const Key('build-information-tile'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.developer_mode_outlined),
            title: const Text('Buildinformatie'),
            subtitle: const Text(
              'App-, data-, back-up- en lokale engineversies.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const BuildInformationScreen()),
            ),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.rule_outlined),
            title: Text('Trainingshulpmiddel'),
            subtitle: Text(
              'Handmatig berekende scores zijn niet gecertificeerd voor wedstrijden.',
            ),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.code_outlined),
            title: Text('Open source'),
            subtitle: Text('Uitgebracht onder de MIT-licentie.'),
          ),
        ],
      ),
    );
  }
}

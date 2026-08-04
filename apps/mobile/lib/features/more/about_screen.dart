import 'package:flutter/material.dart';

import '../../widgets/compact_page_scaffold.dart';

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
          Text(
            'Versie 0.3.0 (build 4)',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
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

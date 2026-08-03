import 'package:flutter/material.dart';

import '../../widgets/compact_page_scaffold.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CompactPageScaffold(
      title: 'Over',
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
            'Versie 0.2.0',
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
            leading: Icon(Icons.verified_user_outlined),
            title: Text('Privé en lokaal'),
            subtitle: Text('Je gegevens verlaten deze app niet automatisch.'),
          ),
          const Divider(),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.rule_outlined),
            title: Text('Training, niet certificering'),
            subtitle: Text(
              'Resultaten zijn bedoeld als persoonlijke trainingsmetingen.',
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../widgets/compact_page_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int? _storageBytes;

  @override
  void initState() {
    super.initState();
    _refreshStorage();
  }

  @override
  Widget build(BuildContext context) {
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
          const ListTile(
            leading: Icon(Icons.brightness_auto_outlined),
            title: Text('Weergave'),
            subtitle: Text('Volgt het lichte of donkere toestelthema'),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Opslag'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(
              _storageBytes == null
                  ? 'Opslag berekenen…'
                  : _formatBytes(_storageBytes!),
            ),
            subtitle: const Text('Database en foto’s in interne appopslag'),
            trailing: IconButton(
              onPressed: _refreshStorage,
              tooltip: 'Opslag opnieuw berekenen',
              icon: const Icon(Icons.refresh),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionLabel('Privacy'),
          const ListTile(
            leading: Icon(Icons.cloud_off_outlined),
            title: Text('Volledig offline'),
            subtitle: Text(
              'Geen account, advertenties, telemetrie of internettoegang.',
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.photo_outlined),
            title: Text('Privéfoto’s'),
            subtitle: Text(
              'Foto’s blijven lokaal en EXIF-gegevens worden bij import verwijderd.',
            ),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.rule_outlined),
            title: Text('Trainingshulpmiddel'),
            subtitle: Text(
              'Handmatig berekende scores zijn niet gecertificeerd voor wedstrijden.',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshStorage() async {
    final root = await getApplicationDocumentsDirectory();
    var bytes = 0;
    if (await root.exists()) {
      await for (final entity in root.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) bytes += await entity.length();
      }
    }
    if (mounted) setState(() => _storageBytes = bytes);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B gebruikt';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB gebruikt';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB gebruikt';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB gebruikt';
  }
}

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

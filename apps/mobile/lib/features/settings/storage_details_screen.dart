import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../widgets/compact_page_scaffold.dart';

class StorageDetailsScreen extends ConsumerStatefulWidget {
  const StorageDetailsScreen({super.key});

  @override
  ConsumerState<StorageDetailsScreen> createState() =>
      _StorageDetailsScreenState();
}

class _StorageDetailsScreenState extends ConsumerState<StorageDetailsScreen> {
  late Future<_StorageBreakdown> _breakdown;

  @override
  void initState() {
    super.initState();
    _breakdown = _loadBreakdown();
  }

  @override
  Widget build(BuildContext context) => CompactPageScaffold(
    title: 'Opslagdetails',
    actions: [
      IconButton(
        onPressed: _refresh,
        tooltip: 'Opslag opnieuw berekenen',
        icon: const Icon(Icons.refresh),
      ),
    ],
    body: FutureBuilder<_StorageBreakdown>(
      future: _breakdown,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _StorageError(onRetry: _refresh);
        }
        final value = snapshot.requireData;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            _TotalStorageCard(bytes: value.totalBytes),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Overige lokale gegevens'),
              subtitle: const Text('Database, originelen en bijlagen'),
              trailing: Text(_formatBytes(value.otherDocumentsBytes)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Conceptscanfoto’s'),
              subtitle: Text(
                '${value.visionDraftCount} onafgewerkte '
                'experimentele scan${value.visionDraftCount == 1 ? '' : 's'}',
              ),
              trailing: Text(_formatBytes(value.visionDraftBytes)),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cached_outlined),
              title: const Text('Tijdelijke cache'),
              subtitle: const Text('Opnieuw opbouwbare tijdelijke bestanden'),
              trailing: Text(_formatBytes(value.cacheBytes)),
            ),
            const SizedBox(height: 20),
            const ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16),
              leading: Icon(Icons.info_outline),
              title: Text('Foto’s blijven bewaard'),
              subtitle: Text(
                'Originele foto’s worden niet automatisch verwijderd. '
                'Verwijder ze bewust vanuit de bijbehorende sessie of reeks.',
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<_StorageBreakdown> _loadBreakdown() async {
    final repository = ref.read(visionScanRepositoryProvider);
    final draftBytes = await repository.getDraftStorageBytes();
    final drafts = await repository.watchDrafts().first;
    return _calculateStorage(
      visionDraftBytes: draftBytes,
      visionDraftCount: drafts.length,
    );
  }

  void _refresh() => setState(() => _breakdown = _loadBreakdown());
}

class _TotalStorageCard extends StatelessWidget {
  const _TotalStorageCard({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(
            Icons.storage_outlined,
            size: 36,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Totaal lokaal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatBytes(bytes),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _StorageError extends StatelessWidget {
  const _StorageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 44),
          const SizedBox(height: 12),
          const Text(
            'Het lokale opslaggebruik kon niet worden berekend.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Opnieuw proberen'),
          ),
        ],
      ),
    ),
  );
}

class _StorageBreakdown {
  const _StorageBreakdown({
    required this.documentsBytes,
    required this.cacheBytes,
    required this.visionDraftBytes,
    required this.visionDraftCount,
  });

  final int documentsBytes;
  final int cacheBytes;
  final int visionDraftBytes;
  final int visionDraftCount;

  int get otherDocumentsBytes =>
      (documentsBytes - visionDraftBytes).clamp(0, documentsBytes);

  int get totalBytes => documentsBytes + cacheBytes;
}

Future<_StorageBreakdown> _calculateStorage({
  required int visionDraftBytes,
  required int visionDraftCount,
}) async {
  final documents = await getApplicationDocumentsDirectory();
  final cache = await getTemporaryDirectory();
  final documentsBytes = await _directorySize(documents);
  final sameDirectory = documents.absolute.path == cache.absolute.path;
  return _StorageBreakdown(
    documentsBytes: documentsBytes,
    cacheBytes: sameDirectory ? 0 : await _directorySize(cache),
    visionDraftBytes: visionDraftBytes,
    visionDraftCount: visionDraftCount,
  );
}

Future<int> _directorySize(Directory directory) async {
  if (!await directory.exists()) return 0;
  var bytes = 0;
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    try {
      bytes += await entity.length();
    } on FileSystemException {
      // A cache file can disappear while the asynchronous scan is running.
    }
  }
  return bytes;
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

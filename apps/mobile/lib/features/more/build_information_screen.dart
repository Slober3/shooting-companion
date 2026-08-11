import 'package:flutter/material.dart';

import '../../release/release_contract.dart';
import '../../widgets/compact_page_scaffold.dart';

class BuildInformationScreen extends StatefulWidget {
  const BuildInformationScreen({this.contract, super.key});

  /// Allows tests and diagnostics to render an already loaded contract without
  /// depending on asynchronous asset loading.
  final ReleaseContract? contract;

  @override
  State<BuildInformationScreen> createState() => _BuildInformationScreenState();
}

class _BuildInformationScreenState extends State<BuildInformationScreen> {
  late final Future<ReleaseContract> _contract = widget.contract == null
      ? ReleaseContract.load()
      : Future.value(widget.contract);

  @override
  Widget build(BuildContext context) {
    return CompactPageScaffold(
      title: 'Buildinformatie',
      body: FutureBuilder<ReleaseContract>(
        future: _contract,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'De buildinformatie kon niet worden gelezen. De overige '
                  'appgegevens blijven beschikbaar.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final contract = snapshot.data;
          if (contract == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            key: const Key('build-information-list'),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              _InfoSection(
                title: 'Applicatie',
                rows: [
                  ('Versie', contract.displayVersion),
                  ('Broncommit', ReleaseContract.compiledGitCommit),
                  ('Package', contract.app.packageName),
                  ('Releasecontract', '${contract.contractVersion}'),
                ],
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Gegevensformaten',
                rows: [
                  ('Database-schema', '${contract.data.databaseSchema}'),
                  ('Back-upmanifest', '${contract.data.backupManifest}'),
                  ('Back-upcontainer', contract.data.backupMagic),
                  (
                    'Doelprofiel-schema’s',
                    contract.data.supportedTargetProfileSchemas.join(', '),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Lokale engines',
                rows: [
                  ('Vision-engine', contract.native.vision.engineVersion),
                  (
                    'Gatendetector',
                    contract.native.vision.candidateAlgorithmVersion,
                  ),
                  ('Vision-ABI', '${contract.native.vision.abiVersion}'),
                  ('OpenCV', contract.native.vision.openCvVersion),
                  (
                    'Shot-timerdetector',
                    contract.native.shotTimer.detectorVersion,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoSection(
                title: 'Android en privacy',
                rows: [
                  ('Release-ABI', contract.android.releaseAbi),
                  (
                    'Benodigde toestemmingen',
                    contract.android.requiredPermissions
                        .map((value) => value.split('.').last)
                        .join(', '),
                  ),
                  ('Internettoegang', 'Niet toegestaan'),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Deze waarden komen uit het gebundelde releasecontract. CI '
                'controleert hetzelfde contract tegen broncode en release-APK.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var index = 0; index < rows.length; index++) ...[
              if (index > 0) const Divider(height: 16),
              _InfoRow(label: rows[index].$1, value: rows[index].$2),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 16),
          Flexible(
            child: SelectableText(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

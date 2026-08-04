import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/providers.dart';
import '../../services/backup_service.dart';
import '../../services/export_service.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../../widgets/safe_sheet_scaffold.dart';
import '../settings/appearance_providers.dart';

class ExportReportsScreen extends StatelessWidget {
  const ExportReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DataTransferScreen(mode: _TransferMode.export);
  }
}

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DataTransferScreen(mode: _TransferMode.backup);
  }
}

enum _TransferMode { export, backup }

class _DataTransferScreen extends ConsumerStatefulWidget {
  const _DataTransferScreen({required this.mode});

  final _TransferMode mode;

  @override
  ConsumerState<_DataTransferScreen> createState() =>
      _DataTransferScreenState();
}

class _DataTransferScreenState extends ConsumerState<_DataTransferScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final isExport = widget.mode == _TransferMode.export;
    return CompactPageScaffold(
      title: isExport ? 'Export en rapporten' : 'Back-up en herstel',
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          _Notice(
            icon: isExport ? Icons.visibility_outlined : Icons.lock_outline,
            text: isExport
                ? 'CSV- en PDF-bestanden zijn niet versleuteld. Deel ze alleen met personen die je vertrouwt.'
                : 'Volledige back-ups worden altijd met je wachtwoord versleuteld. Dit wachtwoord kan niet worden hersteld.',
          ),
          const SizedBox(height: 16),
          if (isExport) ...[
            _ActionTile(
              icon: Icons.table_view_outlined,
              title: 'CSV exporteren',
              subtitle: 'Alle sessies en reeksen als tabel',
              enabled: !_busy,
              onTap: () => _exportCsv(context),
            ),
            const Divider(indent: 56),
            _ActionTile(
              icon: Icons.picture_as_pdf_outlined,
              title: 'PDF-trainingsrapport',
              subtitle: 'Leesbaar rapport dat lokaal wordt gemaakt',
              enabled: !_busy,
              onTap: () => _exportPdf(context),
            ),
          ] else ...[
            _ActionTile(
              icon: Icons.lock_outline,
              title: 'Nieuwe back-up maken',
              subtitle: 'Versleutelde kopie van gegevens en foto’s',
              enabled: !_busy,
              onTap: () => _backup(context),
            ),
            const Divider(indent: 56),
            _ActionTile(
              icon: Icons.restore,
              title: 'Back-up herstellen',
              subtitle: 'Controleer en vervang de huidige lokale gegevens',
              enabled: !_busy,
              onTap: () => _restore(context),
            ),
          ],
          if (_busy) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            const Text('Even geduld…', textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    if (!await _confirmPlainExport(context)) return;
    await _run(() async {
      final service = ExportService(ref.read(databaseProvider));
      final file = await service.createCsv();
      await service.shareFile(file, label: 'Shooting Companion CSV-export');
    });
  }

  Future<void> _exportPdf(BuildContext context) async {
    if (!await _confirmPlainExport(context)) return;
    await _run(() async {
      final service = ExportService(ref.read(databaseProvider));
      final file = await service.createPdfReport();
      await service.shareFile(
        file,
        label: 'Shooting Companion trainingsrapport',
      );
    });
  }

  Future<bool> _confirmPlainExport(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Onversleuteld exportbestand'),
            content: const Text(
              'Iedereen met toegang tot het gedeelde bestand kan de trainingsgegevens lezen.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuleren'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Doorgaan'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _backup(BuildContext context) async {
    final password = await showSafeModalSheet<String>(
      context: context,
      builder: (_) => const _PasswordSheet(),
    );
    if (password == null) return;
    await _run(() async {
      final file = await BackupService(
        ref.read(databaseProvider),
      ).createEncryptedBackup(password);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Versleutelde Shooting Companion-back-up',
        ),
      );
    });
  }

  Future<void> _restore(BuildContext context) async {
    const backupType = XTypeGroup(
      label: 'Shooting Companion-back-up',
      extensions: ['scbackup'],
      mimeTypes: ['application/octet-stream'],
    );
    final selected = await openFile(acceptedTypeGroups: [backupType]);
    final selectedPath = selected?.path;
    if (selectedPath == null || !context.mounted) return;
    final password = await showSafeModalSheet<String>(
      context: context,
      builder: (_) => const _RestorePasswordSheet(),
    );
    if (password == null || !context.mounted) return;

    final service = BackupService(ref.read(databaseProvider));
    BackupSummary summary;
    try {
      summary = await service.inspectEncryptedBackup(
        File(selectedPath),
        password,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Back-upcontrole mislukt: $error')),
        );
      }
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle lokale gegevens vervangen?'),
        content: Text(
          'Back-up met ${summary.sessionCount} sessies, '
          '${summary.seriesCount} reeksen en ${summary.imageCount} foto’s. '
          'Eerst wordt automatisch een veiligheidsback-up gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vervangen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      final result = await service.restoreEncryptedBackup(
        File(selectedPath),
        password,
      );
      ref.invalidate(sessionsProvider);
      ref.invalidate(firearmsProvider);
      ref.invalidate(cartridgesProvider);
      ref.invalidate(ammoLotsProvider);
      ref.invalidate(rangesProvider);
      ref.invalidate(targetProfilesProvider);
      ref.invalidate(appearanceSettingsProvider);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(result.safetyBackup.path)],
          text: 'Veiligheidsback-up van vóór het herstel',
        ),
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Actie mislukt: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      enabled: enabled,
      onTap: enabled ? onTap : null,
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: colors.onSecondaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final formKey = GlobalKey<FormState>();
  final first = TextEditingController();
  final second = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    first.dispose();
    second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Back-upwachtwoord',
    body: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dit wachtwoord kan niet worden hersteld. Bewaar het veilig.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: first,
            autofocus: true,
            obscureText: obscure,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Wachtwoord',
              suffixIcon: IconButton(
                onPressed: () => setState(() => obscure = !obscure),
                tooltip: obscure ? 'Wachtwoord tonen' : 'Wachtwoord verbergen',
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
            validator: (value) => (value?.length ?? 0) < 10
                ? 'Gebruik minstens 10 tekens.'
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: second,
            obscureText: obscure,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Herhaal wachtwoord'),
            validator: (value) => value != first.text
                ? 'De wachtwoorden komen niet overeen.'
                : null,
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _submit(context),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuleren'),
      ),
      FilledButton(
        onPressed: _isValid ? () => _submit(context) : null,
        child: const Text('Back-up maken'),
      ),
    ],
  );

  bool get _isValid => first.text.length >= 10 && first.text == second.text;

  void _submit(BuildContext context) {
    if (formKey.currentState?.validate() != true) return;
    Navigator.pop(context, first.text);
  }
}

class _RestorePasswordSheet extends StatefulWidget {
  const _RestorePasswordSheet();

  @override
  State<_RestorePasswordSheet> createState() => _RestorePasswordSheetState();
}

class _RestorePasswordSheetState extends State<_RestorePasswordSheet> {
  final formKey = GlobalKey<FormState>();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Back-up ontgrendelen',
    body: Form(
      key: formKey,
      child: TextFormField(
        controller: password,
        autofocus: true,
        obscureText: obscure,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: 'Back-upwachtwoord',
          suffixIcon: IconButton(
            onPressed: () => setState(() => obscure = !obscure),
            tooltip: obscure ? 'Wachtwoord tonen' : 'Wachtwoord verbergen',
            icon: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
        validator: (value) => value == null || value.isEmpty
            ? 'Vul het back-upwachtwoord in.'
            : null,
        onChanged: (_) => setState(() {}),
        onFieldSubmitted: (_) => _submit(context),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuleren'),
      ),
      FilledButton(
        onPressed: password.text.isEmpty ? null : () => _submit(context),
        child: const Text('Controleren'),
      ),
    ],
  );

  void _submit(BuildContext context) {
    if (formKey.currentState?.validate() != true) return;
    Navigator.pop(context, password.text);
  }
}

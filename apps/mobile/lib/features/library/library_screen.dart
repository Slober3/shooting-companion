import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_decision_dialog.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_multiline_field.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/compact_page_scaffold.dart';
import '../../widgets/safe_sheet_scaffold.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firearms = ref.watch(firearmsProvider).valueOrNull;
    final cartridges = ref.watch(cartridgesProvider).valueOrNull;
    final ammoLots = ref.watch(ammoLotsProvider).valueOrNull;
    final ranges = ref.watch(rangesProvider).valueOrNull;
    final targets = ref.watch(targetProfilesProvider).valueOrNull;
    return CompactPageScaffold(
      title: 'Bibliotheek',
      body: ListView.separated(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          24 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        itemCount: _LibraryCategory.values.length,
        separatorBuilder: (_, _) => const Divider(indent: 72),
        itemBuilder: (context, index) {
          final category = _LibraryCategory.values[index];
          final count = switch (category) {
            _LibraryCategory.firearms => firearms?.length,
            _LibraryCategory.ammunition =>
              cartridges == null || ammoLots == null
                  ? null
                  : cartridges.length + ammoLots.length,
            _LibraryCategory.ranges => ranges?.length,
            _LibraryCategory.targets => targets?.length,
          };
          return ListTile(
            minTileHeight: 68,
            leading: Icon(category.icon),
            title: Text(category.label),
            subtitle: Text(
              count == null
                  ? 'Laden…'
                  : count == 1
                  ? '1 profiel'
                  : '$count profielen',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _LibraryCategoryScreen(category: category),
              ),
            ),
          );
        },
      ),
    );
  }

  static Future<void> _addFirearm(BuildContext context, WidgetRef ref) async {
    final draft = await Navigator.of(context).push<_FirearmDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _FirearmDialog(),
      ),
    );
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .addFirearm(
          name: draft.name,
          type: draft.type,
          manufacturer: draft.manufacturer,
          model: draft.model,
          defaultCartridgeId: draft.cartridgeId,
          sightNotes: draft.notes,
        );
  }

  static Future<void> _addAmmo(BuildContext context, WidgetRef ref) async {
    final draft = await Navigator.of(context).push<_AmmoDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _AmmoDialog(),
      ),
    );
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .addAmmoLot(
          cartridgeId: draft.cartridgeId,
          displayName: draft.displayName,
          manufacturer: draft.manufacturer,
          productName: draft.productName,
          lotNumber: draft.lotNumber,
          bulletWeightGrains: draft.weight,
          projectileType: draft.projectileType,
          notes: draft.notes,
        );
  }

  static Future<void> _addCartridge(BuildContext context, WidgetRef ref) async {
    final draft = await Navigator.of(context).push<_CartridgeDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CartridgeDialog(),
      ),
    );
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .addCustomCartridge(
          name: draft.name,
          projectileDiameterMm: draft.diameter,
          notes: draft.notes,
        );
  }

  static Future<void> _addRange(BuildContext context, WidgetRef ref) async {
    final draft = await Navigator.of(context).push<_RangeDraft>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _RangeDialog(),
      ),
    );
    if (draft == null) return;
    await ref
        .read(repositoryProvider)
        .addRange(
          name: draft.name,
          isIndoor: draft.isIndoor,
          locationDescription: draft.location,
          availableDistances: draft.distances,
          notes: draft.notes,
        );
  }

  static Future<void> _addTarget(BuildContext context, WidgetRef ref) async {
    final profile = await Navigator.of(context).push<domain.TargetProfile>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _TargetDialog(),
      ),
    );
    if (profile == null) return;
    await ref.read(repositoryProvider).addCustomTargetProfile(profile);
  }
}

enum _LibraryCategory {
  firearms('Wapens', Icons.gps_fixed),
  ammunition('Munitie', Icons.inventory_2_outlined),
  ranges('Schietstanden', Icons.signpost_outlined),
  targets('Doelkaarten', Icons.track_changes);

  const _LibraryCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _LibraryCategoryScreen extends ConsumerWidget {
  const _LibraryCategoryScreen({required this.category});

  final _LibraryCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CompactPageScaffold(
      title: category.label,
      actions: [
        PopupMenuButton<_CategoryAction>(
          tooltip: 'Meer bibliotheekacties',
          onSelected: (action) {
            if (action == _CategoryAction.archived) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ArchivedLibraryScreen(category: category),
                ),
              );
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: _CategoryAction.archived,
              child: Text('Gearchiveerde items'),
            ),
          ],
        ),
        IconButton(
          onPressed: () => _add(context, ref),
          tooltip: '${category.label} toevoegen',
          icon: const Icon(Icons.add),
        ),
      ],
      body: switch (category) {
        _LibraryCategory.firearms => _FirearmList(
          onAdd: () => _add(context, ref),
        ),
        _LibraryCategory.ammunition => _AmmoList(
          onAdd: () => _add(context, ref),
        ),
        _LibraryCategory.ranges => _RangeList(onAdd: () => _add(context, ref)),
        _LibraryCategory.targets => _TargetList(
          onAdd: () => _add(context, ref),
        ),
      },
    );
  }

  Future<void> _add(BuildContext context, WidgetRef ref) {
    return switch (category) {
      _LibraryCategory.firearms => LibraryScreen._addFirearm(context, ref),
      _LibraryCategory.ammunition => _chooseAmmunitionKind(context, ref),
      _LibraryCategory.ranges => LibraryScreen._addRange(context, ref),
      _LibraryCategory.targets => LibraryScreen._addTarget(context, ref),
    };
  }

  Future<void> _chooseAmmunitionKind(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final choice = await showAppDecisionDialog<_AmmunitionAddKind>(
      context: context,
      title: 'Munitie toevoegen',
      content: const Text('Wat wil je aan de bibliotheek toevoegen?'),
      actions: const [
        AppDecisionAction(
          label: 'Munitieprofiel',
          value: _AmmunitionAddKind.ammo,
          kind: AppDecisionActionKind.primary,
        ),
        AppDecisionAction(
          label: 'Eigen kaliber',
          value: _AmmunitionAddKind.cartridge,
        ),
      ],
    );
    if (!context.mounted || choice == null) return;
    if (choice == _AmmunitionAddKind.cartridge) {
      await LibraryScreen._addCartridge(context, ref);
    } else {
      await LibraryScreen._addAmmo(context, ref);
    }
  }
}

enum _CategoryAction { archived }

enum _AmmunitionAddKind { cartridge, ammo }

class _LibraryListBody extends StatelessWidget {
  const _LibraryListBody({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: EdgeInsets.only(
      top: 8,
      bottom: 24 + MediaQuery.viewPaddingOf(context).bottom,
    ),
    itemCount: children.length,
    separatorBuilder: (_, _) => const Divider(indent: 56),
    itemBuilder: (_, index) => children[index],
  );
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

class _FirearmList extends ConsumerWidget {
  const _FirearmList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(firearmsProvider)
      .when(
        data: (items) => items.isEmpty
            ? _Empty(text: 'Nog geen wapenprofielen.', onAdd: onAdd)
            : _LibraryListBody(
                children: items
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.gps_fixed),
                        title: Text(item.name),
                        subtitle: Text(
                          [
                            item.manufacturer,
                            item.model,
                            item.type,
                          ].whereType<String>().join(' • '),
                        ),
                        onTap: () => _openFirearmDetail(context, ref, item),
                        trailing: _LibraryItemMenu(
                          onEdit: () => _editFirearm(context, ref, item),
                          onDelete: () => _removeLibraryItem(
                            context,
                            ref,
                            kind: LibraryItemKind.firearm,
                            id: item.id,
                            label: item.name,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const _LoadingBody(),
        error: (error, stack) => _ErrorBody(error: error),
      );
}

class _AmmoList extends ConsumerWidget {
  const _AmmoList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ammoValue = ref.watch(ammoLotsProvider);
    final cartridgeValue = ref.watch(cartridgesProvider);
    if (ammoValue.isLoading || cartridgeValue.isLoading) {
      return const _LoadingBody();
    }
    if (ammoValue.hasError) return _ErrorBody(error: ammoValue.error!);
    if (cartridgeValue.hasError) {
      return _ErrorBody(error: cartridgeValue.error!);
    }
    final ammo = ammoValue.valueOrNull ?? const <AmmoLotRecord>[];
    final cartridges = cartridgeValue.valueOrNull ?? const <CartridgeRecord>[];
    if (ammo.isEmpty && cartridges.isEmpty) {
      return _Empty(text: 'Nog geen munitieprofielen.', onAdd: onAdd);
    }
    return _LibraryListBody(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Kalibers',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...cartridges.map(
          (item) => ListTile(
            leading: const Icon(Icons.circle, size: 14),
            title: Text(item.name),
            subtitle: Text(
              '${item.projectileDiameterMm.toStringAsFixed(2)} mm scorediameter'
              '${item.builtIn ? ' • Ingebouwd' : ''}',
            ),
            onTap: () => _openCartridgeDetail(context, ref, item),
            trailing: _LibraryItemMenu(
              onEdit: item.builtIn
                  ? null
                  : () => _editCartridge(context, ref, item),
              onDuplicate: () => _duplicateCartridge(context, ref, item),
              onDelete: item.builtIn
                  ? null
                  : () => _removeLibraryItem(
                      context,
                      ref,
                      kind: LibraryItemKind.cartridge,
                      id: item.id,
                      label: item.name,
                    ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Text(
            'Munitieprofielen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...ammo.map(
          (item) => ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(item.displayName),
            subtitle: Text(
              [
                item.manufacturer,
                item.productName,
                item.lotNumber,
              ].whereType<String>().join(' • '),
            ),
            onTap: () => _openAmmoDetail(context, ref, item),
            trailing: _LibraryItemMenu(
              onEdit: () => _editAmmo(context, ref, item),
              onDelete: () => _removeLibraryItem(
                context,
                ref,
                kind: LibraryItemKind.ammoLot,
                id: item.id,
                label: item.displayName,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeList extends ConsumerWidget {
  const _RangeList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(rangesProvider)
      .when(
        data: (items) => items.isEmpty
            ? _Empty(text: 'Nog geen schietstanden.', onAdd: onAdd)
            : _LibraryListBody(
                children: items
                    .map(
                      (item) => ListTile(
                        leading: Icon(
                          item.isIndoor
                              ? Icons.warehouse_outlined
                              : Icons.landscape_outlined,
                        ),
                        title: Text(item.name),
                        subtitle: Text(
                          item.locationDescription ??
                              (item.isIndoor ? 'Binnenstand' : 'Buitenstand'),
                        ),
                        onTap: () => _openRangeDetail(context, ref, item),
                        trailing: _LibraryItemMenu(
                          onEdit: () => _editRange(context, ref, item),
                          onDelete: () => _removeLibraryItem(
                            context,
                            ref,
                            kind: LibraryItemKind.range,
                            id: item.id,
                            label: item.name,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const _LoadingBody(),
        error: (error, stack) => _ErrorBody(error: error),
      );
}

class _TargetList extends ConsumerWidget {
  const _TargetList({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(targetProfilesProvider)
      .when(
        data: (items) => items.isEmpty
            ? _Empty(text: 'Nog geen doelkaartprofielen.', onAdd: onAdd)
            : _LibraryListBody(
                children: items
                    .map(
                      (item) => ListTile(
                        leading: const Icon(Icons.track_changes),
                        title: Text(item.displayName),
                        subtitle: Text(
                          item.builtIn
                              ? 'ISSF 2026 • officieel profiel'
                              : 'Eigen profiel',
                        ),
                        onTap: () => _openTargetDetail(context, ref, item),
                        trailing: _LibraryItemMenu(
                          onEdit: item.builtIn
                              ? null
                              : () => _editTarget(context, ref, item),
                          onDuplicate: () =>
                              _duplicateTarget(context, ref, item),
                          onDelete: item.builtIn
                              ? null
                              : () => _removeLibraryItem(
                                  context,
                                  ref,
                                  kind: LibraryItemKind.targetProfile,
                                  id: item.versionedId,
                                  label: item.displayName,
                                ),
                        ),
                      ),
                    )
                    .toList(),
              ),
        loading: () => const _LoadingBody(),
        error: (error, stack) => _ErrorBody(error: error),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, required this.onAdd});

  final String text;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inbox_outlined, size: 44),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Toevoegen'),
          ),
        ],
      ),
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text('Laden mislukt: $error', textAlign: TextAlign.center),
    ),
  );
}

enum _LibraryMenuAction { edit, duplicate, delete }

class _LibraryItemMenu extends StatelessWidget {
  const _LibraryItemMenu({this.onEdit, this.onDuplicate, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<_LibraryMenuAction>(
    tooltip: 'Acties',
    onSelected: (action) => switch (action) {
      _LibraryMenuAction.edit => onEdit?.call(),
      _LibraryMenuAction.duplicate => onDuplicate?.call(),
      _LibraryMenuAction.delete => onDelete?.call(),
    },
    itemBuilder: (_) => [
      if (onEdit != null)
        const PopupMenuItem(
          value: _LibraryMenuAction.edit,
          child: Text('Bewerken'),
        ),
      if (onDuplicate != null)
        const PopupMenuItem(
          value: _LibraryMenuAction.duplicate,
          child: Text('Dupliceren'),
        ),
      if (onDelete != null)
        const PopupMenuItem(
          value: _LibraryMenuAction.delete,
          child: Text('Verwijderen'),
        ),
    ],
  );
}

class _LibraryDetailPage extends StatelessWidget {
  const _LibraryDetailPage({
    required this.title,
    required this.fields,
    required this.actions,
  });

  final String title;
  final List<(String, String)> fields;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: fields.length,
      separatorBuilder: (_, _) => const Divider(height: 24),
      itemBuilder: (_, index) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(fields[index].$1, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(fields[index].$2.isEmpty ? 'Niet opgegeven' : fields[index].$2),
        ],
      ),
    ),
    bottomNavigationBar: actions.isEmpty
        ? null
        : AppActionDock(actions: actions),
  );
}

Future<void> _openFirearmDetail(
  BuildContext context,
  WidgetRef ref,
  FirearmRecord item,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => _LibraryDetailPage(
      title: item.name,
      fields: [
        ('Type', item.type),
        ('Fabrikant', item.manufacturer ?? ''),
        ('Model', item.model ?? ''),
        ('Vizier en notities', item.sightNotes ?? ''),
      ],
      actions: [
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await _editFirearm(context, ref, item);
          },
          child: const Text('Bewerken'),
        ),
      ],
    ),
  ),
);

Future<void> _openCartridgeDetail(
  BuildContext context,
  WidgetRef ref,
  CartridgeRecord item,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => _LibraryDetailPage(
      title: item.name,
      fields: [
        ('Type', item.builtIn ? 'Ingebouwd' : 'Eigen kaliber'),
        ('Projectieldiameter', '${item.projectileDiameterMm} mm'),
        ('Notities', item.notes ?? ''),
      ],
      actions: [
        if (!item.builtIn)
          OutlinedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _editCartridge(context, ref, item);
            },
            child: const Text('Bewerken'),
          ),
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await _duplicateCartridge(context, ref, item);
          },
          child: const Text('Dupliceren'),
        ),
      ],
    ),
  ),
);

Future<void> _openAmmoDetail(
  BuildContext context,
  WidgetRef ref,
  AmmoLotRecord item,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => _LibraryDetailPage(
      title: item.displayName,
      fields: [
        ('Fabrikant', item.manufacturer ?? ''),
        ('Product', item.productName ?? ''),
        ('Lotnummer', item.lotNumber ?? ''),
        ('Kogelgewicht', item.bulletWeightGrains?.toString() ?? ''),
        ('Projectieltype', item.projectileType ?? ''),
        ('Notities', item.notes ?? ''),
      ],
      actions: [
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await _editAmmo(context, ref, item);
          },
          child: const Text('Bewerken'),
        ),
      ],
    ),
  ),
);

Future<void> _openRangeDetail(
  BuildContext context,
  WidgetRef ref,
  RangeRecord item,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => _LibraryDetailPage(
      title: item.name,
      fields: [
        ('Type', item.isIndoor ? 'Binnenstand' : 'Buitenstand'),
        ('Locatie', item.locationDescription ?? ''),
        (
          'Afstanden',
          (jsonDecode(item.availableDistancesJson) as List).join(' m, '),
        ),
        ('Notities', item.notes ?? ''),
      ],
      actions: [
        FilledButton(
          onPressed: () async {
            Navigator.pop(context);
            await _editRange(context, ref, item);
          },
          child: const Text('Bewerken'),
        ),
      ],
    ),
  ),
);

Future<void> _openTargetDetail(
  BuildContext context,
  WidgetRef ref,
  TargetProfileRecord item,
) {
  final profile = domain.TargetProfile.fromJsonString(item.profileJson);
  return Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => _LibraryDetailPage(
        title: item.displayName,
        fields: [
          (
            'Type',
            item.builtIn ? 'Ingebouwd officieel profiel' : 'Eigen profiel',
          ),
          ('Versie', profile.profileVersion.toString()),
          (
            'Kaartmaat',
            '${profile.physicalCardWidthMm} × ${profile.physicalCardHeightMm} mm',
          ),
          ('Maximumscore', profile.maximumScore.toString()),
          ('Scoringsringen', profile.rings.length.toString()),
        ],
        actions: [
          if (!item.builtIn)
            OutlinedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _editTarget(context, ref, item);
              },
              child: const Text('Bewerken'),
            ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _duplicateTarget(context, ref, item);
            },
            child: const Text('Dupliceren'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _editFirearm(
  BuildContext context,
  WidgetRef ref,
  FirearmRecord item,
) async {
  final draft = await Navigator.of(context).push<_FirearmDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _FirearmDialog(initial: item),
    ),
  );
  if (draft == null) return;
  await ref
      .read(repositoryProvider)
      .updateFirearm(
        id: item.id,
        name: draft.name,
        type: draft.type,
        manufacturer: draft.manufacturer,
        model: draft.model,
        defaultCartridgeId: draft.cartridgeId,
        sightNotes: draft.notes,
      );
}

Future<void> _editAmmo(
  BuildContext context,
  WidgetRef ref,
  AmmoLotRecord item,
) async {
  final draft = await Navigator.of(context).push<_AmmoDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _AmmoDialog(initial: item),
    ),
  );
  if (draft == null) return;
  await ref
      .read(repositoryProvider)
      .updateAmmoLot(
        id: item.id,
        cartridgeId: draft.cartridgeId,
        displayName: draft.displayName,
        manufacturer: draft.manufacturer,
        productName: draft.productName,
        lotNumber: draft.lotNumber,
        bulletWeightGrains: draft.weight,
        projectileType: draft.projectileType,
        notes: draft.notes,
      );
}

Future<void> _editRange(
  BuildContext context,
  WidgetRef ref,
  RangeRecord item,
) async {
  final draft = await Navigator.of(context).push<_RangeDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _RangeDialog(initial: item),
    ),
  );
  if (draft == null) return;
  await ref
      .read(repositoryProvider)
      .updateRange(
        id: item.id,
        name: draft.name,
        isIndoor: draft.isIndoor,
        locationDescription: draft.location,
        availableDistances: draft.distances,
        notes: draft.notes,
      );
}

Future<void> _editCartridge(
  BuildContext context,
  WidgetRef ref,
  CartridgeRecord item,
) async {
  final draft = await Navigator.of(context).push<_CartridgeDraft>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _CartridgeDialog(initial: item),
    ),
  );
  if (draft == null) return;
  await ref
      .read(repositoryProvider)
      .updateCustomCartridge(
        id: item.id,
        name: draft.name,
        projectileDiameterMm: draft.diameter,
        notes: draft.notes,
      );
}

Future<void> _editTarget(
  BuildContext context,
  WidgetRef ref,
  TargetProfileRecord item,
) async {
  final original = domain.TargetProfile.fromJsonString(item.profileJson);
  final edited = await Navigator.of(context).push<domain.TargetProfile>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _TargetDialog(initial: original),
    ),
  );
  if (edited == null) return;
  await ref
      .read(repositoryProvider)
      .saveCustomTargetEdit(item.versionedId, edited);
}

Future<void> _duplicateCartridge(
  BuildContext context,
  WidgetRef ref,
  CartridgeRecord item,
) async {
  await ref.read(repositoryProvider).duplicateCartridge(item.id);
  if (context.mounted) {
    AppMessenger.show(
      context,
      kind: AppNoticeKind.success,
      message: 'Bewerkbare kopie gemaakt',
    );
  }
}

Future<void> _duplicateTarget(
  BuildContext context,
  WidgetRef ref,
  TargetProfileRecord item,
) async {
  await ref.read(repositoryProvider).duplicateTargetProfile(item.versionedId);
  if (context.mounted) {
    AppMessenger.show(
      context,
      kind: AppNoticeKind.success,
      message: 'Bewerkbare kopie gemaakt',
    );
  }
}

Future<void> _removeLibraryItem(
  BuildContext context,
  WidgetRef ref, {
  required LibraryItemKind kind,
  required String id,
  required String label,
}) async {
  final repository = ref.read(repositoryProvider);
  final usage = await repository.getLibraryUsage(kind, id);
  if (!context.mounted) return;
  final confirmed = await showAppDecisionDialog<bool>(
    context: context,
    title: '$label verwijderen?',
    content: Text(
      usage.isInUse
          ? 'Dit item wordt gebruikt en daarom veilig gearchiveerd. Historische gegevens blijven behouden.'
          : 'Dit item wordt definitief verwijderd omdat het nergens gebruikt wordt.',
    ),
    actions: const [
      AppDecisionAction(
        label: 'Verwijderen',
        value: true,
        kind: AppDecisionActionKind.destructive,
      ),
      AppDecisionAction(
        label: 'Annuleren',
        value: false,
        kind: AppDecisionActionKind.text,
      ),
    ],
  );
  if (confirmed != true) return;
  LibraryRemovalResult result;
  switch (kind) {
    case LibraryItemKind.firearm:
      result = await repository.removeFirearm(id);
    case LibraryItemKind.cartridge:
      result = await repository.removeCartridge(
        id,
        archiveDependents: usage.dependentAmmoLotCount > 0,
      );
    case LibraryItemKind.ammoLot:
      result = await repository.removeAmmoLot(id);
    case LibraryItemKind.range:
      result = await repository.removeRange(id);
    case LibraryItemKind.targetProfile:
      result = await repository.removeTargetProfile(id);
  }
  if (!context.mounted) return;
  final message = switch (result) {
    LibraryRemovalResult.deleted => 'Definitief verwijderd',
    LibraryRemovalResult.archived =>
      'Gearchiveerd omdat dit profiel gebruikt wordt',
    LibraryRemovalResult.blockedBuiltIn =>
      'Ingebouwde items kunnen niet verwijderd worden',
    LibraryRemovalResult.blockedDependency =>
      'Verwijdering geblokkeerd door afhankelijke profielen',
  };
  final noticeKind = switch (result) {
    LibraryRemovalResult.deleted ||
    LibraryRemovalResult.archived => AppNoticeKind.success,
    _ => AppNoticeKind.warning,
  };
  AppMessenger.show(context, kind: noticeKind, message: message);
}

class _ArchivedLibraryScreen extends ConsumerWidget {
  const _ArchivedLibraryScreen({required this.category});

  final _LibraryCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = switch (category) {
      _LibraryCategory.firearms =>
        (ref.watch(allFirearmsProvider).valueOrNull ?? const <FirearmRecord>[])
            .where((item) => item.archived)
            .map(
              (item) =>
                  _ArchivedEntry(item.name, LibraryItemKind.firearm, item.id),
            ),
      _LibraryCategory.ammunition => [
        ...(ref.watch(allCartridgesProvider).valueOrNull ??
                const <CartridgeRecord>[])
            .where((item) => item.archived)
            .map(
              (item) =>
                  _ArchivedEntry(item.name, LibraryItemKind.cartridge, item.id),
            ),
        ...(ref.watch(allAmmoLotsProvider).valueOrNull ??
                const <AmmoLotRecord>[])
            .where((item) => item.archived)
            .map(
              (item) => _ArchivedEntry(
                item.displayName,
                LibraryItemKind.ammoLot,
                item.id,
              ),
            ),
      ],
      _LibraryCategory.ranges =>
        (ref.watch(allRangesProvider).valueOrNull ?? const <RangeRecord>[])
            .where((item) => item.archived)
            .map(
              (item) =>
                  _ArchivedEntry(item.name, LibraryItemKind.range, item.id),
            ),
      _LibraryCategory.targets =>
        (ref.watch(allTargetProfilesProvider).valueOrNull ??
                const <TargetProfileRecord>[])
            .where((item) => item.archived)
            .map(
              (item) => _ArchivedEntry(
                item.displayName,
                LibraryItemKind.targetProfile,
                item.versionedId,
              ),
            ),
    };
    final items = entries.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Gearchiveerde items')),
      body: items.isEmpty
          ? const Center(child: Text('Geen gearchiveerde items'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(indent: 16),
              itemBuilder: (context, index) {
                final item = items[index];
                return FutureBuilder<LibraryUsageSummary>(
                  future: ref
                      .read(repositoryProvider)
                      .getLibraryUsage(item.kind, item.id),
                  builder: (context, snapshot) {
                    final usage = snapshot.data;
                    final count =
                        (usage?.sessionCount ?? 0) +
                        (usage?.seriesCount ?? 0) +
                        (usage?.goalCount ?? 0);
                    return ListTile(
                      title: Text(item.label),
                      subtitle: Text(
                        count == 0
                            ? 'Niet meer in gebruik'
                            : 'Bewaard voor $count historische verwijzingen',
                      ),
                      trailing: PopupMenuButton<_ArchivedAction>(
                        onSelected: (action) =>
                            action == _ArchivedAction.restore
                            ? _restoreArchived(context, ref, item)
                            : _removeLibraryItem(
                                context,
                                ref,
                                kind: item.kind,
                                id: item.id,
                                label: item.label,
                              ),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: _ArchivedAction.restore,
                            child: Text('Herstellen'),
                          ),
                          if (usage != null && !usage.isInUse)
                            const PopupMenuItem(
                              value: _ArchivedAction.delete,
                              child: Text('Definitief verwijderen'),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _ArchivedEntry {
  const _ArchivedEntry(this.label, this.kind, this.id);
  final String label;
  final LibraryItemKind kind;
  final String id;
}

enum _ArchivedAction { restore, delete }

Future<void> _restoreArchived(
  BuildContext context,
  WidgetRef ref,
  _ArchivedEntry item,
) async {
  final repository = ref.read(repositoryProvider);
  try {
    switch (item.kind) {
      case LibraryItemKind.firearm:
        await repository.restoreFirearm(item.id);
      case LibraryItemKind.cartridge:
        await repository.restoreCartridge(item.id);
      case LibraryItemKind.ammoLot:
        await repository.restoreAmmoLot(item.id);
      case LibraryItemKind.range:
        await repository.restoreRange(item.id);
      case LibraryItemKind.targetProfile:
        await repository.restoreTargetProfile(item.id);
    }
    if (context.mounted) {
      AppMessenger.show(
        context,
        kind: AppNoticeKind.success,
        message: 'Item hersteld',
      );
    }
  } on StateError catch (error) {
    if (context.mounted) {
      AppMessenger.show(
        context,
        kind: AppNoticeKind.error,
        message: error.message,
      );
    }
  }
}

class _CartridgeDraft {
  const _CartridgeDraft(this.name, this.diameter, this.notes);
  final String name;
  final double diameter;
  final String notes;
}

class _CartridgeDialog extends StatefulWidget {
  const _CartridgeDialog({this.initial});
  final CartridgeRecord? initial;

  @override
  State<_CartridgeDialog> createState() => _CartridgeDialogState();
}

class _CartridgeDialogState extends State<_CartridgeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _diameter;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.name);
    _diameter = TextEditingController(
      text: widget.initial?.projectileDiameterMm.toString() ?? '',
    );
    _notes = TextEditingController(text: widget.initial?.notes);
  }

  @override
  void dispose() {
    _name.dispose();
    _diameter.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormScaffold(
    title: widget.initial == null ? 'Kaliber toevoegen' : 'Kaliber bewerken',
    actions: [FilledButton(onPressed: _submit, child: const Text('Bewaren'))],
    body: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Naam *'),
            validator: (value) => _requiredText(value, 'Vul een naam in'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _diameter,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalInputFormatter()],
            decoration: const InputDecoration(
              labelText: 'Projectieldiameter *',
              suffixText: 'mm',
            ),
            validator: (value) => _positiveNumberError(value, 'diameter'),
          ),
          const SizedBox(height: 16),
          AppMultilineField(
            controller: _notes,
            label: 'Notities',
            minLines: 3,
            maxLines: 5,
          ),
        ],
      ),
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _CartridgeDraft(
        _name.text.trim(),
        _parseDecimal(_diameter.text)!,
        _notes.text.trim(),
      ),
    );
  }
}

class _FirearmDraft {
  const _FirearmDraft(
    this.name,
    this.type,
    this.manufacturer,
    this.model,
    this.cartridgeId,
    this.notes,
  );
  final String name;
  final domain.FirearmType type;
  final String manufacturer;
  final String model;
  final String? cartridgeId;
  final String notes;
}

class _FirearmDialog extends ConsumerStatefulWidget {
  const _FirearmDialog({this.initial});
  final FirearmRecord? initial;
  @override
  ConsumerState<_FirearmDialog> createState() => _FirearmDialogState();
}

class _FirearmDialogState extends ConsumerState<_FirearmDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController manufacturer;
  late final TextEditingController model;
  late final TextEditingController notes;
  late domain.FirearmType type;
  String? cartridgeId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.name);
    manufacturer = TextEditingController(text: initial?.manufacturer);
    model = TextEditingController(text: initial?.model);
    notes = TextEditingController(text: initial?.sightNotes);
    type = initial == null
        ? domain.FirearmType.pistol
        : domain.FirearmType.values.byName(initial.type);
    cartridgeId = initial?.defaultCartridgeId;
  }

  @override
  void dispose() {
    name.dispose();
    manufacturer.dispose();
    model.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartridges =
        ref.watch(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[];
    return AppFormScaffold(
      title: widget.initial == null ? 'Wapen toevoegen' : 'Wapen bewerken',
      actions: [FilledButton(onPressed: _submit, child: const Text('Bewaren'))],
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Naam *'),
              validator: (value) => _requiredText(value, 'Vul een naam in'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: manufacturer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: model,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Model'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            AppSelectField<domain.FirearmType>(
              label: 'Type',
              initialValue: type,
              options: const [
                AppSelectOption(
                  value: domain.FirearmType.pistol,
                  label: 'Pistool',
                ),
                AppSelectOption(
                  value: domain.FirearmType.revolver,
                  label: 'Revolver',
                ),
                AppSelectOption(
                  value: domain.FirearmType.rifle,
                  label: 'Geweer',
                ),
                AppSelectOption(
                  value: domain.FirearmType.other,
                  label: 'Anders',
                ),
              ],
              onChanged: (value) => setState(() => type = value),
            ),
            const SizedBox(height: 16),
            AppSelectField<String?>(
              label: 'Standaardkaliber',
              initialValue: cartridgeId,
              options: [
                const AppSelectOption<String?>(
                  value: null,
                  label: 'Niet opgegeven',
                ),
                ...cartridges.map(
                  (item) => AppSelectOption<String?>(
                    value: item.id,
                    label: item.name,
                  ),
                ),
              ],
              onChanged: (value) => setState(() => cartridgeId = value),
            ),
            const SizedBox(height: 16),
            AppMultilineField(
              controller: notes,
              label: 'Vizier en notities',
              minLines: 3,
              maxLines: 5,
              validator: (value) => _optionalTextLength(value, maximum: 500),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _FirearmDraft(
        name.text.trim(),
        type,
        manufacturer.text.trim(),
        model.text.trim(),
        cartridgeId,
        notes.text.trim(),
      ),
    );
  }
}

class _AmmoDraft {
  const _AmmoDraft(
    this.cartridgeId,
    this.displayName,
    this.manufacturer,
    this.productName,
    this.lotNumber,
    this.weight,
    this.projectileType,
    this.notes,
  );
  final String cartridgeId;
  final String displayName;
  final String manufacturer;
  final String productName;
  final String lotNumber;
  final double? weight;
  final String projectileType;
  final String notes;
}

class _AmmoDialog extends ConsumerStatefulWidget {
  const _AmmoDialog({this.initial});
  final AmmoLotRecord? initial;
  @override
  ConsumerState<_AmmoDialog> createState() => _AmmoDialogState();
}

class _AmmoDialogState extends ConsumerState<_AmmoDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController manufacturer;
  late final TextEditingController product;
  late final TextEditingController lot;
  late final TextEditingController weight;
  late final TextEditingController projectile;
  late final TextEditingController notes;
  String? cartridgeId;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.displayName);
    manufacturer = TextEditingController(text: initial?.manufacturer);
    product = TextEditingController(text: initial?.productName);
    lot = TextEditingController(text: initial?.lotNumber);
    weight = TextEditingController(
      text: initial?.bulletWeightGrains?.toString(),
    );
    projectile = TextEditingController(text: initial?.projectileType);
    notes = TextEditingController(text: initial?.notes);
    cartridgeId = initial?.cartridgeId;
  }

  @override
  void dispose() {
    name.dispose();
    manufacturer.dispose();
    product.dispose();
    lot.dispose();
    weight.dispose();
    projectile.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartridges =
        ref.watch(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[];
    final selectedCartridge = cartridgeId ?? cartridges.firstOrNull?.id;
    return AppFormScaffold(
      title: widget.initial == null
          ? 'Munitieprofiel toevoegen'
          : 'Munitieprofiel bewerken',
      actions: [FilledButton(onPressed: _submit, child: const Text('Bewaren'))],
      body: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSelectField<String?>(
              label: 'Kaliber *',
              initialValue: selectedCartridge,
              options: cartridges
                  .map(
                    (item) => AppSelectOption<String?>(
                      value: item.id,
                      label: item.name,
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => cartridgeId = value),
              validation: (value) => value == null ? 'Kies een kaliber' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Weergavenaam *'),
              validator: (value) =>
                  _requiredText(value, 'Vul een weergavenaam in'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: manufacturer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: product,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Product'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: lot,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Lotnummer'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: weight,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Kogelgewicht (grain)',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final parsed = double.tryParse(value.replaceAll(',', '.'));
                return parsed == null || !parsed.isFinite || parsed <= 0
                    ? 'Vul een positief getal in'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: projectile,
              decoration: const InputDecoration(labelText: 'Projectieltype'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 16),
            AppMultilineField(
              controller: notes,
              label: 'Notities',
              minLines: 3,
              maxLines: 5,
              validator: (value) => _optionalTextLength(value, maximum: 500),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _AmmoDraft(
        cartridgeId ??
            (ref.read(cartridgesProvider).valueOrNull?.firstOrNull?.id ?? ''),
        name.text.trim(),
        manufacturer.text.trim(),
        product.text.trim(),
        lot.text.trim(),
        double.tryParse(weight.text.replaceAll(',', '.')),
        projectile.text.trim(),
        notes.text.trim(),
      ),
    );
  }
}

class _RangeDraft {
  const _RangeDraft(
    this.name,
    this.isIndoor,
    this.location,
    this.distances,
    this.notes,
  );
  final String name;
  final bool isIndoor;
  final String location;
  final List<double> distances;
  final String notes;
}

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({this.initial});
  final RangeRecord? initial;
  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController location;
  late final List<TextEditingController> distanceRows;
  late final TextEditingController notes;
  late bool indoor;
  String? distanceListError;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.name);
    location = TextEditingController(text: initial?.locationDescription);
    final distances = initial == null
        ? const <num>[25, 50]
        : (jsonDecode(initial.availableDistancesJson) as List).cast<num>();
    distanceRows = distances
        .map((value) => TextEditingController(text: value.toString()))
        .toList();
    if (distanceRows.isEmpty) distanceRows.add(TextEditingController());
    notes = TextEditingController(text: initial?.notes);
    indoor = initial?.isIndoor ?? true;
  }

  @override
  void dispose() {
    name.dispose();
    location.dispose();
    for (final row in distanceRows) {
      row.dispose();
    }
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormScaffold(
    title: widget.initial == null
        ? 'Schietstand toevoegen'
        : 'Schietstand bewerken',
    actions: [FilledButton(onPressed: _submit, child: const Text('Bewaren'))],
    body: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Naam *'),
            validator: (value) => _requiredText(value, 'Vul een naam in'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: location,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Locatiebeschrijving'),
            validator: _optionalTextLength,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: indoor,
            onChanged: (value) => setState(() => indoor = value),
            title: Text(indoor ? 'Binnenstand' : 'Buitenstand'),
          ),
          const SizedBox(height: 16),
          Text('Afstanden', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          for (var index = 0; index < distanceRows.length; index++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('range-distance-$index'),
                    controller: distanceRows[index],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [_decimalInputFormatter()],
                    textInputAction: index == distanceRows.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Afstand ${index + 1} (m)',
                    ),
                    validator: (value) =>
                        _positiveNumberError(value, 'afstand'),
                    onChanged: (_) {
                      if (distanceListError != null) {
                        setState(() => distanceListError = null);
                      }
                    },
                  ),
                ),
                if (distanceRows.length > 1) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () => _removeDistance(index),
                    tooltip: 'Afstand ${index + 1} verwijderen',
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton.icon(
            onPressed: _addDistance,
            icon: const Icon(Icons.add),
            label: const Text('Afstand toevoegen'),
          ),
          if (distanceListError != null) ...[
            const SizedBox(height: 8),
            Text(
              distanceListError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          AppMultilineField(
            controller: notes,
            label: 'Notities',
            minLines: 3,
            maxLines: 4,
            validator: (value) => _optionalTextLength(value, maximum: 500),
          ),
        ],
      ),
    ),
  );

  void _addDistance() {
    setState(() {
      distanceRows.add(TextEditingController());
      distanceListError = null;
    });
  }

  void _removeDistance(int index) {
    if (distanceRows.length <= 1) return;
    final removed = distanceRows.removeAt(index);
    removed.dispose();
    setState(() => distanceListError = null);
  }

  void _submit() {
    if (!formKey.currentState!.validate()) return;
    final parsed = distanceRows.map((row) => _parseDecimal(row.text)!).toList();
    if (parsed.toSet().length != parsed.length) {
      setState(
        () => distanceListError = 'Iedere afstand mag maar één keer voorkomen',
      );
      return;
    }
    parsed.sort();
    Navigator.pop(
      context,
      _RangeDraft(
        name.text.trim(),
        indoor,
        location.text.trim(),
        parsed,
        notes.text.trim(),
      ),
    );
  }
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog({this.initial});
  final domain.TargetProfile? initial;
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _basicsFormKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController width;
  late final TextEditingController height;
  late final TextEditingController innerTen;
  late final TextEditingController black;
  late final List<_RingInput> ringRows;
  var step = 0;
  String? error;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    name = TextEditingController(text: initial?.displayName);
    width = TextEditingController(
      text: initial?.physicalCardWidthMm.toString() ?? '550',
    );
    height = TextEditingController(
      text: initial?.physicalCardHeightMm.toString() ?? '550',
    );
    innerTen = TextEditingController(
      text: initial?.innerTenDiameterMm?.toString() ?? '',
    );
    black = TextEditingController(
      text: initial?.blackOuterDiameterMm?.toString() ?? '200',
    );
    ringRows = initial == null
        ? [
            _RingInput(score: '10', diameter: '50'),
            _RingInput(score: '9', diameter: '100'),
            _RingInput(score: '8', diameter: '150'),
            _RingInput(score: '7', diameter: '200'),
            _RingInput(score: '6', diameter: '250'),
            _RingInput(score: '5', diameter: '300'),
          ]
        : initial.rings
              .map(
                (ring) => _RingInput(
                  score: ring.value.toString(),
                  diameter: ring.outerDiameterMm.toString(),
                ),
              )
              .toList();
  }

  @override
  void dispose() {
    name.dispose();
    width.dispose();
    height.dispose();
    innerTen.dispose();
    black.dispose();
    for (final row in ringRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['Basis', 'Scoringsringen', 'Voorbeeld'];
    return AppFormScaffold(
      title: widget.initial == null ? 'Eigen ringkaart' : 'Doelkaart bewerken',
      actions: switch (step) {
        0 => [
          FilledButton(
            onPressed: _nextFromBasics,
            child: const Text('Volgende'),
          ),
        ],
        1 => [
          TextButton(onPressed: _back, child: const Text('Terug')),
          FilledButton(
            onPressed: _nextFromRings,
            child: const Text('Voorbeeld'),
          ),
        ],
        _ => [
          TextButton(onPressed: _back, child: const Text('Terug')),
          FilledButton(onPressed: _save, child: const Text('Profiel bewaren')),
        ],
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Stap ${step + 1} van 3 · ${labels[step]}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: (step + 1) / 3),
          const SizedBox(height: 20),
          switch (step) {
            0 => _buildBasicsStep(),
            1 => _buildRingsStep(),
            _ => _buildPreviewStep(),
          },
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicsStep() => Form(
    key: _basicsFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Eigen profielen zijn experimenteel en niet officieel gevalideerd.',
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: name,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'Naam *'),
          validator: (value) =>
              _requiredText(value, 'Vul een naam in', maximum: 120),
        ),
        const SizedBox(height: 16),
        AdaptiveFormRow(
          minimumChildWidth: 150,
          children: [
            TextFormField(
              controller: width,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalInputFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Breedte (mm) *'),
              validator: (value) => _positiveNumberError(value, 'breedte'),
            ),
            TextFormField(
              controller: height,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalInputFormatter()],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Hoogte (mm) *'),
              validator: (value) => _positiveNumberError(value, 'hoogte'),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildRingsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Voer elke scoringsring apart in. Begin met de hoogste score; '
        'lagere scores moeten een grotere diameter hebben.',
      ),
      const SizedBox(height: 16),
      for (var index = 0; index < ringRows.length; index++) ...[
        _RingEditorRow(
          key: ObjectKey(ringRows[index]),
          index: index,
          input: ringRows[index],
          canRemove: ringRows.length > 1,
          onRemove: () => _removeRing(index),
          onChanged: () => setState(() {
            ringRows[index]
              ..scoreError = null
              ..diameterError = null;
            error = null;
          }),
        ),
        if (index != ringRows.length - 1) const SizedBox(height: 16),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: ringRows.length >= 20 ? null : _addRing,
        icon: const Icon(Icons.add),
        label: const Text('Ring toevoegen'),
      ),
    ],
  );

  Widget _buildPreviewStep() {
    final cardWidth = _parseDecimal(width.text) ?? 1;
    final cardHeight = _parseDecimal(height.text) ?? 1;
    final rings = _currentRings();
    final innerTenDiameter = _parseDecimal(innerTen.text);
    final blackDiameter = _parseDecimal(black.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TargetPreview(
          displayName: name.text.trim(),
          cardWidthMm: cardWidth,
          cardHeightMm: cardHeight,
          rings: rings,
          innerTenDiameterMm: innerTenDiameter,
          blackDiameterMm: blackDiameter,
        ),
        const SizedBox(height: 16),
        Text(
          '${name.text.trim()} · ${_formatNumber(cardWidth)} × '
          '${_formatNumber(cardHeight)} mm · ${rings.length} ringen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        AdaptiveFormRow(
          minimumChildWidth: 180,
          children: [
            TextField(
              controller: innerTen,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalInputFormatter()],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Binnentien (mm)',
                helperText: 'Optioneel',
              ),
              onChanged: (_) => setState(() => error = null),
            ),
            TextField(
              controller: black,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [_decimalInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Zwartvlak (mm)',
                helperText: 'Optioneel',
              ),
              onChanged: (_) => setState(() => error = null),
            ),
          ],
        ),
      ],
    );
  }

  void _nextFromBasics() {
    if (!_basicsFormKey.currentState!.validate()) return;
    setState(() {
      step = 1;
      error = null;
    });
  }

  void _nextFromRings() {
    if (_validateRings() == null) return;
    setState(() {
      step = 2;
      error = null;
    });
  }

  void _back() => setState(() {
    step--;
    error = null;
  });

  void _addRing() => setState(() {
    ringRows.add(_RingInput());
    error = null;
  });

  void _removeRing(int index) => setState(() {
    ringRows.removeAt(index).dispose();
    error = null;
  });

  List<domain.RingZone>? _validateRings() {
    var invalid = false;
    final parsed = <_ParsedRing>[];
    for (final row in ringRows) {
      row
        ..scoreError = null
        ..diameterError = null;
      final score = int.tryParse(row.score.text.trim());
      final diameter = _parseDecimal(row.diameter.text);
      if (score == null || score <= 0) {
        row.scoreError = 'Gebruik een geheel getal vanaf 1';
        invalid = true;
      }
      if (diameter == null || !diameter.isFinite || diameter <= 0) {
        row.diameterError = 'Gebruik een positieve diameter';
        invalid = true;
      }
      if (score != null && score > 0 && diameter != null && diameter > 0) {
        parsed.add(
          _ParsedRing(
            input: row,
            zone: domain.RingZone(value: score, outerDiameterMm: diameter),
          ),
        );
      }
    }

    final byScore = <int, List<_ParsedRing>>{};
    for (final item in parsed) {
      byScore.putIfAbsent(item.zone.value, () => []).add(item);
    }
    for (final duplicates in byScore.values.where(
      (items) => items.length > 1,
    )) {
      invalid = true;
      for (final item in duplicates) {
        item.input.scoreError = 'Deze score komt al voor';
      }
    }

    parsed.sort((left, right) => right.zone.value.compareTo(left.zone.value));
    final cardWidth = _parseDecimal(width.text) ?? 0;
    final cardHeight = _parseDecimal(height.text) ?? 0;
    for (var index = 0; index < parsed.length; index++) {
      final item = parsed[index];
      if (item.zone.outerDiameterMm > cardWidth ||
          item.zone.outerDiameterMm > cardHeight) {
        item.input.diameterError = 'Past niet binnen de kaart';
        invalid = true;
      }
      if (index > 0 &&
          item.zone.outerDiameterMm <= parsed[index - 1].zone.outerDiameterMm) {
        item.input.diameterError = 'Moet groter zijn dan de ring erboven';
        invalid = true;
      }
    }

    setState(() {
      error = invalid ? 'Controleer de gemarkeerde scoringsringen.' : null;
    });
    if (invalid || parsed.isEmpty) return null;
    return parsed.map((item) => item.zone).toList(growable: false);
  }

  List<domain.RingZone> _currentRings() {
    final values = <domain.RingZone>[];
    for (final row in ringRows) {
      final score = int.tryParse(row.score.text.trim());
      final diameter = _parseDecimal(row.diameter.text);
      if (score != null && diameter != null) {
        values.add(domain.RingZone(value: score, outerDiameterMm: diameter));
      }
    }
    values.sort((left, right) => right.value.compareTo(left.value));
    return values;
  }

  void _save() {
    try {
      final parsedRings = _validateRings();
      if (parsedRings == null) return;
      final cardWidth = _parseDecimal(width.text)!;
      final cardHeight = _parseDecimal(height.text)!;
      final displayName = name.text.trim();
      final innerTenDiameter = _optionalPositiveNumber(
        innerTen.text,
        'Binnentien',
      );
      final blackDiameter = _optionalPositiveNumber(black.text, 'Zwartvlak');
      final highestScoreRing = parsedRings.first;
      if (innerTenDiameter != null &&
          innerTenDiameter > highestScoreRing.outerDiameterMm) {
        throw const FormatException(
          'De binnentien moet binnen de hoogste scoringsring passen.',
        );
      }
      if (blackDiameter != null &&
          (blackDiameter > cardWidth || blackDiameter > cardHeight)) {
        throw const FormatException(
          'Het zwartvlak moet binnen de kaartmaten passen.',
        );
      }
      final slug = displayName
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
      Navigator.pop(
        context,
        domain.TargetProfile(
          schemaVersion: 1,
          profileId:
              'custom-${slug.isEmpty ? 'doelkaart' : slug}-'
              '${DateTime.now().millisecondsSinceEpoch}',
          profileVersion: 1,
          displayName: displayName,
          authority: 'Gebruiker',
          rulesEdition: 'Eigen profiel',
          physicalCardWidthMm: cardWidth,
          physicalCardHeightMm: cardHeight,
          rings: parsedRings,
          innerTenDiameterMm: innerTenDiameter,
          blackOuterDiameterMm: blackDiameter,
          lineThicknessMm: 0.5,
          lineBreakingRule: domain.LineBreakingRule.bulletEdgeTouchesHigherRing,
          validationStatus: domain.ValidationStatus.experimental,
        ),
      );
    } on FormatException catch (exception) {
      setState(() => error = exception.message);
    } catch (_) {
      setState(() => error = 'Controleer de ingevoerde waarden.');
    }
  }

  double? _optionalPositiveNumber(String source, String label) {
    final normalized = source.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || !value.isFinite || value <= 0) {
      throw FormatException('$label moet een positief getal zijn.');
    }
    return value;
  }
}

class _RingInput {
  _RingInput({String score = '', String diameter = ''})
    : score = TextEditingController(text: score),
      diameter = TextEditingController(text: diameter);

  final TextEditingController score;
  final TextEditingController diameter;
  String? scoreError;
  String? diameterError;

  void dispose() {
    score.dispose();
    diameter.dispose();
  }
}

class _ParsedRing {
  const _ParsedRing({required this.input, required this.zone});

  final _RingInput input;
  final domain.RingZone zone;
}

class _RingEditorRow extends StatelessWidget {
  const _RingEditorRow({
    required this.index,
    required this.input,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    super.key,
  });

  final int index;
  final _RingInput input;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scoreField = TextField(
      key: ValueKey('target-ring-$index-score'),
      controller: input.score,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Score',
        errorText: input.scoreError,
      ),
      onChanged: (_) => onChanged(),
    );
    final diameterField = TextField(
      key: ValueKey('target-ring-$index-diameter'),
      controller: input.diameter,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_decimalInputFormatter()],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: 'Buitendiameter',
        suffixText: 'mm',
        errorText: input.diameterError,
      ),
      onChanged: (_) => onChanged(),
    );
    final remove = IconButton(
      onPressed: canRemove ? onRemove : null,
      tooltip: 'Ring ${index + 1} verwijderen',
      icon: const Icon(Icons.delete_outline),
    );

    return Semantics(
      container: true,
      label: 'Scoringsring ${index + 1}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 460 ||
                  MediaQuery.textScalerOf(context).scale(1) >= 1.5;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Ring ${index + 1}')),
                        remove,
                      ],
                    ),
                    const SizedBox(height: 8),
                    AdaptiveFormRow(
                      minimumChildWidth: 130,
                      children: [scoreField, diameterField],
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, child: scoreField),
                  const SizedBox(width: 12),
                  Expanded(child: diameterField),
                  const SizedBox(width: 4),
                  remove,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TargetPreview extends StatelessWidget {
  const _TargetPreview({
    required this.displayName,
    required this.cardWidthMm,
    required this.cardHeightMm,
    required this.rings,
    this.innerTenDiameterMm,
    this.blackDiameterMm,
  });

  final String displayName;
  final double cardWidthMm;
  final double cardHeightMm;
  final List<domain.RingZone> rings;
  final double? innerTenDiameterMm;
  final double? blackDiameterMm;

  @override
  Widget build(BuildContext context) {
    final ratio = (cardWidthMm / cardHeightMm).clamp(0.25, 4.0).toDouble();
    return Semantics(
      image: true,
      label: 'Voorbeeld van $displayName met ${rings.length} scoringsringen',
      child: SizedBox(
        height: 260,
        child: Center(
          child: AspectRatio(
            aspectRatio: ratio,
            child: CustomPaint(
              painter: _TargetPreviewPainter(
                cardWidthMm: cardWidthMm,
                cardHeightMm: cardHeightMm,
                rings: rings,
                innerTenDiameterMm: innerTenDiameterMm,
                blackDiameterMm: blackDiameterMm,
                accent: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TargetPreviewPainter extends CustomPainter {
  const _TargetPreviewPainter({
    required this.cardWidthMm,
    required this.cardHeightMm,
    required this.rings,
    required this.accent,
    this.innerTenDiameterMm,
    this.blackDiameterMm,
  });

  final double cardWidthMm;
  final double cardHeightMm;
  final List<domain.RingZone> rings;
  final double? innerTenDiameterMm;
  final double? blackDiameterMm;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final cardRect = Offset.zero & size;
    canvas.drawRect(cardRect, Paint()..color = Colors.white);
    canvas.drawRect(
      cardRect.deflate(1),
      Paint()
        ..color = const Color(0xFF4A4A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final scale = math.min(
      size.width / cardWidthMm,
      size.height / cardHeightMm,
    );
    final center = cardRect.center;
    final blackRadius = (blackDiameterMm ?? 0) * scale / 2;
    if (blackRadius > 0) {
      canvas.drawCircle(center, blackRadius, Paint()..color = Colors.black);
    }
    final ringsByDiameter = [...rings]
      ..sort(
        (left, right) => right.outerDiameterMm.compareTo(left.outerDiameterMm),
      );
    for (final ring in ringsByDiameter) {
      final radius = ring.outerDiameterMm * scale / 2;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = radius <= blackRadius ? Colors.white : Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    final innerTenRadius = (innerTenDiameterMm ?? 0) * scale / 2;
    if (innerTenRadius > 0) {
      canvas.drawCircle(
        center,
        innerTenRadius,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(center, 2.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant _TargetPreviewPainter oldDelegate) =>
      oldDelegate.cardWidthMm != cardWidthMm ||
      oldDelegate.cardHeightMm != cardHeightMm ||
      oldDelegate.rings != rings ||
      oldDelegate.innerTenDiameterMm != innerTenDiameterMm ||
      oldDelegate.blackDiameterMm != blackDiameterMm ||
      oldDelegate.accent != accent;
}

TextInputFormatter _decimalInputFormatter() =>
    FilteringTextInputFormatter.allow(RegExp('[0-9,.]'));

String? _positiveNumberError(String? source, String fieldName) {
  final value = _parseDecimal(source ?? '');
  return value == null || !value.isFinite || value <= 0
      ? 'Vul een geldige $fieldName in'
      : null;
}

double? _parseDecimal(String source) =>
    double.tryParse(source.trim().replaceAll(',', '.'));

String _formatNumber(double value) =>
    value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);

String? _requiredText(String? value, String emptyMessage, {int maximum = 120}) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty) return emptyMessage;
  if (trimmed.length > maximum) {
    return 'Gebruik maximaal $maximum tekens';
  }
  return null;
}

String? _optionalTextLength(String? value, {int maximum = 120}) {
  if ((value?.trim().length ?? 0) > maximum) {
    return 'Gebruik maximaal $maximum tekens';
  }
  return null;
}

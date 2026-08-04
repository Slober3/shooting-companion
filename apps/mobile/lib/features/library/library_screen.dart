import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
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
    final draft = await showSafeModalSheet<_FirearmDraft>(
      context: context,
      builder: (_) => const _FirearmDialog(),
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
    final draft = await showSafeModalSheet<_AmmoDraft>(
      context: context,
      builder: (_) => const _AmmoDialog(),
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
        );
  }

  static Future<void> _addRange(BuildContext context, WidgetRef ref) async {
    final draft = await showSafeModalSheet<_RangeDraft>(
      context: context,
      builder: (_) => const _RangeDialog(),
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
    final profile = await showSafeModalSheet<domain.TargetProfile>(
      context: context,
      builder: (_) => const _TargetDialog(),
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
      _LibraryCategory.ammunition => LibraryScreen._addAmmo(context, ref),
      _LibraryCategory.ranges => LibraryScreen._addRange(context, ref),
      _LibraryCategory.targets => LibraryScreen._addTarget(context, ref),
    };
  }
}

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
        ...cartridges.map(
          (item) => ListTile(
            leading: const Icon(Icons.circle, size: 14),
            title: Text(item.name),
            subtitle: Text(
              '${item.projectileDiameterMm.toStringAsFixed(2)} mm scorediameter',
            ),
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
                              : 'Eigen profiel • experimenteel',
                        ),
                        trailing: Icon(
                          item.builtIn
                              ? Icons.verified_outlined
                              : Icons.science_outlined,
                          semanticLabel: item.builtIn
                              ? 'Officieel profiel'
                              : 'Experimenteel profiel',
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
          const SizedBox(height: 12),
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
  const _FirearmDialog();
  @override
  ConsumerState<_FirearmDialog> createState() => _FirearmDialogState();
}

class _FirearmDialogState extends ConsumerState<_FirearmDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final manufacturer = TextEditingController();
  final model = TextEditingController();
  final notes = TextEditingController();
  var type = domain.FirearmType.pistol;
  String? cartridgeId;

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
    return Form(
      key: formKey,
      child: SafeSheetScaffold(
        title: 'Wapenprofiel',
        actions: [
          FilledButton(onPressed: _submit, child: const Text('Bewaren')),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Naam *'),
              validator: (value) => _requiredText(value, 'Vul een naam in'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: manufacturer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: model,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Model'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<domain.FirearmType>(
              initialValue: type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: domain.FirearmType.pistol,
                  child: Text('Pistool', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: domain.FirearmType.revolver,
                  child: Text('Revolver', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: domain.FirearmType.other,
                  child: Text('Anders', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: cartridgeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Standaardkaliber'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text(
                    'Niet opgegeven',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ...cartridges.map(
                  (item) => DropdownMenuItem(
                    value: item.id,
                    child: Text(item.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => cartridgeId = value),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Vizier/notities'),
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
  );
  final String cartridgeId;
  final String displayName;
  final String manufacturer;
  final String productName;
  final String lotNumber;
  final double? weight;
  final String projectileType;
}

class _AmmoDialog extends ConsumerStatefulWidget {
  const _AmmoDialog();
  @override
  ConsumerState<_AmmoDialog> createState() => _AmmoDialogState();
}

class _AmmoDialogState extends ConsumerState<_AmmoDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final manufacturer = TextEditingController();
  final product = TextEditingController();
  final lot = TextEditingController();
  final weight = TextEditingController();
  final projectile = TextEditingController();
  String? cartridgeId;

  @override
  void dispose() {
    name.dispose();
    manufacturer.dispose();
    product.dispose();
    lot.dispose();
    weight.dispose();
    projectile.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartridges =
        ref.watch(cartridgesProvider).valueOrNull ?? const <CartridgeRecord>[];
    cartridgeId ??= cartridges.firstOrNull?.id;
    return Form(
      key: formKey,
      child: SafeSheetScaffold(
        title: 'Munitieprofiel',
        actions: [
          FilledButton(onPressed: _submit, child: const Text('Bewaren')),
        ],
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: cartridgeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Kaliber *'),
              items: cartridges
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => cartridgeId = value),
              validator: (value) => value == null ? 'Kies een kaliber' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Weergavenaam *'),
              validator: (value) =>
                  _requiredText(value, 'Vul een weergavenaam in'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: manufacturer,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: product,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Product'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: lot,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Lotnummer'),
              validator: _optionalTextLength,
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            TextFormField(
              controller: projectile,
              decoration: const InputDecoration(labelText: 'Projectieltype'),
              validator: _optionalTextLength,
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
        cartridgeId!,
        name.text.trim(),
        manufacturer.text.trim(),
        product.text.trim(),
        lot.text.trim(),
        double.tryParse(weight.text.replaceAll(',', '.')),
        projectile.text.trim(),
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
  const _RangeDialog();
  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final location = TextEditingController();
  final distanceRows = <TextEditingController>[
    TextEditingController(text: '25'),
    TextEditingController(text: '50'),
  ];
  final notes = TextEditingController();
  var indoor = true;
  String? distanceListError;

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
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: SafeSheetScaffold(
      title: 'Schietstand',
      actions: [FilledButton(onPressed: _submit, child: const Text('Bewaren'))],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: name,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Naam *'),
            validator: (value) => _requiredText(value, 'Vul een naam in'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: location,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Locatiebeschrijving'),
            validator: _optionalTextLength,
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: indoor,
            onChanged: (value) => setState(() => indoor = value),
            title: Text(indoor ? 'Binnenstand' : 'Buitenstand'),
          ),
          const SizedBox(height: 10),
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
          const SizedBox(height: 10),
          TextFormField(
            controller: notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notities'),
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
  const _TargetDialog();
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final _basicsFormKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final width = TextEditingController(text: '550');
  final height = TextEditingController(text: '550');
  final innerTen = TextEditingController();
  final black = TextEditingController(text: '200');
  final ringRows = <_RingInput>[
    _RingInput(score: '10', diameter: '50'),
    _RingInput(score: '9', diameter: '100'),
    _RingInput(score: '8', diameter: '150'),
    _RingInput(score: '7', diameter: '200'),
    _RingInput(score: '6', diameter: '250'),
    _RingInput(score: '5', diameter: '300'),
  ];
  var step = 0;
  String? error;

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
    return SafeSheetScaffold(
      title: 'Eigen ringkaart',
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
          FilledButton(onPressed: _save, child: const Text('Profiel maken')),
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
        const SizedBox(height: 12),
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
        if (index != ringRows.length - 1) const SizedBox(height: 10),
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

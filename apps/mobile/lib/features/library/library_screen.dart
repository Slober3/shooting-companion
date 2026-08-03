import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/compact_page_scaffold.dart';

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
    final draft = await showDialog<_FirearmDraft>(
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
    final draft = await showDialog<_AmmoDraft>(
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
    final draft = await showDialog<_RangeDraft>(
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
    final profile = await showDialog<domain.TargetProfile>(
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
    return AlertDialog(
      title: const Text('Wapenprofiel'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Naam *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: manufacturer,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: model,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<domain.FirearmType>(
              initialValue: type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: domain.FirearmType.pistol,
                  child: Text('Pistool'),
                ),
                DropdownMenuItem(
                  value: domain.FirearmType.revolver,
                  child: Text('Revolver'),
                ),
                DropdownMenuItem(
                  value: domain.FirearmType.other,
                  child: Text('Anders'),
                ),
              ],
              onChanged: (value) => setState(() => type = value!),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String?>(
              initialValue: cartridgeId,
              decoration: const InputDecoration(labelText: 'Standaardkaliber'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Niet opgegeven'),
                ),
                ...cartridges.map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                ),
              ],
              onChanged: (value) => setState(() => cartridgeId = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: notes,
              decoration: const InputDecoration(labelText: 'Vizier/notities'),
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
          onPressed: () => name.text.trim().isEmpty
              ? null
              : Navigator.pop(
                  context,
                  _FirearmDraft(
                    name.text,
                    type,
                    manufacturer.text,
                    model.text,
                    cartridgeId,
                    notes.text,
                  ),
                ),
          child: const Text('Bewaren'),
        ),
      ],
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
    return AlertDialog(
      title: const Text('Munitieprofiel'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: cartridgeId,
              decoration: const InputDecoration(labelText: 'Kaliber *'),
              items: cartridges
                  .map(
                    (item) => DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => cartridgeId = value),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Weergavenaam *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: manufacturer,
              decoration: const InputDecoration(labelText: 'Fabrikant'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: product,
              decoration: const InputDecoration(labelText: 'Product'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lot,
              decoration: const InputDecoration(labelText: 'Lotnummer'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: weight,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kogelgewicht (grain)',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: projectile,
              decoration: const InputDecoration(labelText: 'Projectieltype'),
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
          onPressed: () => cartridgeId == null || name.text.trim().isEmpty
              ? null
              : Navigator.pop(
                  context,
                  _AmmoDraft(
                    cartridgeId!,
                    name.text,
                    manufacturer.text,
                    product.text,
                    lot.text,
                    double.tryParse(weight.text.replaceAll(',', '.')),
                    projectile.text,
                  ),
                ),
          child: const Text('Bewaren'),
        ),
      ],
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
  final name = TextEditingController();
  final location = TextEditingController();
  final distances = TextEditingController(text: '25, 50');
  final notes = TextEditingController();
  var indoor = true;

  @override
  void dispose() {
    name.dispose();
    location.dispose();
    distances.dispose();
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Schietstand'),
    content: SingleChildScrollView(
      child: Column(
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Naam *'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: location,
            decoration: const InputDecoration(labelText: 'Locatiebeschrijving'),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: indoor,
            onChanged: (value) => setState(() => indoor = value),
            title: Text(indoor ? 'Binnenstand' : 'Buitenstand'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: distances,
            decoration: const InputDecoration(
              labelText: 'Afstanden in meter',
              helperText: 'Bijvoorbeeld: 15, 25, 50',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: notes,
            decoration: const InputDecoration(labelText: 'Notities'),
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
        onPressed: () {
          if (name.text.trim().isEmpty) return;
          final parsed = distances.text
              .split(',')
              .map((value) => double.tryParse(value.trim()))
              .whereType<double>()
              .toList();
          Navigator.pop(
            context,
            _RangeDraft(name.text, indoor, location.text, parsed, notes.text),
          );
        },
        child: const Text('Bewaren'),
      ),
    ],
  );
}

class _TargetDialog extends StatefulWidget {
  const _TargetDialog();
  @override
  State<_TargetDialog> createState() => _TargetDialogState();
}

class _TargetDialogState extends State<_TargetDialog> {
  final name = TextEditingController();
  final width = TextEditingController(text: '550');
  final height = TextEditingController(text: '550');
  final rings = TextEditingController(
    text: '10:50, 9:100, 8:150, 7:200, 6:250, 5:300',
  );
  final innerTen = TextEditingController();
  final black = TextEditingController(text: '200');
  String? error;

  @override
  void dispose() {
    name.dispose();
    width.dispose();
    height.dispose();
    rings.dispose();
    innerTen.dispose();
    black.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Eigen ringkaart'),
    content: SingleChildScrollView(
      child: Column(
        children: [
          const Text(
            'Eigen profielen zijn experimenteel en niet officieel gevalideerd.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Naam *'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: width,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Breedte mm'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Hoogte mm'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: rings,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Ringen: score:diameter',
              helperText: '10:50, 9:100, 8:150',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: innerTen,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Binnentien diameter mm (optioneel)',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: black,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Zwartvlak diameter mm (optioneel)',
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuleren'),
      ),
      FilledButton(onPressed: _save, child: const Text('Profiel maken')),
    ],
  );

  void _save() {
    try {
      final cardWidth = double.parse(width.text.replaceAll(',', '.'));
      final cardHeight = double.parse(height.text.replaceAll(',', '.'));
      final parsedRings = rings.text.split(',').map((entry) {
        final parts = entry.trim().split(':');
        if (parts.length != 2) {
          throw const FormatException('Gebruik score:diameter per ring.');
        }
        return domain.RingZone(
          value: int.parse(parts[0].trim()),
          outerDiameterMm: double.parse(parts[1].trim().replaceAll(',', '.')),
        );
      }).toList();
      if (name.text.trim().isEmpty ||
          cardWidth <= 0 ||
          cardHeight <= 0 ||
          parsedRings.isEmpty) {
        throw const FormatException(
          'Vul naam, kaartmaten en minstens één ring in.',
        );
      }
      if (parsedRings.any(
        (ring) =>
            ring.outerDiameterMm > cardWidth ||
            ring.outerDiameterMm > cardHeight,
      )) {
        throw const FormatException('Een ring past niet binnen de kaartmaten.');
      }
      final slug = name.text
          .trim()
          .toLowerCase()
          .replaceAll(RegExp('[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'(^-|-$)'), '');
      Navigator.pop(
        context,
        domain.TargetProfile(
          schemaVersion: 1,
          profileId: 'custom-$slug-${DateTime.now().millisecondsSinceEpoch}',
          profileVersion: 1,
          displayName: name.text.trim(),
          authority: 'Gebruiker',
          rulesEdition: 'Eigen profiel',
          physicalCardWidthMm: cardWidth,
          physicalCardHeightMm: cardHeight,
          rings: parsedRings,
          innerTenDiameterMm: double.tryParse(
            innerTen.text.replaceAll(',', '.'),
          ),
          blackOuterDiameterMm: double.tryParse(
            black.text.replaceAll(',', '.'),
          ),
          lineThicknessMm: 0.5,
          lineBreakingRule: domain.LineBreakingRule.bulletEdgeTouchesHigherRing,
          validationStatus: domain.ValidationStatus.experimental,
        ),
      );
    } catch (exception) {
      setState(() => error = '$exception');
    }
  }
}

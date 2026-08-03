import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_domain/domain.dart';

import '../../data/app_database.dart';

class SeriesSettingsValues {
  const SeriesSettingsValues({
    required this.target,
    required this.cartridgeId,
    required this.distanceMeters,
    this.firearmId,
    this.ammoLotId,
    this.notes,
  });

  final TargetProfile target;
  final String cartridgeId;
  final double distanceMeters;
  final String? firearmId;
  final String? ammoLotId;
  final String? notes;
}

Future<SeriesSettingsValues?> showSeriesSettingsSheet({
  required BuildContext context,
  required SeriesSettingsValues initial,
  required List<TargetProfileRecord> targets,
  required List<CartridgeRecord> cartridges,
  required List<FirearmRecord> firearms,
  required List<AmmoLotRecord> ammoLots,
}) => showModalBottomSheet<SeriesSettingsValues>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _SeriesSettingsSheet(
    initial: initial,
    targets: targets,
    cartridges: cartridges,
    firearms: firearms,
    ammoLots: ammoLots,
  ),
);

class _SeriesSettingsSheet extends StatefulWidget {
  const _SeriesSettingsSheet({
    required this.initial,
    required this.targets,
    required this.cartridges,
    required this.firearms,
    required this.ammoLots,
  });

  final SeriesSettingsValues initial;
  final List<TargetProfileRecord> targets;
  final List<CartridgeRecord> cartridges;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;

  @override
  State<_SeriesSettingsSheet> createState() => _SeriesSettingsSheetState();
}

class _SeriesSettingsSheetState extends State<_SeriesSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late TargetProfile _target;
  late String _cartridgeId;
  late String? _firearmId;
  late String? _ammoLotId;
  late final TextEditingController _distance;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _target = widget.initial.target;
    _cartridgeId = widget.initial.cartridgeId;
    _firearmId = widget.initial.firearmId;
    _ammoLotId = widget.initial.ammoLotId;
    _distance = TextEditingController(
      text: widget.initial.distanceMeters.toStringAsFixed(
        widget.initial.distanceMeters % 1 == 0 ? 0 : 1,
      ),
    );
    _notes = TextEditingController(text: widget.initial.notes);
  }

  @override
  void dispose() {
    _distance.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final targetProfiles = widget.targets
        .map((record) => TargetProfile.fromJsonString(record.profileJson))
        .toList();
    final filteredLots = widget.ammoLots
        .where((lot) => lot.cartridgeId == _cartridgeId)
        .toList();
    if (_ammoLotId != null &&
        !filteredLots.any((lot) => lot.id == _ammoLotId)) {
      _ammoLotId = null;
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Reeksinstellingen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Sluiten',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _target.versionedId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Doelkaart'),
                items: targetProfiles
                    .map(
                      (target) => DropdownMenuItem(
                        value: target.versionedId,
                        child: Text(
                          target.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) => setState(() {
                  _target = targetProfiles.firstWhere(
                    (target) => target.versionedId == id,
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _cartridgeId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Kaliber'),
                      items: widget.cartridges
                          .map(
                            (item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (id) => setState(() {
                        _cartridgeId = id!;
                        _ammoLotId = null;
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _distance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9,.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Afstand',
                        suffixText: 'm',
                      ),
                      validator: (value) {
                        final distance = double.tryParse(
                          (value ?? '').replaceAll(',', '.'),
                        );
                        return distance == null || distance <= 0
                            ? 'Vul een afstand in'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _firearmId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Wapen (optioneel)',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Niet opgegeven'),
                  ),
                  ...widget.firearms.map(
                    (item) => DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _firearmId = value),
              ),
              if (filteredLots.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _ammoLotId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Munitielot (optioneel)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Niet opgegeven'),
                    ),
                    ...filteredLots.map(
                      (lot) => DropdownMenuItem<String?>(
                        value: lot.id,
                        child: Text(
                          lot.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _ammoLotId = value),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Reeksnotitie (optioneel)',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _submit, child: const Text('Toepassen')),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      SeriesSettingsValues(
        target: _target,
        cartridgeId: _cartridgeId,
        distanceMeters: double.parse(_distance.text.replaceAll(',', '.')),
        firearmId: _firearmId,
        ammoLotId: _ammoLotId,
        notes: _nullable(_notes.text),
      ),
    );
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

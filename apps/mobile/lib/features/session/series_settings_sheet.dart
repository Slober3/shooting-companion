import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_domain/domain.dart';

import '../../data/app_database.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_multiline_field.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/safe_sheet_scaffold.dart';

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
}) => Navigator.of(context).push<SeriesSettingsValues>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _SeriesSettingsSheet(
      initial: initial,
      targets: targets,
      cartridges: cartridges,
      firearms: firearms,
      ammoLots: ammoLots,
    ),
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
  var _materialExpanded = false;
  var _submitted = false;

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
    _distance.addListener(_changed);
    _notes.addListener(_changed);
  }

  void _changed() => setState(() {});

  bool get _dirty =>
      _target.versionedId != widget.initial.target.versionedId ||
      _cartridgeId != widget.initial.cartridgeId ||
      _firearmId != widget.initial.firearmId ||
      _ammoLotId != widget.initial.ammoLotId ||
      double.tryParse(_distance.text.replaceAll(',', '.')) !=
          widget.initial.distanceMeters ||
      _nullable(_notes.text) != widget.initial.notes;

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

    return AppFormScaffold(
      title: 'Reeksinstellingen',
      dirty: _dirty && !_submitted,
      actions: [
        FilledButton(onPressed: _submit, child: const Text('Toepassen')),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSelectField<String>(
              label: 'Doelkaart',
              initialValue: _target.versionedId,
              options: targetProfiles
                  .map(
                    (target) => AppSelectOption(
                      value: target.versionedId,
                      label: target.displayName,
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
            AdaptiveFormRow(
              minimumChildWidth: 160,
              children: [
                AppSelectField<String>(
                  label: 'Kaliber',
                  initialValue: _cartridgeId,
                  options: widget.cartridges
                      .map(
                        (item) =>
                            AppSelectOption(value: item.id, label: item.name),
                      )
                      .toList(),
                  onChanged: (id) => setState(() {
                    _cartridgeId = id;
                    _ammoLotId = null;
                  }),
                ),
                TextFormField(
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
                    return distance == null ||
                            !distance.isFinite ||
                            distance <= 0
                        ? 'Vul een geldige afstand in'
                        : null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              initiallyExpanded: _materialExpanded,
              onExpansionChanged: (value) => _materialExpanded = value,
              title: const Text('Materiaal en notitie'),
              children: [
                AppSelectField<String?>(
                  label: 'Wapen (optioneel)',
                  initialValue: _firearmId,
                  options: [
                    const AppSelectOption<String?>(
                      value: null,
                      label: 'Niet opgegeven',
                    ),
                    ...widget.firearms.map(
                      (item) => AppSelectOption<String?>(
                        value: item.id,
                        label: item.name,
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(() => _firearmId = value),
                ),
                if (filteredLots.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  AppSelectField<String?>(
                    label: 'Munitieprofiel (optioneel)',
                    initialValue: _ammoLotId,
                    options: [
                      const AppSelectOption<String?>(
                        value: null,
                        label: 'Niet opgegeven',
                      ),
                      ...filteredLots.map(
                        (lot) => AppSelectOption<String?>(
                          value: lot.id,
                          label: lot.displayName,
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _ammoLotId = value),
                  ),
                ],
                const SizedBox(height: 12),
                AppMultilineField(
                  controller: _notes,
                  label: 'Reeksnotitie (optioneel)',
                  hint: 'Bijvoorbeeld houding, vizier of aandachtspunt',
                  validator: (value) => (value?.trim().length ?? 0) > 1000
                      ? 'Gebruik maximaal 1000 tekens'
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
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

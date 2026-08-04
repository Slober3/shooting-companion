import 'package:flutter/material.dart';
import 'package:shooting_companion_training/training.dart';

import '../../widgets/app_form_group.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_select_field.dart';

class SightCalculatorScreen extends StatefulWidget {
  const SightCalculatorScreen({super.key});

  @override
  State<SightCalculatorScreen> createState() => _SightCalculatorScreenState();
}

class _SightCalculatorScreenState extends State<SightCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _horizontalController = TextEditingController(text: '0');
  final _verticalController = TextEditingController(text: '0');
  final _distanceController = TextEditingController(text: '25');
  final _shotCountController = TextEditingController(text: '5');
  final _clickValueController = TextEditingController(text: '0,25');
  var _unit = SightAdjustmentUnit.moa;
  var _horizontalDirection =
      HorizontalAdjustmentDirection.positiveClicksMoveImpactLeft;
  var _verticalDirection =
      VerticalAdjustmentDirection.positiveClicksMoveImpactUp;
  var _directionsConfirmed = false;
  SightCorrectionResult? _result;

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    _distanceController.dispose();
    _shotCountController.dispose();
    _clickValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormScaffold(
    title: 'Viziercalculator',
    body: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Gebruik het gemeten groepscentrum. Positief horizontaal is rechts; '
            'positief verticaal is laag op de kaart.',
          ),
          const SizedBox(height: AppFormSpacing.section),
          AppFormGroup(
            title: 'Groepsmeting',
            children: [
              TextFormField(
                key: const ValueKey('sight-horizontal-offset'),
                controller: _horizontalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Horizontale afwijking',
                  helperText: 'Negatief = links, positief = rechts',
                  suffixText: 'mm',
                ),
                validator: (value) => _number(value, 'afwijking'),
                onChanged: (_) => _clearResult(),
              ),
              TextFormField(
                key: const ValueKey('sight-vertical-offset'),
                controller: _verticalController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Verticale afwijking',
                  helperText: 'Negatief = hoog, positief = laag',
                  suffixText: 'mm',
                ),
                validator: (value) => _number(value, 'afwijking'),
                onChanged: (_) => _clearResult(),
              ),
              TextFormField(
                key: const ValueKey('sight-distance'),
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Afstand',
                  suffixText: 'm',
                ),
                validator: (value) => _positiveNumber(value, 'afstand'),
                onChanged: (_) => _clearResult(),
              ),
              TextFormField(
                key: const ValueKey('sight-shot-count'),
                controller: _shotCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Positionele treffers',
                ),
                validator: (value) {
                  final parsed = int.tryParse((value ?? '').trim());
                  return parsed == null || parsed <= 0
                      ? 'Voer een geldig aantal in.'
                      : null;
                },
                onChanged: (_) => _clearResult(),
              ),
            ],
          ),
          const SizedBox(height: AppFormSpacing.section),
          AppFormGroup(
            title: 'Vizier',
            children: [
              AppSelectField<SightAdjustmentUnit>(
                key: ValueKey('sight-unit-${_unit.name}'),
                label: 'Eenheid',
                initialValue: _unit,
                options: const [
                  AppSelectOption(value: SightAdjustmentUnit.moa, label: 'MOA'),
                  AppSelectOption(
                    value: SightAdjustmentUnit.milliradian,
                    label: 'Milliradian (mrad)',
                  ),
                ],
                onChanged: (value) => setState(() {
                  _unit = value;
                  _result = null;
                }),
              ),
              TextFormField(
                key: const ValueKey('sight-click-value'),
                controller: _clickValueController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Waarde per klik',
                  suffixText: _unit == SightAdjustmentUnit.moa ? 'MOA' : 'mrad',
                ),
                validator: (value) => _positiveNumber(value, 'klikwaarde'),
                onChanged: (_) => _clearResult(),
              ),
              AppSelectField<HorizontalAdjustmentDirection>(
                key: ValueKey(
                  'sight-horizontal-direction-${_horizontalDirection.name}',
                ),
                label: 'Positieve horizontale klikken',
                initialValue: _horizontalDirection,
                options: const [
                  AppSelectOption(
                    value: HorizontalAdjustmentDirection
                        .positiveClicksMoveImpactLeft,
                    label: 'Verplaatsen inslag naar links',
                  ),
                  AppSelectOption(
                    value: HorizontalAdjustmentDirection
                        .positiveClicksMoveImpactRight,
                    label: 'Verplaatsen inslag naar rechts',
                  ),
                ],
                onChanged: (value) => setState(() {
                  _horizontalDirection = value;
                  _directionsConfirmed = false;
                  _result = null;
                }),
              ),
              AppSelectField<VerticalAdjustmentDirection>(
                key: ValueKey(
                  'sight-vertical-direction-${_verticalDirection.name}',
                ),
                label: 'Positieve verticale klikken',
                initialValue: _verticalDirection,
                options: const [
                  AppSelectOption(
                    value:
                        VerticalAdjustmentDirection.positiveClicksMoveImpactUp,
                    label: 'Verplaatsen inslag omhoog',
                  ),
                  AppSelectOption(
                    value: VerticalAdjustmentDirection
                        .positiveClicksMoveImpactDown,
                    label: 'Verplaatsen inslag omlaag',
                  ),
                ],
                onChanged: (value) => setState(() {
                  _verticalDirection = value;
                  _directionsConfirmed = false;
                  _result = null;
                }),
              ),
              CheckboxListTile(
                key: const ValueKey('sight-direction-confirmation'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Ik heb beide klikrichtingen gecontroleerd'),
                subtitle: const Text(
                  'Controleer markeringen of handleiding van je eigen vizier.',
                ),
                value: _directionsConfirmed,
                onChanged: (value) {
                  setState(() {
                    _directionsConfirmed = value ?? false;
                    _result = null;
                  });
                },
              ),
            ],
          ),
          if (_result != null) ...[
            const SizedBox(height: AppFormSpacing.section),
            _CorrectionCard(result: _result!),
          ],
        ],
      ),
    ),
    actions: [
      FilledButton.icon(
        key: const ValueKey('calculate-sight-correction'),
        onPressed: _calculate,
        icon: const Icon(Icons.calculate_outlined),
        label: const Text('Berekenen'),
      ),
    ],
  );

  void _clearResult() {
    if (_result != null) setState(() => _result = null);
  }

  void _calculate() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final profile = SightProfile(
      id: 'local-preview',
      firearmId: 'local-firearm',
      name: 'Lokale berekening',
      adjustmentUnit: _unit,
      clickValue: _parseDecimal(_clickValueController.text)!,
      horizontalDirection: _horizontalDirection,
      verticalDirection: _verticalDirection,
    );
    setState(() {
      _result = SightCorrectionCalculator.calculate(
        profile: profile,
        centroidXMm: _parseDecimal(_horizontalController.text)!,
        centroidYMm: _parseDecimal(_verticalController.text)!,
        distanceMeters: _parseDecimal(_distanceController.text)!,
        positionedShotCount: int.parse(_shotCountController.text.trim()),
        directionsConfirmed: _directionsConfirmed,
      );
    });
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({required this.result});

  final SightCorrectionResult result;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      key: const ValueKey('sight-correction-result'),
      color: result.directionsConfirmed
          ? colors.secondaryContainer
          : colors.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              result.directionsConfirmed
                  ? 'Voorgestelde correctie'
                  : 'Bevestig eerst de klikrichtingen',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _AxisResult(
              axis: 'Horizontaal',
              movement: _horizontalMovement(
                result.horizontal.requiredImpactMovement,
              ),
              absoluteClicks: result.horizontal.absoluteClicks,
              signedClicks: result.horizontal.signedClicks,
            ),
            const SizedBox(height: 8),
            _AxisResult(
              axis: 'Verticaal',
              movement: _verticalMovement(
                result.vertical.requiredImpactMovement,
              ),
              absoluteClicks: result.vertical.absoluteClicks,
              signedClicks: result.vertical.signedClicks,
            ),
            if (result.isProvisional) ...[
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Voorlopig resultaat: gebruik minimaal vijf positionele '
                      'treffers en schiet na een aanpassing een controlegroep.',
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AxisResult extends StatelessWidget {
  const _AxisResult({
    required this.axis,
    required this.movement,
    required this.absoluteClicks,
    required this.signedClicks,
  });

  final String axis;
  final String movement;
  final int absoluteClicks;
  final int? signedClicks;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 92,
        child: Text(axis, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      Expanded(
        child: Text(
          signedClicks == null
              ? '$movement · $absoluteClicks klikken (richting nog niet bevestigd)'
              : '$movement · ${_signedLabel(signedClicks!)}',
        ),
      ),
    ],
  );
}

String _signedLabel(int clicks) {
  if (clicks == 0) return 'geen klikken';
  return '${clicks.abs()} ${clicks > 0 ? 'positieve' : 'negatieve'} klikken';
}

String _horizontalMovement(HorizontalImpactMovement movement) =>
    switch (movement) {
      HorizontalImpactMovement.none => 'geen verplaatsing',
      HorizontalImpactMovement.left => 'inslag naar links',
      HorizontalImpactMovement.right => 'inslag naar rechts',
    };

String _verticalMovement(VerticalImpactMovement movement) => switch (movement) {
  VerticalImpactMovement.none => 'geen verplaatsing',
  VerticalImpactMovement.up => 'inslag omhoog',
  VerticalImpactMovement.down => 'inslag omlaag',
};

String? _number(String? value, String label) =>
    _parseDecimal(value) == null ? 'Voer een geldige $label in.' : null;

String? _positiveNumber(String? value, String label) {
  final parsed = _parseDecimal(value);
  return parsed == null || parsed <= 0 ? 'Voer een geldige $label in.' : null;
}

double? _parseDecimal(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

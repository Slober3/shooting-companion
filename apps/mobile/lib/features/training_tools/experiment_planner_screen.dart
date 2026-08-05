import 'package:flutter/material.dart';
import 'package:shooting_companion_training/training.dart';

import '../../widgets/app_form_group.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_select_field.dart';

class ExperimentPlannerScreen extends StatefulWidget {
  const ExperimentPlannerScreen({
    required this.targetProfileVersionedId,
    required this.initialDistanceMeters,
    this.onPlanCreated,
    super.key,
  });

  final String targetProfileVersionedId;
  final double initialDistanceMeters;
  final ValueChanged<ExperimentPlan>? onPlanCreated;

  @override
  State<ExperimentPlannerScreen> createState() =>
      _ExperimentPlannerScreenState();
}

class _ExperimentPlannerScreenState extends State<ExperimentPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _variantAController = TextEditingController(text: 'Variant A');
  final _variantBController = TextEditingController(text: 'Variant B');
  late final TextEditingController _distanceController;
  var _variable = ExperimentVariable.ammoLot;
  var _blocks = 3;
  ExperimentPlan? _plan;

  @override
  void initState() {
    super.initState();
    _distanceController = TextEditingController(
      text: widget.initialDistanceMeters.toStringAsFixed(
        widget.initialDistanceMeters % 1 == 0 ? 0 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _variantAController.dispose();
    _variantBController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormScaffold(
    title: 'A/B-experiment',
    body: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Verander één variabele. De vaste A-B-B-A-volgorde beperkt '
            'volgorde-effecten zonder je scoreflow aan te passen.',
          ),
          const SizedBox(height: AppFormSpacing.section),
          AppFormGroup(
            title: 'Vergelijking',
            children: [
              AppSelectField<ExperimentVariable>(
                key: ValueKey('experiment-variable-${_variable.name}'),
                label: 'Variabele',
                initialValue: _variable,
                options: [
                  for (final value in ExperimentVariable.values)
                    AppSelectOption(value: value, label: _variableLabel(value)),
                ],
                onChanged: (value) => setState(() {
                  _variable = value;
                  _plan = null;
                }),
              ),
              TextFormField(
                key: const ValueKey('experiment-variant-a'),
                controller: _variantAController,
                decoration: const InputDecoration(labelText: 'Variant A'),
                validator: _required,
                onChanged: (_) => setState(() => _plan = null),
              ),
              TextFormField(
                key: const ValueKey('experiment-variant-b'),
                controller: _variantBController,
                decoration: const InputDecoration(labelText: 'Variant B'),
                validator: (value) {
                  final required = _required(value);
                  if (required != null) return required;
                  if (value!.trim() == _variantAController.text.trim()) {
                    return 'Gebruik een andere naam dan variant A.';
                  }
                  return null;
                },
                onChanged: (_) => setState(() => _plan = null),
              ),
            ],
          ),
          const SizedBox(height: AppFormSpacing.section),
          AppFormGroup(
            title: 'Plan',
            children: [
              TextFormField(
                key: const ValueKey('experiment-distance'),
                controller: _distanceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Afstand',
                  suffixText: 'm',
                ),
                validator: (value) => _positiveNumber(value, 'afstand'),
                onChanged: (_) => setState(() => _plan = null),
              ),
              AppSelectField<int>(
                key: ValueKey('experiment-blocks-$_blocks'),
                label: 'A-B-B-A-blokken',
                initialValue: _blocks,
                options: const [
                  AppSelectOption(
                    value: 1,
                    label: '1 blok · 2 reeksen per variant',
                  ),
                  AppSelectOption(
                    value: 2,
                    label: '2 blokken · 4 reeksen per variant',
                  ),
                  AppSelectOption(
                    value: 3,
                    label: '3 blokken · 6 reeksen per variant',
                  ),
                ],
                onChanged: (value) => setState(() {
                  _blocks = value;
                  _plan = null;
                }),
              ),
            ],
          ),
          const SizedBox(height: AppFormSpacing.section),
          _MinimumDataCard(plannedSeriesPerVariant: _blocks * 2),
          if (_plan != null) ...[
            const SizedBox(height: AppFormSpacing.section),
            _PlanPreview(
              plan: _plan!,
              variantALabel: _variantAController.text.trim(),
              variantBLabel: _variantBController.text.trim(),
            ),
          ],
        ],
      ),
    ),
    actions: [
      FilledButton.icon(
        key: const ValueKey('create-experiment-plan'),
        onPressed: _createPlan,
        icon: const Icon(Icons.route_outlined),
        label: const Text('Plan maken'),
      ),
    ],
  );

  void _createPlan() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final definition = ExperimentDefinition(
      id: 'local-preview',
      version: 1,
      name:
          '${_variantAController.text.trim()} / ${_variantBController.text.trim()}',
      variable: _variable,
      variantA: ExperimentVariant(
        id: 'a',
        label: _variantAController.text.trim(),
      ),
      variantB: ExperimentVariant(
        id: 'b',
        label: _variantBController.text.trim(),
      ),
      targetProfileVersionedId: widget.targetProfileVersionedId,
      distanceMeters: _parseDecimal(_distanceController.text)!,
      plannedBlocks: _blocks,
    );
    final plan = ExperimentPlanner.create(definition);
    setState(() => _plan = plan);
    widget.onPlanCreated?.call(plan);
  }
}

class _MinimumDataCard extends StatelessWidget {
  const _MinimumDataCard({required this.plannedSeriesPerVariant});

  final int plannedSeriesPerVariant;

  @override
  Widget build(BuildContext context) {
    final enoughSeries = plannedSeriesPerVariant >= 5;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wanneer is de vergelijking bruikbaar?',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Minimaal 5 bevestigde reeksen én 50 positionele treffers per '
              'variant. Tot dan toont de app “Nog onvoldoende data”.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(enoughSeries ? Icons.check_circle : Icons.info_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$plannedSeriesPerVariant reeksen per variant gepland${enoughSeries ? '' : ' — plan later extra blokken'}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanPreview extends StatelessWidget {
  const _PlanPreview({
    required this.plan,
    required this.variantALabel,
    required this.variantBLabel,
  });

  final ExperimentPlan plan;
  final String variantALabel;
  final String variantBLabel;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('experiment-plan-preview'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Voorgestelde volgorde',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final assignment in plan.assignments)
            Chip(
              avatar: CircleAvatar(child: Text('${assignment.sequenceNumber}')),
              label: Text(
                assignment.variantId == 'a' ? variantALabel : variantBLabel,
              ),
            ),
        ],
      ),
    ],
  );
}

String _variableLabel(ExperimentVariable value) => switch (value) {
  ExperimentVariable.firearm => 'Wapen',
  ExperimentVariable.ammoLot => 'Munitielot',
  ExperimentVariable.position => 'Houding',
  ExperimentVariable.sightSetting => 'Vizierinstelling',
  ExperimentVariable.other => 'Andere variabele',
};

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Dit veld is verplicht.' : null;

String? _positiveNumber(String? value, String label) {
  final parsed = _parseDecimal(value);
  return parsed == null || parsed <= 0 ? 'Voer een geldige $label in.' : null;
}

double? _parseDecimal(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

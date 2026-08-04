import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart' as domain;

import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/safe_sheet_scaffold.dart';

class GoalDraft {
  const GoalDraft({
    required this.targetProfileVersionedId,
    required this.distanceMeters,
    required this.firearmId,
    required this.ammoLotId,
    required this.metric,
    required this.targetValue,
    required this.comparison,
  });

  final String targetProfileVersionedId;
  final double distanceMeters;
  final String? firearmId;
  final String? ammoLotId;
  final GoalMetric metric;
  final double targetValue;
  final GoalComparison comparison;
}

Future<GoalDraft?> showGoalEditorSheet({
  required BuildContext context,
  required List<TargetProfileRecord> targets,
  required List<FirearmRecord> firearms,
  required List<AmmoLotRecord> ammoLots,
}) => showSafeModalSheet<GoalDraft>(
  context: context,
  builder: (context) =>
      _GoalEditor(targets: targets, firearms: firearms, ammoLots: ammoLots),
);

class _GoalEditor extends StatefulWidget {
  const _GoalEditor({
    required this.targets,
    required this.firearms,
    required this.ammoLots,
  });

  final List<TargetProfileRecord> targets;
  final List<FirearmRecord> firearms;
  final List<AmmoLotRecord> ammoLots;

  @override
  State<_GoalEditor> createState() => _GoalEditorState();
}

class _GoalEditorState extends State<_GoalEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _distance;
  late final TextEditingController _value;
  String? _targetId;
  String? _firearmId;
  String? _ammoLotId;
  GoalMetric _metric = GoalMetric.scorePercentage;

  @override
  void initState() {
    super.initState();
    _targetId = widget.targets.firstOrNull?.versionedId;
    final target = widget.targets.firstOrNull;
    final profile = target == null
        ? null
        : domain.TargetProfile.fromJsonString(target.profileJson);
    _distance = TextEditingController(
      text: (profile?.defaultDistanceMeters ?? 25).toStringAsFixed(0),
    );
    _value = TextEditingController(text: '80');
  }

  @override
  void dispose() {
    _distance.dispose();
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeSheetScaffold(
    title: 'Persoonlijk doel',
    actions: [
      FilledButton(onPressed: _submit, child: const Text('Doel bewaren')),
    ],
    body: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSelectField<String?>(
            label: 'Doelkaart',
            initialValue: _targetId,
            options: [
              for (final target in widget.targets)
                AppSelectOption<String?>(
                  value: target.versionedId,
                  label: target.displayName,
                ),
            ],
            onChanged: (value) => setState(() => _targetId = value),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _distance,
            decoration: const InputDecoration(
              labelText: 'Afstand',
              suffixText: 'm',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _positiveNumber,
          ),
          const SizedBox(height: 16),
          AppSelectField<GoalMetric>(
            label: 'Meting',
            initialValue: _metric,
            options: [
              for (final metric in GoalMetric.values)
                AppSelectOption(value: metric, label: goalMetricLabel(metric)),
            ],
            onChanged: (value) => setState(() {
              _metric = value;
              _value.text = value == GoalMetric.scorePercentage ? '80' : '20';
            }),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _value,
            decoration: InputDecoration(
              labelText: 'Doelwaarde',
              suffixText: goalMetricUnit(_metric),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: _positiveNumber,
          ),
          const SizedBox(height: 16),
          AppSelectField<String?>(
            label: 'Wapen (optioneel)',
            initialValue: _firearmId,
            options: [
              const AppSelectOption(value: null, label: 'Alle wapens'),
              for (final firearm in widget.firearms)
                AppSelectOption(value: firearm.id, label: firearm.name),
            ],
            onChanged: (value) => setState(() => _firearmId = value),
          ),
          const SizedBox(height: 16),
          AppSelectField<String?>(
            label: 'Munitie (optioneel)',
            initialValue: _ammoLotId,
            options: [
              const AppSelectOption(value: null, label: 'Alle munitie'),
              for (final ammo in widget.ammoLots)
                AppSelectOption(value: ammo.id, label: ammo.displayName),
            ],
            onChanged: (value) => setState(() => _ammoLotId = value),
          ),
        ],
      ),
    ),
  );

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || _targetId == null) {
      return;
    }
    final distance = _parseNumber(_distance.text)!;
    final value = _parseNumber(_value.text)!;
    Navigator.pop(
      context,
      GoalDraft(
        targetProfileVersionedId: _targetId!,
        distanceMeters: distance,
        firearmId: _firearmId,
        ammoLotId: _ammoLotId,
        metric: _metric,
        targetValue: value,
        comparison: _defaultComparison(_metric),
      ),
    );
  }
}

String? _positiveNumber(String? source) {
  final value = _parseNumber(source);
  return value == null || value <= 0 ? 'Voer een positief getal in.' : null;
}

double? _parseNumber(String? source) =>
    double.tryParse((source ?? '').trim().replaceAll(',', '.'));

GoalComparison _defaultComparison(GoalMetric metric) => switch (metric) {
  GoalMetric.scorePercentage ||
  GoalMetric.trainingCount ||
  GoalMetric.completedBr50Bulls => GoalComparison.atLeast,
  _ => GoalComparison.atMost,
};

String goalMetricLabel(GoalMetric metric) => switch (metric) {
  GoalMetric.scorePercentage => 'Scorepercentage',
  GoalMetric.meanRadiusMm => 'Mean radius',
  GoalMetric.extremeSpreadMm => 'Extreme spreiding',
  GoalMetric.absoluteHorizontalBiasMm => 'Horizontale afwijking',
  GoalMetric.absoluteVerticalBiasMm => 'Verticale afwijking',
  GoalMetric.trainingCount => 'Trainingen per periode',
  GoalMetric.completedBr50Bulls => 'Voltooide BR50-roosjes',
  GoalMetric.consistency => 'Consistentie',
};

String goalMetricUnit(GoalMetric metric) => switch (metric) {
  GoalMetric.scorePercentage || GoalMetric.consistency => '%',
  GoalMetric.meanRadiusMm ||
  GoalMetric.extremeSpreadMm ||
  GoalMetric.absoluteHorizontalBiasMm ||
  GoalMetric.absoluteVerticalBiasMm => 'mm',
  GoalMetric.trainingCount || GoalMetric.completedBr50Bulls => '',
};

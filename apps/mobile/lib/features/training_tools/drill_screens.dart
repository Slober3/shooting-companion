import 'package:flutter/material.dart';
import 'package:shooting_companion_domain/domain.dart';
import 'package:shooting_companion_training/training.dart';

import '../../widgets/app_action_dock.dart';
import '../../widgets/compact_page_scaffold.dart';

class DrillLibraryScreen extends StatelessWidget {
  const DrillLibraryScreen({this.onDrillSelected, super.key});

  final ValueChanged<DrillDefinition>? onDrillSelected;

  @override
  Widget build(BuildContext context) => CompactPageScaffold(
    title: 'Drills',
    body: ListView.separated(
      key: const ValueKey('drill-library-list'),
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: BuiltInDrills.all.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(4, 8, 4, 16),
            child: Text(
              'Kies een trainingsvorm. Alle inhoud is lokaal beschikbaar; '
              'techniekteksten blijven experimenteel tot coachreview.',
            ),
          );
        }
        final drill = BuiltInDrills.all[index - 1];
        return ListTile(
          key: ValueKey('drill-${drill.id}'),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 6,
          ),
          title: Text(drill.name),
          subtitle: Text(
            '${drill.recommendedSeries} ${drill.recommendedSeries == 1 ? 'reeks' : 'reeksen'} · '
            '${_metricLabel(drill.successMetric.metric)}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => DrillDetailScreen(
                drill: drill,
                onDrillSelected: onDrillSelected,
              ),
            ),
          ),
        );
      },
    ),
  );
}

class DrillDetailScreen extends StatelessWidget {
  const DrillDetailScreen({
    required this.drill,
    this.onDrillSelected,
    super.key,
  });

  final DrillDefinition drill;
  final ValueChanged<DrillDefinition>? onDrillSelected;

  @override
  Widget build(BuildContext context) => CompactPageScaffold(
    title: drill.name,
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            const Chip(
              avatar: Icon(Icons.science_outlined, size: 18),
              label: Text('Experimenteel'),
            ),
            Chip(
              avatar: const Icon(Icons.repeat, size: 18),
              label: Text(
                '${drill.recommendedSeries} ${drill.recommendedSeries == 1 ? 'reeks' : 'reeksen'}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _DetailSection(title: 'Doel', child: Text(drill.objective)),
        _DetailSection(
          title: 'Meten',
          child: Text(
            '${_metricLabel(drill.successMetric.metric)} · '
            '${_directionLabel(drill.successMetric.direction)}',
          ),
        ),
        if (drill.shotStructure != null)
          _DetailSection(
            title: 'Structuur',
            child: Text(
              [
                if (drill.shotStructure!.shotsPerSeries != null)
                  '${drill.shotStructure!.shotsPerSeries} schoten per reeks',
                if (drill.shotStructure!.description != null)
                  drill.shotStructure!.description!,
              ].join(' · '),
            ),
          ),
        _DetailSection(
          title: 'Geschikte kaarten',
          child: Text(
            drill.compatibleTargetKinds.map(_targetKindLabel).join(', '),
          ),
        ),
        _DetailSection(
          title: 'Stappen',
          child: Column(
            children: [
              for (var index = 0; index < drill.instructions.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${index + 1}.',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(child: Text(drill.instructions[index])),
                    ],
                  ),
                ),
            ],
          ),
        ),
        Card(
          key: const ValueKey('drill-safety-note'),
          color: Theme.of(context).colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text(drill.safetyNote)),
              ],
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: onDrillSelected == null
        ? null
        : AppActionDock(
            actions: [
              FilledButton.icon(
                onPressed: () {
                  onDrillSelected!(drill);
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Drill kiezen'),
              ),
            ],
          ),
  );
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

String _metricLabel(DrillMetric metric) => switch (metric) {
  DrillMetric.completion => 'Voltooien',
  DrillMetric.scorePercentage => 'Scorepercentage',
  DrillMetric.meanRadiusMm => 'Mean radius',
  DrillMetric.extremeSpreadMm => 'Extreme spreiding',
  DrillMetric.consistency => 'Consistentie',
  DrillMetric.absoluteBiasMm => 'Afwijking groepscentrum',
  DrillMetric.selfEvaluation => 'Zelfevaluatie',
};

String _directionLabel(DrillMetricDirection direction) => switch (direction) {
  DrillMetricDirection.complete => 'voltooien',
  DrillMetricDirection.maximize => 'hoger is beter',
  DrillMetricDirection.minimize => 'lager is beter',
};

String _targetKindLabel(TargetKind kind) => switch (kind) {
  TargetKind.concentricRings => 'concentrische kaart',
  TargetKind.multiBullConcentric => 'multi-bullkaart',
};

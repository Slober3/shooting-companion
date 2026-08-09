import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';
import 'package:shooting_companion_training/training.dart';

import '../../widgets/compact_page_scaffold.dart';
import 'drill_screens.dart';
import 'experiment_planner_screen.dart';
import 'shot_timer_flow.dart';
import 'sight_calculator_screen.dart';
import 'timer_history_screen.dart';

/// Standalone entry point for offline drills, A/B plans and sight corrections.
///
/// This screen deliberately owns no persistence or app navigation state. The
/// optional callbacks let the app shell connect selections in a later release.
class TrainingToolsScreen extends ConsumerWidget {
  const TrainingToolsScreen({
    this.initialTargetProfileVersionedId = 'issf-25m-precision-50m-pistol@1',
    this.initialDistanceMeters = 25,
    this.onDrillSelected,
    this.onExperimentPlanCreated,
    super.key,
  });

  final String initialTargetProfileVersionedId;
  final double initialDistanceMeters;
  final ValueChanged<DrillDefinition>? onDrillSelected;
  final ValueChanged<ExperimentPlan>? onExperimentPlanCreated;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CompactPageScaffold(
    title: 'Trainingstools',
    body: ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          'Train gericht zonder je snelle scoreflow te vertragen.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _ToolCard(
          key: const ValueKey('training-tool-shot-timer'),
          icon: Icons.timer_outlined,
          title: 'Shot timer',
          description:
              'Meet live-firetijden en splits met een begeleide microfoonsetup.',
          onTap: () => launchShotTimerFlow(context: context, ref: ref),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-par-cadence'),
          icon: Icons.notifications_active_outlined,
          title: 'Par en cadans',
          description:
              'Train tijden, ritme en werk-rustblokken zonder microfoon.',
          onTap: () => launchShotTimerFlow(
            context: context,
            ref: ref,
            initialMode: ShotTimerMode.par,
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-timer-history'),
          icon: Icons.history,
          title: 'Timergeschiedenis',
          description:
              'Bekijk bewaarde runs, schottijden, splits en uitsluitingen.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const TimerHistoryScreen()),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-calibration-profiles'),
          icon: Icons.graphic_eq,
          title: 'Akoestische profielen',
          description:
              'Beheer lokale gevoeligheid en echofilters per omgeving.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => const AcousticCalibrationProfilesScreen(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Andere tools', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _ToolCard(
          key: const ValueKey('training-tool-drills'),
          icon: Icons.fitness_center_outlined,
          title: 'Drillbibliotheek',
          description:
              'Negen offline trainingsvormen met doel, stappen en meetpunt.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  DrillLibraryScreen(onDrillSelected: onDrillSelected),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-experiment'),
          icon: Icons.compare_arrows,
          title: 'A/B-experiment',
          description:
              'Maak een gebalanceerd A-B-B-A-plan voor materiaal of techniek.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => ExperimentPlannerScreen(
                targetProfileVersionedId: initialTargetProfileVersionedId,
                initialDistanceMeters: initialDistanceMeters,
                onPlanCreated: onExperimentPlanCreated,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ToolCard(
          key: const ValueKey('training-tool-sight'),
          icon: Icons.center_focus_strong,
          title: 'Viziercalculator',
          description:
              'Zet een gemeten groepsafwijking om naar MOA- of mrad-klikken.',
          onTap: () => Navigator.push<void>(
            context,
            MaterialPageRoute(builder: (_) => const SightCalculatorScreen()),
          ),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.offline_bolt_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Alle berekeningen en timerdetecties gebeuren lokaal. '
                    'Er worden geen audio-opnames bewaard. Een timerresultaat '
                    'wijzigt nooit automatisch een score of treffer.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

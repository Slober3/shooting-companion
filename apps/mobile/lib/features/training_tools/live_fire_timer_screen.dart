import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_expandable_section.dart';
import '../../widgets/app_notice.dart';
import 'shot_timer_screens.dart';

/// A deliberately small guided entry point for acoustic live-fire timing.
/// Technical detector values remain behind [AppExpandableSection].
class LiveFireShotTimerScreen extends ConsumerStatefulWidget {
  const LiveFireShotTimerScreen({super.key});

  @override
  ConsumerState<LiveFireShotTimerScreen> createState() =>
      _LiveFireShotTimerScreenState();
}

class _LiveFireShotTimerScreenState
    extends ConsumerState<LiveFireShotTimerScreen> {
  final _platform = const ShotTimerPlatformController();
  var _step = 0;
  var _showSetup = false;
  var _busy = false;
  var _microphoneReady = false;
  var _signalsConfirmed = false;
  var _sound = true;
  var _haptic = true;
  var _flash = false;
  var _flashActive = false;
  var _environment = 'Binnen';
  var _delayMode = ShotTimerDelayMode.random;
  var _fixedDelaySeconds = 3;
  var _randomMinimumSeconds = 2;
  var _randomMaximumSeconds = 4;
  var _inactivitySeconds = 3;
  int? _maximumShots;
  var _sensitivity = .65;
  var _sampleRate = 48000;
  var _detectorVersion = 'impulse-v1';

  @override
  Widget build(BuildContext context) {
    final profiles = ref.watch(acousticCalibrationProfilesProvider);
    return profiles.when(
      data: (items) => _buildScreen(items),
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Live-fire timer')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: const Text('Live-fire timer')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('De timerinstellingen konden niet worden geladen.'),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      ref.invalidate(acousticCalibrationProfilesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Opnieuw'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(List<AcousticCalibrationProfileRecord> profiles) {
    final latest = profiles.firstOrNull;
    final quickStart = latest != null && !_showSetup;
    final body = quickStart ? _quickStart(latest) : _wizardBody();
    return Scaffold(
      appBar: AppBar(title: const Text('Live-fire timer')),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: ListView(
              key: const ValueKey('live-fire-timer-content'),
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                140 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              children: [body],
            ),
          ),
          if (_flashActive)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .22),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppActionDock(
        actions: quickStart ? _quickActions(latest) : _wizardActions(latest),
      ),
    );
  }

  Widget _quickStart(AcousticCalibrationProfileRecord profile) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Klaar om te meten',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'De microfoon luistert alleen tijdens de actieve run. Schoten en splits '
        'verschijnen meteen op het scherm; er wordt geen audio bewaard.',
      ),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_delaySummary()),
              Text('Automatisch stoppen: $_inactivitySeconds s na stilte'),
              Text('Omgeving: ${profile.environment}'),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        key: const ValueKey('test-live-fire-signals'),
        onPressed: _busy
            ? null
            : () => _testSignals(requireConfirmation: false),
        icon: const Icon(Icons.volume_up_outlined),
        label: const Text('Test startsignaal'),
      ),
      const SizedBox(height: 12),
      const _LiveFireBoundaryNotice(),
    ],
  );

  Widget _wizardBody() => switch (_step) {
    0 => _introStep(),
    1 => _deviceStep(),
    _ => _settingsStep(),
  };

  Widget _introStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(
        Icons.timer_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 20),
      Text(
        'Eenvoudig live-fire meten',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      const Text(
        'Na een willekeurig startsignaal registreert de telefoon ieder herkend '
        'schot. Je krijgt de eerste-schottijd, alle splits en een controlelijst '
        'voordat je bewaart.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      const _FeatureRow(
        icon: Icons.mic_outlined,
        title: 'Akoestische registratie',
        body: 'De microfoon wordt alleen tijdens de zichtbare timer gebruikt.',
      ),
      const _FeatureRow(
        icon: Icons.lock_outline,
        title: 'Volledig lokaal',
        body: 'Ruwe audio wordt in het geheugen verwerkt en nooit opgeslagen.',
      ),
      const _FeatureRow(
        icon: Icons.fact_check_outlined,
        title: 'Altijd controleerbaar',
        body: 'Je kunt gemiste of fout gedetecteerde events corrigeren.',
      ),
    ],
  );

  Widget _deviceStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Toestelcontrole',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Activeer eerst de microfoon en controleer daarna het startsignaal. '
        'Dit hoeft normaal maar één keer.',
      ),
      const SizedBox(height: 20),
      _CheckCard(
        icon: Icons.mic_outlined,
        title: 'Microfoon',
        detail: _microphoneReady
            ? 'Toegang en audio-invoer zijn klaar.'
            : 'De toestemming wordt alleen voor live-firetiming gebruikt.',
        complete: _microphoneReady,
        actionLabel: _microphoneReady ? 'Opnieuw testen' : 'Activeren',
        onPressed: _busy ? null : _activateMicrophone,
      ),
      const SizedBox(height: 12),
      _CheckCard(
        icon: Icons.notifications_active_outlined,
        title: 'Startsignaal',
        detail: _signalsConfirmed
            ? 'Het gekozen signaal is bevestigd.'
            : 'Test geluid en trilling op dit toestel.',
        complete: _signalsConfirmed,
        actionLabel: 'Testen',
        onPressed: _busy ? null : () => _testSignals(requireConfirmation: true),
      ),
      const SizedBox(height: 16),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Geluid'),
        value: _sound,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                _sound = value;
                _signalsConfirmed = false;
              }),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Trilling'),
        value: _haptic,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                _haptic = value;
                _signalsConfirmed = false;
              }),
      ),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Schermflits'),
        value: _flash,
        onChanged: _busy
            ? null
            : (value) => setState(() {
                _flash = value;
                _signalsConfirmed = false;
              }),
      ),
    ],
  );

  Widget _settingsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Klaarzetten',
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text('De standaardinstellingen werken voor de meeste trainingen.'),
      const SizedBox(height: 20),
      Text('Startuitstel', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SegmentedButton<ShotTimerDelayMode>(
        segments: const [
          ButtonSegment(
            value: ShotTimerDelayMode.random,
            label: Text('Willekeurig'),
          ),
          ButtonSegment(value: ShotTimerDelayMode.fixed, label: Text('Vast')),
        ],
        selected: {_delayMode},
        onSelectionChanged: (value) =>
            setState(() => _delayMode = value.single),
      ),
      const SizedBox(height: 16),
      if (_delayMode == ShotTimerDelayMode.random) ...[
        Text(
          'Tussen $_randomMinimumSeconds en $_randomMaximumSeconds seconden',
        ),
        RangeSlider(
          values: RangeValues(
            _randomMinimumSeconds.toDouble(),
            _randomMaximumSeconds.toDouble(),
          ),
          min: 1,
          max: 8,
          divisions: 7,
          labels: RangeLabels(
            '$_randomMinimumSeconds s',
            '$_randomMaximumSeconds s',
          ),
          onChanged: (value) => setState(() {
            _randomMinimumSeconds = value.start.round();
            _randomMaximumSeconds = value.end.round();
          }),
        ),
      ] else ...[
        Text('Na $_fixedDelaySeconds seconden'),
        Slider(
          value: _fixedDelaySeconds.toDouble(),
          min: 1,
          max: 8,
          divisions: 7,
          label: '$_fixedDelaySeconds s',
          onChanged: (value) =>
              setState(() => _fixedDelaySeconds = value.round()),
        ),
      ],
      const SizedBox(height: 12),
      Text(
        'Stop na $_inactivitySeconds seconden stilte',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Slider(
        value: _inactivitySeconds.toDouble(),
        min: 1,
        max: 8,
        divisions: 7,
        label: '$_inactivitySeconds s',
        onChanged: (value) =>
            setState(() => _inactivitySeconds = value.round()),
      ),
      const SizedBox(height: 12),
      Text('Maximum schoten', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final count in <int?>[null, 5, 10, 15, 25])
            ChoiceChip(
              label: Text(count == null ? 'Geen limiet' : '$count'),
              selected: _maximumShots == count,
              onSelected: (_) => setState(() => _maximumShots = count),
            ),
        ],
      ),
      const SizedBox(height: 16),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'Binnen', label: Text('Binnen')),
          ButtonSegment(value: 'Buiten', label: Text('Buiten')),
        ],
        selected: {_environment},
        onSelectionChanged: (value) =>
            setState(() => _environment = value.single),
      ),
      const SizedBox(height: 16),
      AppExpandableSection(
        title: 'Geavanceerd',
        children: [
          Text('Detectiegevoeligheid: ${_sensitivityLabel()}'),
          Slider(
            value: _sensitivity,
            min: .45,
            max: .85,
            divisions: 8,
            label: _sensitivityLabel(),
            onChanged: (value) => setState(() => _sensitivity = value),
          ),
          const Text(
            'Verhoog alleen wanneer echte schoten niet verschijnen. Verlaag '
            'wanneer baanlawaai te vaak als schot wordt geregistreerd.',
          ),
        ],
      ),
      const SizedBox(height: 8),
      const _LiveFireBoundaryNotice(),
    ],
  );

  List<Widget> _quickActions(AcousticCalibrationProfileRecord profile) => [
    OutlinedButton.icon(
      onPressed: _busy
          ? null
          : () => setState(() {
              _loadProfile(profile);
              _showSetup = true;
              _step = 2;
            }),
      icon: const Icon(Icons.tune),
      label: const Text('Aanpassen'),
    ),
    FilledButton.icon(
      key: const ValueKey('start-live-fire-timer'),
      onPressed: _busy ? null : () => _start(profile),
      icon: const Icon(Icons.play_arrow),
      label: const Text('Start timer'),
    ),
  ];

  List<Widget> _wizardActions(AcousticCalibrationProfileRecord? profile) =>
      switch (_step) {
        0 => [
          FilledButton.icon(
            key: const ValueKey('start-live-fire-setup'),
            onPressed: _busy ? null : () => setState(() => _step = 1),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Instellen'),
          ),
        ],
        1 => [
          OutlinedButton(
            onPressed: _busy ? null : () => setState(() => _step = 0),
            child: const Text('Terug'),
          ),
          FilledButton(
            key: const ValueKey('continue-live-fire-setup'),
            onPressed: !_microphoneReady || !_signalsConfirmed || _busy
                ? null
                : () => setState(() => _step = 2),
            child: const Text('Verder'),
          ),
        ],
        _ => [
          OutlinedButton(
            onPressed: _busy ? null : () => setState(() => _step = 1),
            child: const Text('Terug'),
          ),
          FilledButton.icon(
            key: const ValueKey('start-guided-live-fire-timer'),
            onPressed: _busy ? null : () => _start(profile),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start timer'),
          ),
        ],
      };

  ShotTimerConfiguration _configuration(
    AcousticCalibrationProfileRecord? profile,
  ) => ShotTimerConfiguration(
    mode: ShotTimerMode.acousticLiveFire,
    delayMode: _delayMode,
    fixedDelay: Duration(seconds: _fixedDelaySeconds),
    randomDelayMinimum: Duration(seconds: _randomMinimumSeconds),
    randomDelayMaximum: Duration(seconds: _randomMaximumSeconds),
    maximumShots: _maximumShots,
    inactivityTimeout: Duration(seconds: _inactivitySeconds),
    outputSignals: {
      if (_sound) ShotTimerOutputSignal.sound,
      if (_haptic) ShotTimerOutputSignal.haptic,
      if (_flash) ShotTimerOutputSignal.flash,
    },
    calibration: AcousticCalibrationSnapshot(
      profileId: profile?.id,
      sampleRate: profile?.sampleRate ?? _sampleRate,
      sensitivity: profile?.sensitivity ?? _sensitivity,
      echoLockout: Duration(
        microseconds: profile?.echoLockoutMicroseconds ?? 120000,
      ),
      beepBlanking: Duration(
        microseconds: profile?.beepBlankingMicroseconds ?? 250000,
      ),
      detectorVersion: profile?.detectorVersion ?? _detectorVersion,
    ),
  );

  Future<void> _activateMicrophone() async {
    if (_busy) return;
    setState(() => _busy = true);
    final engine = MethodChannelShotTimerEngine();
    try {
      final capabilities = await engine.getCapabilities();
      _sampleRate =
          (capabilities['nativeSampleRate'] as num?)?.toInt() ?? 48000;
      _detectorVersion =
          capabilities['detectorVersion']?.toString() ?? 'impulse-v1';
      await engine.prepare(_configuration(null));
      if (mounted) {
        setState(() => _microphoneReady = true);
        AppMessenger.success(context, 'Microfoon is klaar');
      }
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, _friendlyError(error));
    } finally {
      await engine.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testSignals({required bool requireConfirmation}) async {
    if (_busy || (!_sound && !_haptic && !_flash)) {
      if (!_sound && !_haptic && !_flash) {
        AppMessenger.warning(context, 'Schakel minstens één signaal in.');
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await _platform.testSignals({
        if (_sound) ShotTimerOutputSignal.sound,
        if (_haptic) ShotTimerOutputSignal.haptic,
        if (_flash) ShotTimerOutputSignal.flash,
      });
      if (_flash) _pulseFlash();
      if (!requireConfirmation || !mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Signaal ontvangen?'),
          content: const Text(
            'Hoorde, voelde of zag je minstens één van de gekozen signalen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Opnieuw'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ja'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        setState(() => _signalsConfirmed = true);
      }
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _start(AcousticCalibrationProfileRecord? profile) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var selected = profile;
      if (selected == null) {
        final id = await ref
            .read(repositoryProvider)
            .saveCalibrationProfile(
              name: 'Standaard live fire',
              environment: _environment,
              audioRoute: 'Ingebouwde microfoon',
              sampleRate: _sampleRate,
              sensitivity: _sensitivity,
              echoLockoutMicroseconds: 120000,
              beepBlankingMicroseconds: 250000,
              detectorVersion: _detectorVersion,
            );
        selected = AcousticCalibrationProfileRecord(
          id: id,
          name: 'Standaard live fire',
          firearmId: null,
          cartridgeId: null,
          environment: _environment,
          audioRoute: 'Ingebouwde microfoon',
          sampleRate: _sampleRate,
          sensitivity: _sensitivity,
          echoLockoutMicroseconds: 120000,
          beepBlankingMicroseconds: 250000,
          detectorVersion: _detectorVersion,
          createdAtUtc: DateTime.now().toUtc(),
          updatedAtUtc: DateTime.now().toUtc(),
        );
      }
      if (!mounted) return;
      final draft = await Navigator.of(context).push<ShotTimerDraft>(
        MaterialPageRoute(
          builder: (_) =>
              ShotTimerRunScreen(configuration: _configuration(selected)),
        ),
      );
      if (draft != null && mounted) Navigator.pop(context, draft);
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, _friendlyError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _loadProfile(AcousticCalibrationProfileRecord profile) {
    _environment = profile.environment;
    _sampleRate = profile.sampleRate;
    _sensitivity = profile.sensitivity;
    _detectorVersion = profile.detectorVersion;
  }

  String _delaySummary() => _delayMode == ShotTimerDelayMode.random
      ? 'Willekeurig startsein: $_randomMinimumSeconds–$_randomMaximumSeconds s'
      : 'Vast startsein: $_fixedDelaySeconds s';

  String _sensitivityLabel() => switch (_sensitivity) {
    < .58 => 'Lager',
    > .72 => 'Hoger',
    _ => 'Normaal',
  };

  void _pulseFlash() {
    if (!mounted) return;
    setState(() => _flashActive = true);
    Timer(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _flashActive = false);
    });
  }

  String _friendlyError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('permission') || text.contains('microphone')) {
      return 'Microfoontoegang is nodig voor live-firetiming.';
    }
    if (text.contains('audio') || text.contains('signal')) {
      return 'De audiofunctie kon niet worden gestart. Controleer volume en microfoon.';
    }
    return 'De toestelcontrole is mislukt. Probeer opnieuw.';
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CheckCard extends StatelessWidget {
  const _CheckCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.complete,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool complete;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Icon(
                complete ? Icons.check_circle : Icons.radio_button_unchecked,
                color: complete ? Theme.of(context).colorScheme.primary : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    ),
  );
}

class _LiveFireBoundaryNotice extends StatelessWidget {
  const _LiveFireBoundaryNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Trainingsmeting, niet voor officiële wedstrijdtiming. Op een '
              'drukke baan kan de telefoon schoten van andere schutters niet '
              'betrouwbaar onderscheiden.',
            ),
          ),
        ],
      ),
    ),
  );
}

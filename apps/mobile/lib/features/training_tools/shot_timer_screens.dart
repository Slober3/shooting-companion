import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shooting_companion_shot_timer/shot_timer.dart';

import '../../app/providers.dart';
import '../../data/app_database.dart';
import '../../data/shooting_repository.dart';
import '../../widgets/app_action_dock.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_notice.dart';
import '../../widgets/app_select_field.dart';
import 'external_timer_input.dart';
import 'shot_timer_release_gate.dart';

class ShotTimerDraft {
  const ShotTimerDraft({
    required this.configuration,
    required this.result,
    required this.startedAtUtc,
  });

  final ShotTimerConfiguration configuration;
  final ShotTimerResult result;
  final DateTime startedAtUtc;
}

class ShotTimerSetupScreen extends ConsumerStatefulWidget {
  const ShotTimerSetupScreen({this.initialMode, super.key});

  final ShotTimerMode? initialMode;

  @override
  ConsumerState<ShotTimerSetupScreen> createState() =>
      _ShotTimerSetupScreenState();
}

class _ShotTimerSetupScreenState extends ConsumerState<ShotTimerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late ShotTimerMode _mode;
  ShotTimerDelayMode _delayMode = ShotTimerDelayMode.random;
  final _fixedDelay = TextEditingController(text: '2');
  final _randomMinimum = TextEditingController(text: '2');
  final _randomMaximum = TextEditingController(text: '4');
  final _parTime = TextEditingController(text: '5');
  final _parTime2 = TextEditingController();
  final _parTime3 = TextEditingController();
  final _repetitions = TextEditingController(text: '1');
  final _rest = TextEditingController(text: '3');
  final _cadenceStart = TextEditingController(text: '1');
  final _cadenceEnd = TextEditingController(text: '1');
  final _cadenceCount = TextEditingController(text: '5');
  final _maximumShots = TextEditingController();
  final _inactivity = TextEditingController(text: '3');
  final _sensitivity = TextEditingController(text: '0,65');
  final _echoLockout = TextEditingController(text: '120');
  bool _sound = true;
  bool _haptic = true;
  bool _flash = false;
  String _selectedPresetId = 'custom';
  String _selectedCalibrationId = 'manual';
  int _sampleRate = 48000;

  @override
  void initState() {
    super.initState();
    final requestedMode = widget.initialMode;
    _mode =
        !acousticShotTimerEnabled &&
            requestedMode == ShotTimerMode.acousticLiveFire
        ? ShotTimerMode.par
        : requestedMode ??
              (acousticShotTimerEnabled
                  ? ShotTimerMode.acousticLiveFire
                  : ShotTimerMode.par);
  }

  @override
  void dispose() {
    for (final controller in [
      _fixedDelay,
      _randomMinimum,
      _randomMaximum,
      _parTime,
      _parTime2,
      _parTime3,
      _repetitions,
      _rest,
      _cadenceStart,
      _cadenceEnd,
      _cadenceCount,
      _maximumShots,
      _inactivity,
      _sensitivity,
      _echoLockout,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storedPresets =
        ref.watch(timerPresetsProvider).valueOrNull ??
        const <TimerPresetRecord>[];
    final presets = acousticShotTimerEnabled
        ? storedPresets
        : storedPresets
              .where((preset) => preset.mode != 'acousticLiveFire')
              .toList(growable: false);
    final calibrationProfiles =
        ref.watch(acousticCalibrationProfilesProvider).valueOrNull ?? const [];
    return AppFormScaffold(
      title: 'Timer instellen',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (presets.isNotEmpty) ...[
              AppSelectField<String>(
                key: ValueKey('timer-preset-$_selectedPresetId'),
                label: 'Preset',
                initialValue: _selectedPresetId,
                options: [
                  const AppSelectOption(
                    value: 'custom',
                    label: 'Aangepaste instellingen',
                  ),
                  for (final preset in presets)
                    AppSelectOption(
                      value: preset.id,
                      label: preset.name,
                      subtitle: preset.builtIn ? 'Ingebouwd' : null,
                    ),
                ],
                onChanged: (value) => _loadPreset(value, presets),
              ),
              const SizedBox(height: 16),
            ],
            AppSelectField<ShotTimerMode>(
              label: 'Modus',
              initialValue: _mode,
              options: const [
                if (acousticShotTimerEnabled)
                  AppSelectOption(
                    value: ShotTimerMode.acousticLiveFire,
                    label: 'Akoestische live fire',
                    subtitle: 'Registreert schoten en splits via de microfoon',
                  ),
                AppSelectOption(
                  value: ShotTimerMode.par,
                  label: 'Par timer',
                  subtitle: 'Start- en eindsignalen zonder microfoon',
                ),
                AppSelectOption(
                  value: ShotTimerMode.cadence,
                  label: 'Cadans',
                  subtitle: 'Vaste of progressieve ritmesignalen',
                ),
                AppSelectOption(
                  value: ShotTimerMode.externalManual,
                  label: 'Externe timer invoeren',
                  subtitle: 'Neem tijden over van een afzonderlijke timer',
                ),
              ],
              onChanged: (value) => setState(() => _mode = value),
            ),
            const SizedBox(height: 16),
            if (_mode != ShotTimerMode.externalManual) ...[
              AppSelectField<ShotTimerDelayMode>(
                label: 'Startuitstel',
                initialValue: _delayMode,
                options: const [
                  AppSelectOption(
                    value: ShotTimerDelayMode.immediate,
                    label: 'Direct',
                  ),
                  AppSelectOption(
                    value: ShotTimerDelayMode.fixed,
                    label: 'Vast',
                  ),
                  AppSelectOption(
                    value: ShotTimerDelayMode.random,
                    label: 'Willekeurig',
                  ),
                ],
                onChanged: (value) => setState(() => _delayMode = value),
              ),
              const SizedBox(height: 16),
              if (_delayMode == ShotTimerDelayMode.fixed)
                _secondsField(_fixedDelay, 'Vast uitstel', minimum: 0)
              else if (_delayMode == ShotTimerDelayMode.random)
                _responsivePair(
                  _secondsField(_randomMinimum, 'Minimum uitstel', minimum: 0),
                  _secondsField(_randomMaximum, 'Maximum uitstel', minimum: 0),
                ),
            ],
            if (_mode == ShotTimerMode.acousticLiveFire) ...[
              const SizedBox(height: 24),
              _sectionTitle('Live-firedetectie'),
              if (calibrationProfiles.isNotEmpty) ...[
                AppSelectField<String>(
                  key: ValueKey('acoustic-calibration-$_selectedCalibrationId'),
                  label: 'Kalibratieprofiel',
                  initialValue: _selectedCalibrationId,
                  options: [
                    const AppSelectOption(
                      value: 'manual',
                      label: 'Handmatige instellingen',
                    ),
                    for (final profile in calibrationProfiles)
                      AppSelectOption(
                        value: profile.id,
                        label: profile.name,
                        subtitle: profile.environment,
                      ),
                  ],
                  onChanged: (value) =>
                      _loadCalibration(value, calibrationProfiles),
                ),
                const SizedBox(height: 16),
              ],
              _responsivePair(
                _integerField(_maximumShots, 'Maximum schoten', optional: true),
                _secondsField(_inactivity, 'Stop na stilte', minimum: .5),
              ),
              const SizedBox(height: 16),
              _responsivePair(
                _decimalField(
                  _sensitivity,
                  'Gevoeligheid',
                  minimum: 0,
                  maximum: 1,
                  suffix: '0–1',
                ),
                _integerField(
                  _echoLockout,
                  'Echofilter',
                  minimum: 20,
                  suffix: 'ms',
                ),
              ),
              const SizedBox(height: 12),
              const _TimerBoundaryNotice(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _saveCalibrationProfile,
                  icon: const Icon(Icons.tune),
                  label: const Text('Kalibratieprofiel bewaren'),
                ),
              ),
            ],
            if (_mode == ShotTimerMode.par) ...[
              const SizedBox(height: 24),
              _sectionTitle('Parreeks'),
              _responsivePair(
                _secondsField(_parTime, 'Par time', minimum: .1),
                _integerField(_repetitions, 'Herhalingen', minimum: 1),
              ),
              const SizedBox(height: 16),
              _responsivePair(
                _optionalSecondsField(_parTime2, 'Tweede parsignaal'),
                _optionalSecondsField(_parTime3, 'Derde parsignaal'),
              ),
              const SizedBox(height: 16),
              _secondsField(_rest, 'Rust tussen herhalingen', minimum: 0),
            ],
            if (_mode == ShotTimerMode.cadence) ...[
              const SizedBox(height: 24),
              _sectionTitle('Cadansreeks'),
              _responsivePair(
                _secondsField(_cadenceStart, 'Eerste interval', minimum: .05),
                _secondsField(_cadenceEnd, 'Laatste interval', minimum: .05),
              ),
              const SizedBox(height: 16),
              _responsivePair(
                _integerField(_cadenceCount, 'Signalen', minimum: 1),
                _integerField(_repetitions, 'Herhalingen', minimum: 1),
              ),
              const SizedBox(height: 16),
              _secondsField(_rest, 'Rust tussen herhalingen', minimum: 0),
            ],
            if (_mode != ShotTimerMode.externalManual) ...[
              const SizedBox(height: 24),
              _sectionTitle('Signalen'),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Geluid'),
                value: _sound,
                onChanged: (value) => setState(() => _sound = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Trilling'),
                value: _haptic,
                onChanged: (value) => setState(() => _haptic = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Schermflits'),
                value: _flash,
                onChanged: (value) => setState(() => _flash = value),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_mode != ShotTimerMode.externalManual)
          OutlinedButton.icon(
            onPressed: _savePreset,
            icon: const Icon(Icons.bookmark_add_outlined),
            label: const Text('Preset bewaren'),
          ),
        FilledButton.icon(
          key: const ValueKey('start-shot-timer'),
          onPressed: _start,
          icon: Icon(
            _mode == ShotTimerMode.externalManual
                ? Icons.edit_outlined
                : Icons.timer_outlined,
          ),
          label: Text(
            _mode == ShotTimerMode.externalManual
                ? 'Tijden invoeren'
                : 'Verder',
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _responsivePair(Widget first, Widget second) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 480 ||
          MediaQuery.textScalerOf(context).scale(1) >= 1.3) {
        return Column(children: [first, const SizedBox(height: 16), second]);
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: first),
          const SizedBox(width: 16),
          Expanded(child: second),
        ],
      );
    },
  );

  Widget _secondsField(
    TextEditingController controller,
    String label, {
    required double minimum,
  }) => _decimalField(controller, label, minimum: minimum, suffix: 's');

  Widget _optionalSecondsField(
    TextEditingController controller,
    String label,
  ) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      suffixText: 's',
      helperText: 'Optioneel',
    ),
    validator: (value) {
      if (value == null || value.trim().isEmpty) return null;
      final parsed = _number(value);
      if (parsed == null) return 'Vul een geldig getal in';
      if (parsed < .1) return 'Minimaal 0,1';
      return null;
    },
  );

  Widget _decimalField(
    TextEditingController controller,
    String label, {
    required double minimum,
    double? maximum,
    String? suffix,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label, suffixText: suffix),
    validator: (value) {
      final parsed = _number(value);
      if (parsed == null) return 'Vul een geldig getal in';
      if (parsed < minimum || (maximum != null && parsed > maximum)) {
        return maximum == null
            ? 'Minimaal ${_formatNumber(minimum)}'
            : '${_formatNumber(minimum)} tot ${_formatNumber(maximum)}';
      }
      return null;
    },
  );

  Widget _integerField(
    TextEditingController controller,
    String label, {
    int minimum = 1,
    bool optional = false,
    String? suffix,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: label,
      suffixText: suffix,
      helperText: optional ? 'Optioneel' : null,
    ),
    validator: (value) {
      if (optional && (value == null || value.trim().isEmpty)) return null;
      final parsed = int.tryParse(value?.trim() ?? '');
      if (parsed == null || parsed < minimum) return 'Minimaal $minimum';
      return null;
    },
  );

  Future<void> _start() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_mode == ShotTimerMode.externalManual) {
      final result = await Navigator.of(context).push<ShotTimerDraft>(
        MaterialPageRoute(builder: (_) => const ExternalTimerEntryScreen()),
      );
      if (result != null && mounted) Navigator.pop(context, result);
      return;
    }
    final configuration = _configuration();
    try {
      configuration.validate();
    } on ArgumentError catch (error) {
      AppMessenger.error(context, error.message?.toString() ?? '$error');
      return;
    }
    final draft = await Navigator.of(context).push<ShotTimerDraft>(
      MaterialPageRoute(
        builder: (_) => ShotTimerRunScreen(configuration: configuration),
      ),
    );
    if (draft != null && mounted) Navigator.pop(context, draft);
  }

  ShotTimerConfiguration _configuration() {
    final outputSignals = <ShotTimerOutputSignal>{
      if (_sound) ShotTimerOutputSignal.sound,
      if (_haptic) ShotTimerOutputSignal.haptic,
      if (_flash) ShotTimerOutputSignal.flash,
    };
    return ShotTimerConfiguration(
      mode: _mode,
      delayMode: _delayMode,
      fixedDelay: _duration(_fixedDelay.text),
      randomDelayMinimum: _duration(_randomMinimum.text),
      randomDelayMaximum: _duration(_randomMaximum.text),
      parSignals: _mode == ShotTimerMode.par
          ? [
              _duration(_parTime.text),
              if (_parTime2.text.trim().isNotEmpty) _duration(_parTime2.text),
              if (_parTime3.text.trim().isNotEmpty) _duration(_parTime3.text),
            ]
          : const [],
      repetitions: int.parse(_repetitions.text.trim()),
      restDuration: _duration(_rest.text),
      cadenceStartInterval: _duration(_cadenceStart.text),
      cadenceEndInterval: _duration(_cadenceEnd.text),
      cadenceSignalCount: _mode == ShotTimerMode.cadence
          ? int.parse(_cadenceCount.text.trim())
          : 0,
      maximumShots: _maximumShots.text.trim().isEmpty
          ? null
          : int.parse(_maximumShots.text.trim()),
      inactivityTimeout: _mode == ShotTimerMode.acousticLiveFire
          ? _duration(_inactivity.text)
          : null,
      outputSignals: outputSignals,
      calibration: _mode == ShotTimerMode.acousticLiveFire
          ? AcousticCalibrationSnapshot(
              profileId: _selectedCalibrationId == 'manual'
                  ? null
                  : _selectedCalibrationId,
              sampleRate: _sampleRate,
              sensitivity: _number(_sensitivity.text)!,
              echoLockout: Duration(
                milliseconds: int.parse(_echoLockout.text.trim()),
              ),
              beepBlanking: const Duration(milliseconds: 250),
            )
          : null,
    );
  }

  void _loadPreset(String presetId, List<TimerPresetRecord> presets) {
    if (presetId == 'custom') {
      setState(() => _selectedPresetId = presetId);
      return;
    }
    final preset = presets.where((item) => item.id == presetId).firstOrNull;
    if (preset == null) return;
    try {
      final map = (jsonDecode(preset.configurationJson) as Map)
          .cast<Object?, Object?>();
      final configuration = ShotTimerConfiguration.fromMap(map);
      if (!acousticShotTimerEnabled &&
          configuration.mode == ShotTimerMode.acousticLiveFire) {
        return;
      }
      setState(() {
        _selectedPresetId = presetId;
        _mode = configuration.mode;
        _delayMode = configuration.delayMode;
        _fixedDelay.text = _seconds(configuration.fixedDelay);
        _randomMinimum.text = _seconds(configuration.randomDelayMinimum);
        _randomMaximum.text = _seconds(configuration.randomDelayMaximum);
        _parTime.text = configuration.parSignals.isEmpty
            ? '5'
            : _seconds(configuration.parSignals.first);
        _parTime2.text = configuration.parSignals.length > 1
            ? _seconds(configuration.parSignals[1])
            : '';
        _parTime3.text = configuration.parSignals.length > 2
            ? _seconds(configuration.parSignals[2])
            : '';
        _repetitions.text = '${configuration.repetitions}';
        _rest.text = _seconds(configuration.restDuration);
        _cadenceStart.text = _seconds(configuration.cadenceStartInterval);
        _cadenceEnd.text = _seconds(configuration.cadenceEndInterval);
        _cadenceCount.text = '${configuration.cadenceSignalCount}';
        _maximumShots.text = configuration.maximumShots?.toString() ?? '';
        _inactivity.text = configuration.inactivityTimeout == null
            ? '3'
            : _seconds(configuration.inactivityTimeout!);
        _sensitivity.text = (configuration.calibration?.sensitivity ?? .65)
            .toStringAsFixed(2)
            .replaceAll('.', ',');
        _selectedCalibrationId =
            configuration.calibration?.profileId ?? 'manual';
        _sampleRate = configuration.calibration?.sampleRate ?? 48000;
        _echoLockout.text =
            '${configuration.calibration?.echoLockout.inMilliseconds ?? 120}';
        _sound = configuration.outputSignals.contains(
          ShotTimerOutputSignal.sound,
        );
        _haptic = configuration.outputSignals.contains(
          ShotTimerOutputSignal.haptic,
        );
        _flash = configuration.outputSignals.contains(
          ShotTimerOutputSignal.flash,
        );
      });
    } on Object {
      AppMessenger.error(context, 'Deze timerpreset kon niet worden geladen.');
    }
  }

  Future<void> _savePreset() async {
    if (_formKey.currentState?.validate() != true) return;
    final configuration = _configuration();
    try {
      configuration.validate();
    } on ArgumentError catch (error) {
      AppMessenger.error(context, error.message?.toString() ?? '$error');
      return;
    }
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Preset bewaren'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Naam'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) Navigator.pop(context, value);
            },
            child: const Text('Bewaren'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || !mounted) return;
    try {
      final id = await ref
          .read(repositoryProvider)
          .saveTimerPreset(
            name: name,
            mode: _storedKind(configuration.mode),
            configuration: configuration.toMap(),
          );
      if (!mounted) return;
      setState(() => _selectedPresetId = id);
      AppMessenger.success(context, 'Timerpreset bewaard');
    } on Object {
      if (mounted) {
        AppMessenger.error(context, 'De timerpreset kon niet worden bewaard.');
      }
    }
  }

  void _loadCalibration(
    String profileId,
    List<AcousticCalibrationProfileRecord> profiles,
  ) {
    if (profileId == 'manual') {
      setState(() => _selectedCalibrationId = profileId);
      return;
    }
    final profile = profiles.where((item) => item.id == profileId).firstOrNull;
    if (profile == null) return;
    setState(() {
      _selectedCalibrationId = profile.id;
      _sampleRate = profile.sampleRate;
      _sensitivity.text = profile.sensitivity
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _echoLockout.text = '${profile.echoLockoutMicroseconds ~/ 1000}';
    });
  }

  Future<void> _saveCalibrationProfile() async {
    final sensitivity = _number(_sensitivity.text);
    final echoMilliseconds = int.tryParse(_echoLockout.text.trim());
    if (sensitivity == null ||
        sensitivity < 0 ||
        sensitivity > 1 ||
        echoMilliseconds == null ||
        echoMilliseconds < 20) {
      _formKey.currentState?.validate();
      return;
    }
    final nameController = TextEditingController();
    var environment = 'Binnen';
    final input = await showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kalibratieprofiel bewaren'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Naam'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Binnen', label: Text('Binnen')),
                  ButtonSegment(value: 'Buiten', label: Text('Buiten')),
                ],
                selected: {environment},
                onSelectionChanged: (value) =>
                    setDialogState(() => environment = value.single),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(context, (name, environment));
                }
              },
              child: const Text('Bewaren'),
            ),
          ],
        ),
      ),
    );
    nameController.dispose();
    if (input == null || !mounted) return;
    try {
      final id = await ref
          .read(repositoryProvider)
          .saveCalibrationProfile(
            name: input.$1,
            environment: input.$2,
            audioRoute: 'Ingebouwde microfoon',
            sampleRate: _sampleRate,
            sensitivity: sensitivity,
            echoLockoutMicroseconds: echoMilliseconds * 1000,
            beepBlankingMicroseconds: 250000,
            detectorVersion: 'impulse-v1',
          );
      if (!mounted) return;
      setState(() => _selectedCalibrationId = id);
      AppMessenger.success(context, 'Kalibratieprofiel bewaard');
    } on Object {
      if (mounted) {
        AppMessenger.error(
          context,
          'Het kalibratieprofiel kon niet worden bewaard.',
        );
      }
    }
  }
}

class ShotTimerRunScreen extends StatefulWidget {
  const ShotTimerRunScreen({required this.configuration, super.key});

  final ShotTimerConfiguration configuration;

  @override
  State<ShotTimerRunScreen> createState() => _ShotTimerRunScreenState();
}

class _ShotTimerRunScreenState extends State<ShotTimerRunScreen>
    with WidgetsBindingObserver {
  late final ShotTimerEngine _engine;
  StreamSubscription<ShotTimerSnapshot>? _snapshotSubscription;
  StreamSubscription<double>? _levelSubscription;
  ShotTimerSnapshot _snapshot = ShotTimerSnapshot.idle();
  ShotTimerResult? _result;
  DateTime? _startedAtUtc;
  Timer? _displayTimer;
  final _displayStopwatch = Stopwatch();
  double _audioLevel = 0;
  bool _busy = true;
  bool _flash = false;
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = widget.configuration.mode == ShotTimerMode.acousticLiveFire
        ? MethodChannelShotTimerEngine()
        : DartSignalShotTimerEngine(
            signalOutput: _FlutterSignalOutput(onFlash: _pulseFlash),
          );
    _snapshot = _engine.snapshot;
    _snapshotSubscription = _engine.snapshots.listen(_handleSnapshot);
    _levelSubscription = _engine.normalizedAudioLevels.listen((value) {
      if (mounted) setState(() => _audioLevel = value);
    });
    unawaited(_prepare());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _isActive(_snapshot.state)) {
      unawaited(_interrupt('App verlaten tijdens de timer'));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    _snapshotSubscription?.cancel();
    _levelSubscription?.cancel();
    unawaited(_engine.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_isActive(_snapshot.state),
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_confirmExit());
    },
    child: Scaffold(
      appBar: AppBar(title: Text(_modeLabel(widget.configuration.mode))),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
              children: [
                _stateHeader(),
                const SizedBox(height: 20),
                Center(
                  child: Semantics(
                    liveRegion: true,
                    label: 'Verstreken tijd ${_formatDuration(_elapsed)}',
                    child: Text(
                      _formatDuration(_elapsed),
                      key: const ValueKey('shot-timer-elapsed'),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (widget.configuration.mode ==
                    ShotTimerMode.acousticLiveFire) ...[
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: _audioLevel,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Microfoonniveau',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 24),
                _summary(),
                if (_result != null) ...[
                  const SizedBox(height: 20),
                  _eventReview(),
                ],
              ],
            ),
          ),
          if (_flash)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: .18),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppActionDock(actions: _actions()),
    ),
  );

  Widget _stateHeader() {
    final (icon, text) = switch (_snapshot.state) {
      ShotTimerState.idle ||
      ShotTimerState.preparing => (Icons.sync, 'Timer voorbereiden…'),
      ShotTimerState.calibrating => (
        Icons.graphic_eq,
        'Omgevingsgeluid meten…',
      ),
      ShotTimerState.ready => (Icons.check_circle_outline, 'Gereed'),
      ShotTimerState.startDelay => (
        Icons.hourglass_top,
        'Wacht op het startsignaal',
      ),
      ShotTimerState.running => (Icons.timer_outlined, 'Bezig'),
      ShotTimerState.reviewing || ShotTimerState.completed => (
        Icons.fact_check_outlined,
        'Resultaat controleren',
      ),
      ShotTimerState.interrupted => (
        Icons.pause_circle_outline,
        'Run onderbroken',
      ),
      ShotTimerState.error => (Icons.error_outline, 'Timerfout'),
      ShotTimerState.disposed => (Icons.stop_circle_outlined, 'Gestopt'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  const Text(
                    'Trainingsmeting — geen gecertificeerde wedstrijdtimer.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summary() {
    final result = _result;
    final events = result?.events ?? _snapshot.events;
    final counted = events
        .where(
          (event) => event.disposition == ShotTimerEventDisposition.counted,
        )
        .length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _summaryValue('$counted', 'Schoten'),
            _summaryValue(
              _formatDuration(result?.firstShotTime),
              'Eerste schot',
            ),
            _summaryValue(
              _formatDuration(result?.averageSplit),
              'Gemiddelde split',
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryValue(String value, String label) => SizedBox(
    width: 125,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label),
      ],
    ),
  );

  Widget _eventReview() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Schotevents',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton.icon(
            onPressed: _addManualEvent,
            icon: const Icon(Icons.add),
            label: const Text('Toevoegen'),
          ),
        ],
      ),
      if (_result!.events.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('Deze timermodus heeft geen gedetecteerde schoten.'),
        )
      else
        for (final event in _result!.events)
          Card(
            child: SwitchListTile.adaptive(
              value: event.disposition == ShotTimerEventDisposition.counted,
              onChanged: (_) => _toggleEvent(event),
              title: Text(
                event.sequenceNumber > 0
                    ? 'Schot ${event.sequenceNumber}'
                    : 'Uitgesloten detectie',
              ),
              subtitle: Text(
                '${_formatDuration(event.elapsed)} · split ${_formatDuration(event.split)}'
                '${event.detectionQuality == null ? '' : ' · ${_qualityLabel(event.detectionQuality!)}'}',
              ),
            ),
          ),
    ],
  );

  List<Widget> _actions() {
    if (_busy) {
      return const [
        FilledButton(onPressed: null, child: Text('Voorbereiden…')),
      ];
    }
    return switch (_snapshot.state) {
      ShotTimerState.ready => [
        FilledButton.icon(
          key: const ValueKey('shot-timer-ready-start'),
          onPressed: _start,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
      ],
      ShotTimerState.startDelay => [
        OutlinedButton.icon(
          key: const ValueKey('shot-timer-cancel-delay'),
          onPressed: () => unawaited(_interrupt('Startuitstel geannuleerd')),
          icon: const Icon(Icons.close),
          label: const Text('Annuleren'),
        ),
      ],
      ShotTimerState.running => [
        FilledButton.icon(
          key: const ValueKey('shot-timer-stop'),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: _finishRun,
          icon: const Icon(Icons.stop),
          label: const Text('Stop'),
        ),
      ],
      ShotTimerState.reviewing || ShotTimerState.completed => [
        FilledButton.icon(
          key: const ValueKey('save-shot-timer-draft'),
          onPressed: _result == null ? null : _returnResult,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Bewaren'),
        ),
      ],
      ShotTimerState.interrupted || ShotTimerState.error => [
        FilledButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Sluiten'),
        ),
      ],
      _ => const [FilledButton(onPressed: null, child: Text('Even geduld…'))],
    };
  }

  Duration? get _elapsed {
    if (_result != null) return _result!.totalTime;
    if (!_displayStopwatch.isRunning &&
        _displayStopwatch.elapsed == Duration.zero) {
      return null;
    }
    return _displayStopwatch.elapsed;
  }

  Future<void> _prepare() async {
    try {
      await _engine.prepare(widget.configuration);
      if (mounted) setState(() => _busy = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppMessenger.error(context, _friendlyTimerError(error));
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    // The activity starts when the user starts the run, not while permissions,
    // preparation or configuration are still on screen.
    _startedAtUtc ??= DateTime.now().toUtc();
    setState(() => _busy = true);
    try {
      await _engine.start();
      if (mounted) setState(() => _busy = false);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      AppMessenger.error(context, _friendlyTimerError(error));
    }
  }

  void _handleSnapshot(ShotTimerSnapshot snapshot) {
    if (!mounted) return;
    setState(() => _snapshot = snapshot);
    if (snapshot.state == ShotTimerState.running &&
        !_displayStopwatch.isRunning) {
      _displayStopwatch
        ..reset()
        ..start();
      _displayTimer ??= Timer.periodic(const Duration(milliseconds: 33), (_) {
        if (mounted) setState(() {});
      });
    }
    if (snapshot.state == ShotTimerState.reviewing && !_completing) {
      unawaited(_finishRun());
    }
    if (snapshot.state == ShotTimerState.error &&
        snapshot.errorMessage != null) {
      AppMessenger.error(context, _friendlyTimerError(snapshot.errorMessage!));
    }
  }

  Future<void> _finishRun() async {
    if (_completing) return;
    _completing = true;
    try {
      _displayStopwatch.stop();
      _displayTimer?.cancel();
      _displayTimer = null;
      final result = await _engine.stop();
      if (mounted) setState(() => _result = result);
    } on Object catch (error) {
      if (mounted) AppMessenger.error(context, _friendlyTimerError(error));
    } finally {
      _completing = false;
    }
  }

  void _toggleEvent(ShotTimerEvent event) {
    final events = _result!.events.map((candidate) {
      if (candidate.id != event.id) return candidate;
      final excluded =
          candidate.disposition == ShotTimerEventDisposition.counted;
      return candidate.copyWith(
        disposition: excluded
            ? ShotTimerEventDisposition.excluded
            : ShotTimerEventDisposition.counted,
        exclusionReason: excluded ? 'Gebruiker uitgesloten' : null,
      );
    });
    _replaceReviewedEvents(events);
  }

  Future<void> _addManualEvent() async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schot toevoegen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Tijd na startsignaal',
            suffixText: 's',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuleren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _number(controller.text)),
            child: const Text('Toevoegen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value < 0 || !mounted) return;
    _replaceReviewedEvents([
      ..._result!.events,
      ShotTimerEvent(
        id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        sequenceNumber: 0,
        elapsed: Duration(microseconds: (value * 1000000).round()),
        split: Duration.zero,
        source: ShotTimerEventSource.manual,
      ),
    ]);
  }

  void _replaceReviewedEvents(Iterable<ShotTimerEvent> events) {
    final normalized = ShotTimerStatistics.normalizeEvents(events);
    setState(() {
      _result = ShotTimerStatistics.summarize(
        actualStartDelay: _result!.actualStartDelay,
        events: normalized,
        qualityWarnings: _result!.qualityWarnings,
        userEdited: true,
      );
    });
  }

  void _returnResult() {
    Navigator.pop(
      context,
      ShotTimerDraft(
        configuration: widget.configuration,
        result: _result!,
        startedAtUtc: _startedAtUtc ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<void> _confirmExit() async {
    final close = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timer stoppen?'),
        content: const Text('De actieve run wordt als onderbroken beschouwd.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Verdergaan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Stoppen'),
          ),
        ],
      ),
    );
    if (close == true && mounted) {
      await _interrupt('Gebruiker heeft de run verlaten');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _interrupt(String reason) async {
    _displayStopwatch.stop();
    _displayTimer?.cancel();
    _displayTimer = null;
    await _engine.abort(reason);
  }

  void _pulseFlash() {
    if (!mounted) return;
    setState(() => _flash = true);
    Timer(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flash = false);
    });
  }
}

class ExternalTimerEntryScreen extends StatefulWidget {
  const ExternalTimerEntryScreen({super.key});

  @override
  State<ExternalTimerEntryScreen> createState() =>
      _ExternalTimerEntryScreenState();
}

class _ExternalTimerEntryScreenState extends State<ExternalTimerEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstShot = TextEditingController();
  final _totalTime = TextEditingController();
  final _cumulativeTimes = TextEditingController();

  @override
  void dispose() {
    _firstShot.dispose();
    _totalTime.dispose();
    _cumulativeTimes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppFormScaffold(
    title: 'Externe timer',
    body: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Neem de samenvatting over van je afzonderlijke timer. De eerste '
            'schottijd en totale tijd zijn voldoende; zonder details verzint '
            'de app geen schotaantal of splits.',
          ),
          const SizedBox(height: 24),
          Text('Samenvatting', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('external-timer-first-shot'),
            controller: _firstShot,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Eerste schot',
              suffixText: 's',
              hintText: '1,14',
              helperText: 'Tijd vanaf het startsignaal tot het eerste schot.',
            ),
            validator: (_) =>
                _validation().errorFor(ExternalTimerInputField.firstShot),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const ValueKey('external-timer-total-time'),
            controller: _totalTime,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Totale tijd',
              suffixText: 's',
              hintText: '4,72',
              helperText: 'De eindtijd die je afzonderlijke timer toont.',
            ),
            validator: (_) =>
                _validation().errorFor(ExternalTimerInputField.totalTime),
          ),
          const SizedBox(height: 24),
          Text(
            'Volledige schottijden (optioneel)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          const Text(
            'Vul dit alleen in wanneer je alle cumulatieve schottijden hebt. '
            'Neem het eerste én laatste schot mee, één tijd per regel. Zo kan '
            'de app het schotaantal en de tussenliggende splits berekenen.',
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: const ValueKey('external-timer-cumulative-times'),
            controller: _cumulativeTimes,
            minLines: 6,
            maxLines: 12,
            textAlignVertical: TextAlignVertical.top,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: const InputDecoration(
              labelText: 'Cumulatieve schottijden',
              alignLabelWithHint: true,
              hintText: '1,14\n1,66\n2,12\n4,72',
              helperText:
                  'Leeg laten wanneer de afzonderlijke tijden ontbreken.',
            ),
            validator: (_) => _validation().errorFor(
              ExternalTimerInputField.cumulativeShotTimes,
            ),
          ),
        ],
      ),
    ),
    actions: [
      FilledButton.icon(
        key: const ValueKey('external-timer-save'),
        onPressed: _save,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Overnemen'),
      ),
    ],
  );

  ExternalTimerInputValidation _validation() =>
      ExternalTimerInputParser.validate(
        firstShotText: _firstShot.text,
        totalTimeText: _totalTime.text,
        cumulativeShotTimesText: _cumulativeTimes.text,
      );

  void _save() {
    if (_formKey.currentState?.validate() != true) return;
    final measurement = _validation().measurement!;
    final configuration = ShotTimerConfiguration(
      mode: ShotTimerMode.externalManual,
    );
    Navigator.pop(
      context,
      ShotTimerDraft(
        configuration: configuration,
        result: measurement.toResult(),
        startedAtUtc: DateTime.now().toUtc(),
      ),
    );
  }
}

class _TimerBoundaryNotice extends StatelessWidget {
  const _TimerBoundaryNotice();

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'De microfoon wordt alleen tijdens het zichtbare timerscherm '
              'gebruikt. Er wordt geen audio opgeslagen. Op een drukke baan '
              'kan de telefoon schoten van anderen niet betrouwbaar scheiden. '
              'Deze build bevat de volwaardige detector, maar heeft nog geen '
              'afgeronde fysieke vergelijking met een referentietimer.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _FlutterSignalOutput implements ShotTimerSignalOutput {
  const _FlutterSignalOutput({required this.onFlash});

  final VoidCallback onFlash;

  @override
  Future<void> emit(
    ShotTimerSignalKind kind,
    Set<ShotTimerOutputSignal> outputs,
  ) async {
    if (outputs.contains(ShotTimerOutputSignal.sound)) {
      await SystemSound.play(SystemSoundType.alert);
    }
    if (outputs.contains(ShotTimerOutputSignal.haptic)) {
      await HapticFeedback.mediumImpact();
    }
    if (outputs.contains(ShotTimerOutputSignal.flash)) onFlash();
  }
}

bool _isActive(ShotTimerState state) =>
    state == ShotTimerState.startDelay || state == ShotTimerState.running;

double? _number(String? value) =>
    double.tryParse((value ?? '').trim().replaceAll(',', '.'));

Duration _duration(String value) =>
    Duration(microseconds: (_number(value)! * 1000000).round());

String _seconds(Duration value) => (value.inMicroseconds / 1000000)
    .toStringAsFixed(value.inMicroseconds % 1000000 == 0 ? 0 : 2)
    .replaceAll('.', ',');

StoredTrainingActivityKind _storedKind(ShotTimerMode mode) => switch (mode) {
  ShotTimerMode.acousticLiveFire => StoredTrainingActivityKind.acousticLiveFire,
  ShotTimerMode.par => StoredTrainingActivityKind.par,
  ShotTimerMode.cadence => StoredTrainingActivityKind.cadence,
  ShotTimerMode.externalManual => StoredTrainingActivityKind.externalManual,
};

String _formatNumber(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(2).replaceAll('.', ',');

String _formatDuration(Duration? value) {
  if (value == null) return '—';
  return (value.inMicroseconds / 1000000)
      .toStringAsFixed(2)
      .replaceAll('.', ',');
}

String _modeLabel(ShotTimerMode mode) => switch (mode) {
  ShotTimerMode.acousticLiveFire => 'Shot timer',
  ShotTimerMode.par => 'Par timer',
  ShotTimerMode.cadence => 'Cadans',
  ShotTimerMode.externalManual => 'Externe timer',
};

String _qualityLabel(ShotTimerDetectionQuality quality) => switch (quality) {
  ShotTimerDetectionQuality.high => 'hoge zekerheid',
  ShotTimerDetectionQuality.medium => 'controleren',
  ShotTimerDetectionQuality.low => 'lage zekerheid',
};

String _friendlyTimerError(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('permission') || text.contains('microphone')) {
    return 'Microfoontoegang is nodig voor de akoestische timer. Par en cadans blijven beschikbaar.';
  }
  if (text.contains('audio') || text.contains('recorder')) {
    return 'De audio-invoer kon niet worden gestart. Controleer de microfoon en probeer opnieuw.';
  }
  return 'De timer kon niet worden gestart. Probeer opnieuw.';
}

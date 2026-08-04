import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../widgets/app_form_scaffold.dart';
import '../../widgets/app_multiline_field.dart';
import '../../widgets/app_select_field.dart';
import '../../widgets/safe_sheet_scaffold.dart';

class SessionEditValues {
  const SessionEditValues({
    required this.startedAtLocal,
    this.rangeId,
    this.trainingGoal,
    this.conditions,
    this.notes,
  });

  final DateTime startedAtLocal;
  final String? rangeId;
  final String? trainingGoal;
  final String? conditions;
  final String? notes;
}

Future<SessionEditValues?> showSessionEditSheet({
  required BuildContext context,
  required SessionRecord session,
  required List<RangeRecord> ranges,
}) => Navigator.of(context).push<SessionEditValues>(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => _SessionEditSheet(session: session, ranges: ranges),
  ),
);

class _SessionEditSheet extends StatefulWidget {
  const _SessionEditSheet({required this.session, required this.ranges});

  final SessionRecord session;
  final List<RangeRecord> ranges;

  @override
  State<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends State<_SessionEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _startedAt;
  late String? _rangeId;
  late final TextEditingController _goal;
  late final TextEditingController _conditions;
  late final TextEditingController _notes;
  var _submitted = false;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.session.startedAtUtc.toLocal();
    _rangeId = widget.session.rangeId;
    _goal = TextEditingController(text: widget.session.trainingGoal);
    _conditions = TextEditingController(text: widget.session.conditions);
    _notes = TextEditingController(text: widget.session.notes);
    _goal.addListener(_changed);
    _conditions.addListener(_changed);
    _notes.addListener(_changed);
  }

  void _changed() => setState(() {});

  bool get _dirty =>
      _startedAt != widget.session.startedAtUtc.toLocal() ||
      _rangeId != widget.session.rangeId ||
      _nullable(_goal.text) != widget.session.trainingGoal ||
      _nullable(_conditions.text) != widget.session.conditions ||
      _nullable(_notes.text) != widget.session.notes;

  @override
  void dispose() {
    _goal.dispose();
    _conditions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppFormScaffold(
      title: 'Sessie bewerken',
      dirty: _dirty && !_submitted,
      actions: [
        FilledButton(
          onPressed: _submit,
          child: const Text('Wijzigingen bewaren'),
        ),
      ],
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdaptiveFormRow(
              minimumChildWidth: 150,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_startedAt.day.toString().padLeft(2, '0')}/'
                    '${_startedAt.month.toString().padLeft(2, '0')}/'
                    '${_startedAt.year}',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    '${_startedAt.hour.toString().padLeft(2, '0')}:'
                    '${_startedAt.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppSelectField<String?>(
              label: 'Schietstand',
              initialValue: _rangeId,
              options: [
                const AppSelectOption<String?>(
                  value: null,
                  label: 'Niet opgegeven',
                ),
                ...widget.ranges.map(
                  (range) => AppSelectOption<String?>(
                    value: range.id,
                    label: range.name,
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _rangeId = value),
            ),
            const SizedBox(height: 12),
            AppMultilineField(
              controller: _notes,
              label: 'Notities',
              hint: 'Voeg later observaties of aandachtspunten toe',
              validator: (value) => _maximumLength(value, 2000),
            ),
            const SizedBox(height: 24),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Meer details'),
              children: [
                AppMultilineField(
                  controller: _goal,
                  label: 'Trainingsdoel',
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) => _maximumLength(value, 160),
                ),
                const SizedBox(height: 12),
                AppMultilineField(
                  controller: _conditions,
                  label: 'Omstandigheden',
                  minLines: 2,
                  maxLines: 4,
                  validator: (value) => _maximumLength(value, 240),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDate: _startedAt,
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startedAt = DateTime(
        selected.year,
        selected.month,
        selected.day,
        _startedAt.hour,
        _startedAt.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startedAt),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _startedAt = DateTime(
        _startedAt.year,
        _startedAt.month,
        _startedAt.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    Navigator.pop(
      context,
      SessionEditValues(
        startedAtLocal: _startedAt,
        rangeId: _rangeId,
        trainingGoal: _nullable(_goal.text),
        conditions: _nullable(_conditions.text),
        notes: _nullable(_notes.text),
      ),
    );
  }

  String? _maximumLength(String? value, int maximum) {
    if ((value?.trim().length ?? 0) > maximum) {
      return 'Gebruik maximaal $maximum tekens';
    }
    return null;
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

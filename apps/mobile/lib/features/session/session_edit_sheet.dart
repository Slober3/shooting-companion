import 'package:flutter/material.dart';

import '../../data/app_database.dart';

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
}) => showModalBottomSheet<SessionEditValues>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _SessionEditSheet(session: session, ranges: ranges),
);

class _SessionEditSheet extends StatefulWidget {
  const _SessionEditSheet({required this.session, required this.ranges});

  final SessionRecord session;
  final List<RangeRecord> ranges;

  @override
  State<_SessionEditSheet> createState() => _SessionEditSheetState();
}

class _SessionEditSheetState extends State<_SessionEditSheet> {
  late DateTime _startedAt;
  late String? _rangeId;
  late final TextEditingController _goal;
  late final TextEditingController _conditions;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _startedAt = widget.session.startedAtUtc.toLocal();
    _rangeId = widget.session.rangeId;
    _goal = TextEditingController(text: widget.session.trainingGoal);
    _conditions = TextEditingController(text: widget.session.conditions);
    _notes = TextEditingController(text: widget.session.notes);
  }

  @override
  void dispose() {
    _goal.dispose();
    _conditions.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, keyboard + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sessie bewerken',
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(
                      '${_startedAt.day.toString().padLeft(2, '0')}/'
                      '${_startedAt.month.toString().padLeft(2, '0')}/'
                      '${_startedAt.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      '${_startedAt.hour.toString().padLeft(2, '0')}:'
                      '${_startedAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _rangeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Schietstand'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Niet opgegeven'),
                ),
                ...widget.ranges.map(
                  (range) => DropdownMenuItem<String?>(
                    value: range.id,
                    child: Text(range.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _rangeId = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _goal,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Trainingsdoel'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _conditions,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Omstandigheden'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Notities'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submit,
              child: const Text('Wijzigingen bewaren'),
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
    if (selected == null) return;
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
    if (selected == null) return;
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

  void _submit() => Navigator.pop(
    context,
    SessionEditValues(
      startedAtLocal: _startedAt,
      rangeId: _rangeId,
      trainingGoal: _nullable(_goal.text),
      conditions: _nullable(_conditions.text),
      notes: _nullable(_notes.text),
    ),
  );

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

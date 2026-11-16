import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';

enum ComposerItemType { task, cadenceGoal, appointment }

/// Quick-add bottom sheet (`+` button) to add a Task, a Recurring Routine,
/// or an Appointment with human-friendly labels and optional date selection.
class TaskComposerSheet extends StatefulWidget {
  const TaskComposerSheet({
    super.key,
    required this.controller,
    this.initialType = ComposerItemType.task,
    this.initialDate,
  });

  final ProductivityController controller;
  final ComposerItemType initialType;
  final DateTime? initialDate;

  @override
  State<TaskComposerSheet> createState() => _TaskComposerSheetState();
}

class _TaskComposerSheetState extends State<TaskComposerSheet> {
  late ComposerItemType _selectedType;
  late DateTime _selectedDate;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  EisenhowerQuadrant _quadrant = EisenhowerQuadrant.doFirst;
  CadenceType _cadence = CadenceType.daily;
  int _leadMinutes = 15;
  bool _isPersistentAlert = true;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomInset + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Add to Your Schedule',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Item Type Selector
            SegmentedButton<ComposerItemType>(
              segments: const [
                ButtonSegment(
                  value: ComposerItemType.task,
                  icon: Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Text('Task'),
                ),
                ButtonSegment(
                  value: ComposerItemType.cadenceGoal,
                  icon: Icon(Icons.repeat_rounded, size: 16),
                  label: Text('Routine'),
                ),
                ButtonSegment(
                  value: ComposerItemType.appointment,
                  icon: Icon(Icons.event_available_rounded, size: 16),
                  label: Text('Appointment'),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (s) {
                setState(() {
                  _selectedType = s.first;
                  _validationError = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Title input
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: _selectedType == ComposerItemType.appointment
                    ? 'What is the appointment? *'
                    : _selectedType == ComposerItemType.cadenceGoal
                        ? 'What habit or routine? *'
                        : 'What needs to get done? *',
                errorText: _validationError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Date Picker Row
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled Date: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Change Date'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location / Link for Appointments
            if (_selectedType == ComposerItemType.appointment) ...[
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Place or Call Link',
                  hintText: 'Room 302 or video call link',
                  prefixIcon: const Icon(Icons.place_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Helpful Notes (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Priority Group Selector for Tasks & Routines
            if (_selectedType != ComposerItemType.appointment) ...[
              Text(
                'How Urgent Is This?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EisenhowerQuadrant.values.map((q) {
                  final selected = _quadrant == q;
                  return ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: q.color, radius: 6),
                    label: Text(q.title),
                    selected: selected,
                    onSelected: (_) => setState(() => _quadrant = q),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Frequency Selector for Routines
            if (_selectedType == ComposerItemType.cadenceGoal) ...[
              Text(
                'How Often Should It Repeat?',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CadenceType.values.map((c) {
                  return ChoiceChip(
                    label: Text(c.label),
                    selected: _cadence == c,
                    onSelected: (_) => setState(() => _cadence = c),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Lead Time Selector for Appointments
            if (_selectedType == ComposerItemType.appointment) ...[
              Text(
                'Remind Me Before It Starts',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [15, 30, 60, 1440].map((mins) {
                  final label = mins == 1440 ? '1 Day Early' : '$mins Mins Early';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _leadMinutes == mins,
                    onSelected: (_) => setState(() => _leadMinutes = mins),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Insistent Reminder Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep Nudging Until I Answer'),
              subtitle: Text(
                'Repeats the notification every few minutes until you mark it done or snooze it',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              value: _isPersistentAlert,
              onChanged: (v) => setState(() => _isPersistentAlert = v),
            ),
            const SizedBox(height: 12),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.add_task_rounded),
              label: Text(
                _selectedType == ComposerItemType.task
                    ? 'Add Task'
                    : _selectedType == ComposerItemType.cadenceGoal
                        ? 'Save ${_cadence.label} Routine'
                        : 'Save Appointment',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _validationError = 'Please enter a title';
      });
      return;
    }

    final now = DateTime.now();
    final scheduledBase = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      now.hour,
      now.minute,
    );
    final baseMs = scheduledBase.millisecondsSinceEpoch;
    const hourMs = 60 * 60 * 1000;

    if (_selectedType == ComposerItemType.task) {
      await widget.controller.createTask(
        title: title,
        notes: _notesController.text,
        quadrant: _quadrant,
        dueAtMillis: baseMs + (2 * hourMs),
        isPersistentAlert: _isPersistentAlert,
      );
    } else if (_selectedType == ComposerItemType.cadenceGoal) {
      await widget.controller.createCadenceGoal(
        title: title,
        notes: _notesController.text,
        cadence: _cadence,
        quadrant: _quadrant,
        nextDueAtMillis: baseMs + (3 * hourMs),
        isPersistentAlert: _isPersistentAlert,
      );
      widget.controller.setCadenceHorizon(_cadence);
    } else {
      await widget.controller.createAppointment(
        title: title,
        locationOrLink: _locationController.text,
        notes: _notesController.text,
        startsAtMillis: baseMs + (30 * 60 * 1000),
        leadMinutes: _leadMinutes,
        isPersistentAlert: _isPersistentAlert,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

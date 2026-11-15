import 'package:flutter/material.dart';
import '../../models/enums.dart';
import '../../state/productivity_controller.dart';

enum ComposerItemType { task, cadenceGoal, appointment }

/// Quick-capture bottom sheet (`+` FAB) to create an Eisenhower **Task**,
/// a 5-tier **Cadence Goal**, or a persistent **Appointment** reminder.
class TaskComposerSheet extends StatefulWidget {
  const TaskComposerSheet({
    super.key,
    required this.controller,
    this.initialType = ComposerItemType.task,
  });

  final ProductivityController controller;
  final ComposerItemType initialType;

  @override
  State<TaskComposerSheet> createState() => _TaskComposerSheetState();
}

class _TaskComposerSheetState extends State<TaskComposerSheet> {
  late ComposerItemType _selectedType;
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
                    'Quick Capture',
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

            // Entity Type Segmented Selector
            SegmentedButton<ComposerItemType>(
              segments: const [
                ButtonSegment(
                  value: ComposerItemType.task,
                  icon: Icon(Icons.grid_view_rounded, size: 16),
                  label: Text('Task'),
                ),
                ButtonSegment(
                  value: ComposerItemType.cadenceGoal,
                  icon: Icon(Icons.repeat_rounded, size: 16),
                  label: Text('Cadence'),
                ),
                ButtonSegment(
                  value: ComposerItemType.appointment,
                  icon: Icon(Icons.notifications_active_rounded, size: 16),
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
                    ? 'Appointment Title *'
                    : _selectedType == ComposerItemType.cadenceGoal
                        ? 'Recurring Cadence Goal Title *'
                        : 'Task Title *',
                errorText: _validationError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Location / Link for Appointments
            if (_selectedType == ComposerItemType.appointment) ...[
              TextField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location or Meeting Link',
                  hintText: 'Room 302 or meet.google.com/...',
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
                labelText: 'Notes / Action Context (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Quadrant Selector for Tasks & Cadence Goals
            if (_selectedType != ComposerItemType.appointment) ...[
              Text(
                'Eisenhower Quadrant',
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
                    label: Text(q.shortTag),
                    selected: selected,
                    onSelected: (_) => setState(() => _quadrant = q),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],

            // Cadence Horizon Selector for Cadence Goals
            if (_selectedType == ComposerItemType.cadenceGoal) ...[
              Text(
                'Cadence Horizon (5-Tier Engine)',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CadenceType.values.map((c) {
                  return ChoiceChip(
                    label: Text('${c.label} (${c.frequencyBadge})'),
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
                'Reminder Lead Time Before Start',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [15, 30, 60, 1440].map((mins) {
                  final label = mins == 1440 ? '24 Hours' : '$mins Mins';
                  return ChoiceChip(
                    label: Text(label),
                    selected: _leadMinutes == mins,
                    onSelected: (_) => setState(() => _leadMinutes = mins),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Social-Media-Style Persistent Alert Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Social-Style Persistent Escalation Alert'),
              subtitle: Text(
                'High-priority heads-up banner + repeating re-ping until acknowledged',
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
                    ? 'Save Eisenhower Task'
                    : _selectedType == ComposerItemType.cadenceGoal
                        ? 'Save ${_cadence.label} Cadence Goal'
                        : 'Schedule Persistent Appointment',
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

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _validationError = 'Title cannot be empty';
      });
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const hourMs = 60 * 60 * 1000;

    if (_selectedType == ComposerItemType.task) {
      await widget.controller.createTask(
        title: title,
        notes: _notesController.text,
        quadrant: _quadrant,
        dueAtMillis: nowMs + (2 * hourMs),
        isPersistentAlert: _isPersistentAlert,
      );
    } else if (_selectedType == ComposerItemType.cadenceGoal) {
      await widget.controller.createCadenceGoal(
        title: title,
        notes: _notesController.text,
        cadence: _cadence,
        quadrant: _quadrant,
        nextDueAtMillis: nowMs + (3 * hourMs),
        isPersistentAlert: _isPersistentAlert,
      );
      widget.controller.setCadenceHorizon(_cadence);
    } else {
      await widget.controller.createAppointment(
        title: title,
        locationOrLink: _locationController.text,
        notes: _notesController.text,
        startsAtMillis: nowMs + (30 * 60 * 1000),
        leadMinutes: _leadMinutes,
        isPersistentAlert: _isPersistentAlert,
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

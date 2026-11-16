import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/appointment.dart';
import '../../models/cadence_goal.dart';
import '../../models/enums.dart';
import '../../models/task_item.dart';
import '../../state/productivity_controller.dart';
import '../../theme/app_theme.dart';
import '../widgets/task_composer_sheet.dart';

/// Calendar Tab: Interactive Daily, Weekly, and Monthly overview of all
/// Tasks, Routines, and Appointments.
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
    super.key,
    required this.controller,
  });

  final ProductivityController controller;

  @override
  Widget build(BuildContext context) {
    final mode = controller.calendarViewMode;
    final selectedDate = controller.selectedCalendarDate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // 1. Solid Calendar Header & View Switcher (Daily / Weekly / Monthly)
        _buildCalendarHeaderCard(context, mode, selectedDate),
        const SizedBox(height: 16),

        // 2. Active Calendar View (Daily, Weekly, or Monthly)
        if (mode == CalendarViewMode.monthly)
          _buildMonthlyView(context, selectedDate)
        else if (mode == CalendarViewMode.weekly)
          _buildWeeklyView(context, selectedDate)
        else
          _buildDailyView(context, selectedDate),
      ],
    );
  }

  Widget _buildCalendarHeaderCard(
    BuildContext context,
    CalendarViewMode mode,
    DateTime selectedDate,
  ) {
    final String headerTitle;
    if (mode == CalendarViewMode.monthly) {
      headerTitle = DateFormat('MMMM yyyy').format(selectedDate);
    } else if (mode == CalendarViewMode.weekly) {
      final startOfWeek = _startOfWeek(selectedDate);
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      headerTitle =
          '${DateFormat('MMM d').format(startOfWeek)} - ${DateFormat('MMM d, yyyy').format(endOfWeek)}';
    } else {
      headerTitle = DateFormat('EEEE, MMM d, yyyy').format(selectedDate);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.heroBannerDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Previous',
                onPressed: () => controller.stepCalendarPeriod(-1),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      headerTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mode.subtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Next',
                onPressed: () => controller.stepCalendarPeriod(1),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                ),
              ),
              TextButton(
                onPressed: controller.jumpToToday,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
                child: const Text('Today'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<CalendarViewMode>(
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
              selectedBackgroundColor: Colors.white,
              selectedForegroundColor: CadenceFlowTheme.primaryTealLight,
            ),
            segments: const [
              ButtonSegment(
                value: CalendarViewMode.daily,
                icon: Icon(Icons.view_day_rounded, size: 16),
                label: Text('Daily'),
              ),
              ButtonSegment(
                value: CalendarViewMode.weekly,
                icon: Icon(Icons.view_week_rounded, size: 16),
                label: Text('Weekly'),
              ),
              ButtonSegment(
                value: CalendarViewMode.monthly,
                icon: Icon(Icons.calendar_view_month_rounded, size: 16),
                label: Text('Monthly'),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) => controller.setCalendarViewMode(s.first),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MONTHLY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildMonthlyView(BuildContext context, DateTime selectedDate) {
    final scheme = Theme.of(context).colorScheme;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth =
        DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final leadingEmptyDays = firstDayOfMonth.weekday % 7; // Sunday = 0
    final totalCells = ((leadingEmptyDays + daysInMonth + 6) ~/ 7) * 7;
    final today = DateTime.now();

    const weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: CadenceFlowTheme.solidCardDecoration(context),
          child: Column(
            children: [
              // Weekday Header Row
              Row(
                children: weekdays
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),

              // Calendar Grid Rows
              for (int row = 0; row < totalCells ~/ 7; row++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: List.generate(7, (col) {
                      final cellIndex = row * 7 + col;
                      final dayNumber = cellIndex - leadingEmptyDays + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const Expanded(child: SizedBox(height: 52));
                      }

                      final date = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        dayNumber,
                      );
                      final isSelected = ProductivityController
                          .isSameCalendarDay(date, selectedDate);
                      final isToday = ProductivityController.isSameCalendarDay(
                        date,
                        today,
                      );

                      final tasks = controller.tasksForDate(date);
                      final routines = controller.routinesForDate(date);
                      final appts = controller.appointmentsForDate(date);
                      final totalCount =
                          tasks.length + routines.length + appts.length;

                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => controller.selectCalendarDate(date),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? scheme.primary
                                    : isToday
                                        ? scheme.primary.withValues(alpha: 0.14)
                                        : scheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? scheme.primary
                                      : isToday
                                          ? scheme.primary
                                          : scheme.outlineVariant
                                              .withValues(alpha: 0.35),
                                  width: isSelected || isToday ? 1.5 : 1.0,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$dayNumber',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected || isToday
                                          ? FontWeight.w800
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? scheme.onPrimary
                                          : scheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (totalCount > 0)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (tasks.isNotEmpty)
                                          _CalendarDot(
                                            color: isSelected
                                                ? Colors.white
                                                : CadenceFlowTheme.q1CoralRed,
                                          ),
                                        if (routines.isNotEmpty)
                                          _CalendarDot(
                                            color: isSelected
                                                ? Colors.white
                                                : CadenceFlowTheme.q2DeepTeal,
                                          ),
                                        if (appts.isNotEmpty)
                                          _CalendarDot(
                                            color: isSelected
                                                ? Colors.white
                                                : CadenceFlowTheme.q3WarmAmber,
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected Date Overview below Month Grid
        _buildDayAgendaSection(context, selectedDate),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // WEEKLY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildWeeklyView(BuildContext context, DateTime selectedDate) {
    final scheme = Theme.of(context).colorScheme;
    final startOfWeek = _startOfWeek(selectedDate);
    final weekDays = List.generate(
      7,
      (i) => startOfWeek.add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 7-Day Week Strip with Workload Bars
        Container(
          padding: const EdgeInsets.all(14),
          decoration: CadenceFlowTheme.solidCardDecoration(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7-Day Workload Overview',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: weekDays.map((day) {
                  final isSelected = ProductivityController.isSameCalendarDay(
                    day,
                    selectedDate,
                  );
                  final count = controller.totalItemsForDate(day);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => controller.selectCalendarDate(day),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primary
                                : scheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EEE').format(day),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? scheme.onPrimary
                                      : scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withValues(alpha: 0.22)
                                      : scheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$count',
                                  style: CadenceFlowTheme.monoStyle(
                                    context,
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : scheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected Day Focus + Rest of Week Breakdown
        _buildDayAgendaSection(context, selectedDate),
        const SizedBox(height: 16),
        Text(
          'Full Week Schedule',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ...weekDays.map((day) {
          final tasks = controller.tasksForDate(day);
          final routines = controller.routinesForDate(day);
          final appts = controller.appointmentsForDate(day);
          final total = tasks.length + routines.length + appts.length;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: CadenceFlowTheme.solidCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('EEEE, MMM d').format(day),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        '$total item${total == 1 ? '' : 's'}',
                        style: CadenceFlowTheme.monoStyle(
                          context,
                          fontSize: 11,
                          color: scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  if (total == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Open day — no scheduled items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 8),
                    ...appts.map(
                      (a) => _CompactCalendarRow(
                        icon: Icons.event_available_rounded,
                        color: CadenceFlowTheme.q3WarmAmber,
                        title: a.title,
                        badge: DateFormat('h:mm a').format(a.startsAtDateTime),
                      ),
                    ),
                    ...tasks.map(
                      (t) => _CompactCalendarRow(
                        icon: t.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: t.quadrant.color,
                        title: t.title,
                        badge: t.quadrant.title,
                      ),
                    ),
                    ...routines.map(
                      (r) => _CompactCalendarRow(
                        icon: Icons.repeat_rounded,
                        color: CadenceFlowTheme.q2DeepTeal,
                        title: r.title,
                        badge: r.cadence.label,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // DAILY VIEW
  // ---------------------------------------------------------------------------

  Widget _buildDailyView(BuildContext context, DateTime selectedDate) {
    final tasks = controller.tasksForDate(selectedDate);
    final routines = controller.routinesForDate(selectedDate);
    final appts = controller.appointmentsForDate(selectedDate);

    // Group items into Morning (<12), Afternoon (12-17), and Evening (>=17)
    final morningItems = <_DailyTimelineEntry>[];
    final afternoonItems = <_DailyTimelineEntry>[];
    final eveningItems = <_DailyTimelineEntry>[];

    for (final a in appts) {
      final hour = a.startsAtDateTime.hour;
      final entry = _DailyTimelineEntry(
        hour: hour,
        title: a.title,
        subtitle: a.locationOrLink.isNotEmpty
            ? a.locationOrLink
            : 'Appointment • ${DateFormat('h:mm a').format(a.startsAtDateTime)}',
        badge: DateFormat('h:mm a').format(a.startsAtDateTime),
        color: CadenceFlowTheme.q3WarmAmber,
        icon: Icons.notifications_active_rounded,
      );
      if (hour < 12) {
        morningItems.add(entry);
      } else if (hour < 17) {
        afternoonItems.add(entry);
      } else {
        eveningItems.add(entry);
      }
    }

    for (final r in routines) {
      final hour = r.reminderHour;
      final entry = _DailyTimelineEntry(
        hour: hour,
        title: r.title,
        subtitle: '${r.cadence.label} routine • 🔥 ${r.streakCount} streak',
        badge: '${r.reminderHour}:00',
        color: CadenceFlowTheme.q2DeepTeal,
        icon: Icons.repeat_rounded,
        onAction: () => controller.completeCadenceCycle(r),
      );
      if (hour < 12) {
        morningItems.add(entry);
      } else if (hour < 17) {
        afternoonItems.add(entry);
      } else {
        eveningItems.add(entry);
      }
    }

    for (final t in tasks) {
      final hour = t.dueAtMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(t.dueAtMillis!).hour
          : 13;
      final entry = _DailyTimelineEntry(
        hour: hour,
        title: t.title,
        subtitle: '${t.quadrant.title} • ${t.notes.isEmpty ? 'Task' : t.notes}',
        badge: t.quadrant.title,
        color: t.quadrant.color,
        icon: t.isCompleted
            ? Icons.check_circle_rounded
            : Icons.check_box_outline_blank_rounded,
        isCompleted: t.isCompleted,
        onAction: () => controller.toggleTaskCompleted(t),
      );
      if (hour < 12) {
        morningItems.add(entry);
      } else if (hour < 17) {
        afternoonItems.add(entry);
      } else {
        eveningItems.add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDayAgendaSection(context, selectedDate),
        const SizedBox(height: 16),
        _TimeBlockCard(
          title: 'Morning Schedule (Before 12:00 PM)',
          icon: Icons.wb_sunny_outlined,
          entries: morningItems,
        ),
        const SizedBox(height: 12),
        _TimeBlockCard(
          title: 'Afternoon Schedule (12:00 PM – 5:00 PM)',
          icon: Icons.light_mode_outlined,
          entries: afternoonItems,
        ),
        const SizedBox(height: 12),
        _TimeBlockCard(
          title: 'Evening Schedule (After 5:00 PM)',
          icon: Icons.nights_stay_outlined,
          entries: eveningItems,
        ),
      ],
    );
  }

  Widget _buildDayAgendaSection(BuildContext context, DateTime date) {
    final tasks = controller.tasksForDate(date);
    final routines = controller.routinesForDate(date);
    final appts = controller.appointmentsForDate(date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.solidCardDecoration(
        context,
        highlighted: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overview for ${DateFormat('EEE, MMM d').format(date)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${tasks.length} Tasks • ${routines.length} Routines • ${appts.length} Appointments',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => TaskComposerSheet(
                      controller: controller,
                      initialType: ComposerItemType.task,
                      initialDate: date,
                    ),
                  );
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add to Day'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty && routines.isEmpty && appts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Nothing scheduled for this day yet. Tap "Add to Day" to plan ahead.',
              ),
            )
          else ...[
            ...appts.map((Appointment a) => _CompactCalendarRow(
                  icon: Icons.event_available_rounded,
                  color: CadenceFlowTheme.q3WarmAmber,
                  title: a.title,
                  badge: DateFormat('h:mm a').format(a.startsAtDateTime),
                )),
            ...tasks.map((TaskItem t) => _CompactCalendarRow(
                  icon: t.isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: t.quadrant.color,
                  title: t.title,
                  badge: t.quadrant.title,
                  onTap: () => controller.toggleTaskCompleted(t),
                )),
            ...routines.map((CadenceGoal r) => _CompactCalendarRow(
                  icon: Icons.repeat_rounded,
                  color: CadenceFlowTheme.q2DeepTeal,
                  title: r.title,
                  badge: r.cadence.label,
                  onTap: () => controller.completeCadenceCycle(r),
                )),
          ],
        ],
      ),
    );
  }

  DateTime _startOfWeek(DateTime date) {
    final offset = date.weekday % 7;
    return DateTime(date.year, date.month, date.day - offset);
  }
}

class _CalendarDot extends StatelessWidget {
  const _CalendarDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _CompactCalendarRow extends StatelessWidget {
  const _CompactCalendarRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.badge,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: CadenceFlowTheme.tactileTileDecoration(
            context,
            accentColor: color,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyTimelineEntry {
  const _DailyTimelineEntry({
    required this.hour,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.icon,
    this.isCompleted = false,
    this.onAction,
  });

  final int hour;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final IconData icon;
  final bool isCompleted;
  final VoidCallback? onAction;
}

class _TimeBlockCard extends StatelessWidget {
  const _TimeBlockCard({
    required this.title,
    required this.icon,
    required this.entries,
  });

  final String title;
  final IconData icon;
  final List<_DailyTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: CadenceFlowTheme.solidCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entries.isEmpty)
            Text(
              'No items scheduled for this time block.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            )
          else
            ...entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: e.onAction,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: CadenceFlowTheme.tactileTileDecoration(
                      context,
                      accentColor: e.color,
                      isCompleted: e.isCompleted,
                    ),
                    child: Row(
                      children: [
                        Icon(e.icon, color: e.color, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      decoration: e.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                              ),
                              Text(
                                e.subtitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: e.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            e.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: e.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../data/productivity_repository.dart';
import '../domain/cadence_calculator.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/enums.dart';
import '../models/task_item.dart';
import '../services/reminder_scheduler.dart';

/// Central state controller for CadenceFlow:
/// - Manages Priority Tasks (Board View + Action List + Priority Filters)
/// - Manages Calendar Overview (Daily, Weekly, and Monthly views)
/// - Manages Recurring Routines & Goals (`DAILY` -> `MONTHLY`)
/// - Manages Appointments & Insistent/Aggressive Reminders
/// - Manages First-Startup Guided Setup Wizard state
class ProductivityController extends ChangeNotifier {
  ProductivityController({
    required this.repository,
    required this.reminderScheduler,
  }) {
    reminderScheduler.onForegroundAction = _handleNotificationAction;
    reminderScheduler.onEscalationStateChanged = notifyListeners;
  }

  final ProductivityRepository repository;
  final ReminderScheduler reminderScheduler;
  final Uuid _uuid = const Uuid();

  String _userId = 'user_local_itel_power70';
  bool _isLoading = false;
  bool _isOnboardingCompleted = false;
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultRepingMinutes = 5;
  bool _aggressiveModeEnabled = true;
  int _dailyStartHour = 8;

  // Priority View State
  bool _isPriorityQueueView = false;
  EisenhowerQuadrant? _selectedQuadrantFilter;

  // Routine Horizon Selector State
  CadenceType _selectedCadenceHorizon = CadenceType.daily;

  // Calendar View State
  CalendarViewMode _calendarViewMode = CalendarViewMode.monthly;
  DateTime _selectedCalendarDate = _stripTime(DateTime.now());

  List<TaskItem> _tasks = [];
  List<CadenceGoal> _cadenceGoals = [];
  List<Appointment> _appointments = [];

  // Getters
  String get userId => _userId;
  bool get isLoading => _isLoading;
  bool get isOnboardingCompleted => _isOnboardingCompleted;
  ThemeMode get themeMode => _themeMode;
  int get defaultRepingMinutes => _defaultRepingMinutes;
  bool get aggressiveModeEnabled => _aggressiveModeEnabled;
  int get dailyStartHour => _dailyStartHour;
  bool get isPriorityQueueView => _isPriorityQueueView;
  EisenhowerQuadrant? get selectedQuadrantFilter => _selectedQuadrantFilter;
  CadenceType get selectedCadenceHorizon => _selectedCadenceHorizon;
  CalendarViewMode get calendarViewMode => _calendarViewMode;
  DateTime get selectedCalendarDate => _selectedCalendarDate;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<CadenceGoal> get cadenceGoals => List.unmodifiable(_cadenceGoals);
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  static DateTime _stripTime(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static bool isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Tasks sorted by Priority rank (Do First -> Plan Ahead -> Quick Tasks -> For Later), then due time.
  List<TaskItem> get rankedPriorityQueue {
    final filtered = _selectedQuadrantFilter == null
        ? List<TaskItem>.from(_tasks)
        : _tasks
            .where((t) => t.quadrant == _selectedQuadrantFilter)
            .toList();

    filtered.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final rankCmp = a.quadrant.rank.compareTo(b.quadrant.rank);
      if (rankCmp != 0) return rankCmp;
      final aDue = a.dueAtMillis ?? 9999999999999;
      final bDue = b.dueAtMillis ?? 9999999999999;
      return aDue.compareTo(bDue);
    });
    return filtered;
  }

  List<TaskItem> tasksForQuadrant(EisenhowerQuadrant quadrant) {
    final list = _tasks.where((t) => t.quadrant == quadrant).toList();
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final aDue = a.dueAtMillis ?? 9999999999999;
      final bDue = b.dueAtMillis ?? 9999999999999;
      return aDue.compareTo(bDue);
    });
    return list;
  }

  List<CadenceGoal> goalsForHorizon(CadenceType horizon) {
    final list = _cadenceGoals.where((g) => g.cadence == horizon).toList();
    list.sort((a, b) => a.nextDueAtMillis.compareTo(b.nextDueAtMillis));
    return list;
  }

  /// Active urgent reminders requiring user acknowledgment.
  List<Appointment> get activeAttentionFeed {
    return _appointments.where((a) => a.isAttentionSeeking()).toList();
  }

  /// Count of unacknowledged urgent reminders + overdue Do First tasks.
  int get urgentAttentionCount {
    final pingingAppts = activeAttentionFeed.length;
    final overdueQ1 = _tasks
        .where((t) =>
            !t.isCompleted &&
            t.quadrant == EisenhowerQuadrant.doFirst &&
            t.isOverdue)
        .length;
    return pingingAppts + overdueQ1;
  }

  int get completedTasksCount => _tasks.where((t) => t.isCompleted).length;
  int get totalTasksCount => _tasks.length;
  double get todayCompletionRatio =>
      totalTasksCount == 0 ? 0.0 : completedTasksCount / totalTasksCount;

  // ---------------------------------------------------------------------------
  // Calendar Overview Queries (Daily, Weekly, Monthly)
  // ---------------------------------------------------------------------------

  void setCalendarViewMode(CalendarViewMode mode) {
    _calendarViewMode = mode;
    notifyListeners();
  }

  void selectCalendarDate(DateTime date) {
    _selectedCalendarDate = _stripTime(date);
    notifyListeners();
  }

  void jumpToToday() {
    _selectedCalendarDate = _stripTime(DateTime.now());
    notifyListeners();
  }

  void stepCalendarPeriod(int direction) {
    final current = _selectedCalendarDate;
    switch (_calendarViewMode) {
      case CalendarViewMode.daily:
        _selectedCalendarDate = current.add(Duration(days: direction));
        break;
      case CalendarViewMode.weekly:
        _selectedCalendarDate = current.add(Duration(days: 7 * direction));
        break;
      case CalendarViewMode.monthly:
        _selectedCalendarDate = DateTime(
          current.year,
          current.month + direction,
          1,
        );
        break;
    }
    notifyListeners();
  }

  /// Returns all tasks scheduled for [day]. If [day] is today, also includes
  /// active tasks without a specific due date so nothing gets overlooked.
  List<TaskItem> tasksForDate(DateTime day) {
    final target = _stripTime(day);
    final today = _stripTime(DateTime.now());
    final matches = _tasks.where((task) {
      if (task.dueAtMillis == null) {
        return isSameCalendarDay(target, today);
      }
      final dueDate =
          DateTime.fromMillisecondsSinceEpoch(task.dueAtMillis!);
      return isSameCalendarDay(dueDate, target);
    }).toList();

    matches.sort((a, b) {
      if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
      final rankCmp = a.quadrant.rank.compareTo(b.quadrant.rank);
      if (rankCmp != 0) return rankCmp;
      return (a.dueAtMillis ?? 0).compareTo(b.dueAtMillis ?? 0);
    });
    return matches;
  }

  /// Returns routines due on [day] (including recurring schedule projection for
  /// future calendar dates so Daily/Weekly/Monthly views show upcoming habits).
  List<CadenceGoal> routinesForDate(DateTime day) {
    final target = _stripTime(day);
    final matches = _cadenceGoals
        .where((goal) => goal.isActive && isRoutineScheduledOnDate(goal, target))
        .toList();
    matches.sort((a, b) => a.reminderHour.compareTo(b.reminderHour));
    return matches;
  }

  bool isRoutineScheduledOnDate(CadenceGoal goal, DateTime day) {
    final target = _stripTime(day);
    final anchor = _stripTime(goal.nextDueDateTime);

    if (isSameCalendarDay(target, anchor)) return true;
    if (target.isBefore(anchor)) return false;

    final diffDays = target.difference(anchor).inDays;
    switch (goal.cadence) {
      case CadenceType.daily:
        return true;
      case CadenceType.biDaily:
        return diffDays % 2 == 0;
      case CadenceType.weekly:
        return target.weekday == anchor.weekday;
      case CadenceType.biWeekly:
        return diffDays % 14 == 0;
      case CadenceType.monthly:
        final maxDay = DateTime(target.year, target.month + 1, 0).day;
        final expectedDay = anchor.day > maxDay ? maxDay : anchor.day;
        return target.day == expectedDay;
    }
  }

  /// Returns appointments scheduled on [day].
  List<Appointment> appointmentsForDate(DateTime day) {
    final target = _stripTime(day);
    final matches = _appointments
        .where((appt) => isSameCalendarDay(appt.startsAtDateTime, target))
        .toList();
    matches.sort((a, b) => a.startsAtMillis.compareTo(b.startsAtMillis));
    return matches;
  }

  int totalItemsForDate(DateTime day) {
    return tasksForDate(day).length +
        routinesForDate(day).length +
        appointmentsForDate(day).length;
  }

  // ---------------------------------------------------------------------------
  // User Hydration & First-Startup Guided Setup
  // ---------------------------------------------------------------------------

  Future<void> bindUserAndHydrate(String newUserId) async {
    _userId = newUserId;
    _isLoading = true;
    notifyListeners();

    await repository.localMirror.setActiveUserId(newUserId);
    _defaultRepingMinutes =
        await repository.localMirror.getDefaultRepingMinutes();
    _aggressiveModeEnabled =
        await repository.localMirror.getAggressiveModeEnabled();
    _dailyStartHour = await repository.localMirror.getDailyStartHour();
    _isOnboardingCompleted =
        await repository.localMirror.isOnboardingCompleted(newUserId);

    reminderScheduler.setAggressiveMode(_aggressiveModeEnabled);

    _tasks = await repository.fetchTasks(newUserId);
    _cadenceGoals = await repository.fetchCadenceGoals(newUserId);
    _appointments = await repository.fetchAppointments(newUserId);

    await reminderScheduler.syncActiveAlertsFromMirror(
      userId: newUserId,
      tasks: _tasks,
      cadenceGoals: _cadenceGoals,
      appointments: _appointments,
      defaultRepingMinutes: _defaultRepingMinutes,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Completes the first-startup setup walkthrough and persists preferences.
  Future<void> completeOnboarding({
    int? repingMinutes,
    bool? aggressiveEnabled,
    int? dailyStartHour,
    ThemeMode? selectedThemeMode,
  }) async {
    if (repingMinutes != null) {
      _defaultRepingMinutes = repingMinutes;
      await repository.localMirror.setDefaultRepingMinutes(repingMinutes);
    }
    if (aggressiveEnabled != null) {
      _aggressiveModeEnabled = aggressiveEnabled;
      reminderScheduler.setAggressiveMode(aggressiveEnabled);
      await repository.localMirror.setAggressiveModeEnabled(aggressiveEnabled);
    }
    if (dailyStartHour != null) {
      _dailyStartHour = dailyStartHour;
      await repository.localMirror.setDailyStartHour(dailyStartHour);
    }
    if (selectedThemeMode != null) {
      _themeMode = selectedThemeMode;
    }

    _isOnboardingCompleted = true;
    await repository.localMirror.setOnboardingCompleted(_userId, true);
    notifyListeners();
  }

  /// Allows re-opening the guided setup wizard at any time from Settings/Help.
  Future<void> reopenOnboardingWizard() async {
    _isOnboardingCompleted = false;
    await repository.localMirror.setOnboardingCompleted(_userId, false);
    notifyListeners();
  }

  void setPriorityQueueView(bool isQueue) {
    _isPriorityQueueView = isQueue;
    notifyListeners();
  }

  void setQuadrantFilter(EisenhowerQuadrant? quadrant) {
    _selectedQuadrantFilter =
        _selectedQuadrantFilter == quadrant ? null : quadrant;
    notifyListeners();
  }

  void setCadenceHorizon(CadenceType horizon) {
    _selectedCadenceHorizon = horizon;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> setDefaultRepingMinutes(int minutes) async {
    _defaultRepingMinutes = minutes;
    await repository.localMirror.setDefaultRepingMinutes(minutes);
    notifyListeners();
  }

  Future<void> setAggressiveModeEnabled(bool enabled) async {
    _aggressiveModeEnabled = enabled;
    reminderScheduler.setAggressiveMode(enabled);
    await repository.localMirror.setAggressiveModeEnabled(enabled);
    notifyListeners();
  }

  Future<void> setDailyStartHour(int hour) async {
    _dailyStartHour = hour;
    await repository.localMirror.setDailyStartHour(hour);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Task Actions
  // ---------------------------------------------------------------------------

  Future<TaskItem> createTask({
    required String title,
    String notes = '',
    required EisenhowerQuadrant quadrant,
    int? dueAtMillis,
    bool isPersistentAlert = false,
  }) async {
    final now = DateTime.now();
    final task = TaskItem(
      id: 'task_${_uuid.v4()}',
      userId: _userId,
      title: title.trim(),
      notes: notes.trim(),
      quadrant: quadrant,
      dueAtMillis: dueAtMillis,
      reminderAtMillis: dueAtMillis,
      isPersistentAlert: isPersistentAlert,
      createdAt: now,
      updatedAt: now,
    );

    _tasks.insert(0, task);
    notifyListeners();
    await repository.upsertTask(_userId, task);

    if (isPersistentAlert) {
      await reminderScheduler.triggerSocialStyleAlert(
        entityType: 'task',
        entityId: task.id,
        userId: _userId,
        title: task.title,
        subtitle:
            '${task.quadrant.title} • Repeats every $_defaultRepingMinutes min until done',
        badgeTag: task.quadrant.title.toUpperCase(),
        repingIntervalMinutes: _defaultRepingMinutes,
        isPersistent: true,
      );
    }
    return task;
  }

  Future<void> toggleTaskCompleted(TaskItem task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _tasks[idx] = updated;
      notifyListeners();
    }
    await repository.upsertTask(_userId, updated);
    if (updated.isCompleted) {
      await reminderScheduler.cancelReminder('task', updated.id);
    }
  }

  Future<void> moveTaskQuadrant(
    TaskItem task,
    EisenhowerQuadrant newQuadrant,
  ) async {
    final updated = task.copyWith(
      quadrant: newQuadrant,
      updatedAt: DateTime.now(),
    );
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      _tasks[idx] = updated;
      notifyListeners();
    }
    await repository.upsertTask(_userId, updated);
  }

  Future<void> deleteTask(String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
    await repository.deleteTask(_userId, taskId);
    await reminderScheduler.cancelReminder('task', taskId);
  }

  // ---------------------------------------------------------------------------
  // Routine & Goal Actions
  // ---------------------------------------------------------------------------

  Future<CadenceGoal> createCadenceGoal({
    required String title,
    String notes = '',
    required CadenceType cadence,
    required EisenhowerQuadrant quadrant,
    required int nextDueAtMillis,
    int reminderHour = 9,
    int reminderMinute = 0,
    bool isPersistentAlert = true,
  }) async {
    final now = DateTime.now();
    final goal = CadenceGoal(
      id: 'cad_${_uuid.v4()}',
      userId: _userId,
      title: title.trim(),
      notes: notes.trim(),
      cadence: cadence,
      quadrant: quadrant,
      nextDueAtMillis: nextDueAtMillis,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
      isPersistentAlert: isPersistentAlert,
      createdAt: now,
      updatedAt: now,
    );

    _cadenceGoals.add(goal);
    notifyListeners();
    await repository.upsertCadenceGoal(_userId, goal);
    return goal;
  }

  Future<CadenceGoal> completeCadenceCycle(
    CadenceGoal goal, {
    DateTime? completedAt,
  }) async {
    final previousState = goal;
    final rolledOver = CadenceCalculator.completeCycle(
      goal,
      completedAt: completedAt,
    );

    final idx = _cadenceGoals.indexWhere((g) => g.id == goal.id);
    if (idx >= 0) {
      _cadenceGoals[idx] = rolledOver;
      notifyListeners();
    }
    await repository.upsertCadenceGoal(_userId, rolledOver);
    return previousState;
  }

  Future<void> restoreCadenceGoalState(CadenceGoal previousGoal) async {
    final idx = _cadenceGoals.indexWhere((g) => g.id == previousGoal.id);
    if (idx >= 0) {
      _cadenceGoals[idx] = previousGoal;
      notifyListeners();
    }
    await repository.upsertCadenceGoal(_userId, previousGoal);
  }

  Future<void> deleteCadenceGoal(String goalId) async {
    _cadenceGoals.removeWhere((g) => g.id == goalId);
    notifyListeners();
    await repository.deleteCadenceGoal(_userId, goalId);
  }

  // ---------------------------------------------------------------------------
  // Appointment & Aggressive Reminder Actions
  // ---------------------------------------------------------------------------

  Future<Appointment> createAppointment({
    required String title,
    String locationOrLink = '',
    String notes = '',
    required int startsAtMillis,
    int leadMinutes = 15,
    bool isPersistentAlert = true,
    int? repingIntervalMinutes,
  }) async {
    final now = DateTime.now();
    final reping = repingIntervalMinutes ?? _defaultRepingMinutes;
    final startsInLessThanLead =
        (startsAtMillis - (leadMinutes * 60 * 1000)) <=
            now.millisecondsSinceEpoch;

    final appt = Appointment(
      id: 'appt_${_uuid.v4()}',
      userId: _userId,
      title: title.trim(),
      locationOrLink: locationOrLink.trim(),
      notes: notes.trim(),
      startsAtMillis: startsAtMillis,
      leadMinutes: leadMinutes,
      isPersistentAlert: isPersistentAlert,
      repingIntervalMinutes: reping,
      alertStatus:
          startsInLessThanLead ? AlertStatus.pinging : AlertStatus.scheduled,
      createdAt: now,
      updatedAt: now,
    );

    _appointments.add(appt);
    _appointments.sort((a, b) => a.startsAtMillis.compareTo(b.startsAtMillis));
    notifyListeners();
    await repository.upsertAppointment(_userId, appt);

    if (isPersistentAlert) {
      await reminderScheduler.triggerSocialStyleAlert(
        entityType: 'appointment',
        entityId: appt.id,
        userId: _userId,
        title: appt.title,
        subtitle: appt.locationOrLink.isNotEmpty
            ? '${appt.locationOrLink} • Repeats every ${appt.repingIntervalMinutes} min until answered'
            : 'Starts in ${appt.leadMinutes} min • Repeats every ${appt.repingIntervalMinutes} min',
        badgeTag: 'INSISTENT REMINDER',
        repingIntervalMinutes: appt.repingIntervalMinutes,
        isPersistent: true,
      );
    }
    return appt;
  }

  Future<void> acknowledgeAppointment(Appointment appt) async {
    final updated = appt.copyWith(
      alertStatus: AlertStatus.acknowledged,
      clearSnoozedUntil: true,
      updatedAt: DateTime.now(),
    );
    await _saveAppointmentState(updated);
    await reminderScheduler.cancelReminder('appointment', appt.id);
  }

  Future<void> snoozeAppointment(Appointment appt, {int minutes = 10}) async {
    final now = DateTime.now();
    final snoozedUntil =
        now.add(Duration(minutes: minutes)).millisecondsSinceEpoch;
    final updated = appt.copyWith(
      alertStatus: AlertStatus.snoozed,
      snoozedUntilMillis: snoozedUntil,
      updatedAt: now,
    );
    await _saveAppointmentState(updated);
    await reminderScheduler.cancelReminder('appointment', appt.id);

    // Schedule automatic wake-up when snooze expires so aggressive alert resumes.
    reminderScheduler.scheduleSnoozeWakeup(
      entityType: 'appointment',
      entityId: appt.id,
      duration: Duration(minutes: minutes),
      onWakeup: () {
        final idx = _appointments.indexWhere((a) => a.id == appt.id);
        if (idx >= 0 &&
            _appointments[idx].alertStatus == AlertStatus.snoozed) {
          triggerNowPing(_appointments[idx]);
        }
      },
    );
  }

  Future<void> completeAppointment(Appointment appt) async {
    final updated = appt.copyWith(
      alertStatus: AlertStatus.completed,
      clearSnoozedUntil: true,
      updatedAt: DateTime.now(),
    );
    await _saveAppointmentState(updated);
    await reminderScheduler.cancelReminder('appointment', appt.id);
  }

  /// Fires an immediate insistent reminder alert for an appointment.
  Future<void> triggerNowPing(Appointment appt) async {
    final updated = appt.copyWith(
      alertStatus: AlertStatus.pinging,
      clearSnoozedUntil: true,
      updatedAt: DateTime.now(),
    );
    await _saveAppointmentState(updated);
    await reminderScheduler.triggerSocialStyleAlert(
      entityType: 'appointment',
      entityId: appt.id,
      userId: _userId,
      title: appt.title,
      subtitle: appt.locationOrLink.isNotEmpty
          ? '${appt.locationOrLink} • Ringing every ${appt.repingIntervalMinutes} min'
          : 'Important Reminder • Ringing every ${appt.repingIntervalMinutes} min',
      badgeTag: 'URGENT REMINDER',
      repingIntervalMinutes: appt.repingIntervalMinutes,
      isPersistent: appt.isPersistentAlert,
    );
  }

  /// Fires a live test of the insistent notification system so the user can
  /// verify sound, vibration, and in-app banner behavior immediately.
  Future<void> triggerTestAggressiveAlert() async {
    if (_appointments.isNotEmpty) {
      await triggerNowPing(_appointments.first);
      return;
    }
    await createAppointment(
      title: 'Quick Reminder Test',
      locationOrLink: 'Tap Got It or Snooze to silence this alert',
      startsAtMillis:
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch,
      leadMinutes: 15,
      isPersistentAlert: true,
      repingIntervalMinutes: _defaultRepingMinutes,
    );
  }

  Future<void> deleteAppointment(String appointmentId) async {
    _appointments.removeWhere((a) => a.id == appointmentId);
    notifyListeners();
    await repository.deleteAppointment(_userId, appointmentId);
    await reminderScheduler.cancelReminder('appointment', appointmentId);
  }

  Future<void> _saveAppointmentState(Appointment updated) async {
    final idx = _appointments.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      _appointments[idx] = updated;
      notifyListeners();
    }
    await repository.upsertAppointment(_userId, updated);
  }

  void _handleNotificationAction(
    String entityType,
    String entityId,
    String actionId,
  ) {
    bindUserAndHydrate(_userId);
  }
}

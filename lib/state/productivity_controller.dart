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
/// - Manages Eisenhower Matrix tasks (2x2 Grid + Priority Queue + Quadrant Filters)
/// - Manages 5-tier Cadence Goals (`DAILY` -> `MONTHLY`) and hybrid cycle rollovers
/// - Manages Appointments & the Social-Media-Style Attention Feed
/// - Coordinates optimistic UI updates, Undo snackbar state, local offline
///   mirroring, Supabase cloud sync, and `ReminderScheduler` escalation alarms.
class ProductivityController extends ChangeNotifier {
  ProductivityController({
    required this.repository,
    required this.reminderScheduler,
  }) {
    reminderScheduler.onForegroundAction = _handleNotificationAction;
  }

  final ProductivityRepository repository;
  final ReminderScheduler reminderScheduler;
  final Uuid _uuid = const Uuid();

  String _userId = 'user_local_itel_power70';
  bool _isLoading = false;
  ThemeMode _themeMode = ThemeMode.system;
  int _defaultRepingMinutes = 10;

  // Eisenhower View State
  bool _isPriorityQueueView = false;
  EisenhowerQuadrant? _selectedQuadrantFilter;

  // Cadence Horizon Selector State
  CadenceType _selectedCadenceHorizon = CadenceType.daily;

  List<TaskItem> _tasks = [];
  List<CadenceGoal> _cadenceGoals = [];
  List<Appointment> _appointments = [];

  // Getters
  String get userId => _userId;
  bool get isLoading => _isLoading;
  ThemeMode get themeMode => _themeMode;
  int get defaultRepingMinutes => _defaultRepingMinutes;
  bool get isPriorityQueueView => _isPriorityQueueView;
  EisenhowerQuadrant? get selectedQuadrantFilter => _selectedQuadrantFilter;
  CadenceType get selectedCadenceHorizon => _selectedCadenceHorizon;

  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<CadenceGoal> get cadenceGoals => List.unmodifiable(_cadenceGoals);
  List<Appointment> get appointments => List.unmodifiable(_appointments);

  /// Tasks sorted by Eisenhower Quadrant rank (Q1 -> Q2 -> Q3 -> Q4), then due time.
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

  /// Active social-style urgent alerts requiring user acknowledgment.
  List<Appointment> get activeAttentionFeed {
    return _appointments.where((a) => a.isAttentionSeeking()).toList();
  }

  /// Count of unacknowledged urgent pings + overdue Q1 tasks + due cadence goals.
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

  /// Hydrates data for the authenticated Clerk user (or offline workspace).
  Future<void> bindUserAndHydrate(String newUserId) async {
    _userId = newUserId;
    _isLoading = true;
    notifyListeners();

    await repository.localMirror.setActiveUserId(newUserId);
    _defaultRepingMinutes =
        await repository.localMirror.getDefaultRepingMinutes();

    _tasks = await repository.fetchTasks(newUserId);
    _cadenceGoals = await repository.fetchCadenceGoals(newUserId);
    _appointments = await repository.fetchAppointments(newUserId);

    await reminderScheduler.syncActiveAlertsFromMirror(
      userId: newUserId,
      tasks: _tasks,
      cadenceGoals: _cadenceGoals,
      appointments: _appointments,
    );

    _isLoading = false;
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
        subtitle: '${task.quadrant.shortTag} • Priority Task Reminder',
        badgeTag: task.quadrant.shortTag.toUpperCase(),
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
  // Cadence Goal Actions (5-Tier Rollover Engine)
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

  /// Completes the current cycle for [goal], increments its streak, and
  /// advances `nextDueAtMillis` using the hybrid [CadenceCalculator].
  /// Returns the previous state so an Undo snackbar can restore it cleanly.
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
  // Appointment & Persistent Alert Actions
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
            ? '${appt.locationOrLink} • Re-pings every ${appt.repingIntervalMinutes}m until acknowledged'
            : 'Lead alert (${appt.leadMinutes}m) • Re-pings every ${appt.repingIntervalMinutes}m',
        badgeTag: 'PERSISTENT APPOINTMENT PING',
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

  /// Simulates/fires an immediate attention-seeking escalation ping for testing
  /// on devices like the itel Power 70.
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
          ? '${appt.locationOrLink} • Escalation ping every ${appt.repingIntervalMinutes}m'
          : 'Urgent Appointment Ping • Escalation every ${appt.repingIntervalMinutes}m',
      badgeTag: 'URGENT SOCIAL PING',
      isPersistent: appt.isPersistentAlert,
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

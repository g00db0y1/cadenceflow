import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/enums.dart';
import '../models/task_item.dart';

/// Offline-first on-device storage mirror that persists Tasks, Cadence Goals,
/// Appointments, and active alarm metadata locally.
///
/// Why this exists (Decision A3):
/// On budget/battery-aggressive Android devices like the **itel Power 70**,
/// `BOOT_COMPLETED` receivers and background notification shade actions
/// (`Done` / `Snooze 10m` / `Acknowledge`) often execute while the device has
/// no active network connection. By mirroring state locally on-device,
/// background isolates can read and update alarm & task state in <5ms offline
/// and queue deltas for Supabase PostgreSQL sync.
class LocalStorageMirror {
  static const String _tasksKeyPrefix = 'cf_tasks_v1_';
  static const String _cadencesKeyPrefix = 'cf_cadences_v1_';
  static const String _appointmentsKeyPrefix = 'cf_appointments_v1_';
  static const String _seededKeyPrefix = 'cf_seeded_v1_';
  static const String _repingMinutesKey = 'cf_default_reping_minutes_v1';
  static const String _activeUserIdKey = 'cf_active_user_id_v1';

  Future<void> setActiveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeUserIdKey, userId);
  }

  Future<String> getActiveUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeUserIdKey) ?? 'user_local_itel_power70';
  }

  Future<int> getDefaultRepingMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_repingMinutesKey) ?? 10;
  }

  Future<void> setDefaultRepingMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repingMinutesKey, minutes);
  }

  Future<List<TaskItem>> loadTasks(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureSeededIfFirstRun(prefs, userId);
    final raw = prefs.getString('$_tasksKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => TaskItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveTasks(String userId, List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString('$_tasksKeyPrefix$userId', encoded);
  }

  Future<List<CadenceGoal>> loadCadenceGoals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureSeededIfFirstRun(prefs, userId);
    final raw = prefs.getString('$_cadencesKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => CadenceGoal.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveCadenceGoals(
    String userId,
    List<CadenceGoal> goals,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(goals.map((g) => g.toMap()).toList());
    await prefs.setString('$_cadencesKeyPrefix$userId', encoded);
  }

  Future<List<Appointment>> loadAppointments(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureSeededIfFirstRun(prefs, userId);
    final raw = prefs.getString('$_appointmentsKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => Appointment.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveAppointments(
    String userId,
    List<Appointment> appointments,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(appointments.map((a) => a.toMap()).toList());
    await prefs.setString('$_appointmentsKeyPrefix$userId', encoded);
  }

  /// Populates realistic starter data on a user's first session so all 4
  /// Eisenhower quadrants, all 5 Cadence horizons, and the Social-Style
  /// Attention Feed are immediately interactive.
  Future<void> _ensureSeededIfFirstRun(
    SharedPreferences prefs,
    String userId,
  ) async {
    final seededFlag = '$_seededKeyPrefix$userId';
    if (prefs.getBool(seededFlag) == true) return;

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    const hourMs = 60 * 60 * 1000;
    const dayMs = 24 * hourMs;

    final starterTasks = <TaskItem>[
      TaskItem(
        id: 'task_q1_1',
        userId: userId,
        title: 'Finalize client sprint deliverables & send invoice',
        notes: 'High-impact priority before 5:00 PM cutoff',
        quadrant: EisenhowerQuadrant.doFirst,
        isCompleted: false,
        dueAtMillis: nowMs + (3 * hourMs),
        reminderAtMillis: nowMs + (2 * hourMs),
        isPersistentAlert: true,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q1_2',
        userId: userId,
        title: 'Review Supabase RLS policy audit & Clerk JWKS status',
        notes: 'Verify zero-trust user_id check on all 3 tables',
        quadrant: EisenhowerQuadrant.doFirst,
        isCompleted: true,
        dueAtMillis: nowMs - hourMs,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q2_1',
        userId: userId,
        title: 'Architect Q4 product roadmap & deep-work milestones',
        notes: 'Block 90m uninterrupted morning session',
        quadrant: EisenhowerQuadrant.schedule,
        isCompleted: false,
        dueAtMillis: nowMs + dayMs,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q3_1',
        userId: userId,
        title: 'Reply to courier delivery confirmation SMS',
        notes: '2-minute quick turnaround',
        quadrant: EisenhowerQuadrant.quickHandle,
        isCompleted: false,
        dueAtMillis: nowMs + (4 * hourMs),
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q4_1',
        userId: userId,
        title: 'Reorganize archived reference bookmarks folder',
        notes: 'Low urgency — defer to weekend cleanup',
        quadrant: EisenhowerQuadrant.defer,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final starterCadences = <CadenceGoal>[
      CadenceGoal(
        id: 'cad_daily_1',
        userId: userId,
        title: 'Morning Top-3 Eisenhower Triage & Hydration',
        notes: 'Lock Q1 priorities before opening messages',
        cadence: CadenceType.daily,
        quadrant: EisenhowerQuadrant.doFirst,
        nextDueAtMillis: DateTime(now.year, now.month, now.day, 9, 0)
            .millisecondsSinceEpoch,
        lastCompletedAtMillis: nowMs - dayMs,
        streakCount: 7,
        reminderHour: 8,
        reminderMinute: 30,
        createdAt: now,
        updatedAt: now,
      ),
      CadenceGoal(
        id: 'cad_bidaily_1',
        userId: userId,
        title: '45m Mobility & Strength Conditioning Session',
        notes: 'Every 2 days — interval rollover from completion date',
        cadence: CadenceType.biDaily,
        quadrant: EisenhowerQuadrant.schedule,
        nextDueAtMillis: DateTime(now.year, now.month, now.day, 18, 0)
            .millisecondsSinceEpoch,
        lastCompletedAtMillis: nowMs - (2 * dayMs),
        streakCount: 4,
        reminderHour: 17,
        reminderMinute: 30,
        createdAt: now,
        updatedAt: now,
      ),
      CadenceGoal(
        id: 'cad_weekly_1',
        userId: userId,
        title: 'Weekly Sprint Retrospective & Inbox Zero Reset',
        notes: 'Preserves weekly calendar weekday anchor',
        cadence: CadenceType.weekly,
        quadrant: EisenhowerQuadrant.schedule,
        nextDueAtMillis: nowMs + (2 * dayMs),
        lastCompletedAtMillis: nowMs - (5 * dayMs),
        streakCount: 5,
        reminderHour: 16,
        reminderMinute: 0,
        createdAt: now,
        updatedAt: now,
      ),
      CadenceGoal(
        id: 'cad_biweekly_1',
        userId: userId,
        title: 'Bi-Weekly Personal Finance & Expense Reconciliation',
        notes: 'Review cashflow, savings rate, and recurring subscriptions',
        cadence: CadenceType.biWeekly,
        quadrant: EisenhowerQuadrant.schedule,
        nextDueAtMillis: nowMs + (6 * dayMs),
        lastCompletedAtMillis: nowMs - (8 * dayMs),
        streakCount: 3,
        reminderHour: 10,
        reminderMinute: 0,
        createdAt: now,
        updatedAt: now,
      ),
      CadenceGoal(
        id: 'cad_monthly_1',
        userId: userId,
        title: 'Monthly Cloud Backup & Security Credential Audit',
        notes: 'Preserves day-of-month anchor across 28–31 day months',
        cadence: CadenceType.monthly,
        quadrant: EisenhowerQuadrant.doFirst,
        nextDueAtMillis: nowMs + (12 * dayMs),
        lastCompletedAtMillis: nowMs - (18 * dayMs),
        streakCount: 6,
        reminderHour: 11,
        reminderMinute: 0,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final starterAppointments = <Appointment>[
      Appointment(
        id: 'appt_urgent_1',
        userId: userId,
        title: 'Product Design Sync with Mobile Engineering Lead',
        locationOrLink: 'Google Meet • meet.google.com/cad-flow-sync',
        notes: 'Review persistent notification escalation on itel Power 70',
        startsAtMillis: nowMs + (15 * 60 * 1000),
        leadMinutes: 15,
        isPersistentAlert: true,
        repingIntervalMinutes: 5,
        alertStatus: AlertStatus.pinging,
        createdAt: now,
        updatedAt: now,
      ),
      Appointment(
        id: 'appt_upcoming_2',
        userId: userId,
        title: 'Dental Checkup & Cleaning — City Medical Center',
        locationOrLink: 'Suite 4B, Westlands Avenue',
        notes: 'Bring insurance card; 30m lead alert enabled',
        startsAtMillis: nowMs + (4 * hourMs),
        leadMinutes: 30,
        isPersistentAlert: true,
        repingIntervalMinutes: 10,
        alertStatus: AlertStatus.scheduled,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    await prefs.setString(
      '$_tasksKeyPrefix$userId',
      jsonEncode(starterTasks.map((t) => t.toMap()).toList()),
    );
    await prefs.setString(
      '$_cadencesKeyPrefix$userId',
      jsonEncode(starterCadences.map((g) => g.toMap()).toList()),
    );
    await prefs.setString(
      '$_appointmentsKeyPrefix$userId',
      jsonEncode(starterAppointments.map((a) => a.toMap()).toList()),
    );
    await prefs.setBool(seededFlag, true);
  }
}

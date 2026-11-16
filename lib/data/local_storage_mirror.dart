import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/enums.dart';
import '../models/task_item.dart';

/// On-device storage mirror that saves Tasks, Routines, Appointments,
/// and first-startup setup preferences locally on the phone.
class LocalStorageMirror {
  static const String _tasksKeyPrefix = 'cf_tasks_v1_';
  static const String _cadencesKeyPrefix = 'cf_cadences_v1_';
  static const String _appointmentsKeyPrefix = 'cf_appointments_v1_';
  static const String _seededKeyPrefix = 'cf_seeded_v1_';
  static const String _onboardingKeyPrefix = 'cf_onboarding_done_v1_';
  static const String _repingMinutesKey = 'cf_default_reping_minutes_v1';
  static const String _aggressiveModeKey = 'cf_aggressive_alerts_enabled_v1';
  static const String _dailyStartHourKey = 'cf_daily_start_hour_v1';
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
    return prefs.getInt(_repingMinutesKey) ?? 5;
  }

  Future<void> setDefaultRepingMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_repingMinutesKey, minutes);
  }

  Future<bool> getAggressiveModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aggressiveModeKey) ?? true;
  }

  Future<void> setAggressiveModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aggressiveModeKey, enabled);
  }

  Future<int> getDailyStartHour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyStartHourKey) ?? 8;
  }

  Future<void> setDailyStartHour(int hour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyStartHourKey, hour);
  }

  Future<bool> isOnboardingCompleted(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_onboardingKeyPrefix$userId') ?? false;
  }

  Future<void> setOnboardingCompleted(String userId, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_onboardingKeyPrefix$userId', completed);
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

  /// Populates friendly, relatable starter items on a user's first session.
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
        title: 'Send project proposal and invoice to client',
        notes: 'Double-check the final numbers before 5:00 PM',
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
        title: 'Share morning update with the team',
        notes: 'Quick summary of what is done and what is next',
        quadrant: EisenhowerQuadrant.doFirst,
        isCompleted: true,
        dueAtMillis: nowMs - hourMs,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q2_1',
        userId: userId,
        title: 'Outline goals and priorities for next week',
        notes: 'Set aside 45 minutes of quiet time tomorrow morning',
        quadrant: EisenhowerQuadrant.schedule,
        isCompleted: false,
        dueAtMillis: nowMs + dayMs,
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q3_1',
        userId: userId,
        title: 'Reply to package delivery text message',
        notes: 'Confirm front-desk drop-off',
        quadrant: EisenhowerQuadrant.quickHandle,
        isCompleted: false,
        dueAtMillis: nowMs + (4 * hourMs),
        createdAt: now,
        updatedAt: now,
      ),
      TaskItem(
        id: 'task_q4_1',
        userId: userId,
        title: 'Clean up saved reading links and bookmarks',
        notes: 'Nice to do over the weekend when free',
        quadrant: EisenhowerQuadrant.defer,
        isCompleted: false,
        dueAtMillis: nowMs + (3 * dayMs),
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final starterCadences = <CadenceGoal>[
      CadenceGoal(
        id: 'cad_daily_1',
        userId: userId,
        title: 'Morning plan & a full glass of water',
        notes: 'Pick your top 3 priorities before checking messages',
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
        title: '45-minute workout & stretching session',
        notes: 'Stay active every two days',
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
        title: 'Weekly review & tidy up workspace',
        notes: 'Clear your desk and plan the week ahead',
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
        title: 'Check personal budget & upcoming bills',
        notes: 'Review spending and savings every two weeks',
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
        title: 'Back up photos & review subscriptions',
        notes: 'Once-a-month digital checkup',
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
        title: 'Catch-up call with Product & Design team',
        locationOrLink: 'Video Call • meet.google.com/team-sync',
        notes: 'Walk through this week\'s launch checklist',
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
        title: 'Dental checkup & cleaning at City Clinic',
        locationOrLink: 'Suite 4B, Main Street',
        notes: 'Arrive 10 minutes early with insurance card',
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

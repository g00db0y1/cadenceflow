import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/local_storage_mirror.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/enums.dart';
import '../models/task_item.dart';

/// Represents an active insistent/aggressive reminder session that continues
/// re-pinging at a fixed interval until acknowledged, snoozed, or completed.
class AggressiveAlertSession {
  const AggressiveAlertSession({
    required this.entityType,
    required this.entityId,
    required this.userId,
    required this.title,
    required this.subtitle,
    required this.badgeTag,
    required this.repingIntervalMinutes,
    required this.pingCount,
    required this.startedAt,
    required this.lastPingAt,
  });

  final String entityType;
  final String entityId;
  final String userId;
  final String title;
  final String subtitle;
  final String badgeTag;
  final int repingIntervalMinutes;
  final int pingCount;
  final DateTime startedAt;
  final DateTime lastPingAt;

  String get key => '$entityType:$entityId';

  AggressiveAlertSession copyWith({
    int? pingCount,
    DateTime? lastPingAt,
    String? subtitle,
  }) {
    return AggressiveAlertSession(
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      title: title,
      subtitle: subtitle ?? this.subtitle,
      badgeTag: badgeTag,
      repingIntervalMinutes: repingIntervalMinutes,
      pingCount: pingCount ?? this.pingCount,
      startedAt: startedAt,
      lastPingAt: lastPingAt ?? this.lastPingAt,
    );
  }
}

/// Top-level background entrypoint invoked by Android when the user taps
/// inline action buttons (`Done`, `Snooze 10m`, `Got It`) directly inside the
/// notification shade while the app is backgrounded or offline.
@pragma('vm:entry-point')
void onBackgroundNotificationAction(NotificationResponse response) async {
  final payloadRaw = response.payload;
  if (payloadRaw == null || payloadRaw.isEmpty) return;

  try {
    final payload = jsonDecode(payloadRaw) as Map<String, dynamic>;
    final entityType = payload['type'] as String?;
    final entityId = payload['id'] as String?;
    final userId = payload['userId'] as String?;
    if (entityType == null || entityId == null || userId == null) return;

    final mirror = LocalStorageMirror();
    final actionId = response.actionId ?? 'ACK_ACTION';

    if (entityType == 'appointment') {
      final appointments = await mirror.loadAppointments(userId);
      final idx = appointments.indexWhere((a) => a.id == entityId);
      if (idx < 0) return;

      final current = appointments[idx];
      final now = DateTime.now();

      if (actionId == ReminderScheduler.actionDone) {
        appointments[idx] = current.copyWith(
          alertStatus: AlertStatus.completed,
          clearSnoozedUntil: true,
          updatedAt: now,
        );
      } else if (actionId == ReminderScheduler.actionSnooze10m) {
        final snoozeUntil =
            now.add(const Duration(minutes: 10)).millisecondsSinceEpoch;
        appointments[idx] = current.copyWith(
          alertStatus: AlertStatus.snoozed,
          snoozedUntilMillis: snoozeUntil,
          updatedAt: now,
        );
      } else {
        appointments[idx] = current.copyWith(
          alertStatus: AlertStatus.acknowledged,
          clearSnoozedUntil: true,
          updatedAt: now,
        );
      }
      await mirror.saveAppointments(userId, appointments);
    } else if (entityType == 'task') {
      final tasks = await mirror.loadTasks(userId);
      final idx = tasks.indexWhere((t) => t.id == entityId);
      if (idx < 0) return;

      final current = tasks[idx];
      final now = DateTime.now();

      if (actionId == ReminderScheduler.actionDone) {
        tasks[idx] = current.copyWith(
          isCompleted: true,
          updatedAt: now,
        );
      } else if (actionId == ReminderScheduler.actionSnooze10m) {
        tasks[idx] = current.copyWith(
          reminderAtMillis:
              now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
          snoozeCount: current.snoozeCount + 1,
          updatedAt: now,
        );
      }
      await mirror.saveTasks(userId, tasks);
    }
  } catch (e) {
    debugPrint('Background notification action handler error: $e');
  }
}

/// Schedules and manages insistent/aggressive persistent notifications, inline
/// shade actions (`Done`, `Snooze 10m`, `Got It`), repeating escalation pings,
/// snooze wake-up timers, and offline alarm restoration.
class ReminderScheduler {
  static const String channelId = 'cadenceflow_aggressive_alerts_v2';
  static const String channelName = 'Insistent Priority Reminders';
  static const String channelDescription =
      'High-priority persistent heads-up alerts with repeating sound, vibration, and inline action buttons.';

  static const String actionDone = 'DONE_ACTION';
  static const String actionSnooze10m = 'SNOOZE_10M_ACTION';
  static const String actionAck = 'ACK_ACTION';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsGranted = true;
  bool _exactAlarmsGranted = true;
  bool _aggressiveModeEnabled = true;

  int _totalPingsDispatched = 0;
  final Map<String, AggressiveAlertSession> _activeSessions = {};
  final Map<String, Timer> _escalationTimers = {};
  final Map<String, Timer> _snoozeTimers = {};

  bool get notificationsGranted => _notificationsGranted;
  bool get exactAlarmsGranted => _exactAlarmsGranted;
  bool get aggressiveModeEnabled => _aggressiveModeEnabled;
  int get totalPingsDispatched => _totalPingsDispatched;
  int get activeEscalationCount => _activeSessions.length;

  List<AggressiveAlertSession> get activeSessions =>
      _activeSessions.values.toList()
        ..sort((a, b) => b.lastPingAt.compareTo(a.lastPingAt));

  AggressiveAlertSession? sessionFor(String entityType, String entityId) =>
      _activeSessions['$entityType:$entityId'];

  void Function(String entityType, String entityId, String actionId)?
      onForegroundAction;

  VoidCallback? onEscalationStateChanged;

  void setAggressiveMode(bool enabled) {
    _aggressiveModeEnabled = enabled;
    if (!enabled) {
      for (final timer in _escalationTimers.values) {
        timer.cancel();
      }
      _escalationTimers.clear();
    }
    onEscalationStateChanged?.call();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          onBackgroundNotificationAction(response);
          final payloadRaw = response.payload;
          if (payloadRaw != null && onForegroundAction != null) {
            final map = jsonDecode(payloadRaw) as Map<String, dynamic>;
            onForegroundAction!(
              (map['type'] ?? '') as String,
              (map['id'] ?? '') as String,
              response.actionId ?? actionAck,
            );
          }
        },
        onDidReceiveBackgroundNotificationResponse:
            onBackgroundNotificationAction,
      );

      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 600, 250, 600, 250, 900]),
          enableLights: true,
          showBadge: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
      _isInitialized = true;
    } catch (e) {
      // Still mark initialized so in-app escalation tracking works in tests.
      _isInitialized = true;
      debugPrint('ReminderScheduler native init fallback: $e');
    }
  }

  /// Requests Android 13+ notification permission and checks exact alarm readiness.
  Future<bool> requestPermissions() async {
    if (kIsWeb) return true;
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final notifResult =
            await androidPlugin.requestNotificationsPermission();
        _notificationsGranted = notifResult ?? true;

        final exactResult = await androidPlugin.canScheduleExactNotifications();
        _exactAlarmsGranted = exactResult ?? true;
      }
    } catch (e) {
      debugPrint('Permission check warning: $e');
    }
    onEscalationStateChanged?.call();
    return _notificationsGranted;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (kIsWeb) return true;
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        _exactAlarmsGranted = granted ?? true;
      }
    } catch (e) {
      debugPrint('Exact alarm request warning: $e');
    }
    onEscalationStateChanged?.call();
    return _exactAlarmsGranted;
  }

  /// Fires an immediate insistent heads-up notification AND starts the repeating
  /// re-ping escalation loop until the user acknowledges, snoozes, or completes it.
  Future<void> triggerSocialStyleAlert({
    required String entityType,
    required String entityId,
    required String userId,
    required String title,
    required String subtitle,
    required String badgeTag,
    int repingIntervalMinutes = 5,
    bool isPersistent = true,
  }) async {
    final key = '$entityType:$entityId';
    _snoozeTimers.remove(key)?.cancel();

    final now = DateTime.now();
    final existing = _activeSessions[key];
    final nextPingCount = (existing?.pingCount ?? 0) + 1;

    final session = AggressiveAlertSession(
      entityType: entityType,
      entityId: entityId,
      userId: userId,
      title: title,
      subtitle: subtitle,
      badgeTag: badgeTag,
      repingIntervalMinutes: repingIntervalMinutes.clamp(1, 60),
      pingCount: nextPingCount,
      startedAt: existing?.startedAt ?? now,
      lastPingAt: now,
    );

    _activeSessions[key] = session;
    _totalPingsDispatched += 1;

    if (isPersistent && _aggressiveModeEnabled) {
      _scheduleEscalationLoop(session);
    }

    onEscalationStateChanged?.call();

    if (kIsWeb || !_isInitialized) return;

    await _dispatchPlatformNotification(
      session: session,
      isPersistent: isPersistent,
    );
  }

  void _scheduleEscalationLoop(AggressiveAlertSession session) {
    final key = session.key;
    _escalationTimers.remove(key)?.cancel();

    final interval = Duration(minutes: session.repingIntervalMinutes);
    _escalationTimers[key] = Timer.periodic(interval, (_) {
      final current = _activeSessions[key];
      if (current == null || !_aggressiveModeEnabled) {
        _escalationTimers.remove(key)?.cancel();
        return;
      }
      final escalated = current.copyWith(
        pingCount: current.pingCount + 1,
        lastPingAt: DateTime.now(),
      );
      _activeSessions[key] = escalated;
      _totalPingsDispatched += 1;
      onEscalationStateChanged?.call();
      _dispatchPlatformNotification(
        session: escalated,
        isPersistent: true,
      );
    });
  }

  /// Advances all active insistent alerts by one escalation cycle immediately
  /// (used for testing aggressive re-pings or user-triggered test alerts).
  Future<void> simulateEscalationTick() async {
    final keys = _activeSessions.keys.toList();
    for (final key in keys) {
      final current = _activeSessions[key];
      if (current == null) continue;
      final escalated = current.copyWith(
        pingCount: current.pingCount + 1,
        lastPingAt: DateTime.now(),
      );
      _activeSessions[key] = escalated;
      _totalPingsDispatched += 1;
      await _dispatchPlatformNotification(
        session: escalated,
        isPersistent: true,
      );
    }
    onEscalationStateChanged?.call();
  }

  /// Schedules a snoozed alert to automatically resume aggressive ringing
  /// once the snooze duration elapses.
  void scheduleSnoozeWakeup({
    required String entityType,
    required String entityId,
    required Duration duration,
    required VoidCallback onWakeup,
  }) {
    final key = '$entityType:$entityId';
    _snoozeTimers.remove(key)?.cancel();
    _snoozeTimers[key] = Timer(duration, () {
      _snoozeTimers.remove(key);
      onWakeup();
    });
  }

  Future<void> _dispatchPlatformNotification({
    required AggressiveAlertSession session,
    required bool isPersistent,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    final notifId = _stableNotificationId(session.entityType, session.entityId);
    final payload = jsonEncode({
      'type': session.entityType,
      'id': session.entityId,
      'userId': session.userId,
    });

    final pingBadge = session.pingCount > 1
        ? '${session.badgeTag} • Reminder #${session.pingCount}'
        : session.badgeTag;

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.max,
      ongoing: isPersistent,
      autoCancel: !isPersistent,
      fullScreenIntent: isPersistent,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 600, 250, 600, 250, 900]),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      subText: pingBadge,
      ticker: 'Reminder: ${session.title}',
      styleInformation: BigTextStyleInformation(
        session.subtitle,
        contentTitle: '🔔 ${session.title}',
        summaryText: pingBadge,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionDone,
          'Mark Done ✓',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionSnooze10m,
          'Snooze 10m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          actionAck,
          'Got It',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    try {
      await _notificationsPlugin.show(
        notifId,
        '🔔 ${session.title}',
        session.subtitle,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Notification dispatch note: $e');
    }
  }

  Future<void> cancelReminder(String entityType, String entityId) async {
    final key = '$entityType:$entityId';
    _activeSessions.remove(key);
    _escalationTimers.remove(key)?.cancel();
    _snoozeTimers.remove(key)?.cancel();
    onEscalationStateChanged?.call();

    if (kIsWeb || !_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(
        _stableNotificationId(entityType, entityId),
      );
    } catch (e) {
      debugPrint('Cancel reminder error: $e');
    }
  }

  void disposeAllTimers() {
    for (final timer in _escalationTimers.values) {
      timer.cancel();
    }
    for (final timer in _snoozeTimers.values) {
      timer.cancel();
    }
    _escalationTimers.clear();
    _snoozeTimers.clear();
  }

  /// Restores active/overdue insistent alerts from [LocalStorageMirror] on
  /// app launch or after device reboot (`BOOT_COMPLETED`).
  Future<void> syncActiveAlertsFromMirror({
    required String userId,
    required List<TaskItem> tasks,
    required List<CadenceGoal> cadenceGoals,
    required List<Appointment> appointments,
    int defaultRepingMinutes = 5,
  }) async {
    for (final appt in appointments) {
      if (appt.alertStatus == AlertStatus.pinging ||
          (appt.isAttentionSeeking() &&
              appt.alertStatus != AlertStatus.snoozed)) {
        await triggerSocialStyleAlert(
          entityType: 'appointment',
          entityId: appt.id,
          userId: userId,
          title: appt.title,
          subtitle: appt.locationOrLink.isNotEmpty
              ? '${appt.locationOrLink} • Repeats every ${appt.repingIntervalMinutes} min'
              : 'Starting soon • Repeats every ${appt.repingIntervalMinutes} min',
          badgeTag: 'URGENT REMINDER',
          repingIntervalMinutes: appt.repingIntervalMinutes,
          isPersistent: appt.isPersistentAlert,
        );
      }
    }

    for (final task in tasks) {
      if (!task.isCompleted && task.isPersistentAlert && task.isOverdue) {
        await triggerSocialStyleAlert(
          entityType: 'task',
          entityId: task.id,
          userId: userId,
          title: task.title,
          subtitle: '${task.quadrant.title} task is overdue',
          badgeTag: 'OVERDUE TASK',
          repingIntervalMinutes: defaultRepingMinutes,
          isPersistent: true,
        );
      }
    }
  }

  int _stableNotificationId(String entityType, String entityId) =>
      ('$entityType:$entityId').hashCode.abs() % 1000000;
}

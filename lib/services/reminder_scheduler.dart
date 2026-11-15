import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/local_storage_mirror.dart';
import '../models/appointment.dart';
import '../models/cadence_goal.dart';
import '../models/enums.dart';
import '../models/task_item.dart';

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

/// Schedules and manages social-media-style persistent notifications, inline
/// shade actions (`Done`, `Snooze 10m`, `Got It`), repeating follow-up
/// escalation pings, and offline alarm restoration on Android devices such as
/// the **itel Power 70**.
class ReminderScheduler {
  static const String channelId = 'social_urgent_alerts';
  static const String channelName = 'Social-Style Urgent Alerts';
  static const String channelDescription =
      'High-priority persistent heads-up alerts with repeating escalation pings and inline Done/Snooze actions.';

  static const String actionDone = 'DONE_ACTION';
  static const String actionSnooze10m = 'SNOOZE_10M_ACTION';
  static const String actionAck = 'ACK_ACTION';

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool _notificationsGranted = true;
  bool _exactAlarmsGranted = true;

  bool get notificationsGranted => _notificationsGranted;
  bool get exactAlarmsGranted => _exactAlarmsGranted;

  void Function(String entityType, String entityId, String actionId)?
      onForegroundAction;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
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
        const channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
      _isInitialized = true;
    } catch (e) {
      debugPrint('ReminderScheduler initialize skipped in test/host env: $e');
    }
  }

  /// Requests Android 13+ `POST_NOTIFICATIONS` and checks Android 12+
  /// `SCHEDULE_EXACT_ALARM` readiness without blocking core app usage.
  Future<void> requestPermissions() async {
    if (kIsWeb) return;
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
  }

  Future<void> requestExactAlarmPermission() async {
    if (kIsWeb) return;
    try {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestExactAlarmsPermission();
        _exactAlarmsGranted = granted ?? false;
      }
    } catch (e) {
      debugPrint('Exact alarm request warning: $e');
    }
  }

  /// Fires an immediate social-media-style persistent heads-up alert with inline
  /// `Done`, `Snooze 10m`, and `Got It` action buttons.
  Future<void> triggerSocialStyleAlert({
    required String entityType,
    required String entityId,
    required String userId,
    required String title,
    required String subtitle,
    required String badgeTag,
    bool isPersistent = true,
  }) async {
    if (kIsWeb || !_isInitialized) return;

    final notifId = _stableNotificationId(entityType, entityId);
    final payload = jsonEncode({
      'type': entityType,
      'id': entityId,
      'userId': userId,
    });

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: isPersistent,
      autoCancel: !isPersistent,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      subText: badgeTag,
      ticker: 'CadenceFlow Alert: $title',
      styleInformation: BigTextStyleInformation(
        subtitle,
        contentTitle: '🔔 $title',
        summaryText: badgeTag,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          actionDone,
          'Done ✓',
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
        '🔔 $title',
        subtitle,
        NotificationDetails(android: androidDetails),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  Future<void> cancelReminder(String entityType, String entityId) async {
    if (kIsWeb || !_isInitialized) return;
    try {
      await _notificationsPlugin.cancel(
        _stableNotificationId(entityType, entityId),
      );
    } catch (e) {
      debugPrint('Cancel reminder error: $e');
    }
  }

  /// Restores active/overdue persistent alerts from [LocalStorageMirror] on
  /// app launch or after device reboot (`BOOT_COMPLETED`).
  Future<void> syncActiveAlertsFromMirror({
    required String userId,
    required List<TaskItem> tasks,
    required List<CadenceGoal> cadenceGoals,
    required List<Appointment> appointments,
  }) async {
    for (final appt in appointments) {
      if (appt.alertStatus == AlertStatus.pinging) {
        await triggerSocialStyleAlert(
          entityType: 'appointment',
          entityId: appt.id,
          userId: userId,
          title: appt.title,
          subtitle: appt.locationOrLink.isNotEmpty
              ? '${appt.locationOrLink} • Re-pings every ${appt.repingIntervalMinutes}m'
              : 'Appointment starting soon • Re-pings every ${appt.repingIntervalMinutes}m',
          badgeTag: 'URGENT APPOINTMENT PING',
          isPersistent: appt.isPersistentAlert,
        );
      }
    }
  }

  int _stableNotificationId(String entityType, String entityId) =>
      ('$entityType:$entityId').hashCode.abs() % 1000000;
}

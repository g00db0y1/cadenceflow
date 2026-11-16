import 'package:cadenceflow/data/local_storage_mirror.dart';
import 'package:cadenceflow/data/productivity_repository.dart';
import 'package:cadenceflow/models/enums.dart';
import 'package:cadenceflow/services/reminder_scheduler.dart';
import 'package:cadenceflow/state/productivity_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProductivityController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final mirror = LocalStorageMirror();
    final repo = ProductivityRepository(localMirror: mirror);
    final scheduler = ReminderScheduler();
    await scheduler.initialize();
    controller = ProductivityController(
      repository: repo,
      reminderScheduler: scheduler,
    );
    await controller.bindUserAndHydrate('user_controller_test');
  });

  tearDown(() {
    controller.reminderScheduler.disposeAllTimers();
  });

  group('ProductivityController — Priority, Calendar, Routines & Aggressive Alerts', () {
    test('creates task, moves priority group, and ranks queue Do First -> For Later',
        () async {
      final created = await controller.createTask(
        title: 'Prepare client presentation',
        quadrant: EisenhowerQuadrant.defer,
      );
      expect(
        controller.tasks.any((t) => t.id == created.id),
        isTrue,
      );

      await controller.moveTaskQuadrant(created, EisenhowerQuadrant.doFirst);
      final updated =
          controller.tasks.firstWhere((t) => t.id == created.id);
      expect(updated.quadrant, EisenhowerQuadrant.doFirst);

      final activeQueue = controller.rankedPriorityQueue
          .where((t) => !t.isCompleted)
          .toList();
      expect(activeQueue.first.quadrant, EisenhowerQuadrant.doFirst);
    });

    test('completes routine cycle and restores previous state on Undo',
        () async {
      final goal = controller.cadenceGoals.first;
      final initialStreak = goal.streakCount;
      final initialDue = goal.nextDueAtMillis;

      final previousState = await controller.completeCadenceCycle(goal);
      final rolledOver =
          controller.cadenceGoals.firstWhere((g) => g.id == goal.id);
      expect(rolledOver.streakCount, initialStreak + 1);
      expect(rolledOver.nextDueAtMillis, greaterThan(initialDue));

      await controller.restoreCadenceGoalState(previousState);
      final restored =
          controller.cadenceGoals.firstWhere((g) => g.id == goal.id);
      expect(restored.streakCount, initialStreak);
      expect(restored.nextDueAtMillis, initialDue);
    });

    test('aggressive notifications escalate ping count and stop when acknowledged or snoozed',
        () async {
      final appt = controller.appointments.first;

      await controller.triggerNowPing(appt);
      final session1 =
          controller.reminderScheduler.sessionFor('appointment', appt.id);
      expect(session1, isNotNull);
      expect(session1!.pingCount, greaterThanOrEqualTo(1));

      final beforeCount = session1.pingCount;
      await controller.reminderScheduler.simulateEscalationTick();
      final session2 =
          controller.reminderScheduler.sessionFor('appointment', appt.id);
      expect(session2!.pingCount, beforeCount + 1);

      await controller.snoozeAppointment(appt, minutes: 10);
      var current =
          controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.snoozed);
      expect(current.snoozedUntilMillis, isNotNull);
      expect(
        controller.reminderScheduler.sessionFor('appointment', appt.id),
        isNull,
      );

      await controller.acknowledgeAppointment(current);
      current = controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.acknowledged);

      await controller.completeAppointment(current);
      current = controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.completed);
    });

    test('calendar daily, weekly, and monthly views filter tasks, routines, and appointments',
        () async {
      final today = DateTime.now();
      controller.selectCalendarDate(today);

      expect(controller.tasksForDate(today), isNotEmpty);
      expect(controller.routinesForDate(today), isNotEmpty);
      expect(controller.appointmentsForDate(today), isNotEmpty);

      controller.setCalendarViewMode(CalendarViewMode.daily);
      expect(controller.calendarViewMode, CalendarViewMode.daily);
      controller.stepCalendarPeriod(1);
      expect(
        ProductivityController.isSameCalendarDay(
          controller.selectedCalendarDate,
          today.add(const Duration(days: 1)),
        ),
        isTrue,
      );

      controller.jumpToToday();
      controller.setCalendarViewMode(CalendarViewMode.weekly);
      controller.stepCalendarPeriod(1);
      expect(
        ProductivityController.isSameCalendarDay(
          controller.selectedCalendarDate,
          today.add(const Duration(days: 7)),
        ),
        isTrue,
      );
    });

    test('first-startup setup walkthrough saves onboarding state and preferences',
        () async {
      expect(controller.isOnboardingCompleted, isFalse);

      await controller.completeOnboarding(
        repingMinutes: 10,
        aggressiveEnabled: true,
        dailyStartHour: 7,
        selectedThemeMode: ThemeMode.dark,
      );

      expect(controller.isOnboardingCompleted, isTrue);
      expect(controller.defaultRepingMinutes, 10);
      expect(controller.dailyStartHour, 7);
      expect(controller.themeMode, ThemeMode.dark);

      await controller.reopenOnboardingWizard();
      expect(controller.isOnboardingCompleted, isFalse);
    });
  });
}

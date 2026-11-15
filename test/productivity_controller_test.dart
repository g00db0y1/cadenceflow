import 'package:cadenceflow/data/local_storage_mirror.dart';
import 'package:cadenceflow/data/productivity_repository.dart';
import 'package:cadenceflow/models/enums.dart';
import 'package:cadenceflow/services/reminder_scheduler.dart';
import 'package:cadenceflow/state/productivity_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ProductivityController controller;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final mirror = LocalStorageMirror();
    final repo = ProductivityRepository(localMirror: mirror);
    final scheduler = ReminderScheduler();
    controller = ProductivityController(
      repository: repo,
      reminderScheduler: scheduler,
    );
    await controller.bindUserAndHydrate('user_controller_test');
  });

  group('ProductivityController — Matrix, Cadences & Persistent Alerts', () {
    test('creates task, moves quadrant, and ranks priority queue Q1 -> Q4',
        () async {
      final created = await controller.createTask(
        title: 'Critical Server Patch',
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

    test('completes cadence cycle and restores previous state on Undo',
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

    test('snoozes, acknowledges, and completes persistent appointment alerts',
        () async {
      final appt = controller.appointments.first;

      await controller.snoozeAppointment(appt, minutes: 10);
      var current =
          controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.snoozed);
      expect(current.snoozedUntilMillis, isNotNull);

      await controller.acknowledgeAppointment(current);
      current = controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.acknowledged);

      await controller.completeAppointment(current);
      current = controller.appointments.firstWhere((a) => a.id == appt.id);
      expect(current.alertStatus, AlertStatus.completed);
    });
  });
}

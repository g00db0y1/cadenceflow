import 'package:cadenceflow/data/local_storage_mirror.dart';
import 'package:cadenceflow/data/productivity_repository.dart';
import 'package:cadenceflow/models/appointment.dart';
import 'package:cadenceflow/models/cadence_goal.dart';
import 'package:cadenceflow/models/enums.dart';
import 'package:cadenceflow/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Supabase & Local Storage Model Serialization', () {
    test('TaskItem round-trips through toMap and fromMap', () {
      final now = DateTime.now();
      final task = TaskItem(
        id: 'task_test_1',
        userId: 'user_2p9xClerk',
        title: 'Ship CadenceFlow v1',
        notes: 'Verify RLS policies',
        quadrant: EisenhowerQuadrant.doFirst,
        isCompleted: false,
        dueAtMillis: 1763220000000,
        isPersistentAlert: true,
        snoozeCount: 2,
        createdAt: now,
        updatedAt: now,
      );

      final map = task.toMap();
      expect(map['user_id'], 'user_2p9xClerk');
      expect(map['quadrant'], 'DO_FIRST');

      final restored = TaskItem.fromMap(map);
      expect(restored.id, task.id);
      expect(restored.userId, task.userId);
      expect(restored.title, task.title);
      expect(restored.quadrant, EisenhowerQuadrant.doFirst);
      expect(restored.snoozeCount, 2);
      expect(restored.isPersistentAlert, isTrue);
    });

    test('CadenceGoal round-trips through toMap and fromMap', () {
      final now = DateTime.now();
      final goal = CadenceGoal(
        id: 'cad_test_1',
        userId: 'user_2p9xClerk',
        title: 'Bi-Daily Workout',
        cadence: CadenceType.biDaily,
        quadrant: EisenhowerQuadrant.schedule,
        nextDueAtMillis: 1763220000000,
        streakCount: 9,
        createdAt: now,
        updatedAt: now,
      );

      final restored = CadenceGoal.fromMap(goal.toMap());
      expect(restored.cadence, CadenceType.biDaily);
      expect(restored.quadrant, EisenhowerQuadrant.schedule);
      expect(restored.streakCount, 9);
    });

    test('Appointment round-trips and computes attention status', () {
      final now = DateTime(2026, 11, 15, 12, 0);
      final appt = Appointment(
        id: 'appt_test_1',
        userId: 'user_2p9xClerk',
        title: 'Architecture Review',
        locationOrLink: 'meet.google.com/abc-defg-hij',
        startsAtMillis:
            now.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
        leadMinutes: 15,
        repingIntervalMinutes: 5,
        alertStatus: AlertStatus.pinging,
        createdAt: now,
        updatedAt: now,
      );

      final restored = Appointment.fromMap(appt.toMap());
      expect(restored.alertStatus, AlertStatus.pinging);
      expect(restored.isAttentionSeeking(now), isTrue);
    });

    test('ProductivityRepository seeds and persists offline CRUD in LocalStorageMirror',
        () async {
      final mirror = LocalStorageMirror();
      final repo = ProductivityRepository(localMirror: mirror);
      const userId = 'user_test_offline';

      final initialTasks = await repo.fetchTasks(userId);
      expect(initialTasks, isNotEmpty);

      final now = DateTime.now();
      final customTask = TaskItem(
        id: 'custom_1',
        userId: userId,
        title: 'Offline Mirror Test Task',
        quadrant: EisenhowerQuadrant.quickHandle,
        createdAt: now,
        updatedAt: now,
      );

      await repo.upsertTask(userId, customTask);
      final afterInsert = await repo.fetchTasks(userId);
      expect(afterInsert.any((t) => t.id == 'custom_1'), isTrue);

      await repo.deleteTask(userId, 'custom_1');
      final afterDelete = await repo.fetchTasks(userId);
      expect(afterDelete.any((t) => t.id == 'custom_1'), isFalse);
    });
  });
}

import 'package:cadenceflow/domain/cadence_calculator.dart';
import 'package:cadenceflow/models/cadence_goal.dart';
import 'package:cadenceflow/models/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CadenceCalculator — Hybrid 5-Tier Rollover Engine', () {
    test('DAILY cadence completed late advances 1 day from completion date', () {
      final dueThreeDaysAgo = DateTime(2026, 11, 12, 9, 0);
      final completedToday = DateTime(2026, 11, 15, 14, 30);

      final nextDue = CadenceCalculator.computeNextDueDate(
        cadence: CadenceType.daily,
        currentDueAt: dueThreeDaysAgo,
        completedAt: completedToday,
        reminderHour: 9,
        reminderMinute: 0,
      );

      expect(nextDue, DateTime(2026, 11, 16, 9, 0));
    });

    test('BI_DAILY cadence completed late advances 2 days from completion date',
        () {
      final dueFiveDaysAgo = DateTime(2026, 11, 10, 18, 0);
      final completedToday = DateTime(2026, 11, 15, 19, 15);

      final nextDue = CadenceCalculator.computeNextDueDate(
        cadence: CadenceType.biDaily,
        currentDueAt: dueFiveDaysAgo,
        completedAt: completedToday,
        reminderHour: 18,
        reminderMinute: 0,
      );

      expect(nextDue, DateTime(2026, 11, 17, 18, 0));
    });

    test('WEEKLY cadence preserves weekday anchor when completed late', () {
      // Anchor is Wednesday Nov 4, 2026. Completed on Sunday Nov 15, 2026.
      // Next Wednesday strictly after Nov 15 is Nov 18, 2026.
      final anchorWednesday = DateTime(2026, 11, 4, 16, 0);
      final completedSunday = DateTime(2026, 11, 15, 12, 0);

      final nextDue = CadenceCalculator.computeNextDueDate(
        cadence: CadenceType.weekly,
        currentDueAt: anchorWednesday,
        completedAt: completedSunday,
        reminderHour: 16,
        reminderMinute: 0,
      );

      expect(nextDue, DateTime(2026, 11, 18, 16, 0));
      expect(nextDue.weekday, anchorWednesday.weekday);
    });

    test('BI_WEEKLY cadence steps in 14-day increments preserving weekday', () {
      final anchor = DateTime(2026, 11, 1, 10, 0);
      final completedOnDueDay = DateTime(2026, 11, 1, 11, 0);

      final nextDue = CadenceCalculator.computeNextDueDate(
        cadence: CadenceType.biWeekly,
        currentDueAt: anchor,
        completedAt: completedOnDueDay,
        reminderHour: 10,
        reminderMinute: 0,
      );

      expect(nextDue, DateTime(2026, 11, 15, 10, 0));
    });

    test('MONTHLY cadence clamps Jan 31 to Feb 28 in non-leap year', () {
      final jan31 = DateTime(2026, 1, 31, 11, 0);
      final completedJan31 = DateTime(2026, 1, 31, 12, 0);

      final nextDue = CadenceCalculator.computeNextDueDate(
        cadence: CadenceType.monthly,
        currentDueAt: jan31,
        completedAt: completedJan31,
        reminderHour: 11,
        reminderMinute: 0,
      );

      expect(nextDue, DateTime(2026, 2, 28, 11, 0));
    });

    test('completeCycle increments streakCount and updates lastCompletedAt',
        () {
      final now = DateTime(2026, 11, 15, 9, 0);
      final goal = CadenceGoal(
        id: 'cad_1',
        userId: 'user_clerk_123',
        title: 'Daily Triage',
        cadence: CadenceType.daily,
        quadrant: EisenhowerQuadrant.doFirst,
        nextDueAtMillis: now.millisecondsSinceEpoch,
        streakCount: 4,
        createdAt: now,
        updatedAt: now,
      );

      final updated = CadenceCalculator.completeCycle(goal, completedAt: now);
      expect(updated.streakCount, 5);
      expect(updated.lastCompletedAtMillis, now.millisecondsSinceEpoch);
      expect(
        updated.nextDueDateTime,
        DateTime(2026, 11, 16, 9, 0),
      );
    });
  });
}

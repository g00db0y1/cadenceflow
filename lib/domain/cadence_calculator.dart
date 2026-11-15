import '../models/cadence_goal.dart';
import '../models/enums.dart';

/// Pure Dart 5-Tier Cadence Engine implementing CadenceFlow's hybrid rollover
/// strategy:
///
/// 1. **Interval Cadences (`DAILY`, `BI_DAILY`)**:
///    - Advance relative to the **completion date** when completed late
///      (or from `currentDueAt` when completed early), ensuring overdue daily
///      or bi-daily goals start a clean cycle from today without piling up.
///
/// 2. **Calendar Anchor Cadences (`WEEKLY`, `BI_WEEKLY`, `MONTHLY`)**:
///    - Preserve the original **weekday or day-of-month anchor** by stepping
///      forward from `currentDueAt` in exact calendar increments until the
///      next due date is strictly in the future relative to `completedAt`.
///    - Safely clamps end-of-month dates (e.g., Jan 31 -> Feb 28/29 -> Mar 31).
class CadenceCalculator {
  const CadenceCalculator._();

  /// Computes the updated [CadenceGoal] after the user completes the current cycle.
  static CadenceGoal completeCycle(
    CadenceGoal goal, {
    DateTime? completedAt,
  }) {
    final now = completedAt ?? DateTime.now();
    final nextDue = computeNextDueDate(
      cadence: goal.cadence,
      currentDueAt: DateTime.fromMillisecondsSinceEpoch(goal.nextDueAtMillis),
      completedAt: now,
      reminderHour: goal.reminderHour,
      reminderMinute: goal.reminderMinute,
    );

    return goal.copyWith(
      nextDueAtMillis: nextDue.millisecondsSinceEpoch,
      lastCompletedAtMillis: now.millisecondsSinceEpoch,
      streakCount: goal.streakCount + 1,
      updatedAt: now,
    );
  }

  /// Calculates the next due [DateTime] for a given [CadenceType].
  static DateTime computeNextDueDate({
    required CadenceType cadence,
    required DateTime currentDueAt,
    required DateTime completedAt,
    required int reminderHour,
    required int reminderMinute,
  }) {
    switch (cadence) {
      case CadenceType.daily:
        return _advanceIntervalCadence(
          intervalDays: 1,
          currentDueAt: currentDueAt,
          completedAt: completedAt,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );

      case CadenceType.biDaily:
        return _advanceIntervalCadence(
          intervalDays: 2,
          currentDueAt: currentDueAt,
          completedAt: completedAt,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );

      case CadenceType.weekly:
        return _advanceWeeklyOrBiWeeklyAnchor(
          stepDays: 7,
          currentDueAt: currentDueAt,
          completedAt: completedAt,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );

      case CadenceType.biWeekly:
        return _advanceWeeklyOrBiWeeklyAnchor(
          stepDays: 14,
          currentDueAt: currentDueAt,
          completedAt: completedAt,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );

      case CadenceType.monthly:
        return _advanceMonthlyAnchor(
          currentDueAt: currentDueAt,
          completedAt: completedAt,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
        );
    }
  }

  /// Interval cadences (`DAILY`, `BI_DAILY`) advance from the later of
  /// `currentDueAt` or `completedAt` calendar date so completing a late goal
  /// never schedules the next cycle in the past.
  static DateTime _advanceIntervalCadence({
    required int intervalDays,
    required DateTime currentDueAt,
    required DateTime completedAt,
    required int reminderHour,
    required int reminderMinute,
  }) {
    final dueDay = DateTime(
      currentDueAt.year,
      currentDueAt.month,
      currentDueAt.day,
    );
    final completedDay = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
    );

    final baseDay = completedDay.isAfter(dueDay) ? completedDay : dueDay;
    final targetDay = baseDay.add(Duration(days: intervalDays));

    return DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      reminderHour,
      reminderMinute,
    );
  }

  /// Weekly (7d) and Bi-Weekly (14d) cadences preserve their weekday anchor,
  /// stepping forward in multiples of `stepDays` until strictly after `completedAt`.
  static DateTime _advanceWeeklyOrBiWeeklyAnchor({
    required int stepDays,
    required DateTime currentDueAt,
    required DateTime completedAt,
    required int reminderHour,
    required int reminderMinute,
  }) {
    var candidate = DateTime(
      currentDueAt.year,
      currentDueAt.month,
      currentDueAt.day,
      reminderHour,
      reminderMinute,
    );

    do {
      candidate = DateTime(
        candidate.year,
        candidate.month,
        candidate.day + stepDays,
        reminderHour,
        reminderMinute,
      );
    } while (!candidate.isAfter(completedAt));

    return candidate;
  }

  /// Monthly cadence preserves the anchor day-of-month (clamping 29–31 to the
  /// last valid day of shorter months) and steps forward month-by-month until
  /// strictly after `completedAt`.
  static DateTime _advanceMonthlyAnchor({
    required DateTime currentDueAt,
    required DateTime completedAt,
    required int reminderHour,
    required int reminderMinute,
  }) {
    final anchorDay = currentDueAt.day;
    var year = currentDueAt.year;
    var month = currentDueAt.month;
    late DateTime candidate;

    do {
      month += 1;
      if (month > 12) {
        month = 1;
        year += 1;
      }
      final maxDaysInTargetMonth = _daysInMonth(year, month);
      final clampedDay =
          anchorDay > maxDaysInTargetMonth ? maxDaysInTargetMonth : anchorDay;
      candidate = DateTime(
        year,
        month,
        clampedDay,
        reminderHour,
        reminderMinute,
      );
    } while (!candidate.isAfter(completedAt));

    return candidate;
  }

  static int _daysInMonth(int year, int month) {
    // Day 0 of month + 1 gives the last day of `month`.
    return DateTime(year, month + 1, 0).day;
  }
}

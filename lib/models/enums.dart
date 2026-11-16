import 'package:flutter/material.dart';

/// Four priority groups based on urgency and importance.
enum EisenhowerQuadrant {
  doFirst(
    dbValue: 'DO_FIRST',
    title: 'Do First',
    subtitle: 'Urgent & Important',
    shortTag: 'Do First',
    actionHint: 'Focus on this today',
    rank: 1,
    colorHex: 0xFFE11D48, // Coral Red
  ),
  schedule(
    dbValue: 'SCHEDULE',
    title: 'Plan Ahead',
    subtitle: 'Important, Not Urgent',
    shortTag: 'Plan Ahead',
    actionHint: 'Set aside focused time',
    rank: 2,
    colorHex: 0xFF0D9488, // Deep Teal
  ),
  quickHandle(
    dbValue: 'QUICK_HANDLE',
    title: 'Quick Tasks',
    subtitle: 'Small & Time-Sensitive',
    shortTag: 'Quick Tasks',
    actionHint: 'Wrap up in a few minutes',
    rank: 3,
    colorHex: 0xFFD97706, // Warm Amber
  ),
  defer(
    dbValue: 'DEFER',
    title: 'For Later',
    subtitle: 'Low Priority',
    shortTag: 'For Later',
    actionHint: 'Save for when you have free time',
    rank: 4,
    colorHex: 0xFF64748B, // Cool Slate
  );

  const EisenhowerQuadrant({
    required this.dbValue,
    required this.title,
    required this.subtitle,
    required this.shortTag,
    required this.actionHint,
    required this.rank,
    required this.colorHex,
  });

  final String dbValue;
  final String title;
  final String subtitle;
  final String shortTag;
  final String actionHint;
  final int rank;
  final int colorHex;

  Color get color => Color(colorHex);

  static EisenhowerQuadrant fromDb(String? raw) {
    for (final quadrant in EisenhowerQuadrant.values) {
      if (quadrant.dbValue == raw) return quadrant;
    }
    return EisenhowerQuadrant.doFirst;
  }
}

/// Five scheduling frequencies for recurring routines and goals.
enum CadenceType {
  daily(
    dbValue: 'DAILY',
    label: 'Daily',
    frequencyBadge: 'Every day',
    humanDescription: 'Resets for tomorrow whenever you check it off.',
    approximateDays: 1,
    isIntervalBased: true,
  ),
  biDaily(
    dbValue: 'BI_DAILY',
    label: 'Every 2 Days',
    frequencyBadge: 'Every 2 days',
    humanDescription: 'Gives you a rest day in between each check-in.',
    approximateDays: 2,
    isIntervalBased: true,
  ),
  weekly(
    dbValue: 'WEEKLY',
    label: 'Weekly',
    frequencyBadge: 'Every week',
    humanDescription: 'Stays on the same day of the week each cycle.',
    approximateDays: 7,
    isIntervalBased: false,
  ),
  biWeekly(
    dbValue: 'BI_WEEKLY',
    label: 'Every 2 Weeks',
    frequencyBadge: 'Every 2 weeks',
    humanDescription: 'Repeats every other week on your chosen day.',
    approximateDays: 14,
    isIntervalBased: false,
  ),
  monthly(
    dbValue: 'MONTHLY',
    label: 'Monthly',
    frequencyBadge: 'Every month',
    humanDescription: 'Repeats on the same date every month.',
    approximateDays: 30,
    isIntervalBased: false,
  );

  const CadenceType({
    required this.dbValue,
    required this.label,
    required this.frequencyBadge,
    required this.humanDescription,
    required this.approximateDays,
    required this.isIntervalBased,
  });

  final String dbValue;
  final String label;
  final String frequencyBadge;
  final String humanDescription;
  final int approximateDays;

  /// True for Daily & Every 2 Days (advances from completion date when late).
  /// False for Weekly, Every 2 Weeks & Monthly (preserves weekday/day-of-month).
  final bool isIntervalBased;

  static CadenceType fromDb(String? raw) {
    for (final cadence in CadenceType.values) {
      if (cadence.dbValue == raw) return cadence;
    }
    return CadenceType.daily;
  }
}

/// View modes for the Calendar overview screen.
enum CalendarViewMode {
  daily(
    label: 'Daily',
    subtitle: 'Morning, afternoon & evening breakdown',
  ),
  weekly(
    label: 'Weekly',
    subtitle: '7-day schedule & workload overview',
  ),
  monthly(
    label: 'Monthly',
    subtitle: 'Full month grid & day inspector',
  );

  const CalendarViewMode({
    required this.label,
    required this.subtitle,
  });

  final String label;
  final String subtitle;
}

/// Status for persistent appointment and reminder alerts.
enum AlertStatus {
  scheduled(dbValue: 'SCHEDULED', label: 'Upcoming'),
  pinging(dbValue: 'PINGING', label: 'Ringing Now'),
  snoozed(dbValue: 'SNOOZED', label: 'Snoozed'),
  acknowledged(dbValue: 'ACKNOWLEDGED', label: 'Got It'),
  completed(dbValue: 'COMPLETED', label: 'Done');

  const AlertStatus({
    required this.dbValue,
    required this.label,
  });

  final String dbValue;
  final String label;

  bool get requiresAttention =>
      this == AlertStatus.pinging || this == AlertStatus.snoozed;

  static AlertStatus fromDb(String? raw) {
    for (final status in AlertStatus.values) {
      if (status.dbValue == raw) return status;
    }
    return AlertStatus.scheduled;
  }
}

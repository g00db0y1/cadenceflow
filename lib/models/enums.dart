import 'package:flutter/material.dart';

/// Four actionable quadrants of the Eisenhower Matrix (Urgent vs. Important).
enum EisenhowerQuadrant {
  doFirst(
    dbValue: 'DO_FIRST',
    title: 'Do First',
    subtitle: 'Urgent & Important',
    shortTag: 'Q1 • Do First',
    actionHint: 'Execute today with immediate focus',
    rank: 1,
    colorHex: 0xFFE11D48, // Coral Red
  ),
  schedule(
    dbValue: 'SCHEDULE',
    title: 'Schedule',
    subtitle: 'Not Urgent & Important',
    shortTag: 'Q2 • Schedule',
    actionHint: 'Plan dedicated deep-work blocks',
    rank: 2,
    colorHex: 0xFF0D9488, // Deep Teal
  ),
  quickHandle(
    dbValue: 'QUICK_HANDLE',
    title: 'Quick Handle',
    subtitle: 'Urgent & Not Important',
    shortTag: 'Q3 • Quick Handle',
    actionHint: 'Batch, delegate, or finish in <5m',
    rank: 3,
    colorHex: 0xFFD97706, // Warm Amber
  ),
  defer(
    dbValue: 'DEFER',
    title: 'Defer',
    subtitle: 'Not Urgent & Not Important',
    shortTag: 'Q4 • Defer',
    actionHint: 'Park for later or eliminate clutter',
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

/// Five explicit scheduling horizons for recurring Cadence Goals.
enum CadenceType {
  daily(
    dbValue: 'DAILY',
    label: 'Daily',
    frequencyBadge: 'Every day',
    approximateDays: 1,
    isIntervalBased: true,
  ),
  biDaily(
    dbValue: 'BI_DAILY',
    label: 'Bi-Daily',
    frequencyBadge: 'Every 2 days',
    approximateDays: 2,
    isIntervalBased: true,
  ),
  weekly(
    dbValue: 'WEEKLY',
    label: 'Weekly',
    frequencyBadge: 'Every week',
    approximateDays: 7,
    isIntervalBased: false,
  ),
  biWeekly(
    dbValue: 'BI_WEEKLY',
    label: 'Bi-Weekly',
    frequencyBadge: 'Every 2 weeks',
    approximateDays: 14,
    isIntervalBased: false,
  ),
  monthly(
    dbValue: 'MONTHLY',
    label: 'Monthly',
    frequencyBadge: 'Every month',
    approximateDays: 30,
    isIntervalBased: false,
  );

  const CadenceType({
    required this.dbValue,
    required this.label,
    required this.frequencyBadge,
    required this.approximateDays,
    required this.isIntervalBased,
  });

  final String dbValue;
  final String label;
  final String frequencyBadge;
  final int approximateDays;

  /// True for Daily & Bi-Daily (advances from completion date when late).
  /// False for Weekly, Bi-Weekly & Monthly (preserves calendar weekday/day-of-month anchor).
  final bool isIntervalBased;

  static CadenceType fromDb(String? raw) {
    for (final cadence in CadenceType.values) {
      if (cadence.dbValue == raw) return cadence;
    }
    return CadenceType.daily;
  }
}

/// Lifecycle state for social-media-style persistent appointment alerts.
enum AlertStatus {
  scheduled(dbValue: 'SCHEDULED', label: 'Scheduled'),
  pinging(dbValue: 'PINGING', label: 'Pinging Now'),
  snoozed(dbValue: 'SNOOZED', label: 'Snoozed'),
  acknowledged(dbValue: 'ACKNOWLEDGED', label: 'Acknowledged'),
  completed(dbValue: 'COMPLETED', label: 'Completed');

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

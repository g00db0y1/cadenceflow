import 'enums.dart';

/// Represents a recurring multi-cadence goal (Daily, Bi-Daily, Weekly,
/// Bi-Weekly, Monthly) synced to `public.cadence_goals` in Supabase.
class CadenceGoal {
  const CadenceGoal({
    required this.id,
    required this.userId,
    required this.title,
    this.notes = '',
    required this.cadence,
    required this.quadrant,
    required this.nextDueAtMillis,
    this.lastCompletedAtMillis,
    this.streakCount = 0,
    this.reminderHour = 9,
    this.reminderMinute = 0,
    this.isPersistentAlert = true,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String notes;
  final CadenceType cadence;
  final EisenhowerQuadrant quadrant;
  final int nextDueAtMillis;
  final int? lastCompletedAtMillis;
  final int streakCount;
  final int reminderHour;
  final int reminderMinute;
  final bool isPersistentAlert;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get nextDueDateTime =>
      DateTime.fromMillisecondsSinceEpoch(nextDueAtMillis);

  bool isDueTodayOrOverdue([DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    return nextDueAtMillis <= endOfToday.millisecondsSinceEpoch;
  }

  bool isOverdue([DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    return nextDueAtMillis < now.millisecondsSinceEpoch;
  }

  /// Computes progress (0.0 to 1.0) through the current cadence cycle.
  double cycleProgress([DateTime? referenceNow]) {
    final nowMs = (referenceNow ?? DateTime.now()).millisecondsSinceEpoch;
    final totalCycleMs = cadence.approximateDays * 24 * 60 * 60 * 1000;
    final cycleStartMs = lastCompletedAtMillis ?? (nextDueAtMillis - totalCycleMs);
    final span = nextDueAtMillis - cycleStartMs;
    if (span <= 0) return 1.0;
    final elapsed = nowMs - cycleStartMs;
    return (elapsed / span).clamp(0.0, 1.0);
  }

  CadenceGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? notes,
    CadenceType? cadence,
    EisenhowerQuadrant? quadrant,
    int? nextDueAtMillis,
    int? lastCompletedAtMillis,
    int? streakCount,
    int? reminderHour,
    int? reminderMinute,
    bool? isPersistentAlert,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CadenceGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      cadence: cadence ?? this.cadence,
      quadrant: quadrant ?? this.quadrant,
      nextDueAtMillis: nextDueAtMillis ?? this.nextDueAtMillis,
      lastCompletedAtMillis:
          lastCompletedAtMillis ?? this.lastCompletedAtMillis,
      streakCount: streakCount ?? this.streakCount,
      reminderHour: reminderHour ?? this.reminderHour,
      reminderMinute: reminderMinute ?? this.reminderMinute,
      isPersistentAlert: isPersistentAlert ?? this.isPersistentAlert,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'notes': notes,
      'cadence': cadence.dbValue,
      'quadrant': quadrant.dbValue,
      'next_due_at_millis': nextDueAtMillis,
      'last_completed_at_millis': lastCompletedAtMillis,
      'streak_count': streakCount,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
      'is_persistent_alert': isPersistentAlert,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory CadenceGoal.fromMap(Map<String, dynamic> map) {
    return CadenceGoal(
      id: map['id'] as String,
      userId: (map['user_id'] ?? map['userId'] ?? 'local_user') as String,
      title: (map['title'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      cadence: CadenceType.fromDb(map['cadence'] as String?),
      quadrant: EisenhowerQuadrant.fromDb(map['quadrant'] as String?),
      nextDueAtMillis: _parseInt(
            map['next_due_at_millis'] ?? map['nextDueAtMillis'],
          ) ??
          DateTime.now().millisecondsSinceEpoch,
      lastCompletedAtMillis: _parseInt(
        map['last_completed_at_millis'] ?? map['lastCompletedAtMillis'],
      ),
      streakCount: _parseInt(map['streak_count'] ?? map['streakCount']) ?? 0,
      reminderHour: _parseInt(map['reminder_hour'] ?? map['reminderHour']) ?? 9,
      reminderMinute:
          _parseInt(map['reminder_minute'] ?? map['reminderMinute']) ?? 0,
      isPersistentAlert: _parseBool(
        map['is_persistent_alert'] ?? map['isPersistentAlert'],
        defaultValue: true,
      ),
      isActive: _parseBool(
        map['is_active'] ?? map['isActive'],
        defaultValue: true,
      ),
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDateTime(map['updated_at'] ?? map['updatedAt']),
    );
  }

  static bool _parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is int) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return defaultValue;
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  static DateTime _parseDateTime(dynamic val) {
    if (val is DateTime) return val;
    if (val is String) {
      return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return DateTime.now();
  }
}

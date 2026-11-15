import 'enums.dart';

/// Represents an Eisenhower Matrix task synced to `public.tasks` in Supabase
/// and mirrored in local device storage for offline CRUD & alarm access.
class TaskItem {
  const TaskItem({
    required this.id,
    required this.userId,
    required this.title,
    this.notes = '',
    required this.quadrant,
    this.isCompleted = false,
    this.dueAtMillis,
    this.reminderAtMillis,
    this.isPersistentAlert = false,
    this.snoozeCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String notes;
  final EisenhowerQuadrant quadrant;
  final bool isCompleted;
  final int? dueAtMillis;
  final int? reminderAtMillis;
  final bool isPersistentAlert;
  final int snoozeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOverdue {
    if (isCompleted || dueAtMillis == null) return false;
    return dueAtMillis! < DateTime.now().millisecondsSinceEpoch;
  }

  TaskItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? notes,
    EisenhowerQuadrant? quadrant,
    bool? isCompleted,
    int? dueAtMillis,
    bool clearDueAt = false,
    int? reminderAtMillis,
    bool clearReminderAt = false,
    bool? isPersistentAlert,
    int? snoozeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      quadrant: quadrant ?? this.quadrant,
      isCompleted: isCompleted ?? this.isCompleted,
      dueAtMillis: clearDueAt ? null : (dueAtMillis ?? this.dueAtMillis),
      reminderAtMillis:
          clearReminderAt ? null : (reminderAtMillis ?? this.reminderAtMillis),
      isPersistentAlert: isPersistentAlert ?? this.isPersistentAlert,
      snoozeCount: snoozeCount ?? this.snoozeCount,
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
      'quadrant': quadrant.dbValue,
      'is_completed': isCompleted,
      'due_at_millis': dueAtMillis,
      'reminder_at_millis': reminderAtMillis,
      'is_persistent_alert': isPersistentAlert,
      'snooze_count': snoozeCount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as String,
      userId: (map['user_id'] ?? map['userId'] ?? 'local_user') as String,
      title: (map['title'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      quadrant: EisenhowerQuadrant.fromDb(map['quadrant'] as String?),
      isCompleted: _parseBool(map['is_completed'] ?? map['isCompleted']),
      dueAtMillis: _parseInt(map['due_at_millis'] ?? map['dueAtMillis']),
      reminderAtMillis:
          _parseInt(map['reminder_at_millis'] ?? map['reminderAtMillis']),
      isPersistentAlert: _parseBool(
        map['is_persistent_alert'] ?? map['isPersistentAlert'],
      ),
      snoozeCount: _parseInt(map['snooze_count'] ?? map['snoozeCount']) ?? 0,
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDateTime(map['updated_at'] ?? map['updatedAt']),
    );
  }

  static bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is int) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return false;
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

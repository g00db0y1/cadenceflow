import 'enums.dart';

/// Represents a cloud-synced appointment with social-media-style persistent
/// escalation reminders (`public.appointments`).
class Appointment {
  const Appointment({
    required this.id,
    required this.userId,
    required this.title,
    this.locationOrLink = '',
    this.notes = '',
    required this.startsAtMillis,
    this.leadMinutes = 15,
    this.isPersistentAlert = true,
    this.repingIntervalMinutes = 10,
    this.alertStatus = AlertStatus.scheduled,
    this.snoozedUntilMillis,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String locationOrLink;
  final String notes;
  final int startsAtMillis;
  final int leadMinutes;
  final bool isPersistentAlert;
  final int repingIntervalMinutes;
  final AlertStatus alertStatus;
  final int? snoozedUntilMillis;
  final DateTime createdAt;
  final DateTime updatedAt;

  DateTime get startsAtDateTime =>
      DateTime.fromMillisecondsSinceEpoch(startsAtMillis);

  /// Timestamp when the initial reminder alarm should trigger.
  int get initialReminderAtMillis =>
      startsAtMillis - (leadMinutes * 60 * 1000);

  /// Returns true when the appointment reminder is actively pinging, snoozed,
  /// or within its lead-time window without having been acknowledged/completed.
  bool isAttentionSeeking([DateTime? referenceNow]) {
    if (alertStatus == AlertStatus.completed ||
        alertStatus == AlertStatus.acknowledged) {
      return false;
    }
    if (alertStatus == AlertStatus.pinging ||
        alertStatus == AlertStatus.snoozed) {
      return true;
    }
    final nowMs = (referenceNow ?? DateTime.now()).millisecondsSinceEpoch;
    return nowMs >= initialReminderAtMillis;
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? title,
    String? locationOrLink,
    String? notes,
    int? startsAtMillis,
    int? leadMinutes,
    bool? isPersistentAlert,
    int? repingIntervalMinutes,
    AlertStatus? alertStatus,
    int? snoozedUntilMillis,
    bool clearSnoozedUntil = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      locationOrLink: locationOrLink ?? this.locationOrLink,
      notes: notes ?? this.notes,
      startsAtMillis: startsAtMillis ?? this.startsAtMillis,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      isPersistentAlert: isPersistentAlert ?? this.isPersistentAlert,
      repingIntervalMinutes:
          repingIntervalMinutes ?? this.repingIntervalMinutes,
      alertStatus: alertStatus ?? this.alertStatus,
      snoozedUntilMillis: clearSnoozedUntil
          ? null
          : (snoozedUntilMillis ?? this.snoozedUntilMillis),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'location_or_link': locationOrLink,
      'notes': notes,
      'starts_at_millis': startsAtMillis,
      'lead_minutes': leadMinutes,
      'is_persistent_alert': isPersistentAlert,
      'reping_interval_minutes': repingIntervalMinutes,
      'alert_status': alertStatus.dbValue,
      'snoozed_until_millis': snoozedUntilMillis,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as String,
      userId: (map['user_id'] ?? map['userId'] ?? 'local_user') as String,
      title: (map['title'] ?? '') as String,
      locationOrLink:
          (map['location_or_link'] ?? map['locationOrLink'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
      startsAtMillis: _parseInt(
            map['starts_at_millis'] ?? map['startsAtMillis'],
          ) ??
          DateTime.now().millisecondsSinceEpoch,
      leadMinutes: _parseInt(map['lead_minutes'] ?? map['leadMinutes']) ?? 15,
      isPersistentAlert: _parseBool(
        map['is_persistent_alert'] ?? map['isPersistentAlert'],
        defaultValue: true,
      ),
      repingIntervalMinutes: _parseInt(
            map['reping_interval_minutes'] ?? map['repingIntervalMinutes'],
          ) ??
          10,
      alertStatus: AlertStatus.fromDb(
        (map['alert_status'] ?? map['alertStatus']) as String?,
      ),
      snoozedUntilMillis: _parseInt(
        map['snoozed_until_millis'] ?? map['snoozedUntilMillis'],
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

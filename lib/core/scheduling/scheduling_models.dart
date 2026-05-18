import 'package:mega_panel_ai/core/treatments/treatment.dart';

enum SessionStatus {
  completed,
  skipped,
}

class PlannedSession {
  const PlannedSession({
    required this.treatmentId,
    required this.dateKey,
    required this.momentLabel,
  });

  final String treatmentId;
  final String dateKey;
  final String momentLabel;

  Map<String, dynamic> toJson() => {
        'treatmentId': treatmentId,
        'dateKey': dateKey,
        'momentLabel': momentLabel,
      };

  factory PlannedSession.fromJson(Map<String, dynamic> json) {
    return PlannedSession(
      treatmentId: json['treatmentId'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      momentLabel: json['momentLabel'] as String? ?? 'Planned',
    );
  }
}

class SessionHistoryEntry {
  const SessionHistoryEntry({
    required this.id,
    required this.treatmentId,
    required this.loggedAtIso,
    required this.dateKey,
    required this.status,
    required this.momentLabel,
  });

  final String id;
  final String treatmentId;
  final String loggedAtIso;
  final String dateKey;
  final SessionStatus status;
  final String momentLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'treatmentId': treatmentId,
        'loggedAtIso': loggedAtIso,
        'dateKey': dateKey,
        'status': status.name,
        'momentLabel': momentLabel,
      };

  factory SessionHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? SessionStatus.completed.name;
    return SessionHistoryEntry(
      id: json['id'] as String? ?? '',
      treatmentId: json['treatmentId'] as String? ?? '',
      loggedAtIso: json['loggedAtIso'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      status: rawStatus == SessionStatus.skipped.name
          ? SessionStatus.skipped
          : SessionStatus.completed,
      momentLabel: json['momentLabel'] as String? ?? 'Tracked',
    );
  }
}

enum ReminderLeadTime {
  sameDay,
  dayBefore,
}

extension ReminderLeadTimeX on ReminderLeadTime {
  String get label {
    switch (this) {
      case ReminderLeadTime.sameDay:
        return 'Same day';
      case ReminderLeadTime.dayBefore:
        return '1 day before';
    }
  }

  int get daysOffset {
    switch (this) {
      case ReminderLeadTime.sameDay:
        return 0;
      case ReminderLeadTime.dayBefore:
        return 1;
    }
  }
}

class ReminderPreference {
  const ReminderPreference({
    required this.id,
    required this.leadTime,
    required this.hour,
    required this.minute,
    this.enabled = true,
  });

  final String id;
  final ReminderLeadTime leadTime;
  final int hour;
  final int minute;
  final bool enabled;

  String get timeLabel {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String get summary => '${leadTime.label} at $timeLabel';

  ReminderPreference copyWith({
    ReminderLeadTime? leadTime,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return ReminderPreference(
      id: id,
      leadTime: leadTime ?? this.leadTime,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'leadTime': leadTime.name,
        'hour': hour,
        'minute': minute,
        'enabled': enabled,
      };

  factory ReminderPreference.fromJson(Map<String, dynamic> json) {
    final rawLeadTime =
        json['leadTime'] as String? ?? ReminderLeadTime.sameDay.name;
    return ReminderPreference(
      id: json['id'] as String? ?? '',
      leadTime: rawLeadTime == ReminderLeadTime.dayBefore.name
          ? ReminderLeadTime.dayBefore
          : ReminderLeadTime.sameDay,
      hour: (json['hour'] as num?)?.toInt() ?? 9,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.reminders,
  });

  final bool enabled;
  final List<ReminderPreference> reminders;

  ReminderSettings copyWith({
    bool? enabled,
    List<ReminderPreference>? reminders,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      reminders: reminders ?? this.reminders,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'reminders': reminders.map((entry) => entry.toJson()).toList(),
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    final reminderList = (json['reminders'] as List? ?? const [])
        .map((entry) => ReminderPreference.fromJson(
            Map<String, dynamic>.from(entry as Map)))
        .toList();
    return ReminderSettings(
      enabled: json['enabled'] as bool? ?? false,
      reminders: reminderList,
    );
  }
}

class ResolvedPlannedSession {
  const ResolvedPlannedSession({
    required this.treatment,
    required this.session,
    required this.date,
  });

  final WellnessTreatment treatment;
  final PlannedSession session;
  final DateTime date;
}

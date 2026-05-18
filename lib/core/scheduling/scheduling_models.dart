enum SessionStatus {
  completed,
  skipped,
}

class PlannedSession {
  const PlannedSession({
    required this.treatmentId,
    required this.dateKey,
    required this.momentLabel,
    this.reminderPlaceholder = 'Reminder placeholder',
  });

  final String treatmentId;
  final String dateKey;
  final String momentLabel;
  final String reminderPlaceholder;

  Map<String, dynamic> toJson() => {
        'treatmentId': treatmentId,
        'dateKey': dateKey,
        'momentLabel': momentLabel,
        'reminderPlaceholder': reminderPlaceholder,
      };

  factory PlannedSession.fromJson(Map<String, dynamic> json) {
    return PlannedSession(
      treatmentId: json['treatmentId'] as String? ?? '',
      dateKey: json['dateKey'] as String? ?? '',
      momentLabel: json['momentLabel'] as String? ?? 'Planned',
      reminderPlaceholder:
          json['reminderPlaceholder'] as String? ?? 'Reminder placeholder',
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

class WeeklyRoutine {
  const WeeklyRoutine({
    required this.weekday,
    required this.focusLabel,
    required this.cardioLabel,
  });

  final int weekday;
  final String focusLabel;
  final String cardioLabel;

  WeeklyRoutine copyWith({
    String? focusLabel,
    String? cardioLabel,
  }) {
    return WeeklyRoutine(
      weekday: weekday,
      focusLabel: focusLabel ?? this.focusLabel,
      cardioLabel: cardioLabel ?? this.cardioLabel,
    );
  }

  Map<String, dynamic> toJson() => {
        'weekday': weekday,
        'focusLabel': focusLabel,
        'cardioLabel': cardioLabel,
      };

  factory WeeklyRoutine.fromJson(Map<String, dynamic> json) {
    return WeeklyRoutine(
      weekday: (json['weekday'] as num?)?.toInt() ?? 1,
      focusLabel: json['focusLabel'] as String? ?? '',
      cardioLabel: json['cardioLabel'] as String? ?? '',
    );
  }
}

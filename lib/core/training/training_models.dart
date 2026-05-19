enum TrainingType {
  hiit,
  yogaPilates,
  upperBodyStrength,
  lowerBodyStrength,
  cardio,
}

enum TrainingRelation {
  independent,
  beforeTraining,
  afterTraining,
}

enum TrainingCompatibilityStatus {
  generallyCompatible,
  compatibleWithCaution,
  limitedEvidence,
  waitUntilRecovered,
}

class RecentTrainingSession {
  const RecentTrainingSession({
    required this.type,
    required this.performedAtIso,
    this.exampleKey,
  });

  final TrainingType type;
  final String performedAtIso;
  final String? exampleKey;

  DateTime get performedAt => DateTime.parse(performedAtIso);

  RecentTrainingSession copyWith({
    TrainingType? type,
    String? performedAtIso,
    String? exampleKey,
  }) {
    return RecentTrainingSession(
      type: type ?? this.type,
      performedAtIso: performedAtIso ?? this.performedAtIso,
      exampleKey: exampleKey ?? this.exampleKey,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'performedAtIso': performedAtIso,
        'exampleKey': exampleKey,
      };

  factory RecentTrainingSession.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? TrainingType.cardio.name;
    return RecentTrainingSession(
      type: TrainingType.values.firstWhere(
        (entry) => entry.name == rawType,
        orElse: () => TrainingType.cardio,
      ),
      performedAtIso:
          json['performedAtIso'] as String? ?? DateTime.now().toIso8601String(),
      exampleKey: json['exampleKey'] as String?,
    );
  }
}

class TrainingReference {
  const TrainingReference({
    required this.label,
    required this.url,
  });

  final String label;
  final String url;
}

class TreatmentTrainingGuidance {
  const TreatmentTrainingGuidance({
    required this.trainingType,
    required this.beforeStatus,
    required this.afterStatus,
    required this.beforeTrainingNote,
    required this.afterTrainingNote,
    required this.sourceReferences,
    this.preferredLeadMinutes,
    this.preferredRecoveryMinutes,
  });

  final TrainingType trainingType;
  final TrainingCompatibilityStatus beforeStatus;
  final TrainingCompatibilityStatus afterStatus;
  final String beforeTrainingNote;
  final String afterTrainingNote;
  final List<TrainingReference> sourceReferences;
  final int? preferredLeadMinutes;
  final int? preferredRecoveryMinutes;
}

class TrainingCompatibilityAssessment {
  const TrainingCompatibilityAssessment({
    required this.training,
    required this.status,
    required this.relation,
    required this.referenceTime,
    required this.elapsedSinceTraining,
    required this.summary,
    required this.detail,
    required this.sourceReferences,
    this.waitRemaining,
  });

  final RecentTrainingSession training;
  final TrainingCompatibilityStatus status;
  final TrainingRelation relation;
  final DateTime referenceTime;
  final Duration elapsedSinceTraining;
  final String summary;
  final String detail;
  final List<TrainingReference> sourceReferences;
  final Duration? waitRemaining;
}

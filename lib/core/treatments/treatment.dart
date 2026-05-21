import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/evidence/training_compatibility.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';

enum TreatmentOrigin {
  curated,
  aiDraft,
  userTreatment,
}

class TreatmentIntensity {
  const TreatmentIntensity({
    required this.wavelengthNm,
    required this.percentage,
  });

  final int wavelengthNm;
  final int percentage;

  Map<String, dynamic> toJson() => {
        'wavelengthNm': wavelengthNm,
        'percentage': percentage,
      };

  factory TreatmentIntensity.fromJson(Map<String, dynamic> json) {
    return TreatmentIntensity(
      wavelengthNm: (json['wavelengthNm'] as num?)?.toInt() ?? 660,
      percentage: (json['percentage'] as num?)?.toInt() ?? 100,
    );
  }
}

class TreatmentCourseGuidance {
  const TreatmentCourseGuidance({
    required this.minSessions,
    required this.maxSessions,
    required this.recommendedSessions,
    required this.recommendedSpacingDays,
    required this.summaryEs,
    required this.summaryEn,
  }) : assert(minSessions > 0),
       assert(maxSessions >= minSessions),
       assert(recommendedSessions >= minSessions),
       assert(recommendedSessions <= maxSessions),
       assert(recommendedSpacingDays > 0);

  final int minSessions;
  final int maxSessions;
  final int recommendedSessions;
  final int recommendedSpacingDays;
  final String summaryEs;
  final String summaryEn;

  String summary(bool isSpanish) => isSpanish ? summaryEs : summaryEn;

  Map<String, dynamic> toJson() => {
        'minSessions': minSessions,
        'maxSessions': maxSessions,
        'recommendedSessions': recommendedSessions,
        'recommendedSpacingDays': recommendedSpacingDays,
        'summaryEs': summaryEs,
        'summaryEn': summaryEn,
      };

  factory TreatmentCourseGuidance.fromJson(Map<String, dynamic> json) {
    return TreatmentCourseGuidance(
      minSessions: (json['minSessions'] as num?)?.toInt() ?? 1,
      maxSessions: (json['maxSessions'] as num?)?.toInt() ?? 1,
      recommendedSessions: (json['recommendedSessions'] as num?)?.toInt() ?? 1,
      recommendedSpacingDays:
          (json['recommendedSpacingDays'] as num?)?.toInt() ?? 1,
      summaryEs: json['summaryEs'] as String? ?? '',
      summaryEn: json['summaryEn'] as String? ?? '',
    );
  }
}

class WellnessTreatment {
  const WellnessTreatment({
    required this.id,
    required this.titleEs,
    required this.titleEn,
    required this.categoryEs,
    required this.categoryEn,
    required this.goalEs,
    required this.goalEn,
    required this.summaryEs,
    required this.summaryEn,
    required this.durationMinutes,
    required this.distanceGuidanceEs,
    required this.distanceGuidanceEn,
    required this.pulseGuidanceEs,
    required this.pulseGuidanceEn,
    required this.intensityDistribution,
    required this.evidenceLevel,
    required this.safetyNotesEs,
    required this.safetyNotesEn,
    required this.sourceReferencesEs,
    required this.sourceReferencesEn,
    required this.beforeSessionTipsEs,
    required this.beforeSessionTipsEn,
    required this.afterSessionTipsEs,
    required this.afterSessionTipsEn,
    required this.trainingGuidance,
    this.courseGuidance,
    this.origin = TreatmentOrigin.curated,
    this.originSearchQuery,
    this.originNoteEs,
    this.originNoteEn,
    this.generatedAtIso,
  });

  final String id;
  final String titleEs;
  final String titleEn;
  final String categoryEs;
  final String categoryEn;
  final String goalEs;
  final String goalEn;
  final String summaryEs;
  final String summaryEn;
  final int durationMinutes;
  final String distanceGuidanceEs;
  final String distanceGuidanceEn;
  final String pulseGuidanceEs;
  final String pulseGuidanceEn;
  final List<TreatmentIntensity> intensityDistribution;
  final EvidenceLevel evidenceLevel;
  final List<String> safetyNotesEs;
  final List<String> safetyNotesEn;
  final List<String> sourceReferencesEs;
  final List<String> sourceReferencesEn;
  final List<String> beforeSessionTipsEs;
  final List<String> beforeSessionTipsEn;
  final List<String> afterSessionTipsEs;
  final List<String> afterSessionTipsEn;
  final List<TreatmentTrainingGuidance> trainingGuidance;
  final TreatmentCourseGuidance? courseGuidance;
  final TreatmentOrigin origin;
  final String? originSearchQuery;
  final String? originNoteEs;
  final String? originNoteEn;
  final String? generatedAtIso;

  String title(bool isSpanish) => isSpanish ? titleEs : titleEn;
  String category(bool isSpanish) => isSpanish ? categoryEs : categoryEn;
  String goal(bool isSpanish) => isSpanish ? goalEs : goalEn;
  String summary(bool isSpanish) => isSpanish ? summaryEs : summaryEn;
  String distanceGuidance(bool isSpanish) =>
      isSpanish ? distanceGuidanceEs : distanceGuidanceEn;
  String pulseGuidance(bool isSpanish) =>
      isSpanish ? pulseGuidanceEs : pulseGuidanceEn;
  List<String> safetyNotes(bool isSpanish) =>
      isSpanish ? safetyNotesEs : safetyNotesEn;
  List<String> sourceReferences(bool isSpanish) =>
      isSpanish ? sourceReferencesEs : sourceReferencesEn;
  List<String> beforeSessionTips(bool isSpanish) =>
      isSpanish ? beforeSessionTipsEs : beforeSessionTipsEn;
  List<String> afterSessionTips(bool isSpanish) =>
      isSpanish ? afterSessionTipsEs : afterSessionTipsEn;
  String? originNote(bool isSpanish) => isSpanish ? originNoteEs : originNoteEn;
  bool get supportsStructuredCourse => courseGuidance != null;
  bool get isAiDraft => origin == TreatmentOrigin.aiDraft;
  bool get isUserTreatment => origin == TreatmentOrigin.userTreatment;
  bool get isCuratedTreatment => origin == TreatmentOrigin.curated;

  String get intensitySummary {
    if (intensityDistribution.isEmpty) return 'No intensity guidance';
    return intensityDistribution
        .map((entry) => '${entry.wavelengthNm}nm ${entry.percentage}%')
        .join('  ·  ');
  }

  WellnessTreatment copyWith({
    String? id,
    String? titleEs,
    String? titleEn,
    String? categoryEs,
    String? categoryEn,
    String? goalEs,
    String? goalEn,
    String? summaryEs,
    String? summaryEn,
    int? durationMinutes,
    String? distanceGuidanceEs,
    String? distanceGuidanceEn,
    String? pulseGuidanceEs,
    String? pulseGuidanceEn,
    List<TreatmentIntensity>? intensityDistribution,
    EvidenceLevel? evidenceLevel,
    List<String>? safetyNotesEs,
    List<String>? safetyNotesEn,
    List<String>? sourceReferencesEs,
    List<String>? sourceReferencesEn,
    List<String>? beforeSessionTipsEs,
    List<String>? beforeSessionTipsEn,
    List<String>? afterSessionTipsEs,
    List<String>? afterSessionTipsEn,
    List<TreatmentTrainingGuidance>? trainingGuidance,
    TreatmentCourseGuidance? courseGuidance,
    TreatmentOrigin? origin,
    String? originSearchQuery,
    String? originNoteEs,
    String? originNoteEn,
    String? generatedAtIso,
  }) {
    return WellnessTreatment(
      id: id ?? this.id,
      titleEs: titleEs ?? this.titleEs,
      titleEn: titleEn ?? this.titleEn,
      categoryEs: categoryEs ?? this.categoryEs,
      categoryEn: categoryEn ?? this.categoryEn,
      goalEs: goalEs ?? this.goalEs,
      goalEn: goalEn ?? this.goalEn,
      summaryEs: summaryEs ?? this.summaryEs,
      summaryEn: summaryEn ?? this.summaryEn,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      distanceGuidanceEs: distanceGuidanceEs ?? this.distanceGuidanceEs,
      distanceGuidanceEn: distanceGuidanceEn ?? this.distanceGuidanceEn,
      pulseGuidanceEs: pulseGuidanceEs ?? this.pulseGuidanceEs,
      pulseGuidanceEn: pulseGuidanceEn ?? this.pulseGuidanceEn,
      intensityDistribution:
          intensityDistribution ?? this.intensityDistribution,
      evidenceLevel: evidenceLevel ?? this.evidenceLevel,
      safetyNotesEs: safetyNotesEs ?? this.safetyNotesEs,
      safetyNotesEn: safetyNotesEn ?? this.safetyNotesEn,
      sourceReferencesEs: sourceReferencesEs ?? this.sourceReferencesEs,
      sourceReferencesEn: sourceReferencesEn ?? this.sourceReferencesEn,
      beforeSessionTipsEs: beforeSessionTipsEs ?? this.beforeSessionTipsEs,
      beforeSessionTipsEn: beforeSessionTipsEn ?? this.beforeSessionTipsEn,
      afterSessionTipsEs: afterSessionTipsEs ?? this.afterSessionTipsEs,
      afterSessionTipsEn: afterSessionTipsEn ?? this.afterSessionTipsEn,
      trainingGuidance: trainingGuidance ?? this.trainingGuidance,
      courseGuidance: courseGuidance ?? this.courseGuidance,
      origin: origin ?? this.origin,
      originSearchQuery: originSearchQuery ?? this.originSearchQuery,
      originNoteEs: originNoteEs ?? this.originNoteEs,
      originNoteEn: originNoteEn ?? this.originNoteEn,
      generatedAtIso: generatedAtIso ?? this.generatedAtIso,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'titleEs': titleEs,
        'titleEn': titleEn,
        'categoryEs': categoryEs,
        'categoryEn': categoryEn,
        'goalEs': goalEs,
        'goalEn': goalEn,
        'summaryEs': summaryEs,
        'summaryEn': summaryEn,
        'durationMinutes': durationMinutes,
        'distanceGuidanceEs': distanceGuidanceEs,
        'distanceGuidanceEn': distanceGuidanceEn,
        'pulseGuidanceEs': pulseGuidanceEs,
        'pulseGuidanceEn': pulseGuidanceEn,
        'intensityDistribution':
            intensityDistribution.map((entry) => entry.toJson()).toList(),
        'evidenceLevel': evidenceLevel.name,
        'safetyNotesEs': safetyNotesEs,
        'safetyNotesEn': safetyNotesEn,
        'sourceReferencesEs': sourceReferencesEs,
        'sourceReferencesEn': sourceReferencesEn,
        'beforeSessionTipsEs': beforeSessionTipsEs,
        'beforeSessionTipsEn': beforeSessionTipsEn,
        'afterSessionTipsEs': afterSessionTipsEs,
        'afterSessionTipsEn': afterSessionTipsEn,
        'courseGuidance': courseGuidance?.toJson(),
        'origin': origin.name,
        'originSearchQuery': originSearchQuery,
        'originNoteEs': originNoteEs,
        'originNoteEn': originNoteEn,
        'generatedAtIso': generatedAtIso,
      };

  factory WellnessTreatment.fromJson(Map<String, dynamic> json) {
    final titleEs = json['titleEs'] as String? ?? '';
    final titleEn = json['titleEn'] as String? ?? titleEs;
    final categoryEs = json['categoryEs'] as String? ?? '';
    final categoryEn = json['categoryEn'] as String? ?? categoryEs;
    return WellnessTreatment(
      id: json['id'] as String? ?? '',
      titleEs: titleEs,
      titleEn: titleEn,
      categoryEs: categoryEs,
      categoryEn: categoryEn,
      goalEs: json['goalEs'] as String? ?? '',
      goalEn: json['goalEn'] as String? ?? '',
      summaryEs: json['summaryEs'] as String? ?? '',
      summaryEn: json['summaryEn'] as String? ?? '',
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 10,
      distanceGuidanceEs: json['distanceGuidanceEs'] as String? ?? '',
      distanceGuidanceEn: json['distanceGuidanceEn'] as String? ?? '',
      pulseGuidanceEs: json['pulseGuidanceEs'] as String? ?? '',
      pulseGuidanceEn: json['pulseGuidanceEn'] as String? ?? '',
      intensityDistribution: (json['intensityDistribution'] as List? ?? const [])
          .map(
            (entry) => TreatmentIntensity.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false),
      evidenceLevel: EvidenceLevel.values.firstWhere(
        (entry) => entry.name == (json['evidenceLevel'] as String? ?? ''),
        orElse: () => EvidenceLevel.emerging,
      ),
      safetyNotesEs:
          List<String>.from(json['safetyNotesEs'] as List? ?? const []),
      safetyNotesEn:
          List<String>.from(json['safetyNotesEn'] as List? ?? const []),
      sourceReferencesEs:
          List<String>.from(json['sourceReferencesEs'] as List? ?? const []),
      sourceReferencesEn:
          List<String>.from(json['sourceReferencesEn'] as List? ?? const []),
      beforeSessionTipsEs:
          List<String>.from(json['beforeSessionTipsEs'] as List? ?? const []),
      beforeSessionTipsEn:
          List<String>.from(json['beforeSessionTipsEn'] as List? ?? const []),
      afterSessionTipsEs:
          List<String>.from(json['afterSessionTipsEs'] as List? ?? const []),
      afterSessionTipsEn:
          List<String>.from(json['afterSessionTipsEn'] as List? ?? const []),
      trainingGuidance: buildTrainingGuidance(
        category: categoryEn.isNotEmpty ? categoryEn : categoryEs,
        title: titleEn.isNotEmpty ? titleEn : titleEs,
      ),
      courseGuidance: json['courseGuidance'] == null
          ? null
          : TreatmentCourseGuidance.fromJson(
              Map<String, dynamic>.from(json['courseGuidance'] as Map),
            ),
      origin: TreatmentOrigin.values.firstWhere(
        (entry) => entry.name == (json['origin'] as String? ?? ''),
        orElse: () => TreatmentOrigin.aiDraft,
      ),
      originSearchQuery: json['originSearchQuery'] as String?,
      originNoteEs: json['originNoteEs'] as String?,
      originNoteEn: json['originNoteEn'] as String?,
      generatedAtIso: json['generatedAtIso'] as String?,
    );
  }
}

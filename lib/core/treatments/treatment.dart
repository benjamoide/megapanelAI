import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';

class TreatmentIntensity {
  const TreatmentIntensity({
    required this.wavelengthNm,
    required this.percentage,
  });

  final int wavelengthNm;
  final int percentage;
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

  String get intensitySummary {
    if (intensityDistribution.isEmpty) return 'No intensity guidance';
    return intensityDistribution
        .map((entry) => '${entry.wavelengthNm}nm ${entry.percentage}%')
        .join('  ·  ');
  }
}

import 'package:mega_panel_ai/core/evidence/evidence_level.dart';

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
    required this.title,
    required this.category,
    required this.goal,
    required this.summary,
    required this.durationMinutes,
    required this.distanceGuidance,
    required this.pulseGuidance,
    required this.intensityDistribution,
    required this.evidenceLevel,
    required this.safetyNotes,
    required this.sourceReferences,
    required this.beforeSessionTips,
    required this.afterSessionTips,
  });

  final String id;
  final String title;
  final String category;
  final String goal;
  final String summary;
  final int durationMinutes;
  final String distanceGuidance;
  final String pulseGuidance;
  final List<TreatmentIntensity> intensityDistribution;
  final EvidenceLevel evidenceLevel;
  final List<String> safetyNotes;
  final List<String> sourceReferences;
  final List<String> beforeSessionTips;
  final List<String> afterSessionTips;

  String get intensitySummary {
    if (intensityDistribution.isEmpty) return 'No intensity guidance';
    return intensityDistribution
        .map((entry) => '${entry.wavelengthNm}nm ${entry.percentage}%')
        .join('  ·  ');
  }
}

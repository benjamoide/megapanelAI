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

  String title(bool isSpanish) => isSpanish
      ? titleEs
      : _englishTextOrFallback(titleEn, titleEs, titleLike: true);
  String category(bool isSpanish) =>
      isSpanish ? categoryEs : _englishTextOrFallback(categoryEn, categoryEs);
  String goal(bool isSpanish) =>
      isSpanish ? goalEs : _englishTextOrFallback(goalEn, goalEs);
  String summary(bool isSpanish) =>
      isSpanish ? summaryEs : _englishTextOrFallback(summaryEn, summaryEs);
  String distanceGuidance(bool isSpanish) => isSpanish
      ? distanceGuidanceEs
      : _englishTextOrFallback(distanceGuidanceEn, distanceGuidanceEs);
  String pulseGuidance(bool isSpanish) => isSpanish
      ? pulseGuidanceEs
      : _englishTextOrFallback(pulseGuidanceEn, pulseGuidanceEs);
  List<String> safetyNotes(bool isSpanish) => isSpanish
      ? safetyNotesEs
      : _englishListOrFallback(safetyNotesEn, safetyNotesEs);
  List<String> sourceReferences(bool isSpanish) => isSpanish
      ? sourceReferencesEs
      : _englishListOrFallback(sourceReferencesEn, sourceReferencesEs);
  List<String> beforeSessionTips(bool isSpanish) => isSpanish
      ? beforeSessionTipsEs
      : _englishListOrFallback(beforeSessionTipsEn, beforeSessionTipsEs);
  List<String> afterSessionTips(bool isSpanish) => isSpanish
      ? afterSessionTipsEs
      : _englishListOrFallback(afterSessionTipsEn, afterSessionTipsEs);
  bool get supportsStructuredCourse => courseGuidance != null;

  String get intensitySummary {
    if (intensityDistribution.isEmpty) return 'No intensity guidance';
    return intensityDistribution
        .map((entry) => '${entry.wavelengthNm}nm ${entry.percentage}%')
        .join('  ·  ');
  }
}

String _englishTextOrFallback(
  String english,
  String spanish, {
  bool titleLike = false,
}) {
  final trimmedEnglish = english.trim();
  final trimmedSpanish = spanish.trim();
  if (trimmedSpanish.isEmpty) return trimmedEnglish;
  if (trimmedEnglish.isEmpty ||
      trimmedEnglish.toLowerCase() == trimmedSpanish.toLowerCase() ||
      _looksSpanish(trimmedEnglish)) {
    return _runtimeTranslateEsToEn(trimmedSpanish, titleLike: titleLike);
  }
  return trimmedEnglish;
}

List<String> _englishListOrFallback(List<String> english, List<String> spanish) {
  if (spanish.isEmpty) return english;
  if (english.isEmpty ||
      english.length != spanish.length ||
      english.any(_looksSpanish)) {
    return spanish
        .map((entry) => _runtimeTranslateEsToEn(entry))
        .toList(growable: false);
  }
  return english;
}

bool _looksSpanish(String value) {
  final lower = value.toLowerCase();
  const markers = [
    'dolor',
    'lesion',
    'sesion',
    'distancia',
    'zona',
    'rodilla',
    'hombro',
    'migra',
    'sueno',
    'coadyuvante',
    'tendinopatia',
    'cicatriz',
    'piel',
    'antes de',
    'despues de',
    'mucositis',
    'grasa',
  ];
  return markers.any(lower.contains);
}

String _runtimeTranslateEsToEn(String value, {bool titleLike = false}) {
  var text = value.trim();
  if (text.isEmpty) return text;

  final exactLower = <String, String>{
    'dolor de cabeza': 'Headache',
    'migraña': 'Migraine',
    'migrana': 'Migraine',
    'grasa localizada': 'Localized fat',
    'sueno': 'Sleep',
    'sueño': 'Sleep',
    'lesiones': 'Injuries',
    'facial': 'Facial',
    'young': 'Young',
    'fat': 'Fat',
  };
  final exactHit = exactLower[text.toLowerCase()];
  if (exactHit != null) {
    return exactHit;
  }

  final replacements = <MapEntry<Pattern, String>>[
    const MapEntry('Fuente:', 'Source:'),
    const MapEntry('migrana', 'migraine'),
    const MapEntry('migraña', 'migraine'),
    const MapEntry('dolor de cabeza', 'headache'),
    const MapEntry('dolor', 'pain'),
    const MapEntry('sueno', 'sleep'),
    const MapEntry('sueño', 'sleep'),
    const MapEntry('relajacion', 'relaxation'),
    const MapEntry('relajación', 'relaxation'),
    const MapEntry('nocturna', 'night-time'),
    const MapEntry('lesion', 'injury'),
    const MapEntry('lesión', 'injury'),
    const MapEntry('lesiones', 'injuries'),
    const MapEntry('tendinopatia', 'tendinopathy'),
    const MapEntry('tendinopatía', 'tendinopathy'),
    const MapEntry('rodilla', 'knee'),
    const MapEntry('hombro', 'shoulder'),
    const MapEntry('codo', 'elbow'),
    const MapEntry('muneca', 'wrist'),
    const MapEntry('muñeca', 'wrist'),
    const MapEntry('tobillo', 'ankle'),
    const MapEntry('pie', 'foot'),
    const MapEntry('pierna', 'leg'),
    const MapEntry('cuello', 'neck'),
    const MapEntry('espalda', 'back'),
    const MapEntry('lumbar', 'lumbar'),
    const MapEntry('dorsal', 'thoracic'),
    const MapEntry('piel', 'skin'),
    const MapEntry('cicatriz', 'scar'),
    const MapEntry('mucositis', 'mucositis'),
    const MapEntry('grasa', 'fat'),
    const MapEntry('localizada', 'localized'),
    const MapEntry('coadyuvante', 'adjunctive'),
    const MapEntry('recuperacion', 'recovery'),
    const MapEntry('recuperación', 'recovery'),
    const MapEntry('muscular', 'muscular'),
    const MapEntry('fascitis plantar', 'plantar fasciitis'),
    const MapEntry('protocolo estetico', 'aesthetic protocol'),
    const MapEntry('protocolo estético', 'aesthetic protocol'),
    const MapEntry('fotoenvejecimiento', 'photoaging'),
    const MapEntry('arruga fina', 'fine lines'),
    const MapEntry('sintomas', 'symptoms'),
    const MapEntry('síntomas', 'symptoms'),
    const MapEntry('distancia', 'distance'),
    const MapEntry('sesion', 'session'),
    const MapEntry('sesión', 'session'),
    const MapEntry('sesiones', 'sessions'),
    const MapEntry('antes de', 'before'),
    const MapEntry('despues de', 'after'),
    const MapEntry('después de', 'after'),
    const MapEntry(
      'general wellness guidance for',
      'General wellness guidance for',
    ),
    const MapEntry('suggested placement:', 'Suggested placement:'),
  ];

  for (final replacement in replacements) {
    text = text.replaceAll(replacement.key, replacement.value);
  }

  text = text
      .replaceAll(RegExp(r'\bde\b', caseSensitive: false), 'of')
      .replaceAll(RegExp(r'\by\b', caseSensitive: false), 'and')
      .replaceAll(RegExp(r'\bcon\b', caseSensitive: false), 'with')
      .replaceAll(RegExp(r'\bpara\b', caseSensitive: false), 'for')
      .replaceAll(RegExp(r'\ben\b', caseSensitive: false), 'in')
      .replaceAll(RegExp(r'\bsi\b', caseSensitive: false), 'if')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  if (titleLike && text.isNotEmpty) {
    return text
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
  return text;
}

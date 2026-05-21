import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/evidence/training_compatibility.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';

class AiTreatmentSearchResult {
  const AiTreatmentSearchResult({
    required this.summaryEs,
    required this.summaryEn,
    required this.recommendedExistingIds,
    required this.proposedTreatments,
  });

  final String summaryEs;
  final String summaryEn;
  final List<String> recommendedExistingIds;
  final List<WellnessTreatment> proposedTreatments;
}

class AiTreatmentSearchService {
  AiTreatmentSearchService({required String apiKey}) : _apiKey = apiKey.trim();

  final String _apiKey;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<AiTreatmentSearchResult> searchTreatments({
    required String query,
    required List<WellnessTreatment> existingCatalog,
  }) async {
    if (!isConfigured) {
      throw const AiTreatmentSearchException(
        'AI search is not configured for this build.',
      );
    }

    final condensedCatalog = existingCatalog
        .take(80)
        .map(
          (entry) => {
            'id': entry.id,
            'title_es': entry.titleEs,
            'title_en': entry.titleEn,
            'category_es': entry.categoryEs,
            'category_en': entry.categoryEn,
            'goal_es': entry.goalEs,
            'goal_en': entry.goalEn,
          },
        )
        .toList(growable: false);

    final prompt = '''
You are helping a wellness companion app propose red light therapy treatments.

User request:
$query

Existing catalog candidates (use their ids only if relevant):
${jsonEncode(condensedCatalog)}

Return STRICT JSON with this shape:
{
  "summary_es": "short explanation in Spanish",
  "summary_en": "short explanation in English",
  "recommended_existing_ids": ["existing_id_1"],
  "proposed_treatments": [
    {
      "title_es": "...",
      "title_en": "...",
      "category_es": "...",
      "category_en": "...",
      "goal_es": "...",
      "goal_en": "...",
      "summary_es": "...",
      "summary_en": "...",
      "duration_minutes": 10,
      "distance_guidance_es": "...",
      "distance_guidance_en": "...",
      "pulse_guidance_es": "...",
      "pulse_guidance_en": "...",
      "intensity_distribution": [
        {"wavelength_nm": 660, "percentage": 50},
        {"wavelength_nm": 850, "percentage": 50}
      ],
      "evidence_level": "emerging|moderate|strong",
      "safety_notes_es": ["..."],
      "safety_notes_en": ["..."],
      "source_references_es": ["Fuente: ..."],
      "source_references_en": ["Source: ..."],
      "before_session_tips_es": ["..."],
      "before_session_tips_en": ["..."],
      "after_session_tips_es": ["..."],
      "after_session_tips_en": ["..."],
      "course_guidance": {
        "min_sessions": 4,
        "max_sessions": 12,
        "recommended_sessions": 8,
        "recommended_spacing_days": 2,
        "summary_es": "...",
        "summary_en": "..."
      }
    }
  ]
}

Rules:
- Prefer recommending existing catalog ids when they are a good fit.
- Only propose up to 2 new treatments.
- Keep treatment proposals neutral, non-device-specific and wellness-oriented.
- Include source references whenever you propose a new treatment.
- If evidence is weak, state that clearly through the evidence level and safety notes.
- Do not add markdown, commentary or code fences. Return JSON only.
''';

    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);
      final response = await model.generateContent([Content.text(prompt)]);
      final raw = response.text?.trim();
      if (raw == null || raw.isEmpty) {
        throw const AiTreatmentSearchException('AI search returned no content.');
      }

      final normalized = _extractJson(raw);
      final decoded = json.decode(normalized) as Map<String, dynamic>;
      final proposed = (decoded['proposed_treatments'] as List? ?? const [])
          .map(
            (entry) => _mapDraftFromJson(
              query: query,
              json: Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(growable: false);

      return AiTreatmentSearchResult(
        summaryEs: decoded['summary_es'] as String? ?? '',
        summaryEn: decoded['summary_en'] as String? ?? '',
        recommendedExistingIds:
            List<String>.from(decoded['recommended_existing_ids'] as List? ?? const []),
        proposedTreatments: proposed,
      );
    } on InvalidApiKey catch (error) {
      throw AiTreatmentSearchException(_normalizeAiKeyError(error.message));
    } on ServerException catch (error) {
      throw AiTreatmentSearchException(_normalizeServerError(error.message));
    } on UnsupportedUserLocation {
      throw const AiTreatmentSearchException(
        'AI search is not available from the current user location.',
      );
    } on AiTreatmentSearchException {
      rethrow;
    } catch (error) {
      throw AiTreatmentSearchException(
        'AI search failed unexpectedly. Please try again later. ($error)',
      );
    }
  }

  WellnessTreatment _mapDraftFromJson({
    required String query,
    required Map<String, dynamic> json,
  }) {
    final titleEs = (json['title_es'] as String? ?? 'Tratamiento IA').trim();
    final titleEn = (json['title_en'] as String? ?? 'AI treatment').trim();
    final categoryEs = (json['category_es'] as String? ?? 'Busqueda IA').trim();
    final categoryEn = (json['category_en'] as String? ?? 'AI search').trim();
    final evidenceLevel = EvidenceLevel.values.firstWhere(
      (entry) => entry.name == (json['evidence_level'] as String? ?? ''),
      orElse: () => EvidenceLevel.emerging,
    );
    final idSuffix = DateTime.now().microsecondsSinceEpoch;

    return WellnessTreatment(
      id: 'ai_${titleEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_$idSuffix',
      titleEs: titleEs,
      titleEn: titleEn,
      categoryEs: categoryEs,
      categoryEn: categoryEn,
      goalEs: (json['goal_es'] as String? ?? '').trim(),
      goalEn: (json['goal_en'] as String? ?? '').trim(),
      summaryEs: (json['summary_es'] as String? ?? '').trim(),
      summaryEn: (json['summary_en'] as String? ?? '').trim(),
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 10,
      distanceGuidanceEs: (json['distance_guidance_es'] as String? ?? '').trim(),
      distanceGuidanceEn: (json['distance_guidance_en'] as String? ?? '').trim(),
      pulseGuidanceEs: (json['pulse_guidance_es'] as String? ?? '').trim(),
      pulseGuidanceEn: (json['pulse_guidance_en'] as String? ?? '').trim(),
      intensityDistribution: (json['intensity_distribution'] as List? ?? const [])
          .map(
            (entry) {
              final map = Map<String, dynamic>.from(entry as Map);
              return TreatmentIntensity(
                wavelengthNm: (map['wavelength_nm'] as num?)?.toInt() ?? 660,
                percentage: (map['percentage'] as num?)?.toInt() ?? 100,
              );
            },
          )
          .toList(growable: false),
      evidenceLevel: evidenceLevel,
      safetyNotesEs:
          List<String>.from(json['safety_notes_es'] as List? ?? const []),
      safetyNotesEn:
          List<String>.from(json['safety_notes_en'] as List? ?? const []),
      sourceReferencesEs:
          List<String>.from(json['source_references_es'] as List? ?? const []),
      sourceReferencesEn:
          List<String>.from(json['source_references_en'] as List? ?? const []),
      beforeSessionTipsEs:
          List<String>.from(json['before_session_tips_es'] as List? ?? const []),
      beforeSessionTipsEn:
          List<String>.from(json['before_session_tips_en'] as List? ?? const []),
      afterSessionTipsEs:
          List<String>.from(json['after_session_tips_es'] as List? ?? const []),
      afterSessionTipsEn:
          List<String>.from(json['after_session_tips_en'] as List? ?? const []),
      trainingGuidance: buildTrainingGuidance(
        category: categoryEn.isNotEmpty ? categoryEn : categoryEs,
        title: titleEn.isNotEmpty ? titleEn : titleEs,
      ),
      courseGuidance: _mapCourseGuidance(
        json['course_guidance'] as Map?,
      ),
      origin: TreatmentOrigin.aiDraft,
      originSearchQuery: query,
      originNoteEs: 'Borrador generado a partir de una busqueda con IA.',
      originNoteEn: 'Draft generated from an AI search.',
      generatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  TreatmentCourseGuidance? _mapCourseGuidance(Map? raw) {
    if (raw == null) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map.isEmpty) return null;
    return TreatmentCourseGuidance(
      minSessions: (map['min_sessions'] as num?)?.toInt() ?? 1,
      maxSessions: (map['max_sessions'] as num?)?.toInt() ?? 1,
      recommendedSessions:
          (map['recommended_sessions'] as num?)?.toInt() ?? 1,
      recommendedSpacingDays:
          (map['recommended_spacing_days'] as num?)?.toInt() ?? 1,
      summaryEs: map['summary_es'] as String? ?? '',
      summaryEn: map['summary_en'] as String? ?? '',
    );
  }

  String _extractJson(String raw) {
    final fenced = RegExp(r'```(?:json)?([\s\S]*?)```', caseSensitive: false)
        .firstMatch(raw);
    if (fenced != null) {
      return fenced.group(1)!.trim();
    }
    final firstBrace = raw.indexOf('{');
    final lastBrace = raw.lastIndexOf('}');
    if (firstBrace >= 0 && lastBrace > firstBrace) {
      return raw.substring(firstBrace, lastBrace + 1).trim();
    }
    return raw;
  }

  String _normalizeAiKeyError(String rawMessage) {
    final normalized = rawMessage.toLowerCase();
    if (normalized.contains('expired')) {
      return 'The AI key configured for this app has expired. Please renew the GEMINI_API_KEY secret and rebuild the app.';
    }
    return 'The AI key configured for this app is invalid. Please update the GEMINI_API_KEY secret and rebuild the app.';
  }

  String _normalizeServerError(String rawMessage) {
    final normalized = rawMessage.toLowerCase();
    if (normalized.contains('expired api key') ||
        normalized.contains('api key expired') ||
        normalized.contains('expired')) {
      return 'The AI key configured for this app has expired. Please renew the GEMINI_API_KEY secret and rebuild the app.';
    }
    if (normalized.contains('api key') && normalized.contains('invalid')) {
      return 'The AI key configured for this app is invalid. Please update the GEMINI_API_KEY secret and rebuild the app.';
    }
    return 'AI search is temporarily unavailable. Please try again later.';
  }
}

class AiTreatmentSearchException implements Exception {
  const AiTreatmentSearchException(this.message);

  final String message;

  @override
  String toString() => message;
}

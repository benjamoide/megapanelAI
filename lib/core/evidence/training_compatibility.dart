import 'package:mega_panel_ai/core/training/training_models.dart';

enum TreatmentExerciseProfile {
  musculoskeletalUpper,
  musculoskeletalLower,
  trunkSpine,
  skinRepair,
  cosmeticSkin,
  systemicWellness,
  metabolicAesthetic,
}

TreatmentExerciseProfile deriveTreatmentExerciseProfile({
  required String category,
  required String title,
}) {
  final normalized = '${category.toLowerCase()} ${title.toLowerCase()}';
  if (normalized.contains('codo') ||
      normalized.contains('antebrazo') ||
      normalized.contains('muneca') ||
      normalized.contains('mano') ||
      normalized.contains('hombro')) {
    return TreatmentExerciseProfile.musculoskeletalUpper;
  }
  if (normalized.contains('pierna') ||
      normalized.contains('rodilla') ||
      normalized.contains('tobillo') ||
      normalized.contains('pie') ||
      normalized.contains('cadera')) {
    return TreatmentExerciseProfile.musculoskeletalLower;
  }
  if (normalized.contains('espalda') ||
      normalized.contains('abdomen') ||
      normalized.contains('atm') ||
      normalized.contains('migrana') ||
      normalized.contains('cabeza')) {
    return TreatmentExerciseProfile.trunkSpine;
  }
  if (normalized.contains('cicatriz') ||
      normalized.contains('quemadura') ||
      normalized.contains('ulcera') ||
      normalized.contains('mucositis')) {
    return TreatmentExerciseProfile.skinRepair;
  }
  if (normalized.contains('antiaging') ||
      normalized.contains('rejuvenec') ||
      normalized.contains('acne') ||
      normalized.contains('estrias') ||
      normalized.contains('fibrosis')) {
    return TreatmentExerciseProfile.cosmeticSkin;
  }
  if (normalized.contains('grasa') || normalized.contains('fat')) {
    return TreatmentExerciseProfile.metabolicAesthetic;
  }
  return TreatmentExerciseProfile.systemicWellness;
}

const TrainingReference _pbmMetaHealthy = TrainingReference(
  label: 'PBMT functional performance meta-analysis (PMID 38150056)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/38150056/',
);

const TrainingReference _pbmOxStress = TrainingReference(
  label: 'PBMT exercise oxidative stress review (PMID 36139746)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/36139746/',
);

const TrainingReference _pbmWholeBody = TrainingReference(
  label: 'Whole-body PBM exercise recovery review (PMID 39883205)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/39883205/',
);

const TrainingReference _pbmTrainedNoExtra = TrainingReference(
  label: 'PBM during training showed no extra effect in trained individuals (PMID 35151026)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/35151026/',
);

const TrainingReference _pbmCyclingNull = TrainingReference(
  label: 'Cycling trial with no benefit at 30 min or 6 h pre-exercise (PMID 33519511)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/33519511/',
);

const TrainingReference _pbmShoulderPositive = TrainingReference(
  label: 'Pre-exercise shoulder fatigue attenuation trial (PMID 38015822)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/38015822/',
);

const TrainingReference _pbmPilatesNull = TrainingReference(
  label: 'Pilates plus PBMT low-back trial with no added effect (PMID 39057559)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/39057559/',
);

const TrainingReference _pbmHiitNull = TrainingReference(
  label: 'High-intensity intermittent BJJ lower-limb trial with no ergogenic effect (PMID 38288386)',
  url: 'https://pubmed.ncbi.nlm.nih.gov/38288386/',
);

List<TreatmentTrainingGuidance> buildTrainingGuidance({
  required String category,
  required String title,
}) {
  final profile = deriveTreatmentExerciseProfile(category: category, title: title);
  return TrainingType.values
      .map((type) => _guidanceFor(profile: profile, trainingType: type))
      .toList(growable: false);
}

TreatmentTrainingGuidance _guidanceFor({
  required TreatmentExerciseProfile profile,
  required TrainingType trainingType,
}) {
  switch (trainingType) {
    case TrainingType.hiit:
      return _guidanceForHiit(profile);
    case TrainingType.yogaPilates:
      return _guidanceForYogaPilates(profile);
    case TrainingType.upperBodyStrength:
      return _guidanceForUpperStrength(profile);
    case TrainingType.lowerBodyStrength:
      return _guidanceForLowerStrength(profile);
    case TrainingType.cardio:
      return _guidanceForCardio(profile);
  }
}

TreatmentTrainingGuidance _guidanceForHiit(TreatmentExerciseProfile profile) {
  switch (profile) {
    case TreatmentExerciseProfile.musculoskeletalUpper:
    case TreatmentExerciseProfile.musculoskeletalLower:
    case TreatmentExerciseProfile.trunkSpine:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.hiit,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredLeadMinutes: 30,
        preferredRecoveryMinutes: 30,
        beforeTrainingNote:
            'High-intensity pre-exercise PBM has mixed evidence. Some localized studies suggest less fatigue, but others show no clear ergogenic effect. Use only as an optional adjunct, not as a performance requirement.',
        afterTrainingNote:
            'After HIIT, localized PBM is generally compatible for recovery-oriented use once the initial cool-down has finished. Evidence supports possible fatigue/oxidative-stress modulation, but benefits are inconsistent across trials.',
        sourceReferences: [
          _pbmMetaHealthy,
          _pbmOxStress,
          _pbmHiitNull,
        ],
      );
    case TreatmentExerciseProfile.skinRepair:
    case TreatmentExerciseProfile.cosmeticSkin:
    case TreatmentExerciseProfile.metabolicAesthetic:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.hiit,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredRecoveryMinutes: 30,
        beforeTrainingNote:
            'No exercise-specific incompatibility was identified before HIIT for this treatment family.',
        afterTrainingNote:
            'Generally compatible after HIIT, but practical comfort is better once skin temperature, sweat and breathing have normalized. Exercise-specific evidence for this treatment family is limited.',
        sourceReferences: [
          _pbmWholeBody,
          _pbmMetaHealthy,
        ],
      );
    case TreatmentExerciseProfile.systemicWellness:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.hiit,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'Whole-body or systemic PBM has not shown consistent performance benefits before intense conditioning work.',
        afterTrainingNote:
            'Compatible after HIIT for general wellness goals. Existing exercise studies do not show a clear incompatibility, but systemic benefits are less established than localized recovery use.',
        sourceReferences: [
          _pbmWholeBody,
          _pbmCyclingNull,
        ],
      );
  }
}

TreatmentTrainingGuidance _guidanceForCardio(TreatmentExerciseProfile profile) {
  switch (profile) {
    case TreatmentExerciseProfile.musculoskeletalUpper:
    case TreatmentExerciseProfile.musculoskeletalLower:
    case TreatmentExerciseProfile.trunkSpine:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.cardio,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredLeadMinutes: 30,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'Localized PBM before cardio has mixed evidence. Some endurance trials are neutral, so this should be considered optional rather than necessary.',
        afterTrainingNote:
            'Compatible after cardio for recovery-oriented treatments, especially when soreness or accumulated load is the target. Evidence is mixed and should not be framed as guaranteed performance enhancement.',
        sourceReferences: [
          _pbmCyclingNull,
          _pbmOxStress,
          _pbmMetaHealthy,
        ],
      );
    case TreatmentExerciseProfile.skinRepair:
    case TreatmentExerciseProfile.cosmeticSkin:
    case TreatmentExerciseProfile.metabolicAesthetic:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.cardio,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'No direct incompatibility with cardio was identified for this treatment family.',
        afterTrainingNote:
            'Generally compatible after cardio once the user has cooled down and the skin is comfortable. Evidence is limited because most sports PBM studies focus on muscle outcomes.',
        sourceReferences: [
          _pbmWholeBody,
          _pbmMetaHealthy,
        ],
      );
    case TreatmentExerciseProfile.systemicWellness:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.cardio,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'Systemic PBM before cardio is not clearly supported for performance. Some endurance trials show no benefit.',
        afterTrainingNote:
            'Compatible after cardio for general wellness purposes, but evidence for systemic performance or recovery gains remains limited.',
        sourceReferences: [
          _pbmCyclingNull,
          _pbmWholeBody,
        ],
      );
  }
}

TreatmentTrainingGuidance _guidanceForUpperStrength(
  TreatmentExerciseProfile profile,
) {
  switch (profile) {
    case TreatmentExerciseProfile.musculoskeletalUpper:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.upperBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredLeadMinutes: 30,
        preferredRecoveryMinutes: 30,
        beforeTrainingNote:
            'This is the most studied combination. Some upper-body resistance trials report less fatigue when PBM is used before exercise, but results are not uniform across studies.',
        afterTrainingNote:
            'Compatible after upper-body strength work for recovery-oriented use on the trained area. Evidence suggests possible help with fatigue and oxidative-stress recovery, but not a guaranteed effect on strength or adaptation.',
        sourceReferences: [
          _pbmShoulderPositive,
          _pbmMetaHealthy,
          _pbmOxStress,
        ],
      );
    case TreatmentExerciseProfile.musculoskeletalLower:
    case TreatmentExerciseProfile.trunkSpine:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.upperBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'No direct incompatibility was identified when the treatment target does not match the primary trained area.',
        afterTrainingNote:
            'Generally compatible after upper-body strength work. Relevance is lower when the treated area was not the main driver of the session.',
        sourceReferences: [
          _pbmMetaHealthy,
          _pbmTrainedNoExtra,
        ],
      );
    case TreatmentExerciseProfile.skinRepair:
    case TreatmentExerciseProfile.cosmeticSkin:
    case TreatmentExerciseProfile.metabolicAesthetic:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.upperBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'No exercise-specific incompatibility was found before upper-body strength work for this treatment family.',
        afterTrainingNote:
            'Generally compatible after training, with a practical preference for waiting until sweat and skin heat settle.',
        sourceReferences: [
          _pbmWholeBody,
          _pbmMetaHealthy,
        ],
      );
    case TreatmentExerciseProfile.systemicWellness:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.upperBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'Systemic use before strength sessions has less direct support than localized use on the working muscles.',
        afterTrainingNote:
            'Compatible after strength training for general wellness goals, but additional benefits over training alone are not consistently demonstrated in trained populations.',
        sourceReferences: [
          _pbmTrainedNoExtra,
          _pbmWholeBody,
        ],
      );
  }
}

TreatmentTrainingGuidance _guidanceForLowerStrength(
  TreatmentExerciseProfile profile,
) {
  switch (profile) {
    case TreatmentExerciseProfile.musculoskeletalLower:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.lowerBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredLeadMinutes: 30,
        preferredRecoveryMinutes: 30,
        beforeTrainingNote:
            'Lower-limb PBM before strength work is sometimes studied as a fatigue-management strategy, but results are mixed and should be treated as optional.',
        afterTrainingNote:
            'Compatible after lower-body strength work for soreness and load-management purposes. Evidence is mixed but generally supportive of recovery-focused use rather than performance claims.',
        sourceReferences: [
          _pbmMetaHealthy,
          _pbmOxStress,
          _pbmTrainedNoExtra,
        ],
      );
    case TreatmentExerciseProfile.musculoskeletalUpper:
    case TreatmentExerciseProfile.trunkSpine:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.lowerBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'No direct incompatibility was identified when the treated area is not the primary lower-body training target.',
        afterTrainingNote:
            'Generally compatible after lower-body strength work. Consider local soreness and fatigue only when the treatment overlaps the worked tissues.',
        sourceReferences: [
          _pbmMetaHealthy,
          _pbmTrainedNoExtra,
        ],
      );
    case TreatmentExerciseProfile.skinRepair:
    case TreatmentExerciseProfile.cosmeticSkin:
    case TreatmentExerciseProfile.metabolicAesthetic:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.lowerBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.compatibleWithCaution,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'No exercise-specific incompatibility was found before lower-body strength work for this treatment family.',
        afterTrainingNote:
            'Generally compatible after training, with a practical preference for waiting until local heat, sweat and friction have settled.',
        sourceReferences: [
          _pbmWholeBody,
          _pbmMetaHealthy,
        ],
      );
    case TreatmentExerciseProfile.systemicWellness:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.lowerBodyStrength,
        beforeStatus: TrainingCompatibilityStatus.limitedEvidence,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        preferredRecoveryMinutes: 20,
        beforeTrainingNote:
            'Systemic PBM before lower-body lifting has limited direct support compared with localized muscle-focused use.',
        afterTrainingNote:
            'Compatible after strength work for general wellness goals, but evidence for extra training adaptation benefits is inconsistent.',
        sourceReferences: [
          _pbmTrainedNoExtra,
          _pbmWholeBody,
        ],
      );
  }
}

TreatmentTrainingGuidance _guidanceForYogaPilates(
  TreatmentExerciseProfile profile,
) {
  switch (profile) {
    case TreatmentExerciseProfile.musculoskeletalUpper:
    case TreatmentExerciseProfile.musculoskeletalLower:
    case TreatmentExerciseProfile.trunkSpine:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.yogaPilates,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.limitedEvidence,
        preferredRecoveryMinutes: 10,
        beforeTrainingNote:
            'Generally compatible before lower-load mobility work when comfort and symptom goals align with the session.',
        afterTrainingNote:
            'Direct evidence specific to yoga or Pilates timing is scarce. In rehabilitation-style Pilates studies, PBM did not add measurable benefit over Pilates alone, so use this more for symptom management than expected synergy.',
        sourceReferences: [
          _pbmPilatesNull,
          _pbmWholeBody,
        ],
      );
    case TreatmentExerciseProfile.skinRepair:
    case TreatmentExerciseProfile.cosmeticSkin:
    case TreatmentExerciseProfile.metabolicAesthetic:
    case TreatmentExerciseProfile.systemicWellness:
      return const TreatmentTrainingGuidance(
        trainingType: TrainingType.yogaPilates,
        beforeStatus: TrainingCompatibilityStatus.generallyCompatible,
        afterStatus: TrainingCompatibilityStatus.generallyCompatible,
        beforeTrainingNote:
            'No exercise-specific incompatibility was identified for low-load mobility sessions.',
        afterTrainingNote:
            'Generally compatible after yoga or Pilates. Direct timing evidence is limited, but no meaningful conflict has been demonstrated.',
        sourceReferences: [
          _pbmPilatesNull,
          _pbmWholeBody,
        ],
      );
  }
}

List<TrainingCompatibilityAssessment> assessTrainingCompatibility({
  required List<TreatmentTrainingGuidance> guidance,
  required List<RecentTrainingSession> recentTraining,
  required DateTime referenceTime,
}) {
  final results = <TrainingCompatibilityAssessment>[];
  for (final session in recentTraining) {
    final rule = guidance.where((entry) => entry.trainingType == session.type).firstOrNull;
    if (rule == null) continue;
    final elapsed = referenceTime.difference(session.performedAt);
    final afterStatus = rule.afterStatus;
    final waitRemaining = _waitRemaining(
      elapsed: elapsed,
      preferredRecoveryMinutes: rule.preferredRecoveryMinutes,
      status: afterStatus,
    );
    final resolvedStatus = waitRemaining != null && !waitRemaining.isNegative
        ? TrainingCompatibilityStatus.waitUntilRecovered
        : afterStatus;
    results.add(
      TrainingCompatibilityAssessment(
        training: session,
        status: resolvedStatus,
        relation: TrainingRelation.afterTraining,
        referenceTime: referenceTime,
        elapsedSinceTraining: elapsed,
        summary: _summaryForStatus(resolvedStatus, afterTraining: true),
        detail: _detailForStatus(
          status: resolvedStatus,
          baseNote: rule.afterTrainingNote,
          waitRemaining: waitRemaining,
        ),
        sourceReferences: rule.sourceReferences,
        waitRemaining: waitRemaining != null && waitRemaining.isNegative
            ? null
            : waitRemaining,
      ),
    );
  }
  results.sort((a, b) => a.training.performedAtIso.compareTo(b.training.performedAtIso));
  return results.reversed.toList(growable: false);
}

Duration? _waitRemaining({
  required Duration elapsed,
  required int? preferredRecoveryMinutes,
  required TrainingCompatibilityStatus status,
}) {
  if (preferredRecoveryMinutes == null) return null;
  if (status != TrainingCompatibilityStatus.compatibleWithCaution) return null;
  final remaining = Duration(minutes: preferredRecoveryMinutes) - elapsed;
  return remaining.inSeconds > 0 ? remaining : null;
}

String _summaryForStatus(
  TrainingCompatibilityStatus status, {
  required bool afterTraining,
}) {
  switch (status) {
    case TrainingCompatibilityStatus.generallyCompatible:
      return afterTraining
          ? 'Generally compatible after training'
          : 'Generally compatible before training';
    case TrainingCompatibilityStatus.compatibleWithCaution:
      return afterTraining
          ? 'Compatible after training with practical caution'
          : 'Compatible before training with practical caution';
    case TrainingCompatibilityStatus.limitedEvidence:
      return afterTraining
          ? 'Possible after training, but evidence is limited'
          : 'Possible before training, but evidence is limited';
    case TrainingCompatibilityStatus.waitUntilRecovered:
      return 'Wait until the immediate post-training period has settled';
  }
}

String _detailForStatus({
  required TrainingCompatibilityStatus status,
  required String baseNote,
  required Duration? waitRemaining,
}) {
  if (status == TrainingCompatibilityStatus.waitUntilRecovered &&
      waitRemaining != null) {
    final minutes = waitRemaining.inMinutes;
    return 'A short recovery gap is advisable first. Approximate wait remaining: $minutes min. $baseNote';
  }
  return baseNote;
}

extension _FirstWhereOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}

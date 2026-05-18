import 'package:flutter/material.dart';

enum EvidenceLevel {
  emerging,
  moderate,
  strong,
}

extension EvidenceLevelX on EvidenceLevel {
  String get label {
    switch (this) {
      case EvidenceLevel.emerging:
        return 'Emerging';
      case EvidenceLevel.moderate:
        return 'Moderate';
      case EvidenceLevel.strong:
        return 'Strong';
    }
  }

  Color get color {
    switch (this) {
      case EvidenceLevel.emerging:
        return const Color(0xFFC17C00);
      case EvidenceLevel.moderate:
        return const Color(0xFF2F7D6B);
      case EvidenceLevel.strong:
        return const Color(0xFF1F5E9C);
    }
  }
}

EvidenceLevel deriveEvidenceLevel({
  required List<String> sourceReferences,
  required List<String> safetyNotes,
}) {
  final joined = sourceReferences.join(' ').toLowerCase();
  final refCount = sourceReferences.length;
  final hasMeta = joined.contains('meta-anal') ||
      joined.contains('cochrane') ||
      joined.contains('systematic') ||
      joined.contains('revision sistematica');
  final hasTrial =
      joined.contains('clinicaltrials.gov') || joined.contains('rct');
  final hasOnlyIndirect =
      joined.contains('extrapolacion') || joined.contains('indirecta');

  if (hasOnlyIndirect && !hasMeta) {
    return EvidenceLevel.emerging;
  }
  if (hasMeta && refCount >= 2) {
    return EvidenceLevel.strong;
  }
  if ((hasTrial || refCount >= 2) && safetyNotes.isNotEmpty) {
    return EvidenceLevel.moderate;
  }
  return refCount >= 2 ? EvidenceLevel.moderate : EvidenceLevel.emerging;
}

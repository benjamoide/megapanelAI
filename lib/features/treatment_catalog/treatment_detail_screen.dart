import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:provider/provider.dart';

class TreatmentDetailScreen extends StatelessWidget {
  const TreatmentDetailScreen({
    super.key,
    required this.treatment,
  });

  final WellnessTreatment treatment;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final today = DateTime.now();
    final compatibility = controller.compatibilityForTreatment(
      treatment: treatment,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(treatment.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7EC), Color(0xFFEAF3F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(treatment.category)),
                    Chip(
                      label:
                          Text(strings.evidenceLabel(treatment.evidenceLevel)),
                      backgroundColor:
                          treatment.evidenceLevel.color.withValues(alpha: 0.14),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  treatment.goal,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(treatment.summary),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _MetricCard(
            title: strings.configuration,
            rows: [
              _MetricRow(strings.duration,
                  strings.minutesLabel(treatment.durationMinutes)),
              _MetricRow(strings.distance, treatment.distanceGuidance),
              _MetricRow(strings.pulseMode, treatment.pulseGuidance),
              _MetricRow(strings.suggestedIntensity,
                  strings.intensitySummary(treatment)),
              _MetricRow(
                strings.evidenceLevel,
                strings.evidenceLabel(treatment.evidenceLevel),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.safetyNotes,
            icon: Icons.shield_outlined,
            children: treatment.safetyNotes
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.beforeSession,
            icon: Icons.wb_sunny_outlined,
            children: treatment.beforeSessionTips
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.afterSession,
            icon: Icons.self_improvement_outlined,
            children: treatment.afterSessionTips
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.sourceReferences,
            icon: Icons.menu_book_outlined,
            children: treatment.sourceReferences
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.compatibilityTitle,
            icon: Icons.fitness_center_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(strings.compatibilityBody),
              ),
              if (compatibility.isEmpty)
                _BulletLine(text: strings.noRecentTrainingCompatibility)
              else
                ...compatibility.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.025),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                label: Text(
                                  strings.trainingTypeLabel(entry.training.type),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  strings.compatibilityStatusLabel(
                                    entry.status,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.trainingLoggedAt(
                              entry.training.performedAt.toLocal(),
                              strings.trainingExampleLabel(
                                entry.training.type,
                                entry.training.exampleKey,
                              ),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            strings.compatibilityAssessmentSummary(
                              entry.status,
                              afterTraining: true,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(strings.localizedCompatibilityText(entry.detail)),
                          if (entry.sourceReferences.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              entry.sourceReferences
                                  .map((ref) => ref.label)
                                  .join(' | '),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ...treatment.trainingGuidance.map(
                (rule) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.08),
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          strings.trainingTypeLabel(rule.trainingType),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${strings.trainingRelationLabel(TrainingRelation.beforeTraining)}: ${strings.compatibilityStatusLabel(rule.beforeStatus)}',
                        ),
                        Text(
                          strings.localizedCompatibilityText(
                            rule.beforeTrainingNote,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${strings.trainingRelationLabel(TrainingRelation.afterTraining)}: ${strings.compatibilityStatusLabel(rule.afterStatus)}',
                        ),
                        Text(
                          strings.localizedCompatibilityText(
                            rule.afterTrainingNote,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _BulletLine(text: strings.genericEvidenceNote),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            strings.disclaimer,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: BlueprintTheme.ink.withValues(alpha: 0.66),
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final relation =
                        await _pickTrainingRelation(context, strings);
                    if (relation == null) return;
                    await controller.scheduleTreatment(
                      treatment: treatment,
                      date: today,
                      momentLabel: strings.todayMomentLabel,
                      trainingRelation: relation,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.plannedFor(today),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(strings.planForToday),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final selectedDate = await showDatePicker(
                      context: context,
                      initialDate: today,
                      firstDate:
                          DateTime(today.year, today.month, today.day - 30),
                      lastDate:
                          DateTime(today.year, today.month, today.day + 365),
                      helpText: strings.chooseDate,
                      cancelText: strings.cancel,
                      confirmText: strings.save,
                    );
                    if (selectedDate == null) return;
                    if (!context.mounted) return;
                    final relation =
                        await _pickTrainingRelation(context, strings);
                    if (relation == null) return;
                    if (!context.mounted) return;
                    await controller.scheduleTreatment(
                      treatment: treatment,
                      date: selectedDate,
                      momentLabel: strings.scheduledMomentLabel,
                      trainingRelation: relation,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            strings.scheduledFor(selectedDate),
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(strings.chooseDate),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<TrainingRelation?> _pickTrainingRelation(
    BuildContext context,
    BlueprintStrings strings,
  ) async {
    var relation = TrainingRelation.independent;
    return showModalBottomSheet<TrainingRelation>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.planRelationTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(strings.choosePlanRelation),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: TrainingRelation.values.map((option) {
                  return ChoiceChip(
                    label: Text(strings.trainingRelationLabel(option)),
                    selected: relation == option,
                    onSelected: (_) => setState(() => relation = option),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(strings.cancel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(relation),
                      child: Text(strings.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_MetricRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...rows.map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 132,
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Expanded(child: Text(row.value)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: BlueprintTheme.ink),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 8),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _MetricRow {
  const _MetricRow(this.label, this.value);

  final String label;
  final String value;
}

import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/panel_control/panel_launch_controller.dart';
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
    final panelLauncher = _maybePanelLauncher(context);
    final strings = BlueprintStrings(controller.language);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compatibility = controller.compatibilityForTreatment(
      treatment: treatment,
    );
    final activeCourses = controller.activeCoursesForTreatment(treatment.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(treatment.title(strings.isSpanish)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BlueprintTheme.heroGradient(
              primary: treatment.evidenceLevel.color,
              secondary: BlueprintTheme.seafoam,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      label: Text(treatment.category(strings.isSpanish)),
                    ),
                    if (!treatment.isCuratedTreatment)
                      Chip(
                        label: Text(strings.originLabel(treatment.origin)),
                        backgroundColor:
                            BlueprintTheme.seafoam.withValues(alpha: 0.14),
                      ),
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
                  treatment.goal(strings.isSpanish),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(treatment.summary(strings.isSpanish)),
                if (treatment.originNote(strings.isSpanish) != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BlueprintTheme.panelRaised,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: BlueprintTheme.outline),
                    ),
                    child: Text(
                      treatment.originNote(strings.isSpanish)!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          _MetricCard(
            title: strings.configuration,
            rows: [
              _MetricRow(strings.duration,
                  strings.minutesLabel(treatment.durationMinutes)),
              _MetricRow(
                strings.distance,
                treatment.distanceGuidance(strings.isSpanish),
              ),
              _MetricRow(
                strings.pulseMode,
                treatment.pulseGuidance(strings.isSpanish),
              ),
              _MetricRow(strings.suggestedIntensity,
                  strings.intensitySummary(treatment)),
              _MetricRow(
                strings.evidenceLevel,
                strings.evidenceLabel(treatment.evidenceLevel),
              ),
            ],
          ),
          if (treatment.courseGuidance != null) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: strings.fullCourseTitle,
              icon: Icons.timeline_outlined,
              children: [
                Text(strings.fullCourseBody),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BlueprintTheme.panelRaised,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BlueprintTheme.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treatment.courseGuidance!.summary(strings.isSpanish),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${strings.courseWindow}: ${strings.courseRangeLabel(treatment.courseGuidance!.minSessions, treatment.courseGuidance!.maxSessions)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${strings.courseCadence}: ${strings.everyXDays(treatment.courseGuidance!.recommendedSpacingDays)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (activeCourses.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...activeCourses.map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: BlueprintTheme.panelRaised,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: BlueprintTheme.outline),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              strings.activeCourse,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.courseProgressLine(
                                course.completedSessions,
                                course.skippedSessions,
                                course.targetSessions,
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (course.nextPlannedDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${strings.nextCourseSession}: ${strings.shortDate(course.nextPlannedDate!)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 14),
          if (treatment.isAiDraft) ...[
            _SectionCard(
              title: strings.aiDraftReviewTitle,
              icon: Icons.auto_awesome_outlined,
              children: [
                Text(strings.aiDraftReviewBody),
                if (treatment.originSearchQuery?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${strings.aiDraftSearchQueryLabel}: ${treatment.originSearchQuery!.trim()}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (treatment.generatedAtIso != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${strings.aiDraftGeneratedAtLabel}: ${strings.shortDate(DateTime.tryParse(treatment.generatedAtIso!) ?? today)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (treatment.sourceReferences(strings.isSpanish).isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    strings.aiDraftSourcePreviewTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.aiDraftSourceCount(
                      treatment.sourceReferences(strings.isSpanish).length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),
          ],
          _SectionCard(
            title: strings.safetyNotes,
            icon: Icons.shield_outlined,
            children: treatment
                .safetyNotes(strings.isSpanish)
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.beforeSession,
            icon: Icons.wb_sunny_outlined,
            children: treatment
                .beforeSessionTips(strings.isSpanish)
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.afterSession,
            icon: Icons.self_improvement_outlined,
            children: treatment
                .afterSessionTips(strings.isSpanish)
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: strings.sourceReferences,
            icon: Icons.menu_book_outlined,
            children: treatment
                .sourceReferences(strings.isSpanish)
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
                        color: BlueprintTheme.panelRaised,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: BlueprintTheme.outline),
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
                      color: BlueprintTheme.panelRaised,
                      border: Border.all(
                        color: BlueprintTheme.outline,
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
                  color: BlueprintTheme.fog,
                ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (treatment.isAiDraft) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final shouldSave = await _confirmAddDraftToMyTreatments(
                        context,
                        strings,
                        treatment,
                      );
                      if (!shouldSave) return;
                      await controller.addDraftToMyTreatments(treatment.id);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(strings.addedToMyTreatments),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: Text(strings.addToMyTreatments),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final result = await _pickPlanConfiguration(
                      context,
                      strings,
                      today,
                      controller,
                      treatment,
                    );
                    if (result == null) return;

                    final isSingleToday = result.dates.length == 1 &&
                        result.dates.first.year == today.year &&
                        result.dates.first.month == today.month &&
                        result.dates.first.day == today.day;
                    final plannedCount = await controller.scheduleTreatmentSeries(
                      treatment: treatment,
                      dates: result.dates,
                      momentLabel: isSingleToday
                          ? strings.todayMomentLabel
                          : strings.scheduledMomentLabel,
                      trainingRelation: result.trainingRelation,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          result.dates.length == 1
                              ? strings.plannedFor(result.dates.first)
                              : strings.coursePlannedResult(
                                  plannedCount,
                                  result.dates.length,
                                ),
                        ),
                      ),
                    );
                    if (panelLauncher != null &&
                        result.dates.length == 1 &&
                        _isSameDay(result.dates.first, today)) {
                      final shouldLaunch = await _confirmLaunchAfterPlanning(
                        context,
                        strings,
                      );
                      if (!shouldLaunch || !context.mounted) return;
                      final started =
                          await panelLauncher.launchTreatment(treatment);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            started
                                ? strings.treatmentStartedOnPanel
                                : panelLauncher.lastErrorMessage ??
                                    strings.treatmentStartFailed,
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(strings.planTreatment),
                ),
              ),
            ],
          ),
          if (panelLauncher != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final planned = await controller.scheduleTreatmentSeries(
                    treatment: treatment,
                    dates: [today],
                    momentLabel: strings.todayMomentLabel,
                    trainingRelation: TrainingRelation.independent,
                  );
                  final started = await panelLauncher.launchTreatment(treatment);
                  if (!context.mounted) return;
                  final startMessage = started
                      ? strings.treatmentStartedOnPanel
                      : panelLauncher.lastErrorMessage ??
                          strings.treatmentStartFailed;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        planned > 0
                            ? '${strings.plannedFor(today)} · $startMessage'
                            : startMessage,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_outline),
                label: Text(strings.startSingleDoseNow),
              ),
            ),
          ],
          if (treatment.isAiDraft) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  final shouldDiscard = await _confirmDiscardDraft(
                    context,
                    strings,
                  );
                  if (!shouldDiscard) return;
                  await controller.removeAiDraft(treatment.id);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(strings.discardedAiDraft)),
                  );
                  Navigator.of(context).maybePop();
                },
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.discardAiDraft),
              ),
            ),
          ],
        ],
      ),
    );
  }

  PanelLaunchController? _maybePanelLauncher(BuildContext context) {
    try {
      return Provider.of<PanelLaunchController>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  Future<bool> _confirmLaunchAfterPlanning(
    BuildContext context,
    BlueprintStrings strings,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.launchOnPanelQuestionTitle),
        content: Text(strings.launchOnPanelQuestionBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.notNowLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.launchOnPanelNow),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<bool> _confirmAddDraftToMyTreatments(
    BuildContext context,
    BlueprintStrings strings,
    WellnessTreatment treatment,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.confirmAddAiDraftTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.confirmAddAiDraftBody),
            const SizedBox(height: 12),
            if (treatment.sourceReferences(strings.isSpanish).isNotEmpty)
              Text(
                strings.aiDraftSourceCount(
                  treatment.sourceReferences(strings.isSpanish).length,
                ),
                style: Theme.of(dialogContext).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.confirmAddAiDraftAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _confirmDiscardDraft(
    BuildContext context,
    BlueprintStrings strings,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.discardAiDraftTitle),
        content: Text(strings.discardAiDraftBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(strings.discardAiDraftAction),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<_PlanConfiguration?> _pickPlanConfiguration(
    BuildContext context,
    BlueprintStrings strings,
    DateTime today,
    BlueprintController controller,
    WellnessTreatment treatment,
  ) async {
    final guidance = treatment.courseGuidance;
    var selectedDate = today;
    var multipleSessions = guidance != null;
    var sessionCount = guidance?.recommendedSessions ?? 4;
    var relation = TrainingRelation.independent;
    var cadence = guidance?.recommendedSpacingDays == 1
        ? _PlanningCadence.daily
        : _PlanningCadence.alternateDays;
    final extraDates = <DateTime>[];

    return showModalBottomSheet<_PlanConfiguration>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.planTreatment,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                guidance?.summary(strings.isSpanish) ??
                    treatment.summary(strings.isSpanish),
              ),
              const SizedBox(height: 14),
              Text(
                strings.planShape,
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    label: Text(strings.singleDose),
                    selected: !multipleSessions,
                    onSelected: (_) => setState(() => multipleSessions = false),
                  ),
                  ChoiceChip(
                    label: Text(strings.repeatedPlan),
                    selected: multipleSessions,
                    onSelected: (_) => setState(() => multipleSessions = true),
                  ),
                ],
              ),
              if (guidance != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${strings.courseWindow}: ${strings.courseRangeLabel(guidance.minSessions, guidance.maxSessions)}',
                  style: Theme.of(ctx).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 14),
              Text(
                '${strings.courseStartDate}: ${strings.shortDate(selectedDate)}',
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate,
                        firstDate: today,
                        lastDate: DateTime(today.year, today.month, today.day + 365),
                        helpText: strings.courseStartDate,
                        cancelText: strings.cancel,
                    confirmText: strings.save,
                  );
                  if (picked != null) {
                    final normalized = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                    );
                    setState(() {
                      selectedDate = normalized;
                      extraDates.removeWhere(
                        (entry) => !entry.isAfter(normalized),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text(strings.courseStartDate),
              ),
              const SizedBox(height: 14),
              if (multipleSessions) ...[
                if (cadence != _PlanningCadence.customDates) ...[
                  Text(
                    '${strings.courseTotalSessions}: $sessionCount',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  if (guidance != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${strings.courseWindow}: ${strings.courseRangeLabel(guidance.minSessions, guidance.maxSessions)}',
                        style: Theme.of(ctx).textTheme.bodySmall,
                      ),
                    ),
                  Slider(
                    value: sessionCount.toDouble(),
                    min: (guidance?.minSessions ?? 2).toDouble(),
                    max: (guidance?.maxSessions ?? 20).toDouble(),
                    divisions: (guidance?.maxSessions ?? 20) -
                        (guidance?.minSessions ?? 2),
                    label: '$sessionCount',
                    onChanged: (value) =>
                        setState(() => sessionCount = value.round()),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  strings.planningCadence,
                  style: Theme.of(ctx).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _PlanningCadence.values.map((option) {
                    return ChoiceChip(
                      label: Text(_cadenceLabel(strings, option)),
                      selected: cadence == option,
                      onSelected: (_) => setState(() => cadence = option),
                    );
                  }).toList(growable: false),
                ),
                if (cadence == _PlanningCadence.customDates) ...[
                  const SizedBox(height: 12),
                  Text(
                    strings.selectedDays,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(label: Text(strings.shortDate(selectedDate))),
                      ...extraDates.map(
                        (date) => InputChip(
                          label: Text(strings.shortDate(date)),
                          onDeleted: () => setState(() => extraDates.remove(date)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: selectedDate.add(const Duration(days: 1)),
                        firstDate: selectedDate,
                        lastDate:
                            DateTime(today.year, today.month, today.day + 365),
                        helpText: strings.addCalendarDay,
                        cancelText: strings.cancel,
                        confirmText: strings.save,
                      );
                      if (picked == null) return;
                      final normalized = DateTime(
                        picked.year,
                        picked.month,
                        picked.day,
                      );
                      if (normalized == selectedDate ||
                          extraDates.any((entry) => entry == normalized)) {
                        return;
                      }
                      setState(() => extraDates.add(normalized));
                    },
                    icon: const Icon(Icons.add_outlined),
                    label: Text(strings.addCalendarDay),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    '${strings.courseSpacing}: ${_cadenceLabel(strings, cadence)}',
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
              const SizedBox(height: 14),
              Text(
                strings.planRelationTitle,
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              ..._buildPlanningCompatibilityNotes(
                context,
                strings,
                compatibility: controller.compatibilityForTreatment(
                  treatment: treatment,
                  referenceTime: DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    12,
                  ),
                ),
                relation: relation,
                selectedDate: selectedDate,
                today: today,
              ),
              const SizedBox(height: 16),
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
                      onPressed: () {
                        final dates = _resolvePlannedDates(
                          startDate: selectedDate,
                          multipleSessions: multipleSessions,
                          sessionCount: sessionCount,
                          cadence: cadence,
                          extraDates: extraDates,
                        );
                        if (dates.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text(strings.startDateRequired)),
                          );
                          return;
                        }
                        if (multipleSessions &&
                            cadence == _PlanningCadence.customDates &&
                            dates.length < 2) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(strings.addAtLeastOneExtraDay),
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop(
                          _PlanConfiguration(
                            dates: dates,
                            trainingRelation: relation,
                          ),
                        );
                      },
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

  List<DateTime> _resolvePlannedDates({
    required DateTime startDate,
    required bool multipleSessions,
    required int sessionCount,
    required _PlanningCadence cadence,
    required List<DateTime> extraDates,
  }) {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    if (!multipleSessions) {
      return [normalizedStart];
    }
    if (cadence == _PlanningCadence.customDates) {
      final dates = <DateTime>{normalizedStart, ...extraDates}.toList()..sort();
      return dates;
    }
    final spacingDays = switch (cadence) {
      _PlanningCadence.daily => 1,
      _PlanningCadence.alternateDays => 2,
      _PlanningCadence.weekly => 7,
      _PlanningCadence.fortnightly => 14,
      _PlanningCadence.customDates => 0,
    };
    return List<DateTime>.generate(
      sessionCount,
      (index) => DateTime(
        normalizedStart.year,
        normalizedStart.month,
        normalizedStart.day + (spacingDays * index),
      ),
    );
  }

  String _cadenceLabel(BlueprintStrings strings, _PlanningCadence cadence) {
    switch (cadence) {
      case _PlanningCadence.daily:
        return strings.dailyCadence;
      case _PlanningCadence.alternateDays:
        return strings.alternateCadence;
      case _PlanningCadence.weekly:
        return strings.weeklyCadence;
      case _PlanningCadence.fortnightly:
        return strings.fortnightlyCadence;
      case _PlanningCadence.customDates:
        return strings.customCadence;
    }
  }

  List<Widget> _buildPlanningCompatibilityNotes(
    BuildContext context,
    BlueprintStrings strings, {
    required List<TrainingCompatibilityAssessment> compatibility,
    required TrainingRelation relation,
    required DateTime selectedDate,
    required DateTime today,
  }) {
    if (relation != TrainingRelation.afterTraining) {
      return const [];
    }
    final isToday = selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;
    TrainingCompatibilityAssessment? mostRestrictive;
    for (final entry in compatibility) {
      if (mostRestrictive == null) {
        mostRestrictive = entry;
        continue;
      }
      if (_compatibilityRank(entry.status) > _compatibilityRank(mostRestrictive.status)) {
        mostRestrictive = entry;
      }
    }

    if (mostRestrictive == null) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BlueprintTheme.seafoam.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BlueprintTheme.seafoam.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            strings.suitableForSelectedDay,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ];
    }

    final status = mostRestrictive.status;
    final showCaution = status == TrainingCompatibilityStatus.waitUntilRecovered ||
        status == TrainingCompatibilityStatus.compatibleWithCaution ||
        status == TrainingCompatibilityStatus.limitedEvidence;
    if (showCaution) {
      return [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BlueprintTheme.coral.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: BlueprintTheme.coral.withValues(alpha: 0.18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.compatibilityForSelectedDay,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                strings.compatibilityAssessmentSummary(
                  status,
                  afterTraining: true,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                strings.localizedCompatibilityText(mostRestrictive.detail),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (isToday) ...[
                const SizedBox(height: 4),
                Text(strings.cautionForSelectedDay),
              ] else ...[
                const SizedBox(height: 4),
                Text(strings.youCanStillPlanFuture),
              ],
            ],
          ),
        ),
      ];
    }
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BlueprintTheme.seafoam.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: BlueprintTheme.seafoam.withValues(alpha: 0.18),
          ),
        ),
        child: Text(
          strings.suitableForSelectedDay,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ];
  }

  int _compatibilityRank(TrainingCompatibilityStatus status) {
    switch (status) {
      case TrainingCompatibilityStatus.generallyCompatible:
        return 0;
      case TrainingCompatibilityStatus.compatibleWithCaution:
        return 1;
      case TrainingCompatibilityStatus.limitedEvidence:
        return 2;
      case TrainingCompatibilityStatus.waitUntilRecovered:
        return 3;
    }
  }
}

enum _PlanningCadence {
  daily,
  alternateDays,
  weekly,
  fortnightly,
  customDates,
}

class _PlanConfiguration {
  const _PlanConfiguration({
    required this.dates,
    required this.trainingRelation,
  });

  final List<DateTime> dates;
  final TrainingRelation trainingRelation;
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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BlueprintTheme.seafoam.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: BlueprintTheme.seafoam, size: 18),
                ),
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

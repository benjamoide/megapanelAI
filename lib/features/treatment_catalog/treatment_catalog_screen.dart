import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/treatment_catalog/ai_treatment_search_screen.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_detail_screen.dart';
import 'package:provider/provider.dart';

class TreatmentCatalogScreen extends StatefulWidget {
  const TreatmentCatalogScreen({super.key});

  @override
  State<TreatmentCatalogScreen> createState() => _TreatmentCatalogScreenState();
}

class _TreatmentCatalogScreenState extends State<TreatmentCatalogScreen> {
  String _query = '';
  String _category = '__all__';
  TreatmentOrigin _origin = TreatmentOrigin.curated;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final source = controller.catalogForOrigin(_origin);
    final categories = <String>{
      '__all__',
      ...source.map((t) => t.category(strings.isSpanish)),
    }.toList()
      ..sort((a, b) {
        if (a == '__all__') return -1;
        if (b == '__all__') return 1;
        return a.compareTo(b);
      });

    final visible = source.where((t) {
      final localizedCategory = t.category(strings.isSpanish);
      final categoryOk = _category == '__all__' || localizedCategory == _category;
      final haystack =
          '${t.title(strings.isSpanish)} $localizedCategory ${t.goal(strings.isSpanish)} ${t.summary(strings.isSpanish)}'
              .toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      return categoryOk && queryOk;
    }).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.coral,
            secondary: BlueprintTheme.seafoam,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.treatmentCatalogue,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                strings.treatmentCatalogueBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: controller.aiSearchAvailable
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AiTreatmentSearchScreen(),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.auto_awesome_outlined),
                label: Text(strings.aiSearchAction),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _OriginChip(
              label: strings.curatedTreatmentsTitle,
              selected: _origin == TreatmentOrigin.curated,
              onTap: () => setState(() {
                _origin = TreatmentOrigin.curated;
                _category = '__all__';
              }),
            ),
            _OriginChip(
              label: strings.myTreatmentsTitle,
              selected: _origin == TreatmentOrigin.userTreatment,
              onTap: () => setState(() {
                _origin = TreatmentOrigin.userTreatment;
                _category = '__all__';
              }),
            ),
            _OriginChip(
              label: strings.aiDraftsTitle,
              selected: _origin == TreatmentOrigin.aiDraft,
              onTap: () => setState(() {
                _origin = TreatmentOrigin.aiDraft;
                _category = '__all__';
              }),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CatalogContextBanner(origin: _origin),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: strings.searchHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final category = categories[index];
              final selected = category == _category;
              return ChoiceChip(
                label: Text(
                  category == '__all__' ? strings.allCategory : category,
                ),
                selected: selected,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        if (visible.isEmpty)
          _EmptyCatalogState(origin: _origin)
        else
          ...visible.map(
            (treatment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TreatmentCard(
                treatment: treatment,
                plannedToday:
                    controller.isPlannedOn(DateTime.now(), treatment.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _CatalogContextBanner extends StatelessWidget {
  const _CatalogContextBanner({required this.origin});

  final TreatmentOrigin origin;

  @override
  Widget build(BuildContext context) {
    final strings =
        BlueprintStrings(context.watch<BlueprintController>().language);
    final (title, body) = switch (origin) {
      TreatmentOrigin.curated => (
          strings.curatedTreatmentsTitle,
          strings.treatmentCatalogueBody,
        ),
      TreatmentOrigin.userTreatment => (
          strings.myTreatmentsTitle,
          strings.myTreatmentsBody,
        ),
      TreatmentOrigin.aiDraft => (
          strings.aiDraftsTitle,
          strings.aiDraftsBody,
        ),
    };

    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _OriginChip extends StatelessWidget {
  const _OriginChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState({required this.origin});

  final TreatmentOrigin origin;

  @override
  Widget build(BuildContext context) {
    final strings =
        BlueprintStrings(context.watch<BlueprintController>().language);
    final text = switch (origin) {
      TreatmentOrigin.curated => strings.catalogEmptyState,
      TreatmentOrigin.userTreatment => strings.myTreatmentsEmptyState,
      TreatmentOrigin.aiDraft => strings.aiDraftsEmptyState,
    };
    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(text),
      ),
    );
  }
}

class _TreatmentCard extends StatelessWidget {
  const _TreatmentCard({
    required this.treatment,
    required this.plannedToday,
  });

  final WellnessTreatment treatment;
  final bool plannedToday;

  @override
  Widget build(BuildContext context) {
    final strings =
        BlueprintStrings(context.watch<BlueprintController>().language);
    final controller = context.watch<BlueprintController>();
    final today = DateTime.now();
    final compatibility = controller.compatibilityForTreatment(
      treatment: treatment,
    );
    final topCompatibility = compatibility.isEmpty ? null : compatibility.first;

    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TreatmentDetailScreen(treatment: treatment),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                treatment.title(strings.isSpanish),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: BlueprintTheme.fog.withValues(alpha: 0.8),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                treatment.category(strings.isSpanish),
                              ),
                            ),
                            Chip(
                              label: Text(strings.originLabel(treatment.origin)),
                            ),
                            Chip(
                              label: Text(
                                strings.minutesLabel(treatment.durationMinutes),
                              ),
                            ),
                            Chip(
                              label: Text(
                                strings.evidenceLabel(treatment.evidenceLevel),
                              ),
                            ),
                            if (treatment.courseGuidance != null)
                              Chip(
                                backgroundColor:
                                    BlueprintTheme.gold.withValues(alpha: 0.12),
                                label: Text(
                                  strings.courseRangeLabel(
                                    treatment.courseGuidance!.minSessions,
                                    treatment.courseGuidance!.maxSessions,
                                  ),
                                ),
                              ),
                            if (topCompatibility != null)
                              Chip(
                                backgroundColor:
                                    BlueprintTheme.seafoam.withValues(alpha: 0.12),
                                label: Text(
                                  strings.compatibilityStatusLabel(
                                    topCompatibility.status,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (plannedToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: BlueprintTheme.seafoam.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: BlueprintTheme.seafoam.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Icon(
                        Icons.event_available,
                        color: BlueprintTheme.seafoam,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                treatment.summary(strings.isSpanish),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: BlueprintTheme.fog,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      strings.tapForDetailAndSources,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (treatment.originNote(strings.isSpanish) != null) ...[
                const SizedBox(height: 10),
                Text(
                  treatment.originNote(strings.isSpanish)!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (treatment.isAiDraft) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
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
                    OutlinedButton.icon(
                      onPressed: () async {
                        final shouldDiscard =
                            await _confirmDiscardDraft(context, strings);
                        if (!shouldDiscard) return;
                        await controller.removeAiDraft(treatment.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(strings.discardedAiDraft),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(strings.discardAiDraft),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final result = await _pickPlanConfiguration(
                        context,
                        strings,
                        DateTime(today.year, today.month, today.day),
                        treatment,
                      );
                      if (result == null || !context.mounted) return;
                      final plannedCount =
                          await controller.scheduleTreatmentSeries(
                        treatment: treatment,
                        dates: result.dates,
                        momentLabel: result.dates.length == 1 &&
                                _isSameDay(
                                  result.dates.first,
                                  DateTime(today.year, today.month, today.day),
                                )
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
                    },
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(strings.planTreatment),
                  ),
                ],
              ),
              const SizedBox(height: 14),
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
                      '${strings.distancePrefix}: ${treatment.distanceGuidance(strings.isSpanish)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${strings.intensityPrefix}: ${strings.intensitySummary(treatment)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (treatment.courseGuidance != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${strings.courseCadence}: ${strings.everyXDays(treatment.courseGuidance!.recommendedSpacingDays)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if (topCompatibility != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${strings.trainingTypeLabel(topCompatibility.training.type)}: ${strings.compatibilityAssessmentSummary(topCompatibility.status, afterTraining: true)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<_CatalogPlanConfiguration?> _pickPlanConfiguration(
    BuildContext context,
    BlueprintStrings strings,
    DateTime today,
    WellnessTreatment treatment,
  ) async {
    final guidance = treatment.courseGuidance;
    var selectedDate = today;
    var multipleSessions = guidance != null;
    var sessionCount = guidance?.recommendedSessions ?? 4;
    var relation = TrainingRelation.independent;
    var cadence = guidance?.recommendedSpacingDays == 1
        ? _CatalogPlanningCadence.daily
        : _CatalogPlanningCadence.alternateDays;
    final extraDates = <DateTime>[];

    return showModalBottomSheet<_CatalogPlanConfiguration>(
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
                if (cadence != _CatalogPlanningCadence.customDates) ...[
                  Text(
                    '${strings.courseTotalSessions}: $sessionCount',
                    style: Theme.of(ctx).textTheme.titleSmall,
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
                  children: _CatalogPlanningCadence.values.map((option) {
                    return ChoiceChip(
                      label: Text(_cadenceLabel(strings, option)),
                      selected: cadence == option,
                      onSelected: (_) => setState(() => cadence = option),
                    );
                  }).toList(growable: false),
                ),
                if (cadence == _CatalogPlanningCadence.customDates) ...[
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
                          onDeleted: () =>
                              setState(() => extraDates.remove(date)),
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
                        lastDate: DateTime(today.year, today.month, today.day + 365),
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
                            cadence == _CatalogPlanningCadence.customDates &&
                            dates.length < 2) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(strings.addAtLeastOneExtraDay),
                            ),
                          );
                          return;
                        }
                        Navigator.of(ctx).pop(
                          _CatalogPlanConfiguration(
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
    required _CatalogPlanningCadence cadence,
    required List<DateTime> extraDates,
  }) {
    final normalizedStart =
        DateTime(startDate.year, startDate.month, startDate.day);
    if (!multipleSessions) return [normalizedStart];
    if (cadence == _CatalogPlanningCadence.customDates) {
      final dates = <DateTime>{normalizedStart, ...extraDates}.toList()..sort();
      return dates;
    }
    final spacingDays = switch (cadence) {
      _CatalogPlanningCadence.daily => 1,
      _CatalogPlanningCadence.alternateDays => 2,
      _CatalogPlanningCadence.weekly => 7,
      _CatalogPlanningCadence.fortnightly => 14,
      _CatalogPlanningCadence.customDates => 0,
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

  String _cadenceLabel(
    BlueprintStrings strings,
    _CatalogPlanningCadence cadence,
  ) {
    switch (cadence) {
      case _CatalogPlanningCadence.daily:
        return strings.dailyCadence;
      case _CatalogPlanningCadence.alternateDays:
        return strings.alternateCadence;
      case _CatalogPlanningCadence.weekly:
        return strings.weeklyCadence;
      case _CatalogPlanningCadence.fortnightly:
        return strings.fortnightlyCadence;
      case _CatalogPlanningCadence.customDates:
        return strings.customCadence;
    }
  }
}

enum _CatalogPlanningCadence {
  daily,
  alternateDays,
  weekly,
  fortnightly,
  customDates,
}

class _CatalogPlanConfiguration {
  const _CatalogPlanConfiguration({
    required this.dates,
    required this.trainingRelation,
  });

  final List<DateTime> dates;
  final TrainingRelation trainingRelation;
}

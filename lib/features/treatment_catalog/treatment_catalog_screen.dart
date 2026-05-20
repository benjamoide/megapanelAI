import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
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

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final categories = <String>{
      '__all__',
      ...controller.treatments.map((t) => t.categoryEs),
    }.toList()
      ..sort((a, b) {
        if (a == '__all__') return -1;
        if (b == '__all__') return 1;
        return a.compareTo(b);
      });

    final visible = controller.treatments.where((t) {
      final categoryOk = _category == '__all__' || t.categoryEs == _category;
      final haystack =
          '${t.title(strings.isSpanish)} ${t.category(strings.isSpanish)} ${t.goal(strings.isSpanish)} ${t.summary(strings.isSpanish)}'
              .toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      return categoryOk && queryOk;
    }).toList();

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
            ],
          ),
        ),
        const SizedBox(height: 18),
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
                  category == '__all__'
                      ? strings.allCategory
                      : controller.treatments
                          .firstWhere((t) => t.categoryEs == category)
                          .category(strings.isSpanish),
                ),
                selected: selected,
                onSelected: (_) => setState(() => _category = category),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
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
    final compatibility = controller.compatibilityForTreatment(
      treatment: treatment,
    );
    final topCompatibility =
        compatibility.isEmpty ? null : compatibility.first;

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
                              label: Text(strings
                                  .minutesLabel(treatment.durationMinutes)),
                            ),
                            Chip(
                              label: Text(
                                strings.evidenceLabel(treatment.evidenceLevel),
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
}

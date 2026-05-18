import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_detail_screen.dart';
import 'package:provider/provider.dart';

class TreatmentCatalogScreen extends StatefulWidget {
  const TreatmentCatalogScreen({super.key});

  @override
  State<TreatmentCatalogScreen> createState() => _TreatmentCatalogScreenState();
}

class _TreatmentCatalogScreenState extends State<TreatmentCatalogScreen> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final categories = <String>{
      'All',
      ...controller.treatments.map((t) => t.category),
    }.toList()
      ..sort();

    final visible = controller.treatments.where((t) {
      final categoryOk = _category == 'All' || t.category == _category;
      final haystack =
          '${t.title} ${t.category} ${t.goal} ${t.summary}'.toLowerCase();
      final queryOk = _query.trim().isEmpty ||
          haystack.contains(_query.trim().toLowerCase());
      return categoryOk && queryOk;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Treatment catalogue',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a goal, review recommended settings and plan it into your week.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 18),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Search by goal, area or symptom',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 12),
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
                label: Text(category),
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
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
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
                        Text(
                          treatment.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text(treatment.category)),
                            Chip(
                                label:
                                    Text('${treatment.durationMinutes} min')),
                            Chip(label: Text(treatment.evidenceLevel.label)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (plannedToday)
                    const Icon(Icons.event_available, color: Colors.green),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                treatment.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Text(
                'Distance: ${treatment.distanceGuidance}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Intensity: ${treatment.intensitySummary}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

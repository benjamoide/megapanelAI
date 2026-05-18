import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/evidence/evidence_level.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
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
    final today = DateTime.now();

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
                      label: Text(treatment.evidenceLevel.label),
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
            title: 'Configuration',
            rows: [
              _MetricRow('Duration', '${treatment.durationMinutes} min'),
              _MetricRow('Distance', treatment.distanceGuidance),
              _MetricRow('Pulse / mode', treatment.pulseGuidance),
              _MetricRow('Suggested intensity', treatment.intensitySummary),
              _MetricRow('Evidence level', treatment.evidenceLevel.label),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Safety notes',
            icon: Icons.shield_outlined,
            children: treatment.safetyNotes
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Before session',
            icon: Icons.wb_sunny_outlined,
            children: treatment.beforeSessionTips
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'After session',
            icon: Icons.self_improvement_outlined,
            children: treatment.afterSessionTips
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Source references',
            icon: Icons.menu_book_outlined,
            children: treatment.sourceReferences
                .map((note) => _BulletLine(text: note))
                .toList(growable: false),
          ),
          const SizedBox(height: 18),
          Text(
            BlueprintController.disclaimer,
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
                    await controller.scheduleTreatment(
                      treatment: treatment,
                      date: today,
                      momentLabel: 'Today',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Planned for ${DateFormat('EEE d MMM').format(today)}',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.event_available_outlined),
                  label: const Text('Plan for today'),
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
                    );
                    if (selectedDate == null) return;
                    await controller.scheduleTreatment(
                      treatment: treatment,
                      date: selectedDate,
                      momentLabel: 'Scheduled',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Scheduled for ${DateFormat('EEE d MMM').format(selectedDate)}',
                          ),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Choose a date'),
                ),
              ),
            ],
          ),
        ],
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:provider/provider.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final history = controller.history;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.gold,
            secondary: BlueprintTheme.ruby,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.sessionHistory,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.sessionHistoryBody,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  final payload = value == 'csv'
                      ? controller.exportHistoryAsCsv()
                      : controller.exportHistoryAsJson();
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(strings.historyCopiedAs(value)),
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'csv',
                    child: Text(strings.copyCsvExport),
                  ),
                  PopupMenuItem(
                    value: 'json',
                    child: Text(strings.copyJsonExport),
                  ),
                ],
                child: Chip(label: Text(strings.export)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                strings.noTrackedSessionsYet,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          )
        else
          ...history.map(
            (entry) {
              final treatment = controller.treatmentById(entry.treatmentId);
              final loggedAt = DateTime.tryParse(entry.loggedAtIso)?.toLocal();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecoratedBox(
                  decoration: BlueprintTheme.softPanel(),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                treatment?.title(strings.isSpanish) ??
                                    entry.treatmentId,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Chip(
                              backgroundColor: entry.status.name == 'completed'
                                  ? BlueprintTheme.seafoam
                                      .withValues(alpha: 0.12)
                                  : BlueprintTheme.coral.withValues(alpha: 0.12),
                              label: Text(
                                strings.sessionStatusLabel(entry.status),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _HistoryLine(text: strings.scheduledDay(entry.dateKey)),
                        _HistoryLine(text: strings.moment(entry.momentLabel)),
                        _HistoryLine(
                          text:
                              '${strings.trainingRelationPrefix}: ${strings.trainingRelationLabel(entry.trainingRelation)}',
                        ),
                        if (loggedAt != null)
                          _HistoryLine(text: strings.loggedAt(loggedAt)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _HistoryLine extends StatelessWidget {
  const _HistoryLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

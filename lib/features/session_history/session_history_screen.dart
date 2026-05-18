import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
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
        Row(
          children: [
            Expanded(
              child: Text(
                strings.sessionHistory,
                style: Theme.of(context).textTheme.headlineMedium,
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
                PopupMenuItem(value: 'csv', child: Text(strings.copyCsvExport)),
                PopupMenuItem(
                  value: 'json',
                  child: Text(strings.copyJsonExport),
                ),
              ],
              child: Chip(label: Text(strings.export)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(strings.sessionHistoryBody),
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
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                treatment?.title ?? entry.treatmentId,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Chip(
                              label: Text(
                                strings.sessionStatusLabel(entry.status),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(strings.scheduledDay(entry.dateKey)),
                        Text(strings.moment(entry.momentLabel)),
                        if (loggedAt != null) Text(strings.loggedAt(loggedAt)),
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

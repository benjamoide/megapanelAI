import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:provider/provider.dart';

class SessionHistoryScreen extends StatelessWidget {
  const SessionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final history = controller.history;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Session history',
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
                        content:
                            Text('History copied as ${value.toUpperCase()}')),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'csv', child: Text('Copy CSV export')),
                PopupMenuItem(value: 'json', child: Text('Copy JSON export')),
              ],
              child: const Chip(label: Text('Export')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Completed and skipped sessions stay here for review and export.',
        ),
        const SizedBox(height: 18),
        if (history.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No tracked sessions yet. Plan a treatment and mark it as completed or skipped from the calendar.',
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
                            Chip(label: Text(entry.status.name)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Scheduled day: ${entry.dateKey}'),
                        Text('Moment: ${entry.momentLabel}'),
                        if (loggedAt != null)
                          Text(
                            'Logged at: ${DateFormat('yyyy-MM-dd HH:mm').format(loggedAt)}',
                          ),
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

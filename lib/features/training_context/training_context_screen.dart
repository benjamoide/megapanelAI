import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/training/training_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:provider/provider.dart';

class TrainingContextScreen extends StatelessWidget {
  const TrainingContextScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final sessions = {
      for (final entry in controller.recentTrainingSessions) entry.type: entry,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.ruby,
            secondary: BlueprintTheme.gold,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.trainingContextTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                strings.trainingContextBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Card(
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
                      child: const Icon(
                        Icons.history_toggle_off_outlined,
                        color: BlueprintTheme.seafoam,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        strings.recentTrainingLogged,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (sessions.isEmpty)
                  Text(strings.noTrainingLogged)
                else
                  ...sessions.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: BlueprintTheme.panelRaised,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: BlueprintTheme.outline),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    strings.trainingTypeLabel(entry.key),
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    strings.trainingLoggedAt(
                                      entry.value.performedAt.toLocal(),
                                      strings.trainingExampleLabel(
                                        entry.key,
                                        entry.value.exampleKey,
                                      ),
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: strings.removeTrainingLog,
                              onPressed: () async {
                                await controller.removeTrainingSession(entry.key);
                              },
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (sessions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await controller.clearTrainingSessions();
                    },
                    icon: const Icon(Icons.layers_clear_outlined),
                    label: Text(strings.clearTrainingContext),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...TrainingType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TrainingTypeCard(
              type: type,
              session: sessions[type],
            ),
          ),
        ),
      ],
    );
  }
}

class _TrainingTypeCard extends StatelessWidget {
  const _TrainingTypeCard({
    required this.type,
    required this.session,
  });

  final TrainingType type;
  final RecentTrainingSession? session;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final selectedExample = session?.exampleKey;

    return DecoratedBox(
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
                    strings.trainingTypeLabel(type),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (session != null)
                  Chip(
                    label: Text(
                      strings.trainingLoggedChip(session!.performedAt.toLocal()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(strings.trainingTypeBody(type)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: strings.trainingExamples(type).map((example) {
                return Chip(label: Text(example.$2));
              }).toList(growable: false),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    final exampleKey = await _pickExample(
                      context,
                      strings,
                      type,
                      selectedExample,
                    );
                    if (!context.mounted || exampleKey == null) return;
                    await controller.logTrainingSession(
                      type: type,
                      performedAt: DateTime.now(),
                      exampleKey: exampleKey,
                    );
                  },
                  icon: const Icon(Icons.bolt_outlined),
                  label: Text(strings.logNow),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final dateTime = await _pickDateTime(context, strings);
                    if (!context.mounted || dateTime == null) return;
                    final exampleKey = await _pickExample(
                      context,
                      strings,
                      type,
                      selectedExample,
                    );
                    if (!context.mounted || exampleKey == null) return;
                    await controller.logTrainingSession(
                      type: type,
                      performedAt: dateTime,
                      exampleKey: exampleKey,
                    );
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(strings.chooseDateAndTime),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _pickExample(
    BuildContext context,
    BlueprintStrings strings,
    TrainingType type,
    String? selected,
  ) async {
    var current = selected ?? strings.trainingExamples(type).first.$1;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(strings.selectTrainingExample),
          content: DropdownButtonFormField<String>(
            initialValue: current,
            items: strings.trainingExamples(type).map((example) {
              return DropdownMenuItem<String>(
                value: example.$1,
                child: Text(example.$2),
              );
            }).toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() => current = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(current),
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _pickDateTime(
    BuildContext context,
    BlueprintStrings strings,
  ) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day - 14),
      lastDate: DateTime(now.year, now.month, now.day + 1),
      helpText: strings.chooseDate,
      cancelText: strings.cancel,
      confirmText: strings.save,
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: strings.chooseTime,
      cancelText: strings.cancel,
      confirmText: strings.save,
    );
    if (time == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}

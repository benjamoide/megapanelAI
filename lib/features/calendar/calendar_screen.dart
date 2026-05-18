import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_detail_screen.dart';
import 'package:provider/provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final week = _weekFor(_selectedDate);
    final plans = controller.plansFor(_selectedDate);
    final history = controller.historyFor(_selectedDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Weekly planner',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Plan sessions, see placeholder reminders and mark them as completed or skipped.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Reminders placeholder: connect your preferred notification flow later.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.notifications_outlined),
                      label: const Text('Reminders'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: week.map((day) {
                    final selected = _isSameDay(day, _selectedDate);
                    final plannedCount = controller.plannedCountFor(day);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDate = day),
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  DateFormat('E').format(day),
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plannedCount == 0 ? '—' : '$plannedCount',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _RoutineCard(selectedDate: _selectedDate),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scheduled sessions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (plans.isEmpty)
                  const Text('No treatments scheduled for this day.')
                else
                  ...plans.map(
                    (plan) {
                      final treatment =
                          controller.treatmentById(plan.treatmentId);
                      if (treatment == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          tileColor: Colors.black.withValues(alpha: 0.025),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(treatment.title),
                          subtitle: Text(
                            '${plan.momentLabel} · ${plan.reminderPlaceholder}',
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    TreatmentDetailScreen(treatment: treatment),
                              ),
                            );
                          },
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Completed',
                                onPressed: () async {
                                  await controller.markStatus(
                                    date: _selectedDate,
                                    treatment: treatment,
                                    status: SessionStatus.completed,
                                    momentLabel: plan.momentLabel,
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                              IconButton(
                                tooltip: 'Skipped',
                                onPressed: () async {
                                  await controller.markStatus(
                                    date: _selectedDate,
                                    treatment: treatment,
                                    status: SessionStatus.skipped,
                                    momentLabel: plan.momentLabel,
                                  );
                                },
                                icon: const Icon(Icons.skip_next_outlined),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Day results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  const Text('Nothing marked yet for this day.')
                else
                  ...history.map(
                    (entry) {
                      final treatment =
                          controller.treatmentById(entry.treatmentId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(treatment?.title ?? entry.treatmentId),
                        subtitle: Text(
                          '${entry.status.name} · ${entry.momentLabel} · ${DateFormat('HH:mm').format(DateTime.parse(entry.loggedAtIso).toLocal())}',
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DateTime> _weekFor(DateTime date) {
    final first = date.subtract(Duration(days: date.weekday - 1));
    return List<DateTime>.generate(
      7,
      (index) => DateTime(first.year, first.month, first.day + index),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final routine = controller.weeklyRoutines[selectedDate.weekday];
    if (routine == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine anchor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text('Focus block: ${routine.focusLabel}'),
            const SizedBox(height: 6),
            Text('Cardio block: ${routine.cardioLabel}'),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _editRoutine(context, controller, routine),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Edit routine labels'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editRoutine(
    BuildContext context,
    BlueprintController controller,
    WeeklyRoutine routine,
  ) async {
    final focusCtrl = TextEditingController(text: routine.focusLabel);
    final cardioCtrl = TextEditingController(text: routine.cardioLabel);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit weekly routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: focusCtrl,
              decoration: const InputDecoration(labelText: 'Focus block'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cardioCtrl,
              decoration: const InputDecoration(labelText: 'Cardio block'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await controller.updateRoutine(
                weekday: routine.weekday,
                focusLabel: focusCtrl.text.trim(),
                cardioLabel: cardioCtrl.text.trim(),
              );
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

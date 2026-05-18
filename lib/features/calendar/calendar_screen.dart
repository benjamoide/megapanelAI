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
    final week = controller.weekFor(_selectedDate);
    final plans = controller.plansFor(_selectedDate);
    final history = controller.historyFor(_selectedDate);
    final nextSession = controller.nextPlannedSession;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Weekly schedule',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Plan treatments through the week, review upcoming reminders and track each session once it is completed or skipped.',
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
                    Chip(
                      label: Text(
                        controller.reminderSettings.enabled
                            ? '${controller.reminderSettings.reminders.where((entry) => entry.enabled).length} reminders'
                            : 'Reminders off',
                      ),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder snapshot',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (nextSession == null)
                  const Text(
                    'No future treatment is planned yet, so there is nothing to notify.',
                  )
                else ...[
                  Text(
                    'Next treatment: ${nextSession.treatment.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('EEE d MMM').format(nextSession.date)} · ${nextSession.session.momentLabel}',
                  ),
                  const SizedBox(height: 8),
                  ...controller.reminderTimesFor(nextSession.date).map(
                        (time) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            DateFormat('EEE d MMM · HH:mm').format(time),
                          ),
                        ),
                      ),
                ],
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
                            '${plan.momentLabel} · ${controller.reminderSummaryForPlan(plan)}',
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

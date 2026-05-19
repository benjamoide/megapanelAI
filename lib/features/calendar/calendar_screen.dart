import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
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
    final strings = BlueprintStrings(controller.language);
    final week = controller.weekFor(_selectedDate);
    final plans = controller.plansFor(_selectedDate);
    final history = controller.historyFor(_selectedDate);
    final nextSession = controller.nextPlannedSession;
    final enabledReminderCount = controller.reminderSettings.reminders
        .where((entry) => entry.enabled)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          strings.weeklySchedule,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(strings.weeklyScheduleBody),
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
                      strings.monthYear(_selectedDate),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Chip(
                      label: Text(
                        controller.reminderSettings.enabled
                            ? strings.remindersCount(enabledReminderCount)
                            : strings.remindersOff,
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
                                  strings.weekdayShort(day.weekday),
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
                                  plannedCount == 0 ? '-' : '$plannedCount',
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
                  strings.reminderSnapshot,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (nextSession == null)
                  Text(strings.noFutureTreatment)
                else ...[
                  Text(
                    strings.nextTreatmentLine(nextSession.treatment.title),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.formattedMomentDate(
                      nextSession.date,
                      nextSession.session.momentLabel,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...controller.reminderTimesFor(nextSession.date).map(
                        (time) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${strings.shortDate(time)} - ${strings.timeLabel(time)}',
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
                  strings.scheduledSessions,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (plans.isEmpty)
                  Text(strings.noTreatmentsScheduledForDay)
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
                            '${strings.translateMomentLabel(plan.momentLabel)} - ${controller.reminderSummaryForPlan(plan, strings)}\n${strings.trainingRelationPrefix}: ${strings.trainingRelationLabel(plan.trainingRelation)}',
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
                                tooltip: strings.completed,
                                onPressed: () async {
                                  await controller.markStatus(
                                    date: _selectedDate,
                                    treatment: treatment,
                                    status: SessionStatus.completed,
                                    momentLabel: plan.momentLabel,
                                    trainingRelation: plan.trainingRelation,
                                  );
                                },
                                icon: const Icon(Icons.check_circle_outline),
                              ),
                              IconButton(
                                tooltip: strings.skipped,
                                onPressed: () async {
                                  await controller.markStatus(
                                    date: _selectedDate,
                                    treatment: treatment,
                                    status: SessionStatus.skipped,
                                    momentLabel: plan.momentLabel,
                                    trainingRelation: plan.trainingRelation,
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
                  strings.dayResults,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Text(strings.nothingMarkedYet)
                else
                  ...history.map(
                    (entry) {
                      final treatment =
                          controller.treatmentById(entry.treatmentId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(treatment?.title ?? entry.treatmentId),
                        subtitle: Text(
                          '${strings.historyEntryLine(entry)}\n${strings.trainingRelationPrefix}: ${strings.trainingRelationLabel(entry.trainingRelation)}',
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

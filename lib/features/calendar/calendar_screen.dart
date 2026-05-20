import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
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
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.seafoam,
            secondary: BlueprintTheme.ruby,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.weeklySchedule,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                strings.weeklyScheduleBody,
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? BlueprintTheme.seafoam
                                      .withValues(alpha: 0.16)
                                  : BlueprintTheme.panelRaised,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? BlueprintTheme.seafoam
                                        .withValues(alpha: 0.25)
                                    : BlueprintTheme.outline,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  strings.weekdayShort(day.weekday),
                                  style: TextStyle(
                                    color: selected
                                        ? BlueprintTheme.pearl
                                        : BlueprintTheme.fog,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    color: selected
                                        ? BlueprintTheme.pearl
                                        : BlueprintTheme.pearl,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plannedCount == 0 ? '-' : '$plannedCount',
                                  style: TextStyle(
                                    color: selected
                                        ? BlueprintTheme.seafoam
                                        : BlueprintTheme.fog,
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
        _CalendarPanel(
          title: strings.reminderSnapshot,
          icon: Icons.notifications_active_outlined,
          child: nextSession == null
              ? Text(strings.noFutureTreatment)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.nextTreatmentLine(
                        nextSession.treatment.title(strings.isSpanish),
                      ),
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
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _CalendarPanel(
          title: strings.scheduledSessions,
          icon: Icons.event_note_outlined,
          child: plans.isEmpty
              ? Text(strings.noTreatmentsScheduledForDay)
              : Column(
                  children: plans.map(
                    (plan) {
                      final treatment =
                          controller.treatmentById(plan.treatmentId);
                      if (treatment == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
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
                                treatment.title(strings.isSpanish),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${strings.translateMomentLabel(plan.momentLabel)} - ${controller.reminderSummaryForPlan(plan, strings)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${strings.trainingRelationPrefix}: ${strings.trainingRelationLabel(plan.trainingRelation)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => TreatmentDetailScreen(
                                            treatment: treatment,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.open_in_new_outlined),
                                    label: const Text('Open'),
                                  ),
                                  const Spacer(),
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
                            ],
                          ),
                        ),
                      );
                    },
                  ).toList(growable: false),
                ),
        ),
        const SizedBox(height: 14),
        _CalendarPanel(
          title: strings.dayResults,
          icon: Icons.task_alt_outlined,
          child: history.isEmpty
              ? Text(strings.nothingMarkedYet)
              : Column(
                  children: history.map(
                    (entry) {
                      final treatment =
                          controller.treatmentById(entry.treatmentId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
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
                              treatment?.title(strings.isSpanish) ??
                                  entry.treatmentId,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              strings.historyEntryLine(entry),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${strings.trainingRelationPrefix}: ${strings.trainingRelationLabel(entry.trainingRelation)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      );
                    },
                  ).toList(growable: false),
                ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

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
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: BlueprintTheme.coral.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: BlueprintTheme.coral, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

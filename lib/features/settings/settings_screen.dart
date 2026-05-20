import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);
    final reminders = controller.reminderSettings.reminders;
    final enabledReminders =
        reminders.where((entry) => entry.enabled).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.seafoam,
            secondary: BlueprintTheme.gold,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.reminderSettings,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                strings.reminderSettingsBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _SettingsPanel(
          title: strings.languageTitle,
          icon: Icons.translate_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.languageSubtitle),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppLanguage.values.map((language) {
                  final selected = controller.language == language;
                  return ChoiceChip(
                    label: Text(
                      language == AppLanguage.spanish
                          ? strings.spanishLabel
                          : strings.englishLabel,
                    ),
                    selected: selected,
                    onSelected: (_) => controller.setLanguage(language),
                  );
                }).toList(growable: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SettingsPanel(
          title: strings.enableTreatmentReminders,
          icon: Icons.notifications_active_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: controller.reminderSettings.enabled,
                onChanged: controller.notificationsSupported
                    ? controller.setReminderNotificationsEnabled
                    : null,
                title: Text(strings.enableTreatmentReminders),
                subtitle: Text(
                  controller.notificationsSupported
                      ? strings.reminderCalendarSource
                      : strings.notificationsNotSupported,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text(
                      controller.notificationsPermissionGranted
                          ? strings.notificationsAllowed
                          : strings.permissionNeeded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (controller.notificationsSupported &&
                      !controller.notificationsPermissionGranted)
                    OutlinedButton(
                      onPressed: () async {
                        await controller.requestNotificationPermissions();
                      },
                      child: Text(strings.allowNotifications),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SettingsPanel(
          title: strings.activeReminders,
          icon: Icons.alarm_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.activeReminders,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: controller.notificationsSupported
                        ? () => _openReminderEditor(context, controller)
                        : null,
                    icon: const Icon(Icons.add_alert_outlined),
                    label: Text(strings.addReminder),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (enabledReminders.isEmpty)
                Text(strings.noActiveRemindersYet)
              else
                ...enabledReminders.map(
                  (reminder) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: BlueprintTheme.panelRaised,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: BlueprintTheme.outline),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.reminderPreferenceSummary(reminder),
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.reminderDescription(reminder),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: strings.editReminder,
                            onPressed: () => _openReminderEditor(
                              context,
                              controller,
                              existing: reminder,
                            ),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: strings.removeReminder,
                            onPressed: () async {
                              await controller.removeReminderPreference(
                                reminder.id,
                              );
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SettingsPanel(
          title: strings.reminderBehavior,
          icon: Icons.info_outline,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(strings.reminderBehaviorBody),
              const SizedBox(height: 10),
              Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openReminderEditor(
    BuildContext context,
    BlueprintController controller, {
    ReminderPreference? existing,
  }) async {
    final strings = BlueprintStrings(controller.language);
    var leadTime = existing?.leadTime ?? ReminderLeadTime.sameDay;
    var selectedTime =
        TimeOfDay(hour: existing?.hour ?? 9, minute: existing?.minute ?? 0);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(
              existing == null
                  ? strings.addReminderDialogTitle
                  : strings.editReminderDialogTitle,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ReminderLeadTime>(
                  initialValue: leadTime,
                  decoration: InputDecoration(labelText: strings.when),
                  items: ReminderLeadTime.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(strings.reminderLeadTimeLabel(value)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => leadTime = value);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                      helpText: strings.when,
                      cancelText: strings.cancel,
                      confirmText: strings.save,
                    );
                    if (picked == null) return;
                    setState(() => selectedTime = picked);
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    strings.timeButtonLabel(selectedTime.format(ctx)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(strings.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  if (existing == null) {
                    await controller.addReminderPreference(
                      leadTime: leadTime,
                      hour: selectedTime.hour,
                      minute: selectedTime.minute,
                    );
                  } else {
                    await controller.updateReminderPreference(
                      existing.copyWith(
                        leadTime: leadTime,
                        hour: selectedTime.hour,
                        minute: selectedTime.minute,
                      ),
                    );
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: Text(strings.save),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({
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
                    color: BlueprintTheme.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: BlueprintTheme.gold, size: 18),
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

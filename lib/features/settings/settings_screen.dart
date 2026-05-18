import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/scheduling/scheduling_models.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final reminders = controller.reminderSettings.reminders;
    final enabledReminders =
        reminders.where((entry) => entry.enabled).toList(growable: false);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Text(
          'Reminder settings',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose whether reminders arrive the same day or one day before, select the hour and add as many reminders as you need.',
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: controller.reminderSettings.enabled,
                  onChanged: controller.notificationsSupported
                      ? controller.setReminderNotificationsEnabled
                      : null,
                  title: const Text('Enable treatment reminders'),
                  subtitle: Text(
                    controller.notificationsSupported
                        ? 'Reminders are scheduled from your treatment calendar.'
                        : 'Notifications are not supported on this platform preview.',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        controller.notificationsPermissionGranted
                            ? 'Notifications allowed'
                            : 'Permission needed',
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (controller.notificationsSupported &&
                        !controller.notificationsPermissionGranted)
                      OutlinedButton(
                        onPressed: () async {
                          await controller.requestNotificationPermissions();
                        },
                        child: const Text('Allow notifications'),
                      ),
                  ],
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Active reminders',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: controller.notificationsSupported
                          ? () => _openReminderEditor(context, controller)
                          : null,
                      icon: const Icon(Icons.add_alert_outlined),
                      label: const Text('Add reminder'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (enabledReminders.isEmpty)
                  const Text(
                    'No active reminders yet. Add one or more reminders to stay on track with planned treatments.',
                  )
                else
                  ...enabledReminders.map(
                    (reminder) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        tileColor: Colors.black.withValues(alpha: 0.025),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        title: Text(reminder.summary),
                        subtitle: Text(
                          reminder.leadTime == ReminderLeadTime.dayBefore
                              ? 'Sent one day before at ${reminder.timeLabel}'
                              : 'Sent the same day at ${reminder.timeLabel}',
                        ),
                        trailing: Wrap(
                          spacing: 6,
                          children: [
                            IconButton(
                              tooltip: 'Edit reminder',
                              onPressed: () => _openReminderEditor(
                                context,
                                controller,
                                existing: reminder,
                              ),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Remove reminder',
                              onPressed: () async {
                                await controller
                                    .removeReminderPreference(reminder.id);
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
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder behavior',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Reminders are created from your planned treatments. Completed or skipped sessions stop generating future notifications for that day.',
                ),
                const SizedBox(height: 8),
                Text(
                  BlueprintController.disclaimer,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
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
    var leadTime = existing?.leadTime ?? ReminderLeadTime.sameDay;
    var selectedTime =
        TimeOfDay(hour: existing?.hour ?? 9, minute: existing?.minute ?? 0);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(existing == null ? 'Add reminder' : 'Edit reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<ReminderLeadTime>(
                  initialValue: leadTime,
                  decoration: const InputDecoration(labelText: 'When'),
                  items: ReminderLeadTime.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
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
                    );
                    if (picked == null) return;
                    setState(() => selectedTime = picked);
                  },
                  icon: const Icon(Icons.schedule_outlined),
                  label: Text(
                    'Time · ${selectedTime.format(ctx)}',
                  ),
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
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}

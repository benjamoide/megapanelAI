import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/calendar/calendar_screen.dart';
import 'package:mega_panel_ai/features/session_history/session_history_screen.dart';
import 'package:mega_panel_ai/features/settings/settings_screen.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_catalog_screen.dart';
import 'package:provider/provider.dart';

class BlueprintOneApp extends StatelessWidget {
  const BlueprintOneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blueprint One',
      debugShowCheckedModeBanner: false,
      theme: BlueprintTheme.light(),
      home: const BlueprintShell(),
    );
  }
}

class BlueprintShell extends StatefulWidget {
  const BlueprintShell({super.key});

  @override
  State<BlueprintShell> createState() => _BlueprintShellState();
}

class _BlueprintShellState extends State<BlueprintShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = _initialIndexFromUri();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    const pages = <Widget>[
      _OverviewScreen(),
      TreatmentCatalogScreen(),
      CalendarScreen(),
      SessionHistoryScreen(),
      SettingsScreen(),
    ];
    const labels = [
      'Overview',
      'Treatments',
      'Calendar',
      'History',
      'Settings'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blueprint One'),
      ),
      body: controller.ready
          ? pages[_index]
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: List<NavigationDestination>.generate(
          labels.length,
          (index) => NavigationDestination(
            icon: Icon(_iconFor(index)),
            label: labels[index],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.wb_sunny_outlined;
      case 1:
        return Icons.auto_awesome_mosaic_outlined;
      case 2:
        return Icons.calendar_month_outlined;
      case 3:
        return Icons.history_edu_outlined;
      case 4:
        return Icons.notifications_active_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  int _initialIndexFromUri() {
    final tab = Uri.base.queryParameters['tab']?.toLowerCase().trim();
    switch (tab) {
      case 'treatments':
        return 1;
      case 'calendar':
        return 2;
      case 'history':
        return 3;
      case 'settings':
        return 4;
      case 'overview':
      default:
        return 0;
    }
  }
}

class _OverviewScreen extends StatelessWidget {
  const _OverviewScreen();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final today = DateTime.now();
    final plansToday = controller.plansFor(today);
    final historyToday = controller.historyFor(today);
    final nextSession = controller.nextPlannedSession;
    final enabledReminders = controller.reminderSettings.reminders
        .where((entry) => entry.enabled)
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF4E8), Color(0xFFE9F6F2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A clearer way to follow light therapy plans',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'Review evidence-based treatments, schedule them through the week and keep a clean record of completed or skipped sessions.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                BlueprintController.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Today planned',
                value: '${plansToday.length}',
                subtitle: 'Sessions waiting in your calendar',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Today tracked',
                value: '${historyToday.length}',
                subtitle: 'Completed or skipped entries',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'This week planned',
                value: '${controller.plannedCountForWeek(today)}',
                subtitle: 'Upcoming sessions across the current week',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Reminders active',
                value: '$enabledReminders',
                subtitle: controller.reminderSettings.enabled
                    ? 'Notification schedule ready'
                    : 'Turn reminders on in settings',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next planned treatment',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (nextSession == null)
                  const Text(
                    'Nothing planned yet. Open the catalogue and add a treatment to your calendar.',
                  )
                else ...[
                  Text(
                    nextSession.treatment.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${DateFormat('EEE d MMM').format(nextSession.date)} · ${nextSession.session.momentLabel}',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.reminderSummaryForPlan(nextSession.session),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'What you can do here',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        const _CapabilityLine(
          title: 'Browse treatments',
          body:
              'Open the catalogue, compare goals, duration, distance and suggested intensity distribution.',
        ),
        const _CapabilityLine(
          title: 'Plan your week',
          body:
              'Assign treatments to specific days, review the week at a glance and keep reminder timing aligned with your schedule.',
        ),
        const _CapabilityLine(
          title: 'Track consistency',
          body:
              'Mark sessions as completed or skipped and export the history for your own records.',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(subtitle),
          ],
        ),
      ),
    );
  }
}

class _CapabilityLine extends StatelessWidget {
  const _CapabilityLine({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 8),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title. ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

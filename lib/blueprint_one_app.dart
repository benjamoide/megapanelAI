import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
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
    final language = context.watch<BlueprintController>().language;
    final strings = BlueprintStrings(language);

    return MaterialApp(
      title: strings.appTitle,
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
    final strings = BlueprintStrings(controller.language);
    const pages = <Widget>[
      _OverviewScreen(),
      TreatmentCatalogScreen(),
      CalendarScreen(),
      SessionHistoryScreen(),
      SettingsScreen(),
    ];
    final labels = [
      strings.navOverview,
      strings.navTreatments,
      strings.navCalendar,
      strings.navHistory,
      strings.navSettings,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
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
    final strings = BlueprintStrings(controller.language);
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
                strings.heroTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                strings.heroBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Text(
                strings.disclaimer,
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
                title: strings.todayPlanned,
                value: '${plansToday.length}',
                subtitle: strings.sessionsWaitingInCalendar,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: strings.todayTracked,
                value: '${historyToday.length}',
                subtitle: strings.completedOrSkippedEntries,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: strings.thisWeekPlanned,
                value: '${controller.plannedCountForWeek(today)}',
                subtitle: strings.upcomingSessionsAcrossWeek,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: strings.remindersActive,
                value: '$enabledReminders',
                subtitle: controller.reminderSettings.enabled
                    ? strings.notificationScheduleReady
                    : strings.turnRemindersOnInSettings,
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
                  strings.nextPlannedTreatment,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (nextSession == null)
                  Text(strings.nothingPlannedYet)
                else ...[
                  Text(
                    nextSession.treatment.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    strings.formattedMomentDate(
                      nextSession.date,
                      nextSession.session.momentLabel,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    controller.reminderSummaryForPlan(
                      nextSession.session,
                      strings,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          strings.whatYouCanDoHere,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        _CapabilityLine(
          title: strings.browseTreatments,
          body: strings.browseTreatmentsBody,
        ),
        _CapabilityLine(
          title: strings.planYourWeek,
          body: strings.planYourWeekBody,
        ),
        _CapabilityLine(
          title: strings.trackConsistency,
          body: strings.trackConsistencyBody,
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

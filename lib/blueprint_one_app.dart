import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/calendar/calendar_screen.dart';
import 'package:mega_panel_ai/features/session_history/session_history_screen.dart';
import 'package:mega_panel_ai/features/settings/settings_screen.dart';
import 'package:mega_panel_ai/features/training_context/training_context_screen.dart';
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
      TrainingContextScreen(),
      TreatmentCatalogScreen(),
      CalendarScreen(),
      SessionHistoryScreen(),
      SettingsScreen(),
    ];
    final labels = [
      strings.navOverview,
      strings.navContext,
      strings.navTreatments,
      strings.navCalendar,
      strings.navHistory,
      strings.navSettings,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.appTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              strings.disclaimer,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              BlueprintTheme.obsidian,
              BlueprintTheme.midnight,
              BlueprintTheme.obsidian,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: controller.ready
            ? pages[_index]
            : const Center(child: CircularProgressIndicator()),
      ),
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
        return Icons.fitness_center_outlined;
      case 2:
        return Icons.auto_awesome_mosaic_outlined;
      case 3:
        return Icons.calendar_month_outlined;
      case 4:
        return Icons.history_edu_outlined;
      case 5:
        return Icons.notifications_active_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  int _initialIndexFromUri() {
    final tab = Uri.base.queryParameters['tab']?.toLowerCase().trim();
    switch (tab) {
      case 'treatments':
        return 2;
      case 'context':
        return 1;
      case 'calendar':
        return 3;
      case 'history':
        return 4;
      case 'settings':
        return 5;
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
    final recentTraining = controller.recentTrainingSessions.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BlueprintTheme.heroGradient(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Pill(
                    icon: Icons.auto_awesome_outlined,
                    label: strings.navOverview,
                  ),
                  const SizedBox(width: 10),
                  _Pill(
                    icon: Icons.menu_book_outlined,
                    label: strings.evidenceLevel,
                    tinted: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                strings.heroTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                strings.heroBody,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              Text(
                strings.disclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: strings.todayPlanned,
                value: '${plansToday.length}',
                subtitle: strings.sessionsWaitingInCalendar,
                accent: BlueprintTheme.seafoam,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: strings.todayTracked,
                value: '${historyToday.length}',
                subtitle: strings.completedOrSkippedEntries,
                accent: BlueprintTheme.coral,
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
                accent: BlueprintTheme.gold,
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
                accent: BlueprintTheme.ruby,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _PanelCard(
          title: strings.nextPlannedTreatment,
          icon: Icons.upcoming_outlined,
          child: nextSession == null
              ? Text(strings.nothingPlannedYet)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextSession.treatment.title(strings.isSpanish),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.formattedMomentDate(
                        nextSession.date,
                        nextSession.session.momentLabel,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _MutedBanner(
                      icon: Icons.notifications_active_outlined,
                      text: controller.reminderSummaryForPlan(
                        nextSession.session,
                        strings,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 14),
        _PanelCard(
          title: strings.trainingContextTitle,
          icon: Icons.fitness_center_outlined,
          child: recentTraining.isEmpty
              ? Text(strings.noTrainingLogged)
              : Column(
                  children: recentTraining
                      .map(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: BlueprintTheme.ruby
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.bolt_outlined,
                                    color: BlueprintTheme.ruby,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        strings.trainingTypeLabel(entry.type),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        strings.trainingLoggedAt(
                                          entry.performedAt.toLocal(),
                                          strings.trainingExampleLabel(
                                            entry.type,
                                            entry.exampleKey,
                                          ),
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
        ),
        const SizedBox(height: 18),
        Text(
          strings.whatYouCanDoHere,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
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
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BlueprintTheme.softPanel(highlighted: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
          ],
          ),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
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
                    color: BlueprintTheme.seafoam.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: BlueprintTheme.seafoam, size: 18),
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

class _MutedBanner extends StatelessWidget {
  const _MutedBanner({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BlueprintTheme.panelRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BlueprintTheme.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: BlueprintTheme.fog),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    this.tinted = false,
  });

  final IconData icon;
  final String label;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tinted
            ? BlueprintTheme.seafoam.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tinted
              ? BlueprintTheme.seafoam.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: tinted ? BlueprintTheme.seafoam : BlueprintTheme.pearl,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: BlueprintTheme.pearl,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 7),
            decoration: BoxDecoration(
              color: BlueprintTheme.coral,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: BlueprintTheme.coral.withValues(alpha: 0.35),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: '$title. ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: BlueprintTheme.pearl,
                    ),
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

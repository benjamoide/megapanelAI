import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:provider/provider.dart';

class HowToUseScreen extends StatelessWidget {
  const HowToUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final strings = BlueprintStrings(controller.language);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.howToUseTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BlueprintTheme.heroGradient(
              primary: BlueprintTheme.gold,
              secondary: BlueprintTheme.seafoam,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.howToUseTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  strings.howToUseIntro,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _HelpPanel(
            title: strings.quickBasicsTitle,
            icon: Icons.info_outline,
            children: [
              Text(strings.quickBasicsBody),
              const SizedBox(height: 10),
              _BulletLine(text: strings.appPurposeBody),
              _BulletLine(text: strings.disclaimer),
              _BulletLine(text: strings.nonMedicalBoundary),
              _BulletLine(text: strings.sourcesDisclosure),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.navigationGuideTitle,
            subtitle: strings.navigationGuideSummary,
            icon: Icons.dashboard_outlined,
            children: [
              _BulletLine(text: strings.menuOverviewHelp),
              _BulletLine(text: strings.menuContextHelp),
              _BulletLine(text: strings.menuTreatmentsHelp),
              _BulletLine(text: strings.menuCalendarHelp),
              _BulletLine(text: strings.menuHistoryHelp),
              _BulletLine(text: strings.menuSettingsHelp),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.individualTreatmentTitle,
            subtitle: strings.individualTreatmentSummary,
            icon: Icons.wb_sunny_outlined,
            children: [
              Text(strings.individualTreatmentBody),
              const SizedBox(height: 10),
              _BulletLine(text: strings.individualTreatmentStep1),
              _BulletLine(text: strings.individualTreatmentStep2),
              _BulletLine(text: strings.individualTreatmentStep3),
              _BulletLine(text: strings.individualTreatmentStep4),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.treatmentReadingTitle,
            subtitle: strings.treatmentReadingSummary,
            icon: Icons.menu_book_outlined,
            children: [
              _BulletLine(text: strings.durationMeaningHelp),
              _BulletLine(text: strings.distanceMeaningHelp),
              _BulletLine(text: strings.pulseMeaningHelp),
              _BulletLine(text: strings.intensityMeaningHelp),
              _BulletLine(text: strings.evidenceMeaningHelp),
              _BulletLine(text: strings.sourcesMeaningHelp),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.planningGuideTitle,
            subtitle: strings.planningGuideSummary,
            icon: Icons.event_note_outlined,
            children: [
              Text(strings.planningGuideBody),
              const SizedBox(height: 10),
              _BulletLine(text: strings.planningSingleDoseHelp),
              _BulletLine(text: strings.planningCourseHelp),
              _BulletLine(text: strings.planningStartDateHelp),
              _BulletLine(text: strings.planningCadenceHelp),
              _BulletLine(text: strings.planningCustomDaysHelp),
              _BulletLine(text: strings.planningCalendarHistoryHelp),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.trainingCompatibilityGuideTitle,
            subtitle: strings.trainingCompatibilityGuideSummary,
            icon: Icons.fitness_center_outlined,
            children: [
              Text(strings.trainingCompatibilityGuideBody),
              const SizedBox(height: 10),
              _BulletLine(text: strings.trainingCompatibilityGuideStep1),
              _BulletLine(text: strings.trainingCompatibilityGuideStep2),
              _BulletLine(text: strings.trainingCompatibilityGuideStep3),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.remindersGuideTitle,
            subtitle: strings.remindersGuideSummary,
            icon: Icons.notifications_active_outlined,
            children: [
              _BulletLine(text: strings.remindersGuideBody),
              _BulletLine(text: strings.remindersGuideStep1),
              _BulletLine(text: strings.remindersGuideStep2),
            ],
          ),
          const SizedBox(height: 14),
          _ExpandableHelpPanel(
            title: strings.sourcesAndSafetyTitle,
            subtitle: strings.sourcesAndSafetySummary,
            icon: Icons.shield_outlined,
            children: [
              _BulletLine(text: strings.sourcesAndSafetyBody1),
              _BulletLine(text: strings.sourcesAndSafetyBody2),
              _BulletLine(text: strings.sourcesAndSafetyBody3),
            ],
          ),
        ],
      ),
    );
  }
}

class _HelpPanel extends StatelessWidget {
  const _HelpPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ExpandableHelpPanel extends StatelessWidget {
  const _ExpandableHelpPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final strings = BlueprintStrings(
      context.read<BlueprintController>().language,
    );
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          initiallyExpanded: false,
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: BlueprintTheme.seafoam.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: BlueprintTheme.seafoam, size: 18),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '$subtitle\n${strings.expandForMore}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 8),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

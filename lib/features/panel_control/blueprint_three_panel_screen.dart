import 'package:flutter/material.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/panel_control/panel_launch_controller.dart';
import 'package:mega_panel_ai/main.dart';
import 'package:mega_panel_ai/views/bluetooth_custom_view.dart';
import 'package:provider/provider.dart';

class BlueprintThreePanelScreen extends StatefulWidget {
  const BlueprintThreePanelScreen({
    super.key,
    this.autoLaunchTreatment,
  });

  final WellnessTreatment? autoLaunchTreatment;

  @override
  State<BlueprintThreePanelScreen> createState() =>
      _BlueprintThreePanelScreenState();
}

class _BlueprintThreePanelScreenState extends State<BlueprintThreePanelScreen> {
  bool _autoLaunchTriggered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_autoLaunchTriggered || widget.autoLaunchTreatment == null) return;
    _autoLaunchTriggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final launcher = context.read<PanelLaunchController>();
      await launcher.launchTreatment(widget.autoLaunchTreatment!);
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<BlueprintController>().language;
    final strings = BlueprintThreePanelStrings(language == AppLanguage.spanish);
    final launcher = context.watch<PanelLaunchController>();
    final error = launcher.lastErrorMessage;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.panelScreenTitle),
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
        child: Column(
          children: [
            if (error != null && error.isNotEmpty)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BlueprintTheme.coral.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: BlueprintTheme.coral.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: BlueprintTheme.coral,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        error,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            const Expanded(
              child: BluetoothCustomView(
                startInHome: true,
                homeBackTarget: ManualHomeBackTarget.treatments,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BlueprintThreePanelStrings {
  const BlueprintThreePanelStrings(this.isSpanish);

  final bool isSpanish;

  String get panelScreenTitle =>
      isSpanish ? 'Control del panel' : 'Panel control';
}

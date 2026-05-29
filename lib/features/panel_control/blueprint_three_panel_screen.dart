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
  ManualStartDiagnosticStrategy _wakeStrategy =
      ManualStartDiagnosticStrategy.control1to2;

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
    final pendingWakeMessage = launcher.pendingWakeMessage;
    final diagnosticTarget = launcher.diagnosticTargetTreatment;
    final diagnosticMessage = launcher.lastDiagnosticMessage;
    final diagnosticSeq = launcher.lastDiagnosticSequenceId;
    final diagnosticStatus = launcher.lastDiagnosticStatusPreview;

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
            if (launcher.isConnected)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BlueprintTheme.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: BlueprintTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.wakeLabTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.wakeLabBody,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: BlueprintTheme.fog,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: BlueprintTheme.obsidian.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BlueprintTheme.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            diagnosticTarget == null
                                ? strings.wakeLabNoTarget
                                : strings.wakeLabTarget(
                                    language == AppLanguage.spanish
                                        ? diagnosticTarget.titleEs
                                        : diagnosticTarget.titleEn,
                                  ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (diagnosticSeq != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              strings.wakeLabSequence(
                                diagnosticSeq,
                                diagnosticStatus,
                              ),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: BlueprintTheme.fog,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<ManualStartDiagnosticStrategy>(
                      value: _wakeStrategy,
                      decoration: InputDecoration(
                        labelText: strings.wakeLabStrategyLabel,
                        filled: true,
                        fillColor:
                            BlueprintTheme.obsidian.withValues(alpha: 0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: ManualStartDiagnosticStrategy.values
                          .where(
                            (strategy) =>
                                strategy != ManualStartDiagnosticStrategy.disabled,
                          )
                          .map(
                            (strategy) => DropdownMenuItem(
                              value: strategy,
                              child: Text(_wakeStrategyLabel(strings, strategy)),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: launcher.diagnosticRunning
                          ? null
                          : (value) {
                              if (value == null) return;
                              setState(() => _wakeStrategy = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: launcher.diagnosticRunning
                                ? null
                                : () async {
                                    await launcher.runWakeDiagnostic(
                                      _wakeStrategy,
                                    );
                                  },
                            icon: const Icon(Icons.science_outlined),
                            label: Text(
                              launcher.diagnosticRunning
                                  ? strings.wakeLabRunning
                                  : strings.wakeLabRun,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (diagnosticMessage != null &&
                        diagnosticMessage.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        diagnosticMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BlueprintTheme.fog,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            if (pendingWakeMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BlueprintTheme.seafoam.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: BlueprintTheme.seafoam.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.touch_app_outlined,
                      color: BlueprintTheme.seafoam,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pendingWakeMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
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

  String _wakeStrategyLabel(
    BlueprintThreePanelStrings strings,
    ManualStartDiagnosticStrategy strategy,
  ) {
    switch (strategy) {
      case ManualStartDiagnosticStrategy.disabled:
        return strings.diagOff;
      case ManualStartDiagnosticStrategy.powerOnOnly:
        return strings.diagPowerOn;
      case ManualStartDiagnosticStrategy.control2to1:
        return strings.diagOfficialDimWake;
      case ManualStartDiagnosticStrategy.control1to2:
        return strings.diagOfficialLoadWake;
      case ManualStartDiagnosticStrategy.quickStart:
        return strings.diagQuickStart;
      case ManualStartDiagnosticStrategy.officialPresetRun:
        return strings.diagOfficialPreset;
      case ManualStartDiagnosticStrategy.powerOnWithModeAndShortCountdown:
        return strings.diagPowerOnModeCt;
      case ManualStartDiagnosticStrategy.control2to1WithModeAndShortCountdown:
        return strings.diagDimWakeModeCt;
      case ManualStartDiagnosticStrategy.control1to2WithModeAndShortCountdown:
        return strings.diagLoadWakeModeCt;
      case ManualStartDiagnosticStrategy.quickStartWithModeAndShortCountdown:
        return strings.diagQuickStartModeCt;
    }
  }
}

class BlueprintThreePanelStrings {
  const BlueprintThreePanelStrings(this.isSpanish);

  final bool isSpanish;

  String get panelScreenTitle =>
      isSpanish ? 'Control del panel' : 'Panel control';

  String get wakeLabTitle =>
      isSpanish ? 'Laboratorio de wake' : 'Wake lab';
  String get wakeLabBody => isSpanish
      ? 'Prueba secuencias concretas de activacion BLE sobre el tratamiento pendiente o el ultimo tratamiento lanzado.'
      : 'Try specific BLE wake sequences against the pending treatment or the last treatment you launched.';
  String get wakeLabNoTarget => isSpanish
      ? 'Lanza o deja pendiente un tratamiento primero para probar una secuencia.'
      : 'Launch or queue a treatment first so the wake lab has a target configuration.';
  String wakeLabTarget(String title) => isSpanish
      ? 'Tratamiento objetivo: $title'
      : 'Target treatment: $title';
  String wakeLabSequence(String seq, String status) => isSpanish
      ? 'Ultima secuencia: $seq · status 0x10: $status'
      : 'Last sequence: $seq · status 0x10: $status';
  String get wakeLabStrategyLabel =>
      isSpanish ? 'Estrategia de wake' : 'Wake strategy';
  String get wakeLabRun =>
      isSpanish ? 'Ejecutar test de wake' : 'Run wake test';
  String get wakeLabRunning =>
      isSpanish ? 'Ejecutando test...' : 'Running test...';

  String get diagOff => isSpanish
      ? 'Diag: Off (arranque normal)'
      : 'Diag: Off (normal start)';
  String get diagPowerOn =>
      isSpanish ? 'Diag: 0x20 1' : 'Diag: 0x20 1';
  String get diagOfficialDimWake => isSpanish
      ? 'Diag: wake oficial dim 0x20 2->1'
      : 'Diag: official dim wake 0x20 2->1';
  String get diagOfficialLoadWake => isSpanish
      ? 'Diag: carga oficial 0x20 1->2'
      : 'Diag: official load 0x20 1->2';
  String get diagQuickStart => isSpanish
      ? 'Diag: 0x21 (sin usar en APK oficial)'
      : 'Diag: 0x21 (unused in official APK)';
  String get diagOfficialPreset => isSpanish
      ? 'Diag: preset oficial 0x70->0x20 0->0x73'
      : 'Diag: official preset run 0x70->0x20 0->0x73';
  String get diagPowerOnModeCt =>
      isSpanish ? 'Diag: 0x20 1 + mode + ct45' : 'Diag: 0x20 1 + mode + ct45';
  String get diagDimWakeModeCt => isSpanish
      ? 'Diag: 0x20 2->1 + mode + ct45'
      : 'Diag: 0x20 2->1 + mode + ct45';
  String get diagLoadWakeModeCt => isSpanish
      ? 'Diag: 0x20 1->2 + mode + ct45'
      : 'Diag: 0x20 1->2 + mode + ct45';
  String get diagQuickStartModeCt => isSpanish
      ? 'Diag: 0x21 + mode + ct45'
      : 'Diag: 0x21 + mode + ct45';
}

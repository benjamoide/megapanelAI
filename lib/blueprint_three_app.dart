import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mega_panel_ai/core/scheduling/blueprint_controller.dart';
import 'package:mega_panel_ai/design_system/blueprint_localization.dart';
import 'package:mega_panel_ai/design_system/blueprint_theme.dart';
import 'package:mega_panel_ai/features/calendar/calendar_screen.dart';
import 'package:mega_panel_ai/features/session_history/session_history_screen.dart';
import 'package:mega_panel_ai/features/settings/settings_screen.dart';
import 'package:mega_panel_ai/features/training_context/training_context_screen.dart';
import 'package:mega_panel_ai/features/treatment_catalog/treatment_catalog_screen.dart';
import 'package:mega_panel_ai/main.dart';
import 'package:mega_panel_ai/views/bluetooth_custom_view.dart';
import 'package:provider/provider.dart';

class BlueprintThreeApp extends StatelessWidget {
  const BlueprintThreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<BlueprintController>().language;
    final strings = BlueprintThreeStrings(language);

    return MaterialApp(
      title: strings.appTitle,
      debugShowCheckedModeBanner: false,
      locale: language.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: BlueprintTheme.light(),
      home: const BlueprintThreeShell(),
    );
  }
}

class BlueprintThreeShell extends StatefulWidget {
  const BlueprintThreeShell({super.key});

  @override
  State<BlueprintThreeShell> createState() => _BlueprintThreeShellState();
}

class _BlueprintThreeShellState extends State<BlueprintThreeShell> {
  late int _index;
  AppState? _panelState;

  @override
  void initState() {
    super.initState();
    _index = _initialIndexFromUri();
  }

  @override
  void dispose() {
    _panelState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final panelState = _panelState;
    final isConnected = panelState?.isConnected ?? false;
    final strings = BlueprintThreeStrings(controller.language);
    final pages = <Widget>[
      _BlueprintThreeOverview(
        onOpenPanelControl: () => _openPanelControl(context),
        onOpenConnect: () => _openConnectDialog(context),
        isConnected: isConnected,
        activeTreatmentName: panelState?.tratamientoActivoActual?.nombre,
        activeRemaining: panelState?.tiempoRestanteCicloActivo(),
      ),
      const TrainingContextScreen(),
      const TreatmentCatalogScreen(),
      const CalendarScreen(),
      const SessionHistoryScreen(),
      const SettingsScreen(),
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
              strings.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isConnected
                ? strings.openPanelControl
                : strings.connectPanel,
            onPressed: () {
              if (isConnected) {
                _openPanelControl(context);
              } else {
                _openConnectDialog(context);
              }
            },
            icon: Icon(
              isConnected
                  ? Icons.tune_rounded
                  : Icons.bluetooth_searching_rounded,
            ),
          ),
          if (isConnected && panelState != null)
            IconButton(
              tooltip: strings.disconnectPanel,
              onPressed: () async {
                await panelState.disconnectDevice();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(strings.panelDisconnected)),
                );
              },
              icon: const Icon(Icons.bluetooth_disabled_rounded),
            ),
        ],
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
      floatingActionButton: _index <= 3
          ? FloatingActionButton.extended(
              onPressed: () => _openPanelControl(context),
              backgroundColor: BlueprintTheme.seafoam,
              foregroundColor: BlueprintTheme.obsidian,
              icon: const Icon(Icons.tune_rounded),
              label: Text(strings.panelAction),
            )
          : null,
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

  Future<void> _openConnectDialog(BuildContext context) async {
    final panelState = await _ensurePanelState();
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider<AppState>.value(
        value: panelState,
        child: const BluetoothScanDialog(),
      ),
    );
  }

  Future<void> _openPanelControl(BuildContext context) async {
    final panelState = await _ensurePanelState();
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChangeNotifierProvider<AppState>.value(
          value: panelState,
          child: const _BlueprintThreePanelScreen(),
        ),
      ),
    );
  }

  Future<AppState> _ensurePanelState() async {
    var panelState = _panelState;
    if (panelState == null) {
      panelState = AppState();
      panelState.addListener(_handlePanelStateChange);
      _panelState = panelState;
    }
    await panelState.ensureBleActivated();
    return panelState;
  }

  void _handlePanelStateChange() {
    if (!mounted) return;
    setState(() {});
  }

  IconData _iconFor(int index) {
    switch (index) {
      case 0:
        return Icons.dashboard_outlined;
      case 1:
        return Icons.fitness_center_outlined;
      case 2:
        return Icons.auto_awesome_mosaic_outlined;
      case 3:
        return Icons.calendar_month_outlined;
      case 4:
        return Icons.history_edu_outlined;
      case 5:
        return Icons.settings_outlined;
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

class _BlueprintThreeOverview extends StatelessWidget {
  const _BlueprintThreeOverview({
    required this.onOpenPanelControl,
    required this.onOpenConnect,
    required this.isConnected,
    required this.activeTreatmentName,
    required this.activeRemaining,
  });

  final VoidCallback onOpenPanelControl;
  final VoidCallback onOpenConnect;
  final bool isConnected;
  final String? activeTreatmentName;
  final Duration? activeRemaining;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BlueprintController>();
    final uiStrings = BlueprintStrings(controller.language);
    final strings = BlueprintThreeStrings(controller.language);
    final nextSession = controller.nextPlannedSession;
    final recentTraining = controller.recentTrainingSessions.take(3).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BlueprintTheme.heroGradient(
            primary: BlueprintTheme.seafoam,
            secondary: BlueprintTheme.coral,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Badge(
                    icon: Icons.bolt_rounded,
                    label: strings.blockBlueLightLabel,
                  ),
                  const SizedBox(width: 10),
                  _Badge(
                    icon: Icons.bluetooth_audio_rounded,
                    label: isConnected
                        ? strings.panelConnected
                        : strings.panelDisconnectedState,
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
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: isConnected ? onOpenPanelControl : onOpenConnect,
                    icon: Icon(isConnected
                        ? Icons.tune_rounded
                        : Icons.bluetooth_searching_rounded),
                    label: Text(isConnected
                        ? strings.openPanelControl
                        : strings.connectPanel),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenPanelControl,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(strings.manualControl),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: strings.panelStatusTitle,
                value: isConnected ? strings.connectedShort : strings.offlineShort,
                subtitle: isConnected
                    ? (activeTreatmentName ?? strings.readyToSendProtocols)
                    : strings.connectPanelHint,
                accent: isConnected
                    ? BlueprintTheme.seafoam
                    : BlueprintTheme.coral,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: uiStrings.todayPlanned,
                value: '${controller.plansFor(DateTime.now()).length}',
                subtitle: uiStrings.sessionsWaitingInCalendar,
                accent: BlueprintTheme.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BlueprintTheme.softPanel(highlighted: isConnected),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.liveControlTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  strings.liveControlBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                _InfoRow(
                  label: strings.currentConnectionLabel,
                  value: isConnected
                      ? strings.connectedShort
                      : strings.offlineShort,
                ),
                _InfoRow(
                  label: strings.activeTreatmentLabel,
                  value: activeTreatmentName ?? strings.noActiveTreatmentLabel,
                ),
                _InfoRow(
                  label: strings.remainingTimeLabel,
                  value: activeRemaining == null
                      ? strings.notRunningLabel
                      : _formatDuration(activeRemaining),
                ),
                const SizedBox(height: 14),
                Text(
                  strings.controlNote,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (nextSession != null)
          DecoratedBox(
            decoration: BlueprintTheme.softPanel(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.nextGuidedSession,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nextSession.treatment.title(uiStrings.isSpanish),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${MaterialLocalizations.of(context).formatShortDate(nextSession.date)} · ${nextSession.session.momentLabel}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        if (nextSession != null) const SizedBox(height: 12),
        if (recentTraining.isNotEmpty)
          DecoratedBox(
            decoration: BlueprintTheme.softPanel(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    uiStrings.recentTrainingLogged,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ...recentTraining.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timeline_rounded,
                            color: BlueprintTheme.coral,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              uiStrings.trainingTypeLabel(entry.type),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay.fromDateTime(entry.performedAt),
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _BlueprintThreePanelScreen extends StatelessWidget {
  const _BlueprintThreePanelScreen();

  @override
  Widget build(BuildContext context) {
    final language = context.watch<BlueprintController>().language;
    final strings = BlueprintThreeStrings(language);

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
        child: const BluetoothCustomView(
          startInHome: true,
          homeBackTarget: ManualHomeBackTarget.treatments,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    return DecoratedBox(
      decoration: BlueprintTheme.softPanel(),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: accent,
                  ),
            ),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
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
            ? BlueprintTheme.seafoam.withValues(alpha: 0.14)
            : BlueprintTheme.midnight.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: tinted
              ? BlueprintTheme.seafoam.withValues(alpha: 0.4)
              : BlueprintTheme.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: tinted ? BlueprintTheme.seafoam : BlueprintTheme.pearl),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class BlueprintThreeStrings {
  const BlueprintThreeStrings(this.language);

  final AppLanguage language;

  bool get isSpanish => language == AppLanguage.spanish;

  String get appTitle =>
      isSpanish ? 'BlockBlueLight' : 'BlockBlueLight';
  String get tagline => isSpanish
      ? 'Planifica tratamientos y controla tu panel Mega desde una sola app.'
      : 'Plan treatments and control your Mega panel from one app.';
  String get heroTitle => isSpanish
      ? 'Guia terapias, agenda sesiones y controla el panel en tiempo real.'
      : 'Guide treatments, schedule sessions and control the panel in real time.';
  String get heroBody => isSpanish
      ? 'Blueprint 3 combina la biblioteca de tratamientos, la planificacion y el control Bluetooth del panel Mega con la experiencia BlockBlueLight.'
      : 'Blueprint 3 combines the treatment library, planning and Bluetooth control of the Mega panel inside the BlockBlueLight experience.';
  String get blockBlueLightLabel =>
      isSpanish ? 'BlockBlueLight' : 'BlockBlueLight';
  String get panelConnected => isSpanish ? 'Panel conectado' : 'Panel connected';
  String get panelDisconnectedState =>
      isSpanish ? 'Panel sin conectar' : 'Panel offline';
  String get connectPanel =>
      isSpanish ? 'Conectar panel' : 'Connect panel';
  String get disconnectPanel =>
      isSpanish ? 'Desconectar panel' : 'Disconnect panel';
  String get panelDisconnected =>
      isSpanish ? 'Panel desconectado' : 'Panel disconnected';
  String get openPanelControl =>
      isSpanish ? 'Abrir control del panel' : 'Open panel control';
  String get manualControl =>
      isSpanish ? 'Control manual' : 'Manual control';
  String get panelAction =>
      isSpanish ? 'Panel' : 'Panel';
  String get panelStatusTitle =>
      isSpanish ? 'Estado del panel' : 'Panel status';
  String get connectedShort => isSpanish ? 'Conectado' : 'Connected';
  String get offlineShort => isSpanish ? 'Desconectado' : 'Offline';
  String get readyToSendProtocols => isSpanish
      ? 'Listo para enviar protocolos'
      : 'Ready to send protocols';
  String get connectPanelHint => isSpanish
      ? 'Conecta el panel Mega para lanzar tratamientos.'
      : 'Connect the Mega panel to start treatments.';
  String get liveControlTitle =>
      isSpanish ? 'Control en vivo' : 'Live control';
  String get liveControlBody => isSpanish
      ? 'Esta version mantiene el catalogo y la planificacion de Blueprint, pero recupera el control BLE del panel Mega para la linea BlockBlueLight.'
      : 'This version keeps the Blueprint catalogue and planning flow, while restoring Mega panel BLE control for the BlockBlueLight line.';
  String get currentConnectionLabel =>
      isSpanish ? 'Conexion actual' : 'Current connection';
  String get activeTreatmentLabel =>
      isSpanish ? 'Tratamiento activo' : 'Active treatment';
  String get noActiveTreatmentLabel =>
      isSpanish ? 'Ninguno' : 'None';
  String get remainingTimeLabel =>
      isSpanish ? 'Tiempo restante' : 'Remaining time';
  String get notRunningLabel =>
      isSpanish ? 'Sin tratamiento en curso' : 'No running treatment';
  String get controlNote => isSpanish
      ? 'Usa el control del panel para conexiones Bluetooth, arranque manual, presets y diagnostico BLE cuando sea necesario.'
      : 'Use panel control for Bluetooth connections, manual start, presets and BLE diagnostics when needed.';
  String get nextGuidedSession =>
      isSpanish ? 'Siguiente sesion guiada' : 'Next guided session';
  String get panelScreenTitle =>
      isSpanish ? 'Control del panel' : 'Panel control';

  String get navOverview => isSpanish ? 'Resumen' : 'Overview';
  String get navContext => isSpanish ? 'Contexto' : 'Context';
  String get navTreatments => isSpanish ? 'Tratamientos' : 'Treatments';
  String get navCalendar => isSpanish ? 'Calendario' : 'Calendar';
  String get navHistory => isSpanish ? 'Historial' : 'History';
  String get navSettings => isSpanish ? 'Ajustes' : 'Settings';
}

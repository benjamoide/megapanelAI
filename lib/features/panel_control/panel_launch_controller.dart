import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mega_panel_ai/bluetooth/ble_manager.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/main.dart';

class PanelLaunchController extends ChangeNotifier {
  AppState? _panelState;
  bool _launching = false;
  String? _lastErrorMessage;
  WellnessTreatment? _pendingWakeTreatment;
  bool _wakeRetryInFlight = false;
  StreamSubscription<List<int>>? _protocolRxSubscription;

  AppState? get panelState => _panelState;
  bool get hasPanelState => _panelState != null;
  bool get isConnected => _panelState?.isConnected ?? false;
  bool get launching => _launching;
  String? get lastErrorMessage => _lastErrorMessage;
  bool get hasPendingWakeTreatment => _pendingWakeTreatment != null;
  WellnessTreatment? get pendingWakeTreatment => _pendingWakeTreatment;
  String? get pendingWakeMessage => _pendingWakeTreatment == null
      ? null
      : 'The panel is connected but asleep. Touch the panel screen and the app will retry automatically.';

  Future<AppState> ensurePanelState() async {
    var state = _panelState;
    if (state == null) {
      state = AppState();
      state.addListener(_handlePanelStateChange);
      state.setBleAutoReconnectAllowed(
        false,
        reason: 'bp3-manual-connect-only',
      );
      _panelState = state;
      _protocolRxSubscription ??=
          BleManager().protocolFrames.listen(_handleProtocolFrame);
    }
    await state.ensureBleActivated();
    return state;
  }

  Future<bool> launchTreatment(WellnessTreatment treatment) async {
    final state = await ensurePanelState();
    if (!state.isConnected) {
      _lastErrorMessage = 'Connect the panel before launching a treatment.';
      notifyListeners();
      return false;
    }

    _launching = true;
    _lastErrorMessage = null;
    _pendingWakeTreatment = null;
    notifyListeners();

    try {
      if (state.hayCicloActivo || state.hayCicloPausado) {
        await state.detenerPanelActivo();
      }
      final legacyTreatment = _mapToLegacyTreatment(treatment);
      final started = await state.iniciarTratamientoBlueprint(
        legacyTreatment,
        origin: 'blueprint',
      );
      if (!started) {
        _lastErrorMessage = _mapStartFailure(null);
        if (_shouldRetryOnWake(null)) {
          _pendingWakeTreatment = treatment;
        }
      }
      return started;
    } catch (e) {
      _lastErrorMessage = _mapStartFailure(e);
      if (_shouldRetryOnWake(e)) {
        _pendingWakeTreatment = treatment;
      }
      return false;
    } finally {
      _launching = false;
      notifyListeners();
    }
  }

  Future<void> disconnectPanel() async {
    final state = _panelState;
    if (state == null) return;
    _pendingWakeTreatment = null;
    await state.disconnectDevice();
    notifyListeners();
  }

  Future<bool> retryPendingTreatment() async {
    final treatment = _pendingWakeTreatment;
    if (treatment == null) return false;
    return launchTreatment(treatment);
  }

  Tratamiento _mapToLegacyTreatment(WellnessTreatment treatment) {
    return Tratamiento(
      id: 'bp3_${treatment.id}',
      nombre: treatment.titleEs,
      zona: treatment.categoryEs,
      descripcion: treatment.goalEs,
      sintomas: treatment.summaryEs,
      posicion: treatment.distanceGuidanceEs,
      hz: _resolveHz(treatment),
      duracion: '${treatment.durationMinutes}',
      frecuencias: treatment.intensityDistribution
          .map(
            (entry) => <String, dynamic>{
              'nm': entry.wavelengthNm,
              'p': entry.percentage,
            },
          )
          .toList(growable: false),
      tipsAntes: treatment.beforeSessionTipsEs,
      tipsDespues: treatment.afterSessionTipsEs,
      prohibidos: treatment.safetyNotesEs,
      esCustom: true,
      oculto: false,
    );
  }

  String _resolveHz(WellnessTreatment treatment) {
    final source = '${treatment.pulseGuidanceEn} ${treatment.pulseGuidanceEs}'
        .toLowerCase()
        .trim();
    final match = RegExp(r'(\d+)\s*hz').firstMatch(source);
    if (match != null) {
      return '${match.group(1)}Hz';
    }
    if (source.contains('cw') ||
        source.contains('continuous') ||
        source.contains('continua') ||
        source.contains('continuo')) {
      return 'CW';
    }
    return 'CW';
  }

  void _handlePanelStateChange() {
    notifyListeners();
  }

  void _handleProtocolFrame(List<int> _) {
    final treatment = _pendingWakeTreatment;
    if (treatment == null || _wakeRetryInFlight || _launching) return;
    final state = _panelState;
    if (state == null || !state.isConnected) return;

    _wakeRetryInFlight = true;
    _pendingWakeTreatment = null;
    _lastErrorMessage = 'Panel awake. Retrying treatment...';
    notifyListeners();

    unawaited(() async {
      try {
        await launchTreatment(treatment);
      } finally {
        _wakeRetryInFlight = false;
        notifyListeners();
      }
    }());
  }

  bool _shouldRetryOnWake(Object? error) {
    final raw = error?.toString() ?? '';
    final normalized = raw.toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('panel not ready') ||
        normalized.contains('no ble rx after retries') ||
        normalized.contains('blocked (panel not ready)') ||
        normalized.contains('did not wake up');
  }

  String _mapStartFailure(Object? error) {
    final raw = error?.toString() ?? '';
    final normalized = raw.toLowerCase();
    if (normalized.contains('panel not ready') ||
        normalized.contains('no ble rx after retries') ||
        normalized.contains('blocked (panel not ready)')) {
      return 'The panel is connected but did not wake up. Touch the panel screen and the app will retry automatically.';
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'The treatment could not be started yet. The panel did not respond.';
  }

  @override
  void dispose() {
    _panelState?.removeListener(_handlePanelStateChange);
    _protocolRxSubscription?.cancel();
    _panelState?.dispose();
    super.dispose();
  }
}

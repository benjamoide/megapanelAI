import 'package:flutter/foundation.dart';
import 'package:mega_panel_ai/core/treatments/treatment.dart';
import 'package:mega_panel_ai/main.dart';

class PanelLaunchController extends ChangeNotifier {
  AppState? _panelState;
  bool _launching = false;
  String? _lastErrorMessage;

  AppState? get panelState => _panelState;
  bool get hasPanelState => _panelState != null;
  bool get isConnected => _panelState?.isConnected ?? false;
  bool get launching => _launching;
  String? get lastErrorMessage => _lastErrorMessage;

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
        _lastErrorMessage =
            'The treatment could not be started. The panel did not respond.';
      }
      return started;
    } catch (e) {
      _lastErrorMessage = e.toString();
      return false;
    } finally {
      _launching = false;
      notifyListeners();
    }
  }

  Future<void> disconnectPanel() async {
    final state = _panelState;
    if (state == null) return;
    await state.disconnectDevice();
    notifyListeners();
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

  @override
  void dispose() {
    _panelState?.removeListener(_handlePanelStateChange);
    _panelState?.dispose();
    super.dispose();
  }
}

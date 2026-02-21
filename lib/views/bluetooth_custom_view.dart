import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_panel_ai/bluetooth/ble_manager.dart';
import 'package:mega_panel_ai/bluetooth/ble_protocol.dart';
import 'package:mega_panel_ai/main.dart';
import 'package:provider/provider.dart';

enum _ManualSection { home, menu, onOff, time, dimming, pulse, presets }

class BluetoothCustomView extends StatefulWidget {
  const BluetoothCustomView({super.key});

  @override
  State<BluetoothCustomView> createState() => _BluetoothCustomViewState();
}

class _BluetoothCustomViewState extends State<BluetoothCustomView> {
  static const Color _screenBg = Color(0xFFE8EDF5);
  static const Color _brandBlueDark = Color(0xFF255F86);
  static const Color _brandBlueLight = Color(0xFF23BFE8);
  static const Color _gradStart = Color(0xFF1ED6CD);
  static const Color _gradEnd = Color(0xFF4B86ED);
  static const List<int> _waveOrder = [630, 660, 810, 830, 850];

  double _red630 = 100.0;
  double _red660 = 100.0;
  double _nir810 = 100.0;
  double _nir830 = 100.0;
  double _nir850 = 100.0;

  double _pulseHz = 0.0;
  bool _pulseEnabled = false;
  double _duration = 10.0;
  int _startCommand = 0x21;
  int _sequenceMode = 0;
  int _workMode = 0;

  _ManualSection _section = _ManualSection.home;
  int _selectedWavelengthIndex = 0;
  bool _powerShouldBeOn = true;
  final List<String> _logs = [];
  StreamSubscription? _logSub;

  final Map<String, Map<String, dynamic>> _presets = const {
    'Lesiones': {
      'duration': 10,
      'pulse': 10,
      'freq': [10, 30, 20, 20, 20]
    },
    'Facial': {
      'duration': 15,
      'pulse': 0,
      'freq': [40, 40, 10, 10, 0]
    },
    'Young': {
      'duration': 15,
      'pulse': 10,
      'freq': [35, 45, 10, 5, 5]
    },
    'Fat': {
      'duration': 20,
      'pulse': 0,
      'freq': [0, 15, 35, 25, 25]
    },
  };

  bool get _isCompact => MediaQuery.of(context).size.width <= 430;

  double get _uiScale {
    final width = MediaQuery.of(context).size.width;
    if (width <= 350) return 0.75;
    if (width <= 390) return 0.86;
    if (width <= 430) return 0.94;
    return 1.0;
  }

  double _s(double value) => value * _uiScale;

  @override
  void initState() {
    super.initState();
    _logSub = BleManager().logs.listen((log) {
      if (!mounted) return;
      setState(() {
        _logs.insert(0, log);
        if (_logs.length > 120) {
          _logs.removeLast();
        }
      });
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = context.watch<AppState>().isConnected;

    return Container(
      color: _screenBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: _isCompact ? 12 : 22,
            vertical: _isCompact ? 12 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLogo(),
                  SizedBox(height: _s(14)),
                  if (_section != _ManualSection.home) _buildBackRow(),
                  if (_section != _ManualSection.home) SizedBox(height: _s(14)),
                  if (!isConnected) _buildConnectionHint(),
                  if (!isConnected) SizedBox(height: _s(10)),
                  _buildSectionContent(isConnected),
                  SizedBox(height: _s(14)),
                  _buildDebugPanel(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BL',
              style: TextStyle(
                fontSize: _s(62),
                height: 0.9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                color: _brandBlueDark,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(4)),
              child: Icon(
                Icons.lightbulb_outline,
                size: _s(58),
                color: _brandBlueLight,
              ),
            ),
            Text(
              'CK',
              style: TextStyle(
                fontSize: _s(62),
                height: 0.9,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.0,
                color: _brandBlueDark,
              ),
            ),
          ],
        ),
        SizedBox(height: _s(2)),
        Text(
          'BLUE-LIGHT',
          style: TextStyle(
            fontSize: _s(33),
            letterSpacing: _s(3.0),
            fontWeight: FontWeight.w600,
            color: _brandBlueLight,
          ),
        ),
      ],
    );
  }

  Widget _buildBackRow() {
    return Row(
      children: [
        _buildRoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (_section == _ManualSection.menu) {
              setState(() => _section = _ManualSection.home);
              return;
            }
            setState(() => _section = _ManualSection.menu);
          },
        ),
        SizedBox(width: _s(12)),
        Text(
          'BACK',
          style: TextStyle(
            color: const Color(0xFF1999ED),
            fontSize: _s(52),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDDEFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.bluetooth_disabled, color: Color(0xFF255F86), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conecta el panel desde el menu lateral para ejecutar RUN.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContent(bool isConnected) {
    switch (_section) {
      case _ManualSection.home:
        return _buildHomeContent();
      case _ManualSection.menu:
        return _buildMainMenu();
      case _ManualSection.onOff:
        return _buildOnOffContent(isConnected);
      case _ManualSection.time:
        return _buildTimeContent(isConnected);
      case _ManualSection.dimming:
        return _buildDimmingContent(isConnected);
      case _ManualSection.pulse:
        return _buildPulseContent(isConnected);
      case _ManualSection.presets:
        return _buildPresetsContent(isConnected);
    }
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        _buildStatusCircle(),
        SizedBox(height: _s(18)),
        InkWell(
          onTap: () => setState(() => _section = _ManualSection.menu),
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildRoundIconButton(
                  icon: Icons.settings,
                  onTap: () => setState(() => _section = _ManualSection.menu),
                  diameter: 96,
                  iconSize: 50,
                ),
                SizedBox(width: _s(14)),
                Text(
                  'SET',
                  style: TextStyle(
                    color: const Color(0xFF1999ED),
                    fontSize: _s(66),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCircle() {
    final pulseLabel =
        (!_pulseEnabled || _pulseHz == 0) ? 'OFF' : '${_pulseHz.toInt()}HZ';

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: _s(610)),
      child: AspectRatio(
        aspectRatio: 1,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [_gradStart, _gradEnd]),
          ),
          child: Padding(
            padding: EdgeInsets.all(_s(20)),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF8FAFD),
              ),
              child: Padding(
                padding: EdgeInsets.all(_s(22)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '0',
                      style: TextStyle(
                        fontSize: _s(160),
                        fontFamily: 'monospace',
                        height: 0.8,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF2E54E8),
                      ),
                    ),
                    SizedBox(height: _s(8)),
                    Text(
                      'Pulse:$pulseLabel',
                      style: TextStyle(
                        fontSize: _s(38),
                        color: const Color(0xFF25AEE2),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: _s(10)),
                    Text(
                      '630:${_red630.toInt()}%  810:${_nir810.toInt()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _s(36),
                        color: const Color(0xFF3D9FD8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: _s(3)),
                    Text(
                      '660:${_red660.toInt()}%  830:${_nir830.toInt()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _s(36),
                        color: const Color(0xFF3D9FD8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: _s(3)),
                    Text(
                      '850:${_nir850.toInt()}%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: _s(36),
                        color: const Color(0xFF3D9FD8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenu() {
    return Column(
      children: [
        _buildMenuButton('ON/OFF',
            onTap: () => _openSection(_ManualSection.onOff)),
        SizedBox(height: _s(13)),
        _buildMenuButton('TIME',
            onTap: () => _openSection(_ManualSection.time)),
        SizedBox(height: _s(13)),
        _buildMenuButton('DIMMING',
            onTap: () => _openSection(_ManualSection.dimming)),
        SizedBox(height: _s(13)),
        _buildMenuButton('PULSE',
            onTap: () => _openSection(_ManualSection.pulse)),
        SizedBox(height: _s(13)),
        _buildMenuButton('PRESETS',
            onTap: () => _openSection(_ManualSection.presets)),
      ],
    );
  }

  Widget _buildOnOffContent(bool isConnected) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                label: 'ON',
                selected: _powerShouldBeOn,
                onTap: () => setState(() => _powerShouldBeOn = true),
              ),
            ),
            SizedBox(width: _s(14)),
            Expanded(
              child: _buildActionTile(
                label: 'OFF',
                selected: !_powerShouldBeOn,
                onTap: () => setState(() => _powerShouldBeOn = false),
              ),
            ),
          ],
        ),
        SizedBox(height: _s(20)),
        Text(
          _powerShouldBeOn ? 'ON' : 'OFF',
          style: TextStyle(
            fontSize: _s(118),
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
        SizedBox(height: _s(14)),
        _buildRunButton(
          isConnected: isConnected,
          onTap: () => _applyPowerSelection(context),
        ),
      ],
    );
  }

  Widget _buildTimeContent(bool isConnected) {
    return Column(
      children: [
        _buildMenuButton(
          '10 MIN',
          compact: true,
          onTap: () => setState(() => _duration = 10),
        ),
        SizedBox(height: _s(12)),
        _buildMenuButton(
          '15 MIN',
          compact: true,
          onTap: () => setState(() => _duration = 15),
        ),
        SizedBox(height: _s(12)),
        _buildMenuButton(
          '20 MIN',
          compact: true,
          onTap: () => setState(() => _duration = 20),
        ),
        SizedBox(height: _s(18)),
        _buildPlusMinusControl(
          onMinus: () => _changeDuration(-1),
          onPlus: () => _changeDuration(1),
          center: Column(
            children: [
              Text(
                _duration.toInt().toString(),
                style: TextStyle(
                  fontSize: _s(96),
                  fontWeight: FontWeight.w500,
                  height: 0.85,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'MIN',
                style: TextStyle(
                  fontSize: _s(56),
                  fontWeight: FontWeight.w600,
                  height: 0.8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _s(16)),
        _buildRunButton(
          isConnected: isConnected,
          onTap: () => _runManualTreatment(context),
        ),
      ],
    );
  }

  Widget _buildDimmingContent(bool isConnected) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: _s(12), vertical: _s(12)),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_gradStart, _gradEnd]),
            borderRadius: BorderRadius.circular(_s(12)),
          ),
          child: Column(
            children: _waveOrder
                .map(
                  (nm) => Padding(
                    padding: EdgeInsets.symmetric(vertical: _s(4)),
                    child: _buildDimmingRow(nm),
                  ),
                )
                .toList(),
          ),
        ),
        SizedBox(height: _s(14)),
        _buildPlusMinusControl(
          onMinus: _selectPreviousWavelength,
          onPlus: _selectNextWavelength,
          center: Column(
            children: [
              Text(
                _currentSelectedWavelength.toString(),
                style: TextStyle(
                  fontSize: _s(84),
                  fontWeight: FontWeight.w500,
                  height: 0.85,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'NM',
                style: TextStyle(
                  fontSize: _s(44),
                  fontWeight: FontWeight.w600,
                  height: 0.9,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _s(16)),
        _buildRunButton(
          isConnected: isConnected,
          onTap: () => _runManualTreatment(context),
        ),
      ],
    );
  }

  Widget _buildPulseContent(bool isConnected) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                label: 'OFF',
                selected: !_pulseEnabled || _pulseHz == 0,
                onTap: () => setState(() {
                  _pulseEnabled = false;
                  _pulseHz = 0;
                }),
              ),
            ),
            SizedBox(width: _s(14)),
            Expanded(
              child: _buildActionTile(
                label: '10 HZ',
                selected: _pulseEnabled && _pulseHz == 10,
                onTap: () => _setPulse(10),
              ),
            ),
          ],
        ),
        SizedBox(height: _s(12)),
        Row(
          children: [
            Expanded(
              child: _buildActionTile(
                label: '20 HZ',
                selected: _pulseEnabled && _pulseHz == 20,
                onTap: () => _setPulse(20),
              ),
            ),
            SizedBox(width: _s(14)),
            Expanded(
              child: _buildActionTile(
                label: '40 HZ',
                selected: _pulseEnabled && _pulseHz == 40,
                onTap: () => _setPulse(40),
              ),
            ),
          ],
        ),
        SizedBox(height: _s(18)),
        _buildPlusMinusControl(
          onMinus: () => _changePulse(-1),
          onPlus: () => _changePulse(1),
          center: Column(
            children: [
              Text(
                (!_pulseEnabled || _pulseHz == 0)
                    ? 'OFF'
                    : _pulseHz.toInt().toString(),
                style: TextStyle(
                  fontSize: _s(84),
                  fontWeight: FontWeight.w500,
                  fontFamily: 'monospace',
                  height: 0.85,
                ),
              ),
              Text(
                'HZ',
                style: TextStyle(
                  fontSize: _s(44),
                  fontWeight: FontWeight.w600,
                  height: 0.9,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: _s(16)),
        _buildRunButton(
          isConnected: isConnected,
          onTap: () => _runManualTreatment(context),
        ),
      ],
    );
  }

  Widget _buildPresetsContent(bool isConnected) {
    return Column(
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: _isCompact ? 1.08 : 1.22,
          mainAxisSpacing: _s(12),
          crossAxisSpacing: _s(12),
          children: _presets.keys
              .map(
                (name) => InkWell(
                  borderRadius: BorderRadius.circular(_s(14)),
                  onTap: () => _applyPreset(name),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_s(14)),
                      color: const Color(0xFFF3F3F3),
                      border: Border.all(color: Colors.black38),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: _s(66),
                          color: Colors.black54,
                        ),
                        SizedBox(height: _s(6)),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: _s(20),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        SizedBox(height: _s(18)),
        Row(
          children: [
            Expanded(
              child: _buildRunButton(
                isConnected: isConnected,
                onTap: () => _runManualTreatment(context),
              ),
            ),
            SizedBox(width: _s(10)),
            Expanded(
              flex: 2,
              child: Opacity(
                opacity: isConnected ? 1 : 0.45,
                child: _buildMenuButton(
                  'SAVE CURRENT AS PRESET',
                  compact: true,
                  onTap:
                      isConnected ? () => _saveCurrentAsPreset(context) : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDimmingRow(int nm) {
    final value = _dimmingValue(nm);
    final selected = nm == _currentSelectedWavelength;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: selected ? Colors.white24 : Colors.transparent,
        borderRadius: BorderRadius.circular(_s(9)),
      ),
      padding: EdgeInsets.symmetric(horizontal: _s(6), vertical: _s(2)),
      child: Row(
        children: [
          SizedBox(
            width: _s(58),
            child: Text(
              '$nm',
              style: TextStyle(fontSize: _s(22), fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                inactiveTrackColor: const Color(0xFF4A4A4A),
                activeTrackColor: const Color(0xFF4A4A4A),
                thumbColor: Colors.white,
                overlayColor: Colors.white24,
                trackHeight: _s(7),
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 100,
                divisions: 100,
                onChanged: (v) => _setDimmingValue(nm, v),
                onChangeStart: (_) => _selectWavelengthByValue(nm),
                onChangeEnd: (_) => _selectWavelengthByValue(nm),
              ),
            ),
          ),
          SizedBox(
            width: _s(68),
            child: Text(
              '${value.toInt()}%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: _s(22), fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(
    String text, {
    required VoidCallback? onTap,
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_s(38)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_s(38)),
        child: Ink(
          height: compact ? _s(84) : _s(98),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_s(38)),
            gradient: const LinearGradient(colors: [_gradStart, _gradEnd]),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(14)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? _s(42) : _s(54),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_s(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_s(14)),
        child: Ink(
          height: _s(110),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_s(14)),
            gradient: LinearGradient(
              colors: selected
                  ? const [Color(0xFF12D9CB), Color(0xFF4686F0)]
                  : const [Color(0xFF71CFE9), Color(0xFF8AAEF1)],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _s(12)),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _s(52),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlusMinusControl({
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    required Widget center,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildRoundTextButton(symbol: '-', onTap: onMinus),
        Expanded(child: Center(child: center)),
        _buildRoundTextButton(symbol: '+', onTap: onPlus),
      ],
    );
  }

  Widget _buildRoundTextButton({
    required String symbol,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: _s(116),
        height: _s(116),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [_gradStart, _gradEnd]),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              color: Colors.white,
              fontSize: _s(72),
              fontWeight: FontWeight.w300,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    double diameter = 76,
    double iconSize = 44,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: _s(diameter),
        height: _s(diameter),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [_gradStart, _gradEnd]),
        ),
        child: Icon(icon, size: _s(iconSize), color: Colors.white),
      ),
    );
  }

  Widget _buildRunButton({
    required bool isConnected,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: isConnected ? 1 : 0.45,
      child: _buildMenuButton(
        'RUN',
        compact: true,
        onTap: isConnected ? onTap : null,
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFACD7F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          title: const Text(
            'Debug avanzado',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF255F86),
            ),
          ),
          subtitle: const Text(
            'Panel plegable',
            style: TextStyle(fontSize: 12),
          ),
          children: [
            DropdownButton<int>(
              value: _startCommand,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 0x21, child: Text('Cmd: Quick Start (0x21)')),
                DropdownMenuItem(
                    value: 0x20, child: Text('Cmd: Power ON (0x20)')),
                DropdownMenuItem(value: -1, child: Text('Cmd: None')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _startCommand = v);
              },
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _sequenceMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                    value: 0, child: Text('Seq: Standard (Params -> Start)')),
                DropdownMenuItem(
                    value: 1, child: Text('Seq: Live (Params only)')),
                DropdownMenuItem(
                    value: 2, child: Text('Seq: Inverse (Start -> Params)')),
                DropdownMenuItem(
                    value: 3,
                    child: Text('Seq: Hard Reset (Stop -> Params -> Start)')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _sequenceMode = v);
              },
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _workMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Mode: 0 (Tested)')),
                DropdownMenuItem(value: 1, child: Text('Mode: 1')),
                DropdownMenuItem(value: 2, child: Text('Mode: 2')),
                DropdownMenuItem(value: 3, child: Text('Mode: 3')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() => _workMode = v);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    BleManager().log('--- READING DEVICE STATE ---');
                    await BleManager().write(BleProtocol.getStatus());
                    await Future.delayed(const Duration(milliseconds: 180));
                    await BleManager().write(BleProtocol.getWorkMode());
                    await Future.delayed(const Duration(milliseconds: 180));
                    await BleManager().write(BleProtocol.getCountdown());
                    await Future.delayed(const Duration(milliseconds: 180));
                    await BleManager().write(BleProtocol.getBrightness());
                  },
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text('Leer estado'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logs copiados al portapapeles'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar logs'),
                ),
              ],
            ),
            Container(
              height: 140,
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) => Text(
                  _logs[index],
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int get _currentSelectedWavelength => _waveOrder[_selectedWavelengthIndex];

  void _openSection(_ManualSection section) {
    setState(() => _section = section);
  }

  void _selectNextWavelength() {
    setState(() {
      _selectedWavelengthIndex =
          (_selectedWavelengthIndex + 1).clamp(0, _waveOrder.length - 1);
    });
  }

  void _selectPreviousWavelength() {
    setState(() {
      _selectedWavelengthIndex =
          (_selectedWavelengthIndex - 1).clamp(0, _waveOrder.length - 1);
    });
  }

  void _selectWavelengthByValue(int nm) {
    final idx = _waveOrder.indexOf(nm);
    if (idx == -1) return;
    setState(() => _selectedWavelengthIndex = idx);
  }

  double _dimmingValue(int nm) {
    switch (nm) {
      case 630:
        return _red630;
      case 660:
        return _red660;
      case 810:
        return _nir810;
      case 830:
        return _nir830;
      case 850:
        return _nir850;
      default:
        return 0;
    }
  }

  void _setDimmingValue(int nm, double value) {
    setState(() {
      switch (nm) {
        case 630:
          _red630 = value;
          break;
        case 660:
          _red660 = value;
          break;
        case 810:
          _nir810 = value;
          break;
        case 830:
          _nir830 = value;
          break;
        case 850:
          _nir850 = value;
          break;
      }
    });
  }

  void _setPulse(int hz) {
    setState(() {
      _pulseEnabled = true;
      _pulseHz = hz.toDouble();
    });
  }

  void _changeDuration(int delta) {
    setState(() {
      final next = _duration.toInt() + delta;
      _duration = next.clamp(1, 60).toDouble();
    });
  }

  void _changePulse(int delta) {
    setState(() {
      final current = (_pulseEnabled ? _pulseHz.toInt() : 0);
      final next = (current + delta).clamp(0, 50);
      _pulseHz = next.toDouble();
      _pulseEnabled = next > 0;
    });
  }

  void _applyPreset(String name) {
    final preset = _presets[name];
    if (preset == null) return;

    final values = List<int>.from(preset['freq'] as List);
    setState(() {
      _duration = (preset['duration'] as int).toDouble();
      final pulse = preset['pulse'] as int;
      _pulseEnabled = pulse > 0;
      _pulseHz = pulse.toDouble();
      _red630 = values[0].toDouble();
      _red660 = values[1].toDouble();
      _nir810 = values[2].toDouble();
      _nir830 = values[3].toDouble();
      _nir850 = values[4].toDouble();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Preset '$name' aplicado")),
    );
  }

  void _saveCurrentAsPreset(BuildContext context) {
    final state = context.read<AppState>();
    final presetName =
        'Custom ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

    final custom = Tratamiento(
      id: 'manual_preset_${DateTime.now().millisecondsSinceEpoch}',
      nombre: presetName,
      zona: 'Manual',
      descripcion: 'Preset guardado desde configuracion manual',
      sintomas: 'Personalizado',
      hz: !_pulseEnabled || _pulseHz == 0 ? 'CW' : '${_pulseHz.toInt()}Hz',
      duracion: _duration.toInt().toString(),
      frecuencias: [
        {'nm': 630, 'p': _red630.toInt()},
        {'nm': 660, 'p': _red660.toInt()},
        {'nm': 810, 'p': _nir810.toInt()},
        {'nm': 830, 'p': _nir830.toInt()},
        {'nm': 850, 'p': _nir850.toInt()},
      ],
      esCustom: true,
    );

    state.agregarTratamientoCatalogo(custom);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Guardado como '$presetName' en catalogo")),
    );
  }

  Future<void> _applyPowerSelection(BuildContext context) async {
    await BleManager().write(BleProtocol.setPower(_powerShouldBeOn));
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            _powerShouldBeOn ? 'Comando ON enviado' : 'Comando OFF enviado'),
      ),
    );
  }

  void _runManualTreatment(BuildContext context) {
    final state = context.read<AppState>();

    final manualT = Tratamiento(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      nombre: 'Manual Custom',
      zona: 'Manual',
      sintomas: 'Personalizado',
      duracion: _duration.toInt().toString(),
      hz: !_pulseEnabled || _pulseHz == 0 ? 'CW' : '${_pulseHz.toInt()}Hz',
      frecuencias: [
        {'nm': 630, 'p': _red630.toInt()},
        {'nm': 660, 'p': _red660.toInt()},
        {'nm': 810, 'p': _nir810.toInt()},
        {'nm': 830, 'p': _nir830.toInt()},
        {'nm': 850, 'p': _nir850.toInt()},
      ],
    );

    state.iniciarCicloManual(
      manualT,
      startCommand: _startCommand,
      sequenceMode: _sequenceMode,
      workMode: _workMode,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enviando configuracion al dispositivo...')),
    );
  }
}

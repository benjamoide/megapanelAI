
import 'package:flutter/material.dart';
import 'package:mega_panel_ai/main.dart'; // To access AppState and Tratamiento
import 'package:provider/provider.dart';
import 'package:mega_panel_ai/bluetooth/ble_manager.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BluetoothCustomView extends StatefulWidget {
  const BluetoothCustomView({Key? key}) : super(key: key);

  @override
  State<BluetoothCustomView> createState() => _BluetoothCustomViewState();
}

class _BluetoothCustomViewState extends State<BluetoothCustomView> {
  // State for sliders
  double _red630 = 0.0;
  double _red660 = 0.0;
  double _nir810 = 0.0;
  double _nir830 = 0.0;
  double _nir850 = 0.0;
  
  double _pulseHz = 0.0; // 0 means CW
  bool _pulseEnabled = true; 
  double _duration = 10.0; // Minutes

  // Protocol Debugging
  int _startCommand = 0x21; // Default to QuickStart
  int _sequenceMode = 0; // 0=Std, 1=Live, 2=Inverse

  // --- LOGGING ---
  final List<String> _logs = [];
  StreamSubscription? _logSub;

  @override
  void initState() {
    super.initState();
    _logSub = BleManager().logs.listen((log) {
      if (mounted) {
        setState(() {
          _logs.insert(0, log);
          if (_logs.length > 100) _logs.removeLast();
        });
      }
    });
  }

  @override
  void dispose() {
    _logSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var state = context.watch<AppState>();
    bool isConnected = state.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Control Manual"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isConnected)
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.red.shade100,
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth_disabled, color: Colors.red),
                    SizedBox(width: 10),
                    Expanded(child: Text("Debes conectar el dispositivo primero."))
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            const Text("Intensidad (Dimming)", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            
            _buildSlider("🔴 630nm (Rojo)", _red630, (v) => setState(() => _red630 = v), Colors.red),
            _buildSlider("🔴 660nm (Rojo Profundo)", _red660, (v) => setState(() => _red660 = v), Colors.red.shade900),
            _buildSlider("🔦 810nm (NIR)", _nir810, (v) => setState(() => _nir810 = v), Colors.purple.shade200),
            _buildSlider("🔦 830nm (NIR)", _nir830, (v) => setState(() => _nir830 = v), Colors.purple.shade300),
            _buildSlider("🔦 850nm (NIR)", _nir850, (v) => setState(() => _nir850 = v), Colors.purple),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            const Text("Pulsación (Hz)", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Text("Pulsación (Hz)", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Switch(value: _pulseEnabled, onChanged: (v) => setState(() => _pulseEnabled = v)),
                const Text("Activar Pulsación"),
              ],
            ),
            if (_pulseEnabled) ...[
                const Text("0 Hz = Modo Continuo (CW)", style: TextStyle(color: Colors.grey)),
                Slider(
                  value: _pulseHz,
                  min: 0,
                  max: 50,
                  divisions: 50,
                  label: "${_pulseHz.toInt()} Hz",
                  onChanged: (v) => setState(() => _pulseHz = v),
                ),
            ],
            
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            const Text("Duración (Minutos)", 
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Slider(
              value: _duration,
              min: 1,
              max: 30,
              divisions: 29,
              label: "${_duration.toInt()} min",
              onChanged: (v) => setState(() => _duration = v),
            ),

            const SizedBox(height: 30),
            
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text("INICIAR TRATAMIENTO (RUN)"),
                onPressed: isConnected ? () {
                  _runManualTreatment(context);
                } : null,
              ),
            ),



            const SizedBox(height: 20),
            const Divider(),
            const Text("Protocol Debugging", style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<int>(
              value: _startCommand,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0x21, child: Text("Cmd: Quick Start (0x21)")),
                DropdownMenuItem(value: 0x20, child: Text("Cmd: Power ON (0x20)")),
                DropdownMenuItem(value: -1, child: Text("Cmd: None")),
              ], 
              onChanged: (v) => setState(() => _startCommand = v!)
            ),
            
            const SizedBox(height: 10),
            
            DropdownButton<int>(
              value: _sequenceMode,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 0, child: Text("Seq: Standard (Reset -> Params -> Start)")),
                DropdownMenuItem(value: 1, child: Text("Seq: Live (Params Only)")),
                DropdownMenuItem(value: 2, child: Text("Seq: Inverse (Start -> Params)")),
              ], 
              onChanged: (v) => setState(() => _sequenceMode = v!)
            ),

            const SizedBox(height: 20),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Debug Console", style: TextStyle(fontWeight: FontWeight.bold)),

                TextButton.icon(
                  icon: const Icon(Icons.info_outline, size: 16),
                  label: const Text("Leer Estado"),
                  onPressed: () async {
                     BleManager().log("--- READING DEVICE STATE ---");
                     await BleManager().write(BleProtocol.getStatus());
                     await Future.delayed(const Duration(milliseconds: 200));
                     await BleManager().write(BleProtocol.getWorkMode());
                     await Future.delayed(const Duration(milliseconds: 200));
                     await BleManager().write(BleProtocol.getCountdown());
                     await Future.delayed(const Duration(milliseconds: 200));
                     await BleManager().write(BleProtocol.getBrightness());
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text("Copiar Logs"),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _logs.join("\n")));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Logs copiados al portapapeles"))
                    );
                  },
                )
              ],
            ),
            Container(
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8)
              ),
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  return Text(_logs[index], style: const TextStyle(fontFamily: 'monospace', fontSize: 10));
                },
              )
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, double value, Function(double) onChanged, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text("${value.toInt()}%", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: 0,
          max: 100,
          divisions: 100,
          activeColor: color,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _runManualTreatment(BuildContext context) {
    var state = context.read<AppState>();
    
    // Create a temporary Tratamiento object
    Tratamiento manualT = Tratamiento(
      id: "manual_${DateTime.now().millisecondsSinceEpoch}",
      nombre: "Manual Custom",
      zona: "Manual",
      sintomas: "Personalizado",

      duracion: _duration.toInt().toString(),
      hz: !_pulseEnabled ? "CW" : (_pulseHz == 0 ? "CW" : "${_pulseHz.toInt()}Hz"),
      frecuencias: [
        {"nm": 630, "p": _red630.toInt()},
        {"nm": 660, "p": _red660.toInt()},
        {"nm": 810, "p": _nir810.toInt()},
        {"nm": 830, "p": _nir830.toInt()},
        {"nm": 850, "p": _nir850.toInt()},
      ]
    );

    state.iniciarCicloManual(manualT, startCommand: _startCommand, sequenceMode: _sequenceMode);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Enviando configuración al dispositivo..."))
    );
  }
}

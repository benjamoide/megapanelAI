import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:mega_panel_ai/bluetooth/ble_manager.dart';
import 'package:mega_panel_ai/main.dart';
import 'package:provider/provider.dart';

class BlueprintThreeBluetoothScanDialog extends StatefulWidget {
  const BlueprintThreeBluetoothScanDialog({super.key});

  @override
  State<BlueprintThreeBluetoothScanDialog> createState() =>
      _BlueprintThreeBluetoothScanDialogState();
}

class _BlueprintThreeBluetoothScanDialogState
    extends State<BlueprintThreeBluetoothScanDialog> {
  final BleManager _ble = BleManager();
  late final AppState _appState;

  StreamSubscription<List<ScanResult>>? _scanResultsSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  Timer? _scanWatchdog;

  List<ScanResult> _scanResults = const [];
  List<BluetoothDevice> _systemDevices = const [];
  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  bool _isScanning = false;
  String? _scanError;
  int _scanAttempt = 0;

  String _displayName(ScanResult result) {
    final advName = result.advertisementData.advName.trim();
    final platformName = result.device.platformName.trim();
    if (advName.isNotEmpty) return advName;
    if (platformName.isNotEmpty) return platformName;
    return 'Unnamed device';
  }

  String _displayDeviceName(BluetoothDevice device) {
    final platformName = device.platformName.trim();
    if (platformName.isNotEmpty) return platformName;
    return 'Unnamed device';
  }

  List<ScanResult> _prioritizeResults(List<ScanResult> results) {
    final source = List<ScanResult>.from(results);
    source.sort((a, b) {
      final nameA = _displayName(a).toLowerCase();
      final nameB = _displayName(b).toLowerCase();
      final aIsBlock = nameA.contains('block');
      final bIsBlock = nameB.contains('block');

      if (aIsBlock && !bIsBlock) return -1;
      if (!aIsBlock && bIsBlock) return 1;

      return b.rssi.compareTo(a.rssi);
    });
    return source;
  }

  Future<void> _loadSystemDevices() async {
    final devices = await _ble.getSystemDevices();
    if (!mounted) return;
    setState(() {
      _systemDevices = devices;
    });
  }

  Future<void> _restartScan() async {
    _scanWatchdog?.cancel();
    if (mounted) {
      setState(() {
        _scanError = null;
        _scanResults = const [];
        _systemDevices = const [];
        _scanAttempt++;
      });
    }
    await _ble.stopScan();
    await Future.delayed(const Duration(milliseconds: 400));
    await _loadSystemDevices();
    await _ble.startScan();
    _scanWatchdog = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      if (_scanResults.isEmpty && _systemDevices.isEmpty) {
        setState(() {
          _scanError ??=
              'No BLE devices reported yet. If you expect the Mega panel here, confirm it is powered on and advertising.';
        });
      }
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {});
  }

  String _adapterStateLabel(BluetoothAdapterState state) {
    switch (state) {
      case BluetoothAdapterState.on:
        return 'ON';
      case BluetoothAdapterState.off:
        return 'OFF';
      case BluetoothAdapterState.turningOn:
        return 'TURNING ON';
      case BluetoothAdapterState.turningOff:
        return 'TURNING OFF';
      case BluetoothAdapterState.unavailable:
        return 'UNAVAILABLE';
      case BluetoothAdapterState.unauthorized:
        return 'UNAUTHORIZED';
      case BluetoothAdapterState.unknown:
        return 'UNKNOWN';
    }
  }

  Widget _buildDeviceTile(BluetoothDevice device, {ScanResult? result}) {
    final title =
        result != null ? _displayName(result) : _displayDeviceName(device);
    final rssiSuffix = result != null ? ' (${result.rssi} dBm)' : '';
    final isCandidate = title.toLowerCase().contains('block');
    return ListTile(
      leading: Icon(
        isCandidate ? Icons.lightbulb_circle_rounded : Icons.bluetooth,
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        '${device.remoteId}$rssiSuffix'
        '${isCandidate ? '' : ' | Generic BLE device'}',
      ),
      onTap: () async {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        final success = await _appState.connectToDevice(device);

        if (context.mounted) {
          Navigator.pop(context);
          if (success) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connected to $title'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _appState = context.read<AppState>();
    _adapterState = _ble.adapterStateNow;
    _isScanning = _ble.isScanningNow;
    _scanResultsSubscription = _ble.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _scanResults = _prioritizeResults(results);
        _scanError = null;
      });
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _scanError = '$error';
      });
    });
    _isScanningSubscription = _ble.isScanning.listen((value) {
      if (!mounted) return;
      setState(() {
        _isScanning = value;
      });
    });
    _adapterStateSubscription = _ble.adapterState.listen((state) {
      if (!mounted) return;
      setState(() {
        _adapterState = state;
      });
    });
    unawaited(_startDialogSession());
  }

  Future<void> _startDialogSession() async {
    await _appState.ensureBleActivated();
    _appState.setBleAutoReconnectSuspended(true, reason: 'scan-dialog');
    await _restartScan();
  }

  @override
  void dispose() {
    _scanWatchdog?.cancel();
    _scanResultsSubscription?.cancel();
    _isScanningSubscription?.cancel();
    _adapterStateSubscription?.cancel();
    _appState.setBleAutoReconnectSuspended(
      false,
      reason: 'scan-dialog-closed',
    );
    _ble.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final connectedDevice = state.connectedBleDevice;
    final connectedName = (() {
      final name = connectedDevice?.platformName.trim() ?? '';
      if (name.isNotEmpty) return name;
      return connectedDevice?.remoteId.str ?? 'Unknown';
    })();
    final systemOnly = _systemDevices
        .where(
          (device) => !_scanResults.any(
            (result) => result.device.remoteId == device.remoteId,
          ),
        )
        .toList();

    return AlertDialog(
      title: const Text('Bluetooth devices'),
      content: SizedBox(
        width: 320,
        height: 460,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Rescan',
                icon: const Icon(Icons.refresh),
                onPressed: _restartScan,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Adapter: ${_adapterStateLabel(_adapterState)} | '
                'Scan: ${_isScanning ? 'running' : 'stopped'} | '
                'Live: ${_scanResults.length} | '
                'System: ${_systemDevices.length} | '
                'Try: $_scanAttempt',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 8),
            if (state.isConnected)
              ListTile(
                title: Text(connectedName),
                subtitle: const Text('Connected'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    state.disconnectDevice();
                    Navigator.pop(context);
                  },
                ),
              ),
            const Divider(),
            Expanded(
              child: (_scanResults.isEmpty && systemOnly.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.bluetooth_searching, size: 28),
                          const SizedBox(height: 8),
                          Text(
                            _scanError != null
                                ? 'Scan error: $_scanError'
                                : _adapterState != BluetoothAdapterState.on
                                    ? 'Bluetooth unavailable: ${_adapterStateLabel(_adapterState)}'
                                    : _isScanning
                                        ? 'Scanning for BLE devices...'
                                        : 'Scan stopped. Tap retry to restart it.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'This dialog now shows any BLE device the phone reports, not only BlockBlueLight candidates.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _restartScan,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry scan'),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        ..._scanResults.map(
                          (item) =>
                              _buildDeviceTile(item.device, result: item),
                        ),
                        if (systemOnly.isNotEmpty) ...[
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(
                              'System BLE devices',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                          ...systemOnly.map(_buildDeviceTile),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

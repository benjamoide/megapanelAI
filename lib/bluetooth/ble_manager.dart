import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class BleManager {
  // Singleton pattern
  static final BleManager _instance = BleManager._internal();
  factory BleManager() => _instance;
  BleManager._internal();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  Future<void> _pendingWrite = Future.value();

  static const int _maxChunkSize = 20;
  static const int _maxWriteAttempts = 3;
  static const Duration _chunkGap = Duration(milliseconds: 80);
  static const Duration _retryDelay = Duration(milliseconds: 120);

  // Persistent stream controller for connection state
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  // Log stream
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logs => _logController.stream;

  void log(String msg) {
    developer.log(msg, name: 'BleManager');
    _logController.add("${DateFormat('HH:mm:ss').format(DateTime.now())}: $msg");
  }

  // Expose current state synchronously
  bool get isConnected => _connectedDevice != null && _connectedDevice!.isConnected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> init() async {
    // Request core BLE permissions early.
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    // Some Android devices still need location permission for reliable BLE discovery.
    await Permission.locationWhenInUse.request();
    // Emit initial disconnected state
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> startScan() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      log("Bluetooth adapter is not ON: $adapterState");
      return;
    }

    final scanGranted = await Permission.bluetoothScan.request().isGranted;
    final connectGranted = await Permission.bluetoothConnect.request().isGranted;
    final locationGranted = await Permission.location.request().isGranted ||
        await Permission.locationWhenInUse.request().isGranted;

    if (!scanGranted || !connectGranted) {
      log("Permissions not granted for scanning");
      return;
    }

    if (!locationGranted) {
      log("Location permission denied; some devices may not appear in scan.");
    }

    try {
      await FlutterBluePlus.startScan(
        continuousUpdates: true,
        removeIfGone: const Duration(seconds: 8),
        androidScanMode: AndroidScanMode.lowLatency,
        androidUsesFineLocation: locationGranted,
        // Some phones incorrectly report location-services state and block scans.
        androidCheckLocationServices: false,
      );
      log("Scan started.");
    } catch (e) {
      log("Error starting scan (primary mode): $e");
      try {
        await FlutterBluePlus.startScan(
          continuousUpdates: true,
          removeIfGone: const Duration(seconds: 8),
          androidScanMode: AndroidScanMode.lowLatency,
          androidUsesFineLocation: false,
          androidCheckLocationServices: false,
        );
        log("Scan started in compatibility fallback mode.");
      } catch (fallbackError) {
        log("Error starting scan (fallback mode): $fallbackError");
      }
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      log("Error stopping scan: $e");
    }
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<bool> connect(BluetoothDevice device) async {
    try {
      // Stop scanning before connecting
      await stopScan();

      if (_connectedDevice != null && _connectedDevice!.remoteId != device.remoteId) {
        await _connectedDevice?.disconnect();
      }

      await _connectWithRetry(device);
      _connectedDevice = device;

      // Update local stream
      _connectionStateController.add(BluetoothConnectionState.connected);

      // Listen to connection state
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
          log("BleManager: Device Disconnected");
          _cleanup();
        }
      });
  
      // Stabilization delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      log("BleManager: Discovering Services...");
      final services = await device.discoverServices();

      _selectCharacteristics(services);
      if (_writeCharacteristic == null) {
        log("No write characteristic found!");
        await disconnect();
        return false;
      }

      await _notifySubscription?.cancel();
      if (_notifyCharacteristic != null) {
        await _notifyCharacteristic!.setNotifyValue(true);
        _notifySubscription = _notifyCharacteristic!.lastValueStream.listen((value) {
          log("BLE RX: ${_hex(value)}");
        }, onError: (error) {
          log("Notify stream error: $error");
        });
      } else {
        log("No notify characteristic found (writes only).");
      }

      log(
        "BleManager: Connected and ready. "
        "Write=${_writeCharacteristic?.uuid.str}, "
        "Notify=${_notifyCharacteristic?.uuid.str ?? 'none'}",
      );
      return true;
    } catch (e) {
      log("Connection failed: $e");
      await disconnect();
      return false;
    }
  }

  Future<void> _connectWithRetry(BluetoothDevice device) async {
    if (device.isConnected) return;

    try {
      await device.connect(timeout: const Duration(seconds: 15));
      return;
    } catch (e) {
      if (device.isConnected || _isAlreadyConnectedError(e)) {
        log("BleManager: Device already connected, continuing discovery.");
        return;
      }
      log("BleManager: First connect attempt failed, retrying once: $e");
    }

    try {
      await device.disconnect();
    } catch (_) {
      // Ignore cleanup errors before retry.
    }
    await Future.delayed(const Duration(milliseconds: 350));
    await device.connect(timeout: const Duration(seconds: 15));
  }

  bool _isAlreadyConnectedError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains("already connected") ||
        message.contains("connection is already");
  }

  void _selectCharacteristics(List<BluetoothService> services) {
    BluetoothCharacteristic? pairedWrite;
    BluetoothCharacteristic? pairedNotify;
    BluetoothCharacteristic? fallbackWrite;
    BluetoothCharacteristic? fallbackNotify;

    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    for (final service in services) {
      log("BleManager: Service ${service.uuid.str}");
      BluetoothCharacteristic? serviceWrite;
      BluetoothCharacteristic? serviceNotify;
      for (final characteristic in service.characteristics) {
        final canWrite =
            characteristic.properties.write || characteristic.properties.writeWithoutResponse;
        final canNotify = characteristic.properties.notify || characteristic.properties.indicate;
        final props = characteristic.properties;
        log(
          "  Char ${characteristic.uuid.str} "
          "[write=${props.write}, wnr=${props.writeWithoutResponse}, "
          "notify=${props.notify}, indicate=${props.indicate}]",
        );

        if (canWrite) {
          serviceWrite = characteristic;
          fallbackWrite = characteristic;
        }
        if (canNotify) {
          serviceNotify = characteristic;
          fallbackNotify = characteristic;
        }
      }

      // Mirrors the APK behavior: keep the latest service that has both.
      if (serviceWrite != null && serviceNotify != null) {
        pairedWrite = serviceWrite;
        pairedNotify = serviceNotify;
      }
    }

    _writeCharacteristic = pairedWrite ?? fallbackWrite;
    _notifyCharacteristic = pairedNotify ?? fallbackNotify;
    log(
      "BleManager: Characteristic selection "
      "write=${_writeCharacteristic?.uuid.str ?? 'none'} "
      "notify=${_notifyCharacteristic?.uuid.str ?? 'none'}",
    );
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    log("BleManager: Cleaning up resources");
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _pendingWrite = Future.value();
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> write(List<int> data) async {
    if (_writeCharacteristic == null) {
      log("Not connected or no write characteristic");
      return;
    }

    final normalized = data.map((byte) => byte & 0xFF).toList(growable: false);
    _pendingWrite = _pendingWrite.then((_) => _writeInternal(normalized)).catchError((error) {
      log("Write queue error: $error");
    });
    return _pendingWrite;
  }

  Future<void> _writeInternal(List<int> data) async {
    if (data.isEmpty) return;
    final totalChunks = (data.length / _maxChunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      final start = i * _maxChunkSize;
      final end = math.min(start + _maxChunkSize, data.length);
      final chunk = data.sublist(start, end);
      await _writeChunkWithRetry(chunk, index: i + 1, total: totalChunks);
      if (i < totalChunks - 1) {
        await Future.delayed(_chunkGap);
      }
    }
  }

  Future<void> _writeChunkWithRetry(
    List<int> chunk, {
    required int index,
    required int total,
  }) async {
    for (int attempt = 1; attempt <= _maxWriteAttempts; attempt++) {
      final characteristic = _writeCharacteristic;
      if (characteristic == null) {
        throw StateError("Write characteristic is no longer available");
      }

      try {
        log("BLE WRITE [$index/$total] try $attempt: ${_hex(chunk)}");
        await characteristic.write(chunk, withoutResponse: _shouldUseWithoutResponse(characteristic));
        return;
      } catch (e) {
        if (attempt >= _maxWriteAttempts) {
          rethrow;
        }
        log("BLE write retry needed [$index/$total]: $e");
        await Future.delayed(_retryDelay);
      }
    }
  }

  bool _shouldUseWithoutResponse(BluetoothCharacteristic characteristic) {
    // Prefer write-with-response when available, matching APK behavior.
    if (characteristic.properties.write) return false;
    return characteristic.properties.writeWithoutResponse;
  }

  String _hex(List<int> data) =>
      data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
}

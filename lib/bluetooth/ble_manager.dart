import 'dart:async';
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
  final List<BluetoothCharacteristic> _writeCandidates = [];
  final List<BluetoothCharacteristic> _notifyCandidates = [];
  
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  final List<StreamSubscription<List<int>>> _notifySubscriptions = [];
  Future<void> _pendingWrite = Future.value();
  DateTime _lastRxAt = DateTime.fromMillisecondsSinceEpoch(0);

  static const int _maxChunkSize = 20;
  static const int _maxWriteAttempts = 3;
  static const Duration _chunkGap = Duration(milliseconds: 80);
  static const Duration _retryDelay = Duration(milliseconds: 120);
  static const List<int> _statusProbePacket = [0x3A, 0x01, 0x10, 0x00, 0x00, 0x11, 0x0A];

  // Persistent stream controller for connection state
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  // Log stream
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logs => _logController.stream;

  void log(String msg) {
    print(msg); // Keep console print
    _logController.add("${DateFormat('HH:mm:ss').format(DateTime.now())}: $msg");
  }

  // Expose current state synchronously
  bool get isConnected => _connectedDevice != null && _connectedDevice!.isConnected;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> init() async {
    // Check permissions
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      // Permissions granted
    }
    // Emit initial disconnected state
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> startScan() async {
    // Ensure permissions are granted before scanning
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        (await Permission.location.request().isGranted || await Permission.locationWhenInUse.request().isGranted)) {
      try {
        await FlutterBluePlus.startScan(
            timeout: const Duration(seconds: 10), androidUsesFineLocation: true);
      } catch (e) {
          log("Error starting scan: $e");
      }
    } else {
      log("Permissions not granted for scanning");
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

      await _startNotifyListeners();
      if (_notifySubscriptions.isEmpty) {
        log("No notify characteristic found (writes only).");
      }

      await _autoDetectWriteCharacteristic();

      log(
        "BleManager: Connected and ready. "
        "Write=${_writeCharacteristic?.uuid.str}, "
        "Notify=${_notifyCharacteristic?.uuid.str ?? 'none'} "
        "(writeCandidates=${_writeCandidates.length}, notifyCandidates=${_notifyCandidates.length})",
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
    _writeCandidates.clear();
    _notifyCandidates.clear();
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
          serviceWrite ??= characteristic;
          fallbackWrite ??= characteristic;
          _writeCandidates.add(characteristic);
        }
        if (canNotify) {
          serviceNotify ??= characteristic;
          fallbackNotify ??= characteristic;
          _notifyCandidates.add(characteristic);
        }
      }

      // Prefer the first service that has both write + notify/indicate.
      if (serviceWrite != null && serviceNotify != null) {
        _writeCharacteristic = serviceWrite;
        _notifyCharacteristic = serviceNotify;
        log(
          "BleManager: Characteristic selection "
          "write=${_writeCharacteristic?.uuid.str ?? 'none'} "
          "notify=${_notifyCharacteristic?.uuid.str ?? 'none'}",
        );
        return;
      }
    }

    _writeCharacteristic = fallbackWrite;
    _notifyCharacteristic = fallbackNotify;
    log(
      "BleManager: Characteristic selection "
      "write=${_writeCharacteristic?.uuid.str ?? 'none'} "
      "notify=${_notifyCharacteristic?.uuid.str ?? 'none'}",
    );
  }

  Future<void> _startNotifyListeners() async {
    for (final sub in _notifySubscriptions) {
      await sub.cancel();
    }
    _notifySubscriptions.clear();

    final targets = _notifyCandidates.isNotEmpty
        ? _notifyCandidates
        : (_notifyCharacteristic == null ? <BluetoothCharacteristic>[] : <BluetoothCharacteristic>[_notifyCharacteristic!]);

    for (final characteristic in targets) {
      try {
        final forceIndications =
            characteristic.properties.indicate && !characteristic.properties.notify;
        await characteristic.setNotifyValue(true, forceIndications: forceIndications);
        log(
          "Notify enabled on ${characteristic.uuid.str} "
          "(forceIndications=$forceIndications)",
        );

        final sub = characteristic.onValueReceived.listen((value) {
          _lastRxAt = DateTime.now();
          log("BLE RX [${characteristic.uuid.str}]: ${_hex(value)}");
        }, onError: (error) {
          log("Notify stream error on ${characteristic.uuid.str}: $error");
        });
        _notifySubscriptions.add(sub);
      } catch (e) {
        log("Notify enable failed on ${characteristic.uuid.str}: $e");
      }
    }
  }

  Future<void> _autoDetectWriteCharacteristic() async {
    if (_writeCandidates.length <= 1) return;

    log("BleManager: Probing ${_writeCandidates.length} write candidates...");
    for (final candidate in _writeCandidates) {
      final marker = DateTime.now();
      try {
        log("BLE PROBE WRITE: ${candidate.uuid.str} ${_hex(_statusProbePacket)}");
        await candidate.write(
          _statusProbePacket,
          withoutResponse: _shouldUseWithoutResponse(candidate),
        );
      } catch (e) {
        log("BLE PROBE failed on ${candidate.uuid.str}: $e");
        continue;
      }

      final gotRx = await _waitForRxAfter(marker, const Duration(milliseconds: 450));
      if (gotRx) {
        _writeCharacteristic = candidate;
        log("BleManager: Auto-selected write characteristic ${candidate.uuid.str} after probe RX.");
        return;
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }

    log("BleManager: No RX during probe; keeping write=${_writeCharacteristic?.uuid.str ?? 'none'}");
  }

  Future<bool> _waitForRxAfter(DateTime marker, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_lastRxAt.isAfter(marker)) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 40));
    }
    return _lastRxAt.isAfter(marker);
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    log("BleManager: Cleaning up resources");
    _connectionSubscription?.cancel();
    for (final sub in _notifySubscriptions) {
      sub.cancel();
    }
    _notifySubscriptions.clear();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _writeCandidates.clear();
    _notifyCandidates.clear();
    _pendingWrite = Future.value();
    _lastRxAt = DateTime.fromMillisecondsSinceEpoch(0);
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

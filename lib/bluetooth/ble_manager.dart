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
  int _writeSession = 0;
  bool _isReady = false;
  DateTime? _lastRxAt;
  bool _hadProtocolRxSinceConnect = false;
  bool _preferWriteWithoutResponse = false;
  bool _suspendReadCommands = false;
  List<int> _rxBuffer = <int>[];

  static const int _maxChunkSize = 20;
  static const int _maxWriteAttempts = 3;
  static const Duration _chunkGap = Duration(milliseconds: 80);
  static const Duration _retryDelay = Duration(milliseconds: 120);

  // Persistent stream controller for connection state
  final _connectionStateController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState =>
      _connectionStateController.stream;

  // Log stream
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logs => _logController.stream;
  final _protocolFrameController = StreamController<List<int>>.broadcast();
  Stream<List<int>> get protocolFrames => _protocolFrameController.stream;

  void log(String msg) {
    developer.log(msg, name: 'BleManager');
    _logController
        .add("${DateFormat('HH:mm:ss').format(DateTime.now())}: $msg");
  }

  // Expose current state synchronously
  bool get isConnected =>
      _connectedDevice != null &&
      _connectedDevice!.isConnected &&
      _isReady &&
      _writeCharacteristic != null;
  bool get canObserveRx => _notifyCharacteristic != null;
  bool get hasSeenProtocolRx => _hadProtocolRxSinceConnect;
  bool get prefersWriteWithoutResponse => _preferWriteWithoutResponse;
  bool get readCommandGateActive => _suspendReadCommands;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  void setPreferWriteWithoutResponse(bool enabled, {String reason = ""}) {
    if (_preferWriteWithoutResponse == enabled) return;
    _preferWriteWithoutResponse = enabled;
    final reasonSuffix = reason.isEmpty ? "" : " ($reason)";
    log(
      "BLE WRITE MODE -> ${enabled ? 'withoutResponse' : 'withResponse'}$reasonSuffix",
    );
  }

  void setReadCommandGate(bool enabled, {String reason = ""}) {
    if (_suspendReadCommands == enabled) return;
    _suspendReadCommands = enabled;
    final reasonSuffix = reason.isEmpty ? "" : " ($reason)";
    log(
      "BLE READ GATE -> ${enabled ? 'enabled' : 'disabled'}$reasonSuffix",
    );
  }

  bool hasRecentRx(Duration window) {
    final rx = _lastRxAt;
    if (rx == null) return false;
    return DateTime.now().difference(rx) <= window;
  }

  Future<List<int>?> waitForFrame(
    bool Function(List<int> frame) predicate, {
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!canObserveRx) return null;
    final completer = Completer<List<int>?>();
    late final StreamSubscription<List<int>> subscription;
    subscription = protocolFrames.listen((frame) {
      if (completer.isCompleted) return;
      bool matched = false;
      try {
        matched = predicate(frame);
      } catch (_) {
        matched = false;
      }
      if (matched) {
        completer.complete(frame);
      }
    });

    try {
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      return null;
    } finally {
      await subscription.cancel();
    }
  }

  Future<List<int>?> writeAndWaitForAck(
    List<int> data, {
    required int ackCommand,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    if (!canObserveRx) {
      await write(data);
      return null;
    }
    final waitFuture = waitForFrame(
      (frame) => frame.length > 2 && (frame[2] & 0xFF) == (ackCommand & 0xFF),
      timeout: timeout,
    );
    await write(data);
    return waitFuture;
  }

  int? _extractProtocolCommand(List<int> data) {
    if (data.length < 3) return null;
    if ((data[0] & 0xFF) != 0x3A) return null;
    return data[2] & 0xFF;
  }

  bool _isReadCommand(int command) {
    return command == 0x10 || // getStatus
        command == 0x30 || // getCountdown
        command == 0x40 || // getBrightness
        command == 0x51; // getWorkMode
  }

  void _ingestNotifyBytes(List<int> value) {
    if (value.isEmpty) {
      log("BLE RX: <empty>");
      return;
    }
    _rxBuffer.addAll(value);
    _drainRxBuffer();
  }

  int _findFrameStart(List<int> data) {
    for (var i = 0; i < data.length - 1; i++) {
      if ((data[i] & 0xFF) == 0x2A && (data[i + 1] & 0xFF) == 0x01) {
        return i;
      }
    }
    return -1;
  }

  void _drainRxBuffer() {
    while (true) {
      if (_rxBuffer.isEmpty) return;
      final start = _findFrameStart(_rxBuffer);
      if (start < 0) {
        final keepTrailingHead =
            (_rxBuffer.last & 0xFF) == 0x2A ? <int>[0x2A] : <int>[];
        if (_rxBuffer.length > keepTrailingHead.length) {
          log("BLE RX (ignored/non-protocol): ${_hex(_rxBuffer)}");
        }
        _rxBuffer = keepTrailingHead;
        return;
      }

      if (start > 0) {
        final dropped = _rxBuffer.sublist(0, start);
        log("BLE RX (dropped-prefix): ${_hex(dropped)}");
        _rxBuffer.removeRange(0, start);
      }

      if (_rxBuffer.length < 7) return;
      final payloadLength =
          ((_rxBuffer[3] & 0xFF) << 8) | (_rxBuffer[4] & 0xFF);
      final frameLength = payloadLength + 7;
      if (frameLength <= 0) {
        _rxBuffer.removeAt(0);
        continue;
      }
      if (_rxBuffer.length < frameLength) return;

      final frame = _rxBuffer.sublist(0, frameLength);
      _rxBuffer.removeRange(0, frameLength);
      _handleProtocolFrame(frame);
    }
  }

  void _handleProtocolFrame(List<int> frame) {
    if (frame.length < 7) {
      log("BLE RX (ignored/short-frame): ${_hex(frame)}");
      return;
    }
    final tail = frame.last & 0xFF;
    if (tail != 0x0A) {
      log("BLE RX (ignored/bad-tail): ${_hex(frame)}");
      return;
    }

    var checksum = 0;
    for (var i = 1; i < frame.length - 2; i++) {
      checksum += frame[i] & 0xFF;
    }
    checksum &= 0xFF;
    final expected = frame[frame.length - 2] & 0xFF;
    if (checksum != expected) {
      log(
        "BLE RX checksum mismatch "
        "(calc=${checksum.toRadixString(16).padLeft(2, '0')} "
        "pkt=${expected.toRadixString(16).padLeft(2, '0')}): ${_hex(frame)}",
      );
    }

    _lastRxAt = DateTime.now();
    _hadProtocolRxSinceConnect = true;
    log("BLE RX: ${_hex(frame)}");
    _protocolFrameController.add(frame);
  }

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
    final connectGranted =
        await Permission.bluetoothConnect.request().isGranted;
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

      if (_connectedDevice != null &&
          _connectedDevice!.remoteId != device.remoteId) {
        await _connectedDevice?.disconnect();
      }

      await _connectWithRetry(device);
      _connectedDevice = device;
      _isReady = false;
      _lastRxAt = null;
      _hadProtocolRxSinceConnect = false;
      _rxBuffer.clear();

      // Listen to connection state
      await _connectionSubscription?.cancel();
      _connectionSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectionStateController.add(state);
          log("BleManager: Device Disconnected");
          _cleanup();
          return;
        }

        // Avoid publishing "connected" before service discovery/characteristic setup.
        if (state == BluetoothConnectionState.connected && !_isReady) {
          log("BleManager: Connected event received before ready; waiting for discovery.");
          return;
        }

        _connectionStateController.add(state);
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
        _notifySubscription =
            _notifyCharacteristic!.lastValueStream.listen((value) {
          final normalized =
              value.map((byte) => byte & 0xFF).toList(growable: false);
          _ingestNotifyBytes(normalized);
        }, onError: (error) {
          log("Notify stream error: $error");
        });
      } else {
        log("No notify characteristic found (writes only).");
      }

      _isReady = true;
      // Publish connected only after service discovery/characteristic selection.
      _connectionStateController.add(BluetoothConnectionState.connected);

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

  bool _looksLikeVendorBleUuid(String uuid) {
    final normalized = uuid.toLowerCase();
    return normalized.contains("fff") ||
        normalized.contains("ffe") ||
        normalized.contains("ff0");
  }

  int _scoreCharacteristicPair({
    required String serviceUuid,
    required String writeUuid,
    required String notifyUuid,
  }) {
    var score = 0;
    if (_looksLikeVendorBleUuid(serviceUuid)) score += 120;
    if (_looksLikeVendorBleUuid(writeUuid)) score += 70;
    if (_looksLikeVendorBleUuid(notifyUuid)) score += 70;
    if (writeUuid == notifyUuid) score += 20;
    return score;
  }

  int _scoreSingleCharacteristic({
    required String serviceUuid,
    required String characteristicUuid,
  }) {
    var score = 0;
    if (_looksLikeVendorBleUuid(serviceUuid)) score += 100;
    if (_looksLikeVendorBleUuid(characteristicUuid)) score += 60;
    return score;
  }

  void _selectCharacteristics(List<BluetoothService> services) {
    BluetoothCharacteristic? pairedWrite;
    BluetoothCharacteristic? pairedNotify;
    int pairedScore = -1;
    BluetoothCharacteristic? fallbackWrite;
    BluetoothCharacteristic? fallbackNotify;
    int fallbackWriteScore = -1;
    int fallbackNotifyScore = -1;

    _writeCharacteristic = null;
    _notifyCharacteristic = null;

    for (final service in services) {
      final serviceUuid = service.uuid.str;
      final serviceUuidNorm = serviceUuid.toLowerCase();
      log("BleManager: Service $serviceUuid");
      BluetoothCharacteristic? serviceWrite;
      BluetoothCharacteristic? serviceNotify;
      int serviceWriteScore = -1;
      int serviceNotifyScore = -1;
      for (final characteristic in service.characteristics) {
        final charUuid = characteristic.uuid.str;
        final charUuidNorm = charUuid.toLowerCase();
        final canWrite = characteristic.properties.write ||
            characteristic.properties.writeWithoutResponse;
        final canNotify = characteristic.properties.notify ||
            characteristic.properties.indicate;
        final props = characteristic.properties;
        log(
          "  Char $charUuid "
          "[write=${props.write}, wnr=${props.writeWithoutResponse}, "
          "notify=${props.notify}, indicate=${props.indicate}]",
        );

        if (canWrite) {
          final score = _scoreSingleCharacteristic(
            serviceUuid: serviceUuidNorm,
            characteristicUuid: charUuidNorm,
          );
          if (serviceWrite == null || score >= serviceWriteScore) {
            serviceWrite = characteristic;
            serviceWriteScore = score;
          }
          if (fallbackWrite == null || score >= fallbackWriteScore) {
            fallbackWrite = characteristic;
            fallbackWriteScore = score;
          }
        }
        if (canNotify) {
          final score = _scoreSingleCharacteristic(
            serviceUuid: serviceUuidNorm,
            characteristicUuid: charUuidNorm,
          );
          if (serviceNotify == null || score >= serviceNotifyScore) {
            serviceNotify = characteristic;
            serviceNotifyScore = score;
          }
          if (fallbackNotify == null || score >= fallbackNotifyScore) {
            fallbackNotify = characteristic;
            fallbackNotifyScore = score;
          }
        }
      }

      // Prefer the strongest vendor-looking write+notify pair.
      if (serviceWrite != null && serviceNotify != null) {
        final candidateScore = _scoreCharacteristicPair(
          serviceUuid: serviceUuidNorm,
          writeUuid: serviceWrite.uuid.str.toLowerCase(),
          notifyUuid: serviceNotify.uuid.str.toLowerCase(),
        );
        if (pairedWrite == null || candidateScore >= pairedScore) {
          pairedWrite = serviceWrite;
          pairedNotify = serviceNotify;
          pairedScore = candidateScore;
        }
      }
    }

    _writeCharacteristic = pairedWrite ?? fallbackWrite;
    _notifyCharacteristic = pairedNotify ?? fallbackNotify;
    log(
      "BleManager: Characteristic selection "
      "write=${_writeCharacteristic?.uuid.str ?? 'none'} "
      "notify=${_notifyCharacteristic?.uuid.str ?? 'none'} "
      "(pairScore=$pairedScore, fallbackWriteScore=$fallbackWriteScore, "
      "fallbackNotifyScore=$fallbackNotifyScore)",
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
    _lastRxAt = null;
    _hadProtocolRxSinceConnect = false;
    _rxBuffer.clear();
    _pendingWrite = Future.value();
    _writeSession++;
    _isReady = false;
    _preferWriteWithoutResponse = false;
    _suspendReadCommands = false;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> write(List<int> data) async {
    if (_writeCharacteristic == null) {
      log("Not connected or no write characteristic");
      return;
    }

    final normalized = data.map((byte) => byte & 0xFF).toList(growable: false);
    final command = _extractProtocolCommand(normalized);
    if (_suspendReadCommands && command != null && _isReadCommand(command)) {
      final cmdHex = command.toRadixString(16).padLeft(2, '0');
      log("BLE WRITE skipped by read-gate: cmd=0x$cmdHex");
      return;
    }
    final sessionAtEnqueue = _writeSession;
    _pendingWrite = _pendingWrite
        .then((_) => _writeInternal(normalized, sessionAtEnqueue))
        .catchError((error) {
      log("Write queue error: $error");
    });
    return _pendingWrite;
  }

  Future<void> _writeInternal(List<int> data, int sessionId) async {
    if (data.isEmpty) return;
    if (sessionId != _writeSession) return;
    final totalChunks = (data.length / _maxChunkSize).ceil();

    for (int i = 0; i < totalChunks; i++) {
      if (sessionId != _writeSession) return;
      final start = i * _maxChunkSize;
      final end = math.min(start + _maxChunkSize, data.length);
      final chunk = data.sublist(start, end);
      await _writeChunkWithRetry(
        chunk,
        index: i + 1,
        total: totalChunks,
        sessionId: sessionId,
      );
      if (i < totalChunks - 1) {
        await Future.delayed(_chunkGap);
      }
    }
  }

  Future<void> _writeChunkWithRetry(
    List<int> chunk, {
    required int index,
    required int total,
    required int sessionId,
  }) async {
    for (int attempt = 1; attempt <= _maxWriteAttempts; attempt++) {
      if (sessionId != _writeSession) return;
      final characteristic = _writeCharacteristic;
      if (characteristic == null) {
        throw StateError("Write characteristic is no longer available");
      }

      try {
        final withoutResponse = _shouldUseWithoutResponse(characteristic);
        log(
          "BLE WRITE [$index/$total] try $attempt "
          "(wnr=${withoutResponse ? '1' : '0'}): ${_hex(chunk)}",
        );
        await characteristic.write(chunk, withoutResponse: withoutResponse);
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
    if (characteristic.properties.writeWithoutResponse &&
        (!characteristic.properties.write || _preferWriteWithoutResponse)) {
      return true;
    }
    // Default path: write with response when available.
    if (characteristic.properties.write) return false;
    return characteristic.properties.writeWithoutResponse;
  }

  String _hex(List<int> data) =>
      data.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join(' ');
}

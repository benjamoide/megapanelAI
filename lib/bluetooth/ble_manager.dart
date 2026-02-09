
import 'dart:async';
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
      
      await device.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = device;
      
      // Update local stream
      _connectionStateController.add(BluetoothConnectionState.connected);

      // Listen to connection state
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
      List<BluetoothService> services = await device.discoverServices();
      
      // Find write characteristic
      _writeCharacteristic = null;
      _notifyCharacteristic = null;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
          if (characteristic.properties.notify) {
            _notifyCharacteristic = characteristic;
             await _notifyCharacteristic?.setNotifyValue(true);
             _notifySubscription = _notifyCharacteristic?.lastValueStream.listen((value) {
               log("Received data: $value");
             });
          }
        }
      }
      
      if (_writeCharacteristic == null) {
        log("No write characteristic found!");
        await disconnect();
        return false;
      }
      
      log("BleManager: Connected and ready.");
      return true;
    } catch (e) {
      log("Connection failed: $e");
      await disconnect();
      return false;
    }
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
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> write(List<int> data) async {
    if (_writeCharacteristic != null) {
      String hexData = data.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ');
      log("BLE WRITE: $hexData");
      try {
        if (_writeCharacteristic!.properties.writeWithoutResponse) {
           await _writeCharacteristic!.write(data, withoutResponse: true);
        } else {
           await _writeCharacteristic!.write(data, withoutResponse: false);
        }
      } catch (e) {
        log("Write Error: $e");
      }
    } else {
      log("Not connected or no write characteristic");
    }
  }
}

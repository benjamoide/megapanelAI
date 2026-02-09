
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

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
        print("Error starting scan: $e");
      }
    } else {
      print("Permissions not granted for scanning");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("Error stopping scan: $e");
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
          _cleanup();
        }
      });
  
      // Discover services
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
               print("Received data: $value");
             });
          }
        }
      }
      
      if (_writeCharacteristic == null) {
        print("No write characteristic found!");
        await disconnect();
        return false;
      }
      
      return true;
    } catch (e) {
      print("Connection failed: $e");
      await disconnect();
      return false;
    }
  }

  Future<void> disconnect() async {
    await _connectedDevice?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    _connectionSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectedDevice = null;
    _writeCharacteristic = null;
    _notifyCharacteristic = null;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  Future<void> write(List<int> data) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(data, withoutResponse: true); // usually BLE devices use writeNoResponse for fast updates
    } else {
      print("Not connected or no write characteristic");
    }
  }
}

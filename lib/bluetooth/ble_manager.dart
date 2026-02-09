
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

  // Expose connection state
  Stream<BluetoothConnectionState> get connectionState => 
      _connectedDevice?.connectionState ?? Stream.value(BluetoothConnectionState.disconnected);
  
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<void> init() async {
    // Check permissions
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      // Permissions granted
    }
  }

  Future<void> startScan() async {
    // Optional: filter by service UUIDs if known
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
    _connectedDevice = device;
    
    // Listen to connection state
    _connectionSubscription = device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        _cleanup();
      }
    });

    // Discover services
    List<BluetoothService> services = await device.discoverServices();
    
    // Find write characteristic
    // Based on analysis, we don't know the exact UUIDs yet.
    // We will look for a characteristic that supports WRITE.
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
  }

  Future<void> write(List<int> data) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(data, withoutResponse: true); // usually BLE devices use writeNoResponse for fast updates
    } else {
      print("Not connected or no write characteristic");
    }
  }
}

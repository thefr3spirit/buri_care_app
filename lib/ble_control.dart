import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleControl {
  // Singleton
  static final BleControl _instance = BleControl._internal();
  factory BleControl() => _instance;
  BleControl._internal();

  final _deviceStreamController = StreamController<List<ScanResult>>.broadcast();
  Stream<List<ScanResult>> get deviceStream => _deviceStreamController.stream;
  List<ScanResult> _scanResults = [];

  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  /// Call once at startup to wire up scan results & scanning flag.
  Future<void> initialize() async {
    // Emit scan results to anyone listening
    FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      _deviceStreamController.add(results);
    }, onError: (e) {
      debugPrint('Error listening to scan results: $e');
    });

    // Keep _isScanning in sync
    FlutterBluePlus.isScanning.listen((scanning) {
      _isScanning = scanning;
    });
  }

  /// Request necessary BLE & location permissions
  Future<bool> checkAndRequestPermissions() async {
    if (!await Permission.bluetoothScan.request().isGranted) return false;
    if (!await Permission.bluetoothConnect.request().isGranted) return false;
    if (!await Permission.locationWhenInUse.request().isGranted) return false;
    return true;
  }

  /// Check adapter on/off
  Future<bool> isBluetoothAvailable() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  /// Start BLE scan
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_isScanning) return;
    _scanResults = [];
    _deviceStreamController.add(_scanResults);

    if (!await checkAndRequestPermissions()) {
      throw Exception('BLE permissions not granted');
    }
    if (!await isBluetoothAvailable()) {
      throw Exception('Bluetooth is off');
    }

    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// Stop BLE scan
  Future<void> stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
    }
  }

  /// Connect to a device and listen to its state stream
  Future<void> connectToDevice(BluetoothDevice device) async {
    // If already managing this device, skip
    if (_connectedDevice?.id == device.id) return;

    // Disconnect any previous
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }

    try {
      await device.connect(autoConnect: false);
      _connectedDevice = device;

      // Subscribe to THIS device's state changes
      device.state.listen((s) {
        if (s == BluetoothDeviceState.disconnected && _connectedDevice?.id == device.id) {
          _connectedDevice = null;
        }
      });
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      rethrow;
    }
  }

  /// Disconnect current device
  Future<void> disconnectDevice() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  /// Find specific service on connected device
  Future<BluetoothService?> findService(Guid serviceUuid) async {
    if (_connectedDevice == null) {
      throw Exception('No device connected');
    }
    final services = await _connectedDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid == serviceUuid) {
        return service;
      }
    }
    return null;
  }

  /// Read from a characteristic
  Future<List<int>> readCharacteristic(BluetoothCharacteristic c) async {
    return await c.read();
  }

  /// Write to a characteristic
  Future<void> writeCharacteristic(
      BluetoothCharacteristic c, List<int> data,
      {bool withResponse = true}) {
    return c.write(
      data,
      withoutResponse: !withResponse,
    );
  }

  /// Enable/disable notifications on a characteristic
  Future<void> setNotification(
    BluetoothCharacteristic c,
    bool enable,
    void Function(List<int>) onDataReceived,
  ) async {
    if (enable) {
      await c.setNotifyValue(true);
      c.onValueReceived.listen(onDataReceived);
    } else {
      await c.setNotifyValue(false);
    }
  }

  void dispose() {
    _deviceStreamController.close();
    if (_connectedDevice != null) {
      _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }
}

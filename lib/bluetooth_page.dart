import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ble_control.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BleControl _bleControl = BleControl();
  StreamSubscription<List<ScanResult>>? _scanSub;

  List<ScanResult> _devices = [];
  bool _isScanning = false;
  String _statusMessage = 'Initializing…';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    try {
      await _bleControl.initialize();

      // Listen to scan results
      _scanSub = _bleControl.deviceStream.listen((devices) {
        if (!mounted) return;
        setState(() {
          _devices = devices;
        });
      });

      // Permissions
      if (!await _bleControl.checkAndRequestPermissions()) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Bluetooth permissions not granted');
        return;
      }

      // Adapter state
      if (!await _bleControl.isBluetoothAvailable()) {
        if (!mounted) return;
        setState(() => _statusMessage = 'Bluetooth is off or unavailable');
        return;
      }

      if (!mounted) return;
      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready to scan';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Init error: $e');
    }
  }

  Future<void> _startScan() async {
    if (_isScanning) return;
    if (!mounted) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning…';
    });

    try {
      await _bleControl.startScan(timeout: const Duration(seconds: 15));
      // Let the listener collect results for 15s
      await Future.delayed(const Duration(seconds: 15));
      await _bleControl.stopScan();
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = _devices.isEmpty
            ? 'No devices found'
            : 'Found ${_devices.length} device(s)';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _statusMessage = 'Scan error: $e';
      });
    }
  }

  Future<void> _stopScan() async {
    if (!_isScanning) return;
    try {
      await _bleControl.stopScan();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _isScanning = false;
      _statusMessage = 'Scan stopped';
    });
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    if (!mounted) return;
    setState(() => _statusMessage = 'Connecting to ${device.name}…');
    try {
      await _bleControl.connectToDevice(device);
      if (!mounted) return;
      setState(() => _statusMessage = 'Connected to ${device.name}');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Connect failed: $e');
    }
  }

  Future<void> _disconnectDevice() async {
    final device = _bleControl.connectedDevice;
    if (device == null) return;
    if (!mounted) return;
    setState(() => _statusMessage = 'Disconnecting…');
    try {
      await _bleControl.disconnectDevice();
      if (!mounted) return;
      setState(() => _statusMessage = 'Disconnected');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = 'Disconnect failed: $e');
    }
  }

  void _showConnectDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Connect to ${device.name}'),
        content: const Text('Do you want to connect?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(onPressed: () => _connectToDevice(device), child: const Text('CONNECT')),
        ],
      ),
    );
  }

  void _showDisconnectDialog(BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Disconnect from ${device.name}'),
        content: const Text('Do you want to disconnect?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(onPressed: _disconnectDevice, child: const Text('DISCONNECT')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = _bleControl.connectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        backgroundColor: const Color(0xFF6D071A),
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (connected != null) ...[
                  const Padding(
                    padding: EdgeInsets.only(left: 16, top: 8),
                    child: Text('Connected Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      leading: const Icon(Icons.bluetooth_connected, color: Color(0xFF6D071A)),
                      title: Text(connected.name.isNotEmpty ? connected.name : 'Unknown'),
                      subtitle: Text(connected.id.id),
                      onTap: () => _showDisconnectDialog(connected),
                    ),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Available Devices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                  child: _devices.isEmpty
                      ? const Center(child: Text('No devices'))
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (ctx, i) {
                            final device = _devices[i].device;
                            if (connected != null && device.id == connected.id) {
                              return const SizedBox.shrink();
                            }
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: const Icon(Icons.bluetooth, color: Color(0xFF6D071A)),
                                title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
                                subtitle: Text(device.id.id),
                                trailing: Text('${_devices[i].rssi} dBm'),
                                onTap: () => _showConnectDialog(device),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: _isScanning ? _stopScan : _startScan,
              backgroundColor: const Color(0xFF6D071A),
              child: Icon(_isScanning ? Icons.stop : Icons.search),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _stopScan();
    super.dispose();
  }
}

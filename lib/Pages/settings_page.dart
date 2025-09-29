//For Bluetooth Connection

import 'package:flutter/material.dart';
import 'package:universal_ble/universal_ble.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'ble_manager.dart';
import 'dart:convert';
import 'dart:async';

class SettingsPage extends StatefulWidget {
  final BLEManager bleManager;
  final Function(BLEManager) onBleManagerUpdated;

  const SettingsPage({required this.bleManager, required this.onBleManagerUpdated, Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BLEManager bleManager = BLEManager();
  List<BleDevice> devices = [];

  bool isConnected = false;
  bool isScanning = false;
  bool isConnecting = false;
  BleDevice? selectedDevice;

  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _requestPermissions();

    // Safely update UI when BLEManager notifies a connection
    widget.bleManager.onConnectionUpdate = (bool connected) {
      if (!mounted) return;
      setState(() {
        isConnected = connected;
        isConnecting = false;
      });
    };
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  void _startScan() {
    setState(() {
      devices.clear();
      isScanning = true;
    });

    UniversalBle.onScanResult = (BleDevice device) {
      if (!devices.any((d) => d.deviceId == device.deviceId)) {
        setState(() {
          devices.add(device);
        });
      }
    };

    UniversalBle.startScan(
      scanFilter: ScanFilter(withServices: ["12345678-1234-5678-1234-56789abcdef0"])
    );

    // Stop scan after 10 seconds
    _scanTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return; // Ensure widget is still alive
      UniversalBle.stopScan();
      setState(() {
        isScanning = false;
      });
    });
  }

  void _connectToDevice(String deviceId) async {
    setState(() {
      isConnecting = true;
    });

    try {
      await bleManager.connectToDevice(deviceId);
      if (!mounted) return;
      setState(() {
        selectedDevice = devices.firstWhere((device) => device.deviceId == deviceId);
        isConnected = true;
      });

      widget.onBleManagerUpdated(bleManager);// Update BLEManager in parent
      bleManager.subscribeToCharacteristics();
    } catch (e) {
      if (!mounted) return;
      print("❌ Connection failed: $e");
      setState(() {
        isConnecting = false;
      });
    }
  }

  /// ✅ Manual Disconnect Function
  void _disconnectDevice() {
    if (isConnected) {
      widget.bleManager.disconnect();
      setState(() {
        isConnected = false;
        selectedDevice = null;
      });
    }
  }

  @override
  void dispose() {
    print("🔴 Disposing SettingsPage...");
    _scanTimer?.cancel();
    UniversalBle.stopScan(); // Stop scanning if still running
    //widget.bleManager.disconnect(); // Ensure disconnection
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("BLE Scanner & Connector")),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isScanning ? null : _startScan,
            child: Text(isScanning ? "Scanning..." : "Scan for Devices"),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                return ListTile(
                  title: Text(device.name ?? "Unknown"),
                  subtitle: Text(device.deviceId),
                  trailing: isConnecting && device.deviceId == selectedDevice?.deviceId
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                    onPressed: (isConnected || isConnecting)
                      ? null
                    : () => _connectToDevice(device.deviceId),
                    child: const Text("Connect"),
                  ),
                );
              },
            ),
          ),
          if (selectedDevice != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(
                    isConnected
                        ? "Connected to ${selectedDevice!.name}"
                        : "Connecting...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 10),

                ],
              ),
            ),
          // ✅ Disconnect button always visible if connected
          ElevatedButton(
            onPressed: isConnected ? _disconnectDevice : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Disconnect"),
          ),
        ],
      ),
    );
  }
}

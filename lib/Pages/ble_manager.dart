import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:universal_ble/universal_ble.dart';

enum DeviceConnectionState {
  connected,
  disconnected,
  connecting,
  unknown,
}

class BLEManager {
  static final BLEManager _instance = BLEManager._internal();
  factory BLEManager() => _instance;
  BLEManager._internal();

  final UniversalBle ble = UniversalBle();
  String? connectedDeviceId;

  final String serviceId = "12345678-1234-5678-1234-56789abcdef0";
  final String charId = "abcdef01-1234-5678-1234-56789abcdef0";

  Function(bool isConnected)? onConnectionUpdate;
  Function(double)? onYDataReceived;

  Timer? _reconnectTimer;

  void initialize() {
    UniversalBle.onConnectionChange = (deviceId, state, error) {
      print("📡 Received connection update: ");
      print("🔌 Device ID: $deviceId");
      print("🔄 State: $state (Type: ${state.runtimeType})");
      print("⚠️ Error: $error (Type: ${error.runtimeType})");

      DeviceConnectionState connectionState = _mapState(state);

      if (connectionState == DeviceConnectionState.disconnected && state == false && error == 'Connection Timeout') {
        connectedDeviceId = deviceId;
        Future.delayed(const Duration(seconds: 2));
        connectToDevice(deviceId);
        _startReconnect();
      }
    };
  }

  DeviceConnectionState _mapState(dynamic state) {
    if (state is bool) {
      return state ? DeviceConnectionState.connected : DeviceConnectionState.disconnected;
    }

    // Optional fallback in case of unexpected types
    return DeviceConnectionState.unknown;
  }


  // ✅ Fixed connectToDevice
  Future<void> connectToDevice(String deviceId) async {
      if (connectedDeviceId != null) {
        await UniversalBle.disconnect(connectedDeviceId!).catchError((_) {});
      }

      print("🔄 Connecting to $deviceId...");
      connectedDeviceId = deviceId;

      await UniversalBle.connect(deviceId);
      print("✅ Connected to $deviceId");

      onConnectionUpdate?.call(true);

      await discoverServices();
  }

  // ✅ Fixed discoverServices
  Future<void> discoverServices() async {
    if (connectedDeviceId == null) return;

    try {
      final services = await UniversalBle.discoverServices(connectedDeviceId!);
      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid == charId) {
            await subscribeToCharacteristics();
            return;
          }
        }
      }
    } catch (e) {
      print("❌ Service discovery failed: $e");
    }
  }

  // ✅ Fixed subscribeToCharacteristics
  Future<void> subscribeToCharacteristics({int retries = 5}) async {
    if (connectedDeviceId == null) return;

    int attempt = 0;
    while (attempt < retries) {
      try {
        await UniversalBle.setNotifiable(
          connectedDeviceId!,
          serviceId,
          charId,
          BleInputProperty.notification,
        );

        UniversalBle.onValueChange = (String deviceId, String charId, Uint8List value) {
          if (connectedDeviceId != null &&
              deviceId == connectedDeviceId &&
              charId == this.charId) {
            _handleYData(value);
          }
        };

        print("✅ Subscribed to characteristics");
        return;
      } catch (e) {
        print("⚠️ Subscription attempt ${attempt + 1} failed: $e");
        await Future.delayed(const Duration(seconds: 2));
      }
      attempt++;
    }

    print("❌ Subscription failed after $attempt attempts");
  }

  // ✅ Handle data from BLE
  void _handleYData(Uint8List data) {
    if (data.length == 4) {
      ByteData byteData = ByteData.sublistView(data);
      double yValue = byteData.getFloat32(0, Endian.little);
      onYDataReceived?.call(yValue);
      print("📡 Received BLE Data: Y = $yValue");
    } else {
      print("Recieved BLE Data: length != 4");
    }
  }

  void _startReconnect() {
    const interval = Duration(seconds: 5);
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer.periodic(interval, (_) async {
      try {
        await UniversalBle.connect(connectedDeviceId!);
        _reconnectTimer?.cancel();
        print('Reconnected');
      } catch (e) {
        print('Failed to Reconnect');
      }
    });
  }

  // ✅ Manual disconnect
  void disconnect() async {
    if (connectedDeviceId != null) {
      try {
        await UniversalBle.disconnect(connectedDeviceId!);
        connectedDeviceId = null;
        _reconnectTimer?.cancel();
        onConnectionUpdate?.call(false);
        print("✅ Manually disconnected");
      } catch (e) {
        print("❌ Error while disconnecting: $e");
      }
    }
  }

  // ✅ Cleanup
  void clearListeners() {
    _reconnectTimer?.cancel();
    onConnectionUpdate = null;
    onYDataReceived = null;
    print("🧹 Cleared BLE listeners");
  }

  void dispose() {
    _reconnectTimer?.cancel();
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Connects to any smartwatch / chest strap that exposes the standard
/// Bluetooth LE Heart Rate service (0x180D) and streams live BPM.
///
/// Works with: Garmin, Polar, Suunto, Amazfit/Zepp, Huawei, Coros and most
/// chest straps. Apple Watch and some Wear OS watches do NOT broadcast HR
/// over BLE by default — see README for companion-app options.
class HeartRateService extends ChangeNotifier {
  static final Guid _hrService = Guid('180D');
  static final Guid _hrMeasurement = Guid('2A37');

  BluetoothDevice? _device;
  StreamSubscription<List<int>>? _hrSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;

  int? bpm;
  bool scanning = false;
  bool get connected => _device != null;
  String get deviceName => _device?.platformName ?? '';

  List<ScanResult> results = [];

  Future<bool> get isSupported => FlutterBluePlus.isSupported;

  Future<void> startScan() async {
    results = [];
    scanning = true;
    notifyListeners();

    final sub = FlutterBluePlus.onScanResults.listen((r) {
      results = r;
      notifyListeners();
    });

    await FlutterBluePlus.startScan(
      withServices: [_hrService],
      timeout: const Duration(seconds: 10),
    );
    await FlutterBluePlus.isScanning.where((s) => s == false).first;
    await sub.cancel();

    scanning = false;
    notifyListeners();
  }

  Future<void> connect(BluetoothDevice device) async {
    await FlutterBluePlus.stopScan();
    await device.connect(timeout: const Duration(seconds: 15));
    _device = device;

    _connSub = device.connectionState.listen((s) {
      if (s == BluetoothConnectionState.disconnected) {
        _cleanup();
      }
    });

    final services = await device.discoverServices();
    for (final s in services) {
      if (s.uuid == _hrService) {
        for (final c in s.characteristics) {
          if (c.uuid == _hrMeasurement) {
            await c.setNotifyValue(true);
            _hrSub = c.onValueReceived.listen(_onHrData);
          }
        }
      }
    }
    notifyListeners();
  }

  /// Parses the standard Heart Rate Measurement characteristic:
  /// byte 0 = flags (bit 0: HR value is uint16), then HR value.
  void _onHrData(List<int> data) {
    if (data.isEmpty) return;
    final is16bit = (data[0] & 0x01) != 0;
    bpm = is16bit && data.length >= 3
        ? data[1] | (data[2] << 8)
        : (data.length >= 2 ? data[1] : null);
    notifyListeners();
  }

  Future<void> disconnect() async {
    await _device?.disconnect();
    _cleanup();
  }

  void _cleanup() {
    _hrSub?.cancel();
    _connSub?.cancel();
    _hrSub = null;
    _connSub = null;
    _device = null;
    bpm = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

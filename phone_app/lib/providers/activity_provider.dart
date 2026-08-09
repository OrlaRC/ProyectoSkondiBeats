import 'dart:async';
import 'package:flutter/foundation.dart';
import '../ble/ble_service.dart';
import '../sensors/sensor_service.dart';

class ActivityProvider extends ChangeNotifier {
  final SensorService _sensors;
  Timer? _notifyTimer;

  ActivityProvider(this._sensors) {
    _sensors.init();
    _sensors.elapsedStream.listen((v) { _elapsed = v; _scheduleNotify(); });
    _sensors.bpmStream.listen((v) { _bpm = v; _scheduleNotify(); });
    _sensors.batteryStream.listen((v) { _battery = v; _scheduleNotify(); });
    _sensors.stateStream.listen((v) { _state = v; notifyListeners(); });
  }

  int _elapsed = 0, _bpm = 0, _battery = 100;
  BleConnectionState _state = BleConnectionState.disconnected;

  int get elapsed => _elapsed;
  int get bpm => _bpm;
  int get battery => _battery;
  BleConnectionState get state => _state;
  String get transport => _sensors.transport;
  bool get isBpmHigh => _bpm > 160;
  bool get isBatteryLow => _battery < 20;

  void _scheduleNotify() {
    _notifyTimer ??= Timer(const Duration(milliseconds: 500), () {
      _notifyTimer = null;
      notifyListeners();
    });
  }

  void startScanning() => _sensors.connect();

  bool get wearSending => _sensors.wearSending;

  void sendBeatToWear({
    required String? name,
    required String genre,
    required int bpm,
    required int posSec,
    required int durSec,
    required bool playing,
  }) => _sensors.sendBeatToWear(
      name: name, genre: genre, bpm: bpm, posSec: posSec, durSec: durSec, playing: playing);

  Future<void> disconnectWear() async => await _sensors.disconnect();

  void stopWearData() => _sensors.stopWearData();

  void resumeWearData() => _sensors.resumeWearData();

  @override
  void dispose() {
    _notifyTimer?.cancel();
    super.dispose();
  }
}

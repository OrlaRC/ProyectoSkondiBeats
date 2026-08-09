import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../ble/ble_service.dart';
import '../classic/classic_service.dart';

/// Orchestrates both transports (BLE for physical devices, Classic SPP for
/// emulators) and exposes a single unified sensor stream for the UI.
class SensorService {
  final BleService _ble = BleService();
  final ClassicService _classic = ClassicService();

  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _elapsedController = StreamController<int>.broadcast();
  final _bpmController = StreamController<int>.broadcast();
  final _batteryController = StreamController<int>.broadcast();

  String _transport = 'ninguno';
  String get transport => _transport;

  Stream<BleConnectionState> get stateStream => _stateController.stream;
  Stream<int> get elapsedStream => _elapsedController.stream;
  Stream<int> get bpmStream => _bpmController.stream;
  Stream<int> get batteryStream => _batteryController.stream;

  void init() {
    _ble.elapsedStream.listen(_elapsedController.add);
    _ble.bpmStream.listen(_bpmController.add);
    _ble.batteryStream.listen(_batteryController.add);
    _classic.elapsedStream.listen(_elapsedController.add);
    _classic.bpmStream.listen(_bpmController.add);
    _classic.batteryStream.listen(_batteryController.add);
  }

  Future<void> connect() async {
    _stateController.add(BleConnectionState.searching);
    _transport = 'ninguno';
    for (var attempt = 0; attempt < 3; attempt++) {
      final classicOk = await _tryClassic();
      if (classicOk) return;
      debugPrint('[sensors] intento SPP ${attempt + 1} fallido');
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    debugPrint('[sensors] SPP no disponible, probando BLE...');
    final bleOk = await _tryBle();
    if (!bleOk) {
      debugPrint('[sensors] ambos transportes fallaron');
      _stateController.add(BleConnectionState.error);
    }
  }

  Future<bool> _tryClassic() async {
    try {
      final ok = await _classic.connect().timeout(const Duration(seconds: 12));
      if (_classic.isConnected) {
        _transport = 'SPP';
        debugPrint('[sensors] conectado via SPP');
        _stateController.add(BleConnectionState.connected);
        return true;
      }
      if (ok) return true;
    } catch (e) {
      debugPrint('[sensors] timeout SPP: $e');
    }
    return false;
  }

  Future<bool> _tryBle() async {
    try {
      await _ble.scanAndConnect().timeout(const Duration(seconds: 20));
      if (_ble.isConnected) {
        _transport = 'BLE';
        debugPrint('[sensors] conectado via BLE');
        _stateController.add(BleConnectionState.connected);
        return true;
      }
    } catch (e) {
      debugPrint('[sensors] timeout BLE: $e');
    }
    return false;
  }

  Future<void> disconnect() async {
    await _ble.disconnect();
    await _classic.disconnect();
    _transport = 'ninguno';
    _stateController.add(BleConnectionState.disconnected);
  }

  /// Envía el beat + progreso al wearable por SPP (si está conectado y habilitado).
  void sendBeatToWear({
    required String? name,
    required String genre,
    required int bpm,
    required int posSec,
    required int durSec,
    required bool playing,
  }) {
    if (!_classic.dataSending || !_classic.isConnected) return;
    _classic.send(jsonEncode({
      'beat': name,
      'genre': genre,
      'bpm': bpm,
      'pos': posSec,
      'dur': durSec,
      'playing': playing,
    }));
  }

  bool get wearSending => _classic.dataSending;

  /// Detiene el envío de datos del celular al wearable (notifica al reloj).
  void stopWearData() => _classic.stopSending();

  /// Reanuda el envío de datos hacia el wearable.
  void resumeWearData() {
    _classic.dataSending = true;
    _classic.send(jsonEncode({'cmd': 'RESUME_DATA'}));
  }
}

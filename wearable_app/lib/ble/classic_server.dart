import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

/// RFCOMM/SPP server that streams sensor data to the phone.
/// Used as an emulator-compatible transport (the virtual radio of the
/// Android Emulator does not transmit BLE advertising, but Classic BT
/// between two AVDs is bridged by netsimd).
class ClassicServer {
  static const MethodChannel _channel = MethodChannel('skondit/classic');
  static const EventChannel _events = EventChannel('skondit/classic_events');

  bool _running = false;
  bool get isRunning => _running;

  final _raw = _events.receiveBroadcastStream().cast<String>();

  /// Líneas JSON que el teléfono envía por el socket SPP (datos de beat,
  /// STOP_DATA/RESUME_DATA), sin los eventos de estado de conexión.
  Stream<String> get incoming => _raw.where((line) {
        try {
          final m = jsonDecode(line);
          if (m is Map && m['type'] == 'conn') return false;
        } catch (_) {}
        return true;
      });

  /// Emite true cuando un teléfono se conecta al socket SPP y false al
  /// desconectarse.
  Stream<bool> get connected => _raw
      .map((line) {
        try {
          final m = jsonDecode(line);
          if (m is Map && m['type'] == 'conn') return m['connected'] == true;
        } catch (_) {}
        return null;
      })
      .where((v) => v != null)
      .cast<bool>();

  Future<void> start() async {
    await _channel.invokeMethod('start');
    _running = true;
    try {
      await _channel.invokeMethod('makeDiscoverable');
    } catch (_) {
      // Discoverability dialog dismissed is not fatal for already-bonded
      // devices; the server socket keeps accepting connections.
    }
  }

  Future<void> sendData(int elapsed, int bpm, int battery) async {
    if (!_running) return;
    final line = jsonEncode({'e': elapsed, 'b': bpm, 't': battery});
    try {
      await _channel.invokeMethod('send', {'json': line});
    } catch (_) {
      // No client connected yet; ignore.
    }
  }

  Future<void> stop() async {
    _running = false;
    try {
      await _channel.invokeMethod('stop');
    } catch (_) {}
  }
}

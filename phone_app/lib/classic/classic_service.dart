import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

enum ClassicConnectionState { searching, connected, error, disconnected }

/// Bluetooth Classic (SPP/RFCOMM) client that receives the wearable's
/// sensor stream. It is the emulator-compatible transport: the Android
/// Emulator virtual radio does not transmit BLE advertising between two
/// AVDs, but Classic BT is bridged by netsimd.
class ClassicService {
  final _stateController = StreamController<ClassicConnectionState>.broadcast();
  final _elapsedController = StreamController<int>.broadcast();
  final _bpmController = StreamController<int>.broadcast();
  final _batteryController = StreamController<int>.broadcast();

  Stream<ClassicConnectionState> get stateStream => _stateController.stream;
  Stream<int> get elapsedStream => _elapsedController.stream;
  Stream<int> get bpmStream => _bpmController.stream;
  Stream<int> get batteryStream => _batteryController.stream;

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSub;
  String _buffer = '';
  String? _deviceName;
  String? _deviceMac;

  /// Controla si el teléfono sigue mandando datos (beat/progreso) al wearable.
  bool dataSending = true;

  String? get deviceName => _deviceName;
  String? get deviceMac => _deviceMac;

  bool get isConnected => _connection != null;

  Future<bool> connect() async {
    _stateController.add(ClassicConnectionState.searching);
    try {
      if (await Permission.bluetoothConnect.request().isDenied ||
          await Permission.bluetoothScan.request().isDenied) {
        _stateController.add(ClassicConnectionState.error);
        return false;
      }
      await FlutterBluetoothSerial.instance.requestEnable();
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      final target = _findDevice(devices);
      if (target == null) {
        debugPrint('[classic] no se encontro dispositivo SkonditBeats emparejado (${devices.length} emparejados)');
        _stateController.add(ClassicConnectionState.error);
        return false;
      }
      _deviceName = target.name;
      _deviceMac = target.address;
      debugPrint('[classic] conectando a ${target.name} (${target.address})');
      final connection = await BluetoothConnection.toAddress(target.address);
      _connection = connection;
      _inputSub = connection.input!.listen(
        _onData,
        onDone: () => _stateController.add(ClassicConnectionState.disconnected),
        onError: (_) => _stateController.add(ClassicConnectionState.error),
      );
      debugPrint('[classic] conectado OK');
      _stateController.add(ClassicConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('[classic] error: $e');
      _stateController.add(ClassicConnectionState.error);
      return false;
    }
  }

  BluetoothDevice? _findDevice(List<BluetoothDevice> devices) {
    for (final d in devices) {
      if (d.name != null && d.name!.contains('SkonditBeats')) return d;
    }
    for (final d in devices) {
      if (d.address.startsWith('BB:BB:BB')) return d;
    }
    return null;
  }

  void _onData(Uint8List data) {
    _buffer += utf8.decode(data, allowMalformed: true);
    var idx = _buffer.indexOf('\n');
    while (idx >= 0) {
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);
      _parseLine(line);
      idx = _buffer.indexOf('\n');
    }
  }

  void stopSending() {
    dataSending = false;
    send(jsonEncode({'cmd': 'STOP_DATA'}));
  }

  void resumeSending() => dataSending = true;

  /// Envía una línea JSON al wearable por el socket SPP.
  Future<void> send(String json) async {
    final c = _connection;
    if (c == null) return;
    try {
      c.output.add(utf8.encode('$json\n'));
    } catch (_) {}
  }

  void _parseLine(String line) {
    if (line.isEmpty) return;
    try {
      final map = jsonDecode(line) as Map<String, dynamic>;
      final e = map['e'];
      final b = map['b'];
      final t = map['t'];
      if (e != null) _elapsedController.add((e as num).toInt());
      if (b != null) _bpmController.add((b as num).toInt());
      if (t != null) _batteryController.add((t as num).toInt());
    } catch (_) {}
  }

  Future<void> disconnect() async {
    await _inputSub?.cancel();
    _inputSub = null;
    _buffer = '';
    await _connection?.close();
    _connection = null;
    _stateController.add(ClassicConnectionState.disconnected);
  }

  void dispose() {
    _stateController.close();
    _elapsedController.close();
    _bpmController.close();
    _batteryController.close();
  }
}

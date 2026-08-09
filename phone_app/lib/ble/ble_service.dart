import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_constants.dart';

enum BleConnectionState { searching, connected, error, disconnected }

class BleService {
  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _elapsedController = StreamController<int>.broadcast();
  final _bpmController = StreamController<int>.broadcast();
  final _batteryController = StreamController<int>.broadcast();

  Stream<BleConnectionState> get stateStream => _stateController.stream;
  Stream<int> get elapsedStream => _elapsedController.stream;
  Stream<int> get bpmStream => _bpmController.stream;
  Stream<int> get batteryStream => _batteryController.stream;

  BluetoothDevice? _device;
  final List<StreamSubscription> _subs = [];

  bool get isConnected => _device != null && _device!.isConnected;

  Future<void> scanAndConnect() async {
    _stateController.add(BleConnectionState.searching);
    try {
      if (await Permission.bluetoothScan.request().isDenied ||
          await Permission.bluetoothConnect.request().isDenied) {
        _stateController.add(BleConnectionState.error);
        return;
      }
      await FlutterBluePlus.turnOn();
      await FlutterBluePlus.startScan(
        withServices: [Guid(SkonditBleConstants.serviceUuid)],
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: true,
      );
      final results = await FlutterBluePlus.onScanResults
          .firstWhere((list) => list.isNotEmpty)
          .timeout(const Duration(seconds: 15));
      _device = results.first.device;
      await _device!.connect();
      await _device!.discoverServices();
      final service = _device!.servicesList.firstWhere(
        (s) => s.serviceUuid.toString().toUpperCase() ==
            SkonditBleConstants.serviceUuid.toUpperCase(),
      );
      for (final char in service.characteristics) {
        if (char.properties.notify) {
          await char.setNotifyValue(true);
          final uuid = char.characteristicUuid.toString().toUpperCase();
          _subs.add(char.onValueReceived.listen((data) => _parseData(uuid, data)));
        }
      }
      _stateController.add(BleConnectionState.connected);
    } catch (e) {
      debugPrint('[ble] error: $e');
      _stateController.add(BleConnectionState.error);
    }
  }

  void _parseData(String uuid, List<int> data) {
    final bytes = Uint8List.fromList(data);
    final prefix = uuid.split('-').first;
    if (prefix == SkonditBleConstants.elapsedTimeCharUuid.split('-').first) {
      _elapsedController.add(ByteData.view(bytes.buffer).getUint16(0, Endian.little));
    } else if (prefix == SkonditBleConstants.bpmCharUuid.split('-').first) {
      _bpmController.add(ByteData.view(bytes.buffer).getUint16(0, Endian.little));
    } else if (prefix == SkonditBleConstants.batteryCharUuid.split('-').first) {
      _batteryController.add(bytes.isNotEmpty ? bytes[0] : 0);
    }
  }

  Future<void> disconnect() async {
    for (final sub in _subs) { await sub.cancel(); }
    _subs.clear();
    await _device?.disconnect();
    _stateController.add(BleConnectionState.disconnected);
  }

  void dispose() {
    _stateController.close();
    _elapsedController.close();
    _bpmController.close();
    _batteryController.close();
  }
}

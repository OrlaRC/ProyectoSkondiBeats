import 'dart:async';
import 'dart:typed_data';
import 'package:ble_peripheral/ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_constants.dart';
import '../sensors/playback_simulator.dart';

class GattServer {
  final PlaybackSimulator _simulator;
  GattServer(this._simulator);

  bool _running = false;
  bool get isRunning => _running;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuses.values.every((s) => s.isGranted);
  }

  Future<void> start() async {
    try {
      await BlePeripheral.initialize();
      await BlePeripheral.clearServices();

      await BlePeripheral.addService(BleService(
        uuid: SkonditBleConstants.serviceUuid,
        primary: true,
        characteristics: [
          _char(SkonditBleConstants.elapsedTimeCharUuid, Uint8List(2)),
          _char(SkonditBleConstants.bpmCharUuid, Uint8List(2)),
          _char(SkonditBleConstants.batteryCharUuid, Uint8List.fromList([100])),
        ],
      ));

      await BlePeripheral.startAdvertising(
        services: [SkonditBleConstants.serviceUuid],
        localName: 'SkonditBeats',
      );
      _running = true;

      _simulator.elapsedTimeStream.listen((v) {
        final bytes = Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);
        _tryNotify(SkonditBleConstants.elapsedTimeCharUuid, bytes);
      });
      _simulator.bpmStream.listen((v) {
        final bytes = Uint8List(2)..buffer.asByteData().setUint16(0, v, Endian.little);
        _tryNotify(SkonditBleConstants.bpmCharUuid, bytes);
      });
      _simulator.batteryStream.listen((v) {
        _tryNotify(SkonditBleConstants.batteryCharUuid, Uint8List.fromList([v]));
      });
    } catch (e) {
      _running = false;
      rethrow;
    }
  }

  void _tryNotify(String uuid, Uint8List value) {
    BlePeripheral.updateCharacteristic(characteristicId: uuid, value: value)
        .catchError((_) {});
  }

  BleCharacteristic _char(String uuid, Uint8List value) => BleCharacteristic(
        uuid: uuid,
        properties: [
          CharacteristicProperties.read.index,
          CharacteristicProperties.notify.index,
        ],
        permissions: [AttributePermissions.readable.index],
        value: value,
      );

  Future<void> stop() async {
    await BlePeripheral.stopAdvertising();
    _running = false;
  }
}

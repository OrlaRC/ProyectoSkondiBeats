import 'dart:convert';
import 'package:flutter/material.dart';
import '../sensors/playback_simulator.dart';
import '../ble/gatt_server.dart';
import '../ble/classic_server.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({super.key});
  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  final _simulator = PlaybackSimulator();
  late final GattServer _gatt;
  late final ClassicServer _classic;
  int _elapsed = 0, _bpm = 0, _battery = 100;
  bool _running = false;
  String _status = 'Listo';

  String? _beatName;
  int _beatBpm = 0;
  int _beatPos = 0;
  int _beatDur = 0;
  bool _streamStopped = false;
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _gatt = GattServer(_simulator);
    _classic = ClassicServer();
    _simulator.elapsedTimeStream.listen((v) => setState(() => _elapsed = v));
    _simulator.bpmStream.listen((v) => setState(() => _bpm = v));
    _simulator.batteryStream.listen((v) => setState(() => _battery = v));
    _simulator.bpmStream.listen((_) => _classic.sendData(_elapsed, _bpm, _battery));
    _classic.incoming.listen(_onIncoming, onError: (_) {});
    _classic.connected.listen((c) => setState(() => _connected = c));
    _startTransports();
  }

  void _onIncoming(String line) {
    String? name, cmd;
    int? pos, dur, bpm;
    try {
      final m = jsonDecode(line);
      if (m is Map) {
        cmd = m['cmd'] as String?;
        name = m['beat'] as String?;
        bpm = m['bpm'] as int?;
        pos = m['pos'] as int?;
        dur = m['dur'] as int?;
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    setState(() {
      if (cmd == 'STOP_DATA') {
        _streamStopped = true;
        return;
      }
      if (cmd == 'RESUME_DATA') {
        _streamStopped = false;
        return;
      }
      if (name != null) {
        _beatName = name;
        _beatBpm = bpm ?? _beatBpm;
        _beatPos = pos ?? _beatPos;
        _beatDur = dur ?? _beatDur;
        _streamStopped = false;
      }
    });
  }

  Future<void> _startTransports() async {
    try {
      final granted = await _gatt.requestPermissions();
      if (!granted) {
        setState(() => _status = 'Permisos BLE denegados');
        return;
      }
      _simulator.start();
      var gattOk = false;
      try {
        await _gatt.start();
        gattOk = true;
      } catch (e) {
        print('[gatt] no disponible: $e');
      }
      var classicOk = false;
      try {
        await _classic.start();
        classicOk = true;
      } catch (e) {
        print('[classic] no disponible: $e');
      }
      setState(() {
        _running = true;
        _status = classicOk
            ? (gattOk ? 'Transmitiendo BLE + SPP' : 'Transmitiendo SPP')
            : (gattOk ? 'Transmitiendo BLE' : 'Error: sin transporte');
      });
    } catch (e) {
      print('[auto] error: $e');
    }
  }

  void _toggle() async {
    try {
      if (_running) {
        _simulator.stop();
        await _classic.stop();
        await _gatt.stop();
        setState(() { _running = false; _status = 'Detenido'; _connected = false; });
        return;
      }
      await _startTransports();
    } catch (e) {
      _simulator.stop();
      setState(() { _running = false; _status = 'Error: $e'; });
    }
  }

  void _disconnect() async {
    _simulator.stop();
    try { await _classic.stop(); } catch (_) {}
    try { await _gatt.stop(); } catch (_) {}
    setState(() { _running = false; _status = 'Desconectado'; _connected = false; });
  }

  @override
  void dispose() { _simulator.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _connected ? _buildMain() : _buildWaiting(),
      ),
    );
  }

  Widget _buildWaiting() {
    return Column(
      children: [
        const Text('SkonditBeats', style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          height: 60, width: 60,
          decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
          child: Image.asset('assets/images/bs1.png', width: 52, height: 52, fit: BoxFit.contain),
        ),
        const Spacer(),
        Text(_status, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFACC15),
              foregroundColor: Colors.black,
              disabledBackgroundColor: const Color(0xFF3F3F46),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: null,
            child: const Text('Esperando conexión', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildMain() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const Text('SkonditBeats', style: TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Container(
            height: 60, width: 60,
            decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(8)),
            child: Image.asset('assets/images/bs1.png', width: 52, height: 52, fit: BoxFit.contain),
          ),
          const SizedBox(height: 6),
          Text(_status, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          if (_streamStopped) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF6B6B)),
              ),
              child: const Text(
                'Se detuvo el proceso de datos',
                style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 6),
          ],
          if (_beatName != null) ...[
            Text(
              _beatName!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '${_fmt(_beatPos)} / ${_fmt(_beatDur)}',
              style: const TextStyle(color: Color(0xFF2AC227), fontSize: 11),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _beatDur > 0 ? (_beatPos / _beatDur).clamp(0.0, 1.0) : 0,
                minHeight: 4,
                backgroundColor: const Color(0xFF1E1E1E),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF2AC227)),
              ),
            ),
          ] else
            Text('Beat #$_elapsed', style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _metric('BPM', _beatBpm > 0 ? '$_beatBpm' : '$_bpm'),
            _metric('BAT', '$_battery%'),
          ]),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              width: 56, height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: const CircleBorder(), backgroundColor: const Color(0xFFFACC15), padding: EdgeInsets.zero),
                onPressed: _toggle,
                child: Icon(_running ? Icons.stop : Icons.play_arrow, size: 30, color: Colors.black),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 56, height: 56,
              child: IconButton(
                tooltip: 'Desconectar',
                onPressed: _running ? _disconnect : null,
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF1E1E1E), disabledBackgroundColor: const Color(0xFF141414)),
                icon: const Icon(Icons.link_off, size: 26, color: Color(0xFFFF6B6B)),
              ),
            ),
          ]),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Column(children: [
        Text(label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 10)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ]);

  String _fmt(int s) {
    final m = s ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }
}

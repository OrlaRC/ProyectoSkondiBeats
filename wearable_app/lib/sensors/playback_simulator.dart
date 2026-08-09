import 'dart:async';
import 'dart:math';

class PlaybackSimulator {
  final _elapsedTime = StreamController<int>.broadcast();
  final _bpm = StreamController<int>.broadcast();
  final _battery = StreamController<int>.broadcast();
  Stream<int> get elapsedTimeStream => _elapsedTime.stream;
  Stream<int> get bpmStream => _bpm.stream;
  Stream<int> get batteryStream => _battery.stream;
  Timer? _timer;
  int _seconds = 0;
  int _currentBpm = 78;
  int _targetBpm = 78;
  int _batteryLevel = 100;
  bool _running = false;
  bool get isRunning => _running;

  static const List<int> _warmupTargets = [95, 100, 105, 110];
  static const List<int> _workoutTargets = [130, 135, 140, 145, 150, 155, 160];

  void start() {
    if (_running) return;
    _running = true;
    _seconds = 0;
    _currentBpm = 78;
    _targetBpm = 78;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void _tick() {
    _seconds++;
    // La batería se agota a razón de 1% cada 3 minutos (~300 min de uso continuo).
    if (_seconds % 180 == 0 && _batteryLevel > 0) {
      _batteryLevel = (_batteryLevel - 1).clamp(0, 100);
    }
    // El objetivo de BPM cambia cada 20s: calentamiento (60s) y luego trabajo.
    if (_seconds == 1 || _seconds % 20 == 0) {
      _targetBpm = _seconds < 60
          ? _warmupTargets[Random().nextInt(_warmupTargets.length)]
          : _workoutTargets[Random().nextInt(_workoutTargets.length)];
    }
    // Transición suave hacia el objetivo: ±1-4 BPM por segundo.
    final step = 1 + Random().nextInt(4);
    if (_currentBpm < _targetBpm) {
      _currentBpm = min(_targetBpm, _currentBpm + step);
    } else if (_currentBpm > _targetBpm) {
      _currentBpm = max(_targetBpm, _currentBpm - step);
    }
    _elapsedTime.add(_seconds);
    _bpm.add(_currentBpm);
    _battery.add(_batteryLevel);
  }

  void dispose() {
    stop();
    _elapsedTime.close();
    _bpm.close();
    _battery.close();
  }
}

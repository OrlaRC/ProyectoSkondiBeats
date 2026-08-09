import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/beat.dart';
import '../services/now_playing_sync.dart';

/// Envía la información del beat actual al wearable (vía ActivityProvider).
typedef WearSendFn = void Function({
  required String? name,
  required String genre,
  required int bpm,
  required int posSec,
  required int durSec,
  required bool playing,
});

/// Motor de reproducción compartido: vive por encima de la navegación, así que
/// el audio sigue sonando al cambiar de vista y al regresar al reproductor.
class MusicPlayer extends ChangeNotifier {
  List<Beat> _beats = localBeats;
  int _index = 0;

  /// 'app' = reproduce en el teléfono; 'tv' = reproduce la Smart TV / PWA.
  String _target = 'app';

  late final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _totalPlayedSec = 0;

  Timer? _syncTimer;
  Timer? _settleTimer;
  Timer? _wearTimer;
  WearSendFn? _wearSink;

  static const _tvNominalDuration = Duration(seconds: 180);

  MusicPlayer() {
    _player.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _player.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
    _player.onPlayerStateChanged.listen((s) {
      _playing = s == PlayerState.playing;
      notifyListeners();
    });
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_playing) publishNow();
    });
    _wearTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_playing) _totalPlayedSec++;
      if (_target == 'tv' && _playing) {
        _position += const Duration(seconds: 1);
        notifyListeners();
      }
      _sendWear();
    });
  }

  void attachWear(WearSendFn fn) => _wearSink = fn;

  List<Beat> get beats => _beats;
  int get index => _index;
  String get target => _target;
  bool get playing => _playing;
  Duration get position => _position;
  Duration get duration => _duration;

  /// Tiempo acumulado de reproducción (segundos reales escuchados).
  int get totalPlayedSec => _totalPlayedSec;

  Beat? get current => _beats.isEmpty ? null : _beats[_index % _beats.length];

  void setTarget(String t) {
    _target = t;
    notifyListeners();
  }

  Future<void> load() async {
    final fetched = await CatalogService.fetchBeats();
    if (fetched.isNotEmpty) {
      _beats = fetched;
      if (_index >= _beats.length) _index = 0;
      notifyListeners();
    }
  }

  void select(int i) {
    if (i >= 0 && i < _beats.length) {
      _index = i;
      notifyListeners();
    }
  }

  Future<void> playIndex(int i) async {
    if (_beats.isEmpty) return;
    final idx = i.clamp(0, _beats.length - 1);
    _index = idx;
    _position = Duration.zero;
    if (_target == 'tv') {
      await _player.stop();
      _duration = _tvNominalDuration;
      _playing = true;
    } else {
      final b = _beats[idx];
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(b.isStream ? UrlSource(b.audio) : AssetSource(b.audio));
    }
    notifyListeners();
    publishNow();
    _sendWear();
  }

  Future<void> toggle() async {
    if (_playing) {
      _playing = false;
      notifyListeners();
      if (_target != 'tv') await _player.pause();
    } else {
      if (_target == 'tv') {
        if (_position >= _duration) _position = Duration.zero;
        _playing = true;
        notifyListeners();
      } else if (_player.state == PlayerState.stopped ||
          _player.state == PlayerState.completed) {
        await playIndex(_index);
        return;
      } else {
        _playing = true;
        notifyListeners();
        await _player.resume();
      }
    }
    publishNow();
    _scheduleSettle();
    _sendWear();
  }

  Future<void> next() async {
    if (_beats.isEmpty) return;
    await playIndex((_index + 1) % _beats.length);
  }

  Future<void> prev() async {
    if (_beats.isEmpty) return;
    await playIndex((_index - 1 + _beats.length) % _beats.length);
  }

  /// Re-publica ~700 ms después del toggle: si el primer POST llevaba estado
  /// obsoleto (callback de audio aún no disparado) o falló, el segundo con el
  /// estado definitivo llega a la TV.
  void _scheduleSettle() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 700), publishNow);
  }

  Future<void> publishNow() async {
    final b = current;
    if (b == null) return;
    await NowPlayingSync.publish(
      beat: b,
      positionSec: _position.inSeconds,
      durationSec: _duration.inSeconds,
      playing: _playing,
      target: _target,
    );
  }

  void _sendWear() {
    _wearSink?.call(
      name: current?.name,
      genre: current?.genre ?? '',
      bpm: current?.bpm ?? 0,
      posSec: _position.inSeconds,
      durSec: _duration.inSeconds,
      playing: _playing,
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _settleTimer?.cancel();
    _wearTimer?.cancel();
    NowPlayingSync.publish(
      beat: null,
      positionSec: 0,
      durationSec: 0,
      playing: false,
      target: _target,
    );
    _player.dispose();
    super.dispose();
  }
}
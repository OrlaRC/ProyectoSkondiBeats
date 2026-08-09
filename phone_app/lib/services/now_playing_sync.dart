import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';
import '../models/beat.dart';

/// Publica el beat actual del teléfono en la tabla `now_playing` de Supabase
/// para que la Smart TV lo refleje (P3.3). Un solo renglón (id = 1).
class NowPlayingSync {
  static Future<void> publish({
    required Beat? beat,
    required int positionSec,
    required int durationSec,
    required bool playing,
    String target = 'app',
  }) async {
    if (!Env.configured) return;
    try {
      final body = jsonEncode({
        'id': 1,
        'beat_id': beat?.id,
        'beat_name': beat?.name,
        'genre': beat?.genre,
        'bpm': beat?.bpm,
        'position_sec': positionSec,
        'duration_sec': durationSec,
        'playing': playing,
        'target': target,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      await http.post(
        Uri.parse('${Env.supabaseUrl}/rest/v1/now_playing'),
        headers: {
          'apikey': Env.supabaseKey,
          'Authorization': 'Bearer ${Env.supabaseKey}',
          'Content-Type': 'application/json',
          'Prefer': 'resolution=merge-duplicates',
        },
        body: body,
      ).timeout(const Duration(seconds: 4));
    } catch (_) {}
  }
}

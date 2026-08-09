import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';

class Beat {
  final String id;
  final String name;
  final String genre;
  final int bpm;
  final double price;
  final String? coverUrl;
  final String audio;

  const Beat({
    required this.id,
    required this.name,
    required this.genre,
    required this.bpm,
    required this.price,
    this.coverUrl,
    required this.audio,
  });

  bool get isStream => audio.startsWith('http');

  factory Beat.fromRemote(Map<String, dynamic> j) => Beat(
        id: (j['id'] ?? '').toString(),
        name: j['nombre'] ?? 'Beat',
        genre: j['genero'] ?? 'Trap',
        bpm: (j['bpm'] ?? 140).toInt(),
        price: (j['precio'] ?? 0).toDouble(),
        coverUrl: j['imagen_url'],
        audio: j['audio_url'] ?? 'audio/night_city.wav',
      );
}

const localBeats = [
  Beat(id: '1', name: 'Night City', genre: 'Trap', bpm: 140, price: 29.99, audio: 'audio/night_city.wav'),
  Beat(id: '2', name: 'Drill King', genre: 'Drill', bpm: 150, price: 34.99, audio: 'audio/drill_king.wav'),
  Beat(id: '3', name: 'Old School', genre: 'Rap', bpm: 85, price: 24.99, audio: 'audio/old_school.wav'),
  Beat(id: '4', name: 'Dark Trap', genre: 'Trap', bpm: 145, price: 39.99, audio: 'audio/dark_trap.wav'),
];

class CatalogService {
  static Future<List<Beat>> fetchBeats() async {
    if (!Env.configured) return localBeats;
    try {
      final uri = Uri.parse(
        '${Env.supabaseUrl}/rest/v1/orders'
        '?select=order_items(beat_id,beats(id,nombre,genero,bpm,precio,audio_url,imagen_url))'
        '&user_id=eq.${Env.userId}&status=eq.COMPLETADO',
      );
      final res = await http.get(
        uri,
        headers: {
          'apikey': Env.supabaseKey,
          'Authorization': 'Bearer ${Env.supabaseKey}',
        },
      ).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return localBeats;

      final data = jsonDecode(res.body) as List;
      final beats = <Beat>[];
      final seen = <String>{};
      for (final order in data) {
        final items = (order as Map<String, dynamic>)['order_items'];
        if (items is! List) continue;
        for (final item in items) {
          final bm = (item as Map<String, dynamic>)['beats'];
          if (bm is! Map<String, dynamic>) continue;
          final beat = Beat.fromRemote(bm);
          if (seen.add(beat.id)) beats.add(beat);
        }
      }
      return beats.isEmpty ? localBeats : beats;
    } catch (_) {
      return localBeats;
    }
  }
}

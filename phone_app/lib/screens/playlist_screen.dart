import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_provider.dart';

class PlaylistScreen extends StatelessWidget {
  final void Function(int index) onPlay;
  const PlaylistScreen({super.key, required this.onPlay});

  /// Pregunta dónde reproducir el beat para evitar doble reproducción.
  Future<void> _chooseTarget(BuildContext context, int index) async {
    final target = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tv, color: Color(0xFF6C5CE7)),
              title: const Text('En la Smart TV (PWA)', style: TextStyle(color: Colors.white)),
              subtitle: const Text('El teléfono solo manda datos', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.of(ctx).pop('tv'),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Color(0xFFFACC15)),
              title: const Text('En el teléfono', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Reproduce este dispositivo', style: TextStyle(color: Colors.grey)),
              onTap: () => Navigator.of(ctx).pop('app'),
            ),
          ],
        ),
      ),
    );
    if (target == null || !context.mounted) return;
    context.read<MusicPlayer>().setTarget(target);
    onPlay(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text('Lista de reproducción'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: Consumer<MusicPlayer>(
        builder: (context, player, _) {
          final beats = player.beats;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: beats.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final b = beats[i];
              final active = i == player.index;
              return Card(
                color: active ? const Color(0xFFFACC15) : const Color(0xFF1E1E1E),
                child: ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B0B0B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      active ? Icons.play_arrow : Icons.music_note,
                      color: const Color(0xFFFACC15),
                    ),
                  ),
                  title: Text(
                    b.name,
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '${b.genre} · ${b.bpm} BPM',
                    style: TextStyle(color: active ? Colors.black87 : const Color(0xFFA1A1AA)),
                  ),
                  onTap: () => _chooseTarget(context, i),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
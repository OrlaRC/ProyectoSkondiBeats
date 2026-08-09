import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../providers/music_provider.dart';
import '../models/beat.dart';

class PlayerScreen extends StatelessWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<MusicPlayer>();
    final beats = player.beats;
    final cur = player.current;
    final pos = player.position.inSeconds;
    final targetLabel = player.target == 'tv'
        ? 'Reproduciendo en la Smart TV'
        : 'Reproduciendo en el teléfono';
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text('Reproductor'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
      ),
      body: cur == null
          ? const Center(
              child: Text('Sin beats', style: TextStyle(color: Colors.white70)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: player.target == 'tv'
                        ? const Color(0xFF6C5CE7)
                        : const Color(0xFFFACC15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    targetLabel,
                    style: TextStyle(
                      color: player.target == 'tv' ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _cover(cur),
                const SizedBox(height: 24),
                Text(
                  cur.name,
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${cur.genre} · ${cur.bpm} BPM',
                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 18),
                ),
                const SizedBox(height: 16),
                Text(_fmt(pos), style: const TextStyle(color: Color(0xFF2AC227), fontSize: 16)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: () => context.read<MusicPlayer>().prev(),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor: const Color(0xFFFACC15),
                      padding: const EdgeInsets.all(24),
                    ),
                    onPressed: () => context.read<MusicPlayer>().toggle(),
                    child: Icon(player.playing ? Icons.pause : Icons.play_arrow, size: 44, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    iconSize: 40,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: () => context.read<MusicPlayer>().next(),
                  ),
                ]),
                const SizedBox(height: 16),
                Consumer<ActivityProvider>(
                  builder: (context, act, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _metric('BPM del beat', '${cur.bpm}'),
                      const SizedBox(width: 48),
                      _metric('Batería', '${act.battery}%'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.6,
                    children: List.generate(beats.length, (i) {
                      final b = beats[i];
                      final active = i == player.index;
                      return InkWell(
                        onTap: () => context.read<MusicPlayer>().playIndex(i),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: active ? const Color(0xFFFACC15) : const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: active ? const Color(0xFFFACC15) : Colors.transparent),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                b.name,
                                style: TextStyle(
                                  color: active ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${b.genre} · ${b.bpm}',
                                style: TextStyle(
                                  color: active ? Colors.black87 : const Color(0xFFA1A1AA),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ]),
            ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final ss = (s % 60).toString().padLeft(2, '0');
    return '$m:$ss';
  }

  Widget _metric(String label, String value) => Column(children: [
        Text(label, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ]);

  Widget _cover(Beat b) {
    final fallback = Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.music_note, color: Color(0xFFFACC15), size: 96),
    );
    Widget image;
    final url = b.coverUrl;
    if (url != null && url.isNotEmpty) {
      image = Image.network(
        url,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else if (b.name == 'Chill LoFi') {
      image = Image.asset(
        'assets/images/trap1.png',
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    } else {
      return fallback;
    }
    return ClipRRect(borderRadius: BorderRadius.circular(16), child: image);
  }
}
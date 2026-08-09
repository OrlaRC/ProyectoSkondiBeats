import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'sensors/sensor_service.dart';
import 'providers/activity_provider.dart';
import 'providers/music_provider.dart';
import 'screens/login_screen.dart';
import 'screens/monitor_screen.dart';
import 'screens/playlist_screen.dart';
import 'screens/player_screen.dart';

void main() {
  runApp(const SkonditPhoneApp());
}

class SkonditPhoneApp extends StatelessWidget {
  const SkonditPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sensorService = SensorService();
    return ChangeNotifierProvider(
      create: (_) => ActivityProvider(sensorService),
      child: ChangeNotifierProvider(
        create: (context) {
          final music = MusicPlayer();
          final ap = context.read<ActivityProvider>();
          music.attachWear(({required name, required genre, required bpm, required posSec, required durSec, required playing}) {
            ap.sendBeatToWear(
              name: name,
              genre: genre,
              bpm: bpm,
              posSec: posSec,
              durSec: durSec,
              playing: playing,
            );
          });
          music.load();
          return music;
        },
        child: MaterialApp(
          title: 'SkonditBeats Phone',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.dark(),
          home: const LoginScreen(),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  final String userName;
  const HomeShell({super.key, this.userName = 'Sara'});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ActivityProvider>().startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      MonitorScreen(userName: widget.userName),
      PlaylistScreen(
        onPlay: (i) {
          context.read<MusicPlayer>().playIndex(i);
          setState(() => _index = 2);
        },
      ),
      const PlayerScreen(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      body: screens[_index],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.monitor_heart),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.queue_music),
            label: 'Lista de reproducción',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle),
            label: 'Reproductor',
          ),
        ],
      ),
    );
  }
}

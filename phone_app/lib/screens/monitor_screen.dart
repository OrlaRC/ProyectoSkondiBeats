import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../providers/music_provider.dart';
import '../ble/ble_service.dart';
import '../services/now_playing_sync.dart';
import 'login_screen.dart';

class MonitorScreen extends StatelessWidget {
  final String userName;
  const MonitorScreen({super.key, this.userName = 'Sara'});

  Future<void> _logout(BuildContext context) async {
    final ap = context.read<ActivityProvider>();
    await ap.disconnectWear();
    await NowPlayingSync.publish(beat: null, positionSec: 0, durationSec: 0, playing: false);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ap = context.watch<ActivityProvider>();
    final music = context.watch<MusicPlayer>();
    final beatBpm = music.current?.bpm;
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0B),
      appBar: AppBar(
        title: const Text('SkonditBeats Monitor'),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Reintentar conexión',
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ActivityProvider>().startScanning(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Hola, $userName',
              style: const TextStyle(color: Color(0xFFFACC15), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          _connectionBanner(ap.state, ap.transport),
          const SizedBox(height: 16),
          _metricCard('Tiempo total', _fmtTotal(music.totalPlayedSec), Icons.timer),
          _metricCard('BPM', beatBpm != null ? '$beatBpm' : '--', Icons.favorite),
          _metricCard('Batería', '${ap.battery}%', Icons.battery_std),
          if (ap.isBpmHigh) _alert('Alerta: Beat de alta intensidad (BPM > 160)', Colors.red),
          if (ap.isBatteryLow) _alert('Alerta: Batería baja (< 20%)', const Color(0xFFFACC15)),
          const SizedBox(height: 16),
          _wearControls(context, ap),
        ]),
      ),
    );
  }

  Widget _wearControls(BuildContext context, ActivityProvider ap) {
    final connected = ap.state == BleConnectionState.connected;
    final sending = connected && ap.wearSending;
    final subtitle = connected
        ? (sending ? 'Enviando datos al wearable' : 'Envío de datos al wearable detenido')
        : 'Sin conexión con el wearable';
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vinculación con el wearable',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: connected
                    ? (sending ? const Color(0xFF2AC227) : Colors.orangeAccent)
                    : const Color(0xFFA1A1AA),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: connected ? Colors.redAccent : const Color(0xFF2AC227)),
                  ),
                  icon: Icon(
                    connected ? Icons.link_off : Icons.link,
                    color: connected ? Colors.redAccent : const Color(0xFF2AC227),
                  ),
                  label: Text(connected ? 'Detener conexión' : 'Conectar'),
                  onPressed: () {
                    final p = context.read<ActivityProvider>();
                    connected ? p.disconnectWear() : p.startScanning();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: connected ? Colors.white : const Color(0xFF555555),
                    side: BorderSide(color: connected ? (sending ? Colors.orangeAccent : const Color(0xFF2AC227)) : const Color(0xFF333333)),
                  ),
                  icon: Icon(
                    sending ? Icons.link_off : Icons.link,
                    color: connected ? (sending ? Colors.orangeAccent : const Color(0xFF2AC227)) : const Color(0xFF555555),
                  ),
                  label: Text(sending ? 'Detener envío de datos' : 'Reanudar envío'),
                  onPressed: connected
                      ? () {
                          final p = context.read<ActivityProvider>();
                          p.wearSending ? p.stopWearData() : p.resumeWearData();
                        }
                      : null,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _connectionBanner(BleConnectionState s, String transport) {
    final data = switch (s) {
      BleConnectionState.searching => ('Buscando wearable...', const Color(0xFFFACC15)),
      BleConnectionState.connected => ('Conectado a SkonditBeats (${transport.toUpperCase()})', const Color(0xFF2AC227)),
      BleConnectionState.error => ('Error: wearable no encontrado. Revisa que esté transmitiendo (Play en el reloj)', Colors.red),
      BleConnectionState.disconnected => ('Desconectado', const Color(0xFFA1A1AA)),
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: data.$2.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(data.$1, style: TextStyle(color: data.$2, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
    );
  }

  Widget _metricCard(String label, String value, IconData icon) => Card(
        color: const Color(0xFF1E1E1E),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFFACC15)),
          title: Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          subtitle: Text(label, style: const TextStyle(color: Color(0xFFA1A1AA))),
        ),
      );

  Widget _alert(String msg, Color c) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: c)),
        child: Text(msg, style: TextStyle(color: c, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      );

  String _fmtTotal(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m min $s s' : '$s s';
  }
}

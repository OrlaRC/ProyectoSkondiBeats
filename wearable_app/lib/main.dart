import 'package:flutter/material.dart';
import 'screens/watch_screen.dart';

void main() {
  runApp(const SkonditWearableApp());
}

class SkonditWearableApp extends StatelessWidget {
  const SkonditWearableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkonditBeats Wearable',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const WatchScreen(),
    );
  }
}
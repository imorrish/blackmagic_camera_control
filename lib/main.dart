import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/camera_connection_provider.dart';
import 'providers/camera_state_provider.dart';
import 'midi/midi_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CameraConnectionProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => CameraStateProvider(),
        ),
        ChangeNotifierProxyProvider<CameraStateProvider, MidiProvider>(
          create: (_) => MidiProvider(),
          update: (_, cameraState, midi) {
            midi!.updateCameraState(cameraState);
            return midi;
          },
        ),
      ],
      child: const BlackmagicControlApp(),
    ),
  );
}

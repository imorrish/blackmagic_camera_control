import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/camera_connection_provider.dart';
import '../providers/camera_state_provider.dart';
import '../widgets/common/error_banner.dart';
import '../widgets/common/tally_indicator.dart';
import '../widgets/common/power_status_indicator.dart';
import 'control_screen.dart';
import 'audio_screen.dart';
import 'media_screen.dart';
import 'monitoring_screen.dart';
import 'color_screen.dart';
import 'midi_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  Timer? _statusRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCameraState();
      _startStatusRefresh();
    });
  }

  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }

  void _startStatusRefresh() {
    // Refresh status indicators every 5 seconds
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        context.read<CameraStateProvider>().refreshStatusIndicators();
      }
    });
  }

  void _initializeCameraState() {
    final connection = context.read<CameraConnectionProvider>();
    final cameraState = context.read<CameraStateProvider>();
    cameraState.initialize(connection.cameraService);
  }

  Future<void> _disconnect() async {
    _statusRefreshTimer?.cancel();
    final cameraState = context.read<CameraStateProvider>();
    cameraState.initialize(null);
    await context.read<CameraConnectionProvider>().disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<CameraConnectionProvider>();
    final cameraState = context.watch<CameraStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              connection.softwareVersion != null
                  ? '${connection.cameraDisplayName} (v${connection.softwareVersion})'
                  : connection.cameraDisplayName,
              style: const TextStyle(fontSize: 16),
            ),
            if (connection.cameraModel != null)
              Text(
                connection.cameraIp,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(179),
                ),
              ),
          ],
        ),
        actions: [
          TallyIndicator(status: cameraState.tallyStatus),
          PowerStatusIndicator(powerState: cameraState.power),
          if (cameraState.isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cameraState.isLoading ? null : _refreshCurrentTab,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.link_off),
            onPressed: _disconnect,
            tooltip: 'Disconnect',
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: const [
              ControlScreen(),
              AudioScreen(),
              MediaScreen(),
              MonitoringScreen(),
              ColorScreen(),
              MidiScreen(),
            ],
          ),
          if (cameraState.error != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ErrorBanner(
                message: cameraState.error!,
                onDismiss: () {
                  cameraState.clearError();
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.camera),
            selectedIcon: Icon(Icons.camera),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.mic_outlined),
            selectedIcon: Icon(Icons.mic),
            label: 'Audio',
          ),
          NavigationDestination(
            icon: Icon(Icons.sd_card_outlined),
            selectedIcon: Icon(Icons.sd_card),
            label: 'Media',
          ),
          NavigationDestination(
            icon: Icon(Icons.monitor_outlined),
            selectedIcon: Icon(Icons.monitor),
            label: 'Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.color_lens_outlined),
            selectedIcon: Icon(Icons.color_lens),
            label: 'Color',
          ),
          NavigationDestination(
            icon: Icon(Icons.piano_outlined),
            selectedIcon: Icon(Icons.piano),
            label: 'MIDI',
          ),
        ],
      ),
    );
  }

  Future<void> _refreshCurrentTab() async {
    final cameraState = context.read<CameraStateProvider>();
    switch (_currentIndex) {
      case 0:
        await cameraState.refresh();
        break;
      case 1:
        await cameraState.refreshAudio();
        break;
      case 2:
        await cameraState.refreshMedia();
        break;
      case 3:
        await cameraState.refreshMonitoring();
        break;
      case 4:
        await cameraState.refreshColorCorrection();
        break;
      case 5:
        // MIDI screen manages its own state; nothing to refresh here.
        break;
    }
  }
}

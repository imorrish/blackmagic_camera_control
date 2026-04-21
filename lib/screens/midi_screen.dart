import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../midi/midi_provider.dart';
import '../utils/constants.dart';
import '../utils/platform_capabilities.dart';
import '../widgets/midi/device_selector_card.dart';
import '../widgets/midi/activity_monitor_card.dart';
import '../widgets/midi/mapping_table_card.dart';
import '../widgets/midi/profile_manager_card.dart';

/// Full-screen MIDI control configuration screen.
///
/// On non-web platforms this shows an informational banner explaining
/// that MIDI is only available in the web version.
class MidiScreen extends StatefulWidget {
  const MidiScreen({super.key});

  @override
  State<MidiScreen> createState() => _MidiScreenState();
}

class _MidiScreenState extends State<MidiScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && PlatformCapabilities.hasMidi) {
        context.read<MidiProvider>().initialize();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformCapabilities.hasMidi) {
      return _buildUnsupportedPlatformBanner(context);
    }
    return _buildMidiContent(context);
  }

  Widget _buildUnsupportedPlatformBanner(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.piano_off, size: 64, color: Colors.grey),
            Spacing.verticalLg,
            const Text(
              'MIDI Control',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Spacing.verticalSm,
            const Text(
              'MIDI control is only available in the web version of this app.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            Spacing.verticalSm,
            const Text(
              'Open the app in a Chromium-based browser (Chrome, Edge, Opera) '
              'for Web MIDI API support.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMidiContent(BuildContext context) {
    final midi = context.watch<MidiProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1 – Device selection
          const DeviceSelectorCard(),

          // 2 – Activity monitor (only when a device is selected or any message received)
          if (midi.selectedDevice != null ||
              midi.recentMessages.isNotEmpty)
            const ActivityMonitorCard(),

          // 3 – Profile manager
          const ProfileManagerCard(),

          // 4 – Mapping table
          const MappingTableCard(),
        ],
      ),
    );
  }
}

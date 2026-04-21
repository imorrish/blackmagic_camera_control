import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../midi/midi_provider.dart';
import '../../midi/midi_message.dart';
import '../../utils/constants.dart';
import '../../utils/platform_capabilities.dart';

/// Card for selecting a MIDI input device and enabling/disabling MIDI control.
class DeviceSelectorCard extends StatelessWidget {
  const DeviceSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiProvider>();

    return Card(
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.piano),
                Spacing.horizontalSm,
                const Expanded(
                  child: Text(
                    'MIDI Control',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                Switch(
                  value: midi.isEnabled,
                  onChanged: PlatformCapabilities.hasMidi &&
                          midi.isMidiAvailable
                      ? (v) => midi.enableMidi(v)
                      : null,
                ),
              ],
            ),
            Spacing.verticalSm,
            _buildStatusRow(context, midi),
            if (midi.isMidiAvailable && midi.isEnabled) ...[
              Spacing.verticalMd,
              _buildDeviceDropdown(context, midi),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, MidiProvider midi) {
    if (!PlatformCapabilities.hasMidi) {
      return const _StatusChip(
        label: 'MIDI not available on this platform',
        color: Colors.orange,
        icon: Icons.info_outline,
      );
    }

    if (!midi.permissionRequested) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.piano),
        label: const Text('Request MIDI Access'),
        onPressed: () => midi.requestMidiAccess(),
      );
    }

    if (!midi.isMidiAvailable) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatusChip(
            label: 'MIDI access denied',
            color: Colors.red,
            icon: Icons.error_outline,
          ),
          Spacing.verticalSm,
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: () => midi.requestMidiAccess(),
          ),
        ],
      );
    }

    if (midi.devices.isEmpty) {
      return const _StatusChip(
        label: 'No MIDI devices found',
        color: Colors.orange,
        icon: Icons.device_unknown,
      );
    }

    if (midi.selectedDevice != null) {
      return _StatusChip(
        label: 'Connected: ${midi.selectedDevice!.displayName}',
        color: Colors.green,
        icon: Icons.check_circle_outline,
      );
    }

    return const _StatusChip(
      label: 'No device selected',
      color: Colors.grey,
      icon: Icons.piano_off,
    );
  }

  Widget _buildDeviceDropdown(BuildContext context, MidiProvider midi) {
    final items = midi.devices
        .map(
          (d) => DropdownMenuItem<String>(
            value: d.id,
            child: Text(d.displayName, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();

    return DropdownButtonFormField<String>(
      value: midi.selectedDeviceId,
      decoration: const InputDecoration(
        labelText: 'MIDI Input Device',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.piano),
      ),
      items: items,
      hint: const Text('Select a device…'),
      onChanged: (id) {
        if (id != null) midi.selectDevice(id);
      },
      isExpanded: true,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        Spacing.horizontalSm,
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../midi/midi_provider.dart';
import '../../utils/constants.dart';

/// Card for managing named MIDI mapping profiles (save, load, delete,
/// import, export, and loading the built-in Behringer CMD DV-1 defaults).
class ProfileManagerCard extends StatefulWidget {
  const ProfileManagerCard({super.key});

  @override
  State<ProfileManagerCard> createState() => _ProfileManagerCardState();
}

class _ProfileManagerCardState extends State<ProfileManagerCard> {
  final _nameController = TextEditingController();
  String? _selectedProfileName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final midi = context.read<MidiProvider>();
      _nameController.text = midi.activeProfile.name;
      setState(() {
        _selectedProfileName = midi.profileNames.contains(midi.activeProfile.name)
            ? midi.activeProfile.name
            : null;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiProvider>();

    return Card(
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.folder_open),
                Spacing.horizontalSm,
                const Text(
                  'Profile Manager',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Spacing.verticalMd,

            // Profile name input + saved profiles dropdown
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Profile Name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Spacing.horizontalSm,
                if (midi.profileNames.isNotEmpty)
                  DropdownButton<String>(
                    value: _selectedProfileName,
                    hint: const Text('Saved…'),
                    underline: const SizedBox(),
                    items: midi.profileNames
                        .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text(n),
                            ))
                        .toList(),
                    onChanged: (name) {
                      if (name != null) {
                        setState(() => _selectedProfileName = name);
                        _nameController.text = name;
                      }
                    },
                  ),
              ],
            ),
            Spacing.verticalMd,

            // Error message
            if (midi.profileError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  midi.profileError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),

            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('Save'),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (name.isEmpty) return;
                    midi.saveProfile(name);
                    setState(() => _selectedProfileName = name);
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Load'),
                  onPressed:
                      _selectedProfileName != null
                          ? () => midi.loadProfile(_selectedProfileName!)
                          : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red),
                  onPressed: _selectedProfileName != null
                      ? () => _confirmDelete(context, midi)
                      : null,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Export JSON'),
                  onPressed: () => midi.exportProfile(),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Import JSON'),
                  onPressed: () => midi.importProfile(),
                ),
              ],
            ),
            Spacing.verticalMd,
            const Divider(),
            Spacing.verticalSm,

            // Behringer preset button
            OutlinedButton.icon(
              icon: const Icon(Icons.music_note, size: 16),
              label: const Text('Load Behringer CMD DV-1 defaults'),
              onPressed: () {
                midi.loadBehringerDefaults();
                _nameController.text = midi.activeProfile.name;
                setState(() => _selectedProfileName = null);
              },
            ),
            Spacing.verticalXs,
            const Text(
              'Loads a default mapping for the Behringer CMD DV-1 controller.\n'
              'Use the Activity Monitor + Learn workflow to verify exact CC numbers.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, MidiProvider midi) async {
    final name = _selectedProfileName!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$name"?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) {
      await midi.deleteProfile(name);
      setState(() => _selectedProfileName = null);
    }
  }
}

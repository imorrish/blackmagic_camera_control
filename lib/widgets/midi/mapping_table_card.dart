import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../midi/midi_provider.dart';
import '../../midi/midi_mapping.dart';
import '../../midi/midi_action_registry.dart';
import '../../utils/constants.dart';
import 'mapping_editor_dialog.dart';

/// Card that shows the active profile's MIDI mappings in a table.
class MappingTableCard extends StatelessWidget {
  const MappingTableCard({super.key});

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiProvider>();
    final mappings = midi.activeProfile.mappings;

    return Card(
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.tune),
                Spacing.horizontalSm,
                const Expanded(
                  child: Text(
                    'MIDI Mappings',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                if (mappings.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Clear All'),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red),
                    onPressed: () =>
                        _confirmClearAll(context, midi),
                  ),
              ],
            ),
            Spacing.verticalSm,

            if (mappings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No mappings defined yet.\n'
                    'Tap "+ Add Mapping" to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              _buildTable(context, midi, mappings),

            Spacing.verticalMd,
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Mapping'),
                onPressed: () => _openEditor(context, midi, null, -1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(
    BuildContext context,
    MidiProvider midi,
    List<MidiMapping> mappings,
  ) {
    // Group by category for visual separation.
    final categories = MidiActionRegistry.categories;
    final categorised = <String, List<(int, MidiMapping)>>{};
    for (var i = 0; i < mappings.length; i++) {
      final action =
          MidiActionRegistry.findById(mappings[i].target.actionId);
      final cat = action?.category ?? 'Other';
      categorised.putIfAbsent(cat, () => []).add((i, mappings[i]));
    }

    final allCats = [
      ...categories.where(categorised.containsKey),
      ...categorised.keys
          .where((k) => !categories.contains(k)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Table header
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('MIDI Source', style: _headerStyle)),
              Expanded(flex: 4, child: Text('Camera Control', style: _headerStyle)),
              Expanded(flex: 2, child: Text('Range', style: _headerStyle)),
              SizedBox(width: 56, child: Text('', style: _headerStyle)),
            ],
          ),
        ),
        for (final cat in allCats) ...[
          _CategoryDivider(label: cat),
          for (final (idx, mapping) in categorised[cat]!)
            _MappingRow(
              mapping: mapping,
              onEdit: () => _openEditor(context, midi, mapping, idx),
              onDelete: () => midi.removeMapping(idx),
            ),
        ],
      ],
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    MidiProvider midi,
    MidiMapping? existing,
    int index,
  ) async {
    final result = await MappingEditorDialog.show(
      context,
      initial: existing,
    );
    if (result == null) return;
    if (index < 0) {
      midi.addMapping(result);
    } else {
      midi.updateMapping(index, result);
    }
  }

  Future<void> _confirmClearAll(
      BuildContext context, MidiProvider midi) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Mappings?'),
        content: const Text('This will remove all MIDI mappings from the active profile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Clear All')),
        ],
      ),
    );
    if (confirmed == true) midi.clearMappings();
  }

  static const _headerStyle =
      TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
}

class _CategoryDivider extends StatelessWidget {
  const _CategoryDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Theme.of(context)
          .colorScheme
          .primary
          .withAlpha(20),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _MappingRow extends StatelessWidget {
  const _MappingRow({
    required this.mapping,
    required this.onEdit,
    required this.onDelete,
  });

  final MidiMapping mapping;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final action =
        MidiActionRegistry.findById(mapping.target.actionId);
    final actionName = action?.displayName ?? mapping.target.actionId;
    final minPct = '${(mapping.target.minValue * 100).round()}%';
    final maxPct = '${(mapping.target.maxValue * 100).round()}%';
    final range = mapping.target.invert
        ? '$maxPct → $minPct ↕'
        : '$minPct → $maxPct';

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context)
                .dividerColor
                .withAlpha(80),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              mapping.source.label,
              style: const TextStyle(
                  fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(actionName,
                style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(range,
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey)),
          ),
          SizedBox(
            width: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onEdit,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit, size: 16),
                  ),
                ),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline,
                        size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

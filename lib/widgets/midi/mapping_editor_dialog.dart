import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../midi/midi_provider.dart';
import '../../midi/midi_mapping.dart';
import '../../midi/midi_message.dart';
import '../../midi/midi_action_registry.dart';
import '../../utils/constants.dart';

/// Dialog for creating or editing a single MIDI → camera-control mapping.
///
/// Returns a [MidiMapping] when confirmed, or null when cancelled.
class MappingEditorDialog extends StatefulWidget {
  const MappingEditorDialog({
    super.key,
    this.initial,
  });

  /// Existing mapping to edit, or null when creating a new one.
  final MidiMapping? initial;

  /// Show the dialog and return the resulting [MidiMapping], or null.
  static Future<MidiMapping?> show(
    BuildContext context, {
    MidiMapping? initial,
  }) {
    return showDialog<MidiMapping>(
      context: context,
      builder: (_) => MappingEditorDialog(initial: initial),
    );
  }

  @override
  State<MappingEditorDialog> createState() => _MappingEditorDialogState();
}

class _MappingEditorDialogState extends State<MappingEditorDialog> {
  // ── MIDI source ────────────────────────────────────────────────────────────
  MidiControl? _source;
  bool _isLearning = false;

  // Manual entry fields
  MidiMessageType _manualType = MidiMessageType.controlChange;
  int _manualChannel = 0;
  int _manualNumber = 0;

  // ── Camera target ──────────────────────────────────────────────────────────
  String? _actionId;

  // ── Scaling ────────────────────────────────────────────────────────────────
  double _minValue = 0.0;
  double _maxValue = 1.0;
  bool _invert = false;

  // ── Learn subscription ─────────────────────────────────────────────────────
  MidiProvider? _midiProvider;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) {
      final m = widget.initial!;
      _source = m.source;
      _manualType = m.source.type;
      _manualChannel = m.source.channel;
      _manualNumber = m.source.number;
      _actionId = m.target.actionId;
      _minValue = m.target.minValue;
      _maxValue = m.target.maxValue;
      _invert = m.target.invert;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _midiProvider = context.read<MidiProvider>();
  }

  @override
  void dispose() {
    if (_isLearning) _midiProvider?.cancelLearn();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _startLearn() {
    setState(() => _isLearning = true);
    // Use the sentinel action ID so the provider captures the next message.
    _midiProvider?.startLearn(MidiProvider.learnSentinelActionId);
    _pollLearnResult();
  }

  Future<void> _pollLearnResult() async {
    while (_isLearning && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      final provider = context.read<MidiProvider>();
      if (!provider.isLearning) {
        // Find the learned mapping for our sentinel action id.
        final matches = provider.activeProfile.mappings
            .where((m) => m.target.actionId == MidiProvider.learnSentinelActionId)
            .toList();
        final learned = matches.isEmpty ? null : matches.last;
        if (learned != null) {
          // Remove the sentinel mapping.
          final idx = provider.activeProfile.mappings.lastIndexWhere(
              (m) => m.target.actionId == MidiProvider.learnSentinelActionId);
          if (idx >= 0) provider.removeMapping(idx);

          setState(() {
            _source = learned.source;
            _manualType = learned.source.type;
            _manualChannel = learned.source.channel;
            _manualNumber = learned.source.number;
            _isLearning = false;
          });
        } else {
          setState(() => _isLearning = false);
        }
        return;
      }
    }
  }

  void _cancelLearn() {
    _midiProvider?.cancelLearn();
    setState(() => _isLearning = false);
  }

  MidiControl get _effectiveSource => _source ??
      MidiControl(
        type: _manualType,
        channel: _manualChannel,
        number: _manualNumber,
      );

  bool get _isValid => _actionId != null && _actionId!.isNotEmpty;

  MidiMapping _buildMapping() => MidiMapping(
        source: _effectiveSource,
        target: MidiTarget(
          actionId: _actionId!,
          minValue: _minValue,
          maxValue: _maxValue,
          invert: _invert,
        ),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiProvider>();

    return AlertDialog(
      title:
          Text(widget.initial == null ? 'Add Mapping' : 'Edit Mapping'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSectionHeader('Step 1 — MIDI Source'),
              _buildLearnSection(midi),
              Spacing.verticalMd,
              _buildSectionHeader('Step 2 — Camera Control'),
              _buildActionDropdown(),
              Spacing.verticalMd,
              _buildSectionHeader('Step 3 — Scaling'),
              _buildScalingSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLearning ? _cancelLearn : () => Navigator.pop(context),
          child:
              Text(_isLearning ? 'Cancel Learn' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _isValid && !_isLearning
              ? () => Navigator.pop(context, _buildMapping())
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      );

  Widget _buildLearnSection(MidiProvider midi) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _source != null
                  ? Text(
                      _source!.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    )
                  : Text(
                      _isLearning
                          ? 'Move a control on your MIDI device…'
                          : 'No source selected',
                      style: TextStyle(
                        color: _isLearning ? Colors.orange : Colors.grey,
                        fontStyle: _isLearning
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
            ),
            _isLearning
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: _cancelLearn,
                    child: const Text('Cancel'),
                  )
                : ElevatedButton.icon(
                    icon: const Icon(Icons.sensors, size: 18),
                    label: const Text('Learn'),
                    onPressed: () => _startLearn(),
                  ),
          ],
        ),
        Spacing.verticalSm,
        // Manual fallback
        ExpansionTile(
          title: const Text('Or enter manually',
              style: TextStyle(fontSize: 13)),
          children: [
            _buildManualSourceFields(),
          ],
        ),
      ],
    );
  }

  Widget _buildManualSourceFields() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          DropdownButtonFormField<MidiMessageType>(
            value: _manualType,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(
                value: MidiMessageType.controlChange,
                child: Text('Control Change (CC)'),
              ),
              DropdownMenuItem(
                value: MidiMessageType.noteOn,
                child: Text('Note On'),
              ),
              DropdownMenuItem(
                value: MidiMessageType.pitchBend,
                child: Text('Pitch Bend'),
              ),
            ],
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _manualType = v;
                  _source = null;
                });
              }
            },
          ),
          Spacing.verticalSm,
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '${_manualChannel + 1}',
                  decoration: const InputDecoration(
                    labelText: 'Channel (1–16)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final ch = (int.tryParse(v) ?? 1) - 1;
                    setState(() {
                      _manualChannel = ch.clamp(0, 15);
                      _source = null;
                    });
                  },
                ),
              ),
              Spacing.horizontalSm,
              Expanded(
                child: TextFormField(
                  initialValue: '$_manualNumber',
                  decoration: const InputDecoration(
                    labelText: 'Number (0–127)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    setState(() {
                      _manualNumber =
                          (int.tryParse(v) ?? 0).clamp(0, 127);
                      _source = null;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionDropdown() {
    final categories = MidiActionRegistry.categories;
    final items = <DropdownMenuItem<String>>[];

    for (final cat in categories) {
      // Category header (not selectable – use a disabled item as header).
      items.add(
        DropdownMenuItem<String>(
          enabled: false,
          child: Text(
            cat.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      );
      for (final action in MidiActionRegistry.forCategory(cat)) {
        items.add(
          DropdownMenuItem<String>(
            value: action.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(action.displayName),
            ),
          ),
        );
      }
    }

    return DropdownButtonFormField<String>(
      value: _actionId,
      decoration: const InputDecoration(
        labelText: 'Camera Control',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select a control…'),
      items: items,
      onChanged: (v) => setState(() => _actionId = v),
      isExpanded: true,
    );
  }

  Widget _buildScalingSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Min: ${(_minValue * 100).round()}%',
                      style: const TextStyle(fontSize: 12)),
                  Slider(
                    value: _minValue,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    onChanged: (v) =>
                        setState(() => _minValue = v),
                  ),
                ],
              ),
            ),
            Spacing.horizontalSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Max: ${(_maxValue * 100).round()}%',
                      style: const TextStyle(fontSize: 12)),
                  Slider(
                    value: _maxValue,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    onChanged: (v) =>
                        setState(() => _maxValue = v),
                  ),
                ],
              ),
            ),
          ],
        ),
        CheckboxListTile(
          title: const Text('Invert'),
          subtitle: const Text('Flip direction (high → low)'),
          value: _invert,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) => setState(() => _invert = v ?? false),
          dense: true,
        ),
      ],
    );
  }
}

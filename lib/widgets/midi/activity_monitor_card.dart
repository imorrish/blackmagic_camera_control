import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../midi/midi_provider.dart';
import '../../midi/midi_message.dart';
import '../../utils/constants.dart';

/// Card that shows the last [_maxVisible] incoming MIDI messages.
class ActivityMonitorCard extends StatefulWidget {
  const ActivityMonitorCard({super.key});

  @override
  State<ActivityMonitorCard> createState() => _ActivityMonitorCardState();
}

class _ActivityMonitorCardState extends State<ActivityMonitorCard> {
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final midi = context.watch<MidiProvider>();
    final count = midi.recentMessages.length;

    // Auto-scroll only when a new message arrives.
    if (count > _lastMessageCount) {
      _lastMessageCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Card(
      child: Padding(
        padding: Spacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.graphic_eq),
                Spacing.horizontalSm,
                const Expanded(
                  child: Text(
                    'Activity Monitor',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: const Text('Clear'),
                  onPressed: () {
                    context.read<MidiProvider>().clearRecentMessages();
                    setState(() => _lastMessageCount = 0);
                  },
                ),
              ],
            ),
            Spacing.verticalSm,
            SizedBox(
              height: 200,
              child: midi.recentMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'No MIDI messages received yet.\n'
                        'Select a device and enable MIDI to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: midi.recentMessages.length,
                      itemBuilder: (context, index) {
                        final msg = midi.recentMessages[index];
                        return _MidiMessageRow(
                          message: msg,
                          isLatest:
                              index == midi.recentMessages.length - 1,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MidiMessageRow extends StatelessWidget {
  const _MidiMessageRow({required this.message, required this.isLatest});

  final MidiMessage message;
  final bool isLatest;

  Color _chipColor() {
    switch (message.type) {
      case MidiMessageType.controlChange:
        return Colors.blue;
      case MidiMessageType.noteOn:
        return Colors.green;
      case MidiMessageType.noteOff:
        return Colors.red;
      case MidiMessageType.pitchBend:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = message.receivedAt;
    final timeLabel =
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}.'
        '${(time.millisecond ~/ 10).toString().padLeft(2, '0')}';

    return Container(
      color: isLatest
          ? Theme.of(context).colorScheme.primary.withAlpha(30)
          : null,
      padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 40,
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _chipColor().withAlpha(200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              message.typeLabel,
              style: const TextStyle(fontSize: 10, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          Spacing.horizontalSm,
          Text(
            'CH${message.channel + 1}',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          Spacing.horizontalSm,
          Text(
            '#${message.number.toString().padLeft(3, ' ')}',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          Spacing.horizontalSm,
          Text(
            'val:${message.value.toString().padLeft(3, ' ')}',
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
          const Spacer(),
          Text(
            timeLabel,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

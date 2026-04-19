import 'package:flutter/foundation.dart';

/// MIDI message types
enum MidiMessageType {
  noteOff,
  noteOn,
  controlChange,
  pitchBend,
  unknown,
}

/// A device available as a MIDI input.
@immutable
class MidiInputDevice {
  const MidiInputDevice({
    required this.id,
    required this.name,
    this.manufacturer = '',
  });

  final String id;
  final String name;
  final String manufacturer;

  String get displayName =>
      manufacturer.isNotEmpty ? '$name ($manufacturer)' : name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiInputDevice &&
          other.id == id &&
          other.name == name &&
          other.manufacturer == manufacturer;

  @override
  int get hashCode => Object.hash(id, name, manufacturer);

  @override
  String toString() => 'MidiInputDevice($displayName)';
}

/// A parsed MIDI message.
@immutable
class MidiMessage {
  const MidiMessage({
    required this.type,
    required this.channel,
    required this.number,
    required this.value,
    required this.receivedAt,
  });

  /// The type of MIDI message.
  final MidiMessageType type;

  /// MIDI channel (0–15).
  final int channel;

  /// Note number (for note on/off) or CC number (for control change).
  final int number;

  /// Velocity (for notes), CC value (0–127), or 14-bit pitch bend value.
  final int value;

  /// When this message was received.
  final DateTime receivedAt;

  /// Parse a MIDI message from raw bytes [status, data1, data2].
  /// Returns null if the bytes list is empty.
  static MidiMessage? fromBytes(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final status = bytes[0];
    final typeNibble = (status >> 4) & 0xF;
    final channel = status & 0xF;
    final data1 = bytes.length > 1 ? bytes[1] : 0;
    final data2 = bytes.length > 2 ? bytes[2] : 0;

    final MidiMessageType messageType;
    int number = data1;
    int msgValue = data2;

    switch (typeNibble) {
      case 0x8:
        messageType = MidiMessageType.noteOff;
      case 0x9:
        // Note-on with velocity 0 is treated as note-off by convention,
        // but we keep the type as noteOn so mappings work consistently.
        messageType = MidiMessageType.noteOn;
      case 0xB:
        messageType = MidiMessageType.controlChange;
      case 0xE:
        messageType = MidiMessageType.pitchBend;
        number = 0;
        msgValue = data1 | (data2 << 7); // 14-bit value
      default:
        messageType = MidiMessageType.unknown;
    }

    return MidiMessage(
      type: messageType,
      channel: channel,
      number: number,
      value: msgValue,
      receivedAt: DateTime.now(),
    );
  }

  /// Human-readable label for the message type.
  String get typeLabel {
    switch (type) {
      case MidiMessageType.noteOff:
        return 'Note Off';
      case MidiMessageType.noteOn:
        return 'Note On';
      case MidiMessageType.controlChange:
        return 'CC';
      case MidiMessageType.pitchBend:
        return 'Pitch';
      case MidiMessageType.unknown:
        return 'Unknown';
    }
  }

  /// Short display label for the MIDI source.
  String get sourceLabel {
    switch (type) {
      case MidiMessageType.controlChange:
        return 'CH${channel + 1} CC#$number';
      case MidiMessageType.noteOn:
      case MidiMessageType.noteOff:
        return 'CH${channel + 1} Note#$number';
      case MidiMessageType.pitchBend:
        return 'CH${channel + 1} Pitch';
      case MidiMessageType.unknown:
        return 'CH${channel + 1} ?';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMessage &&
          other.type == type &&
          other.channel == channel &&
          other.number == number &&
          other.value == value;

  @override
  int get hashCode => Object.hash(type, channel, number, value);

  @override
  String toString() =>
      'MidiMessage(${typeLabel} ch:$channel num:$number val:$value)';
}

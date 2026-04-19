import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'midi_message.dart';

/// Identifies a MIDI source: the message type, channel, and number.
@immutable
class MidiControl {
  const MidiControl({
    required this.type,
    required this.channel,
    required this.number,
  });

  final MidiMessageType type;

  /// MIDI channel (0–15).
  final int channel;

  /// CC number or note number.
  final int number;

  /// Whether a received [message] matches this control.
  bool matches(MidiMessage message) =>
      message.type == type &&
      message.channel == channel &&
      message.number == number;

  /// Human-readable label (e.g. "CH1 CC#22").
  String get label {
    switch (type) {
      case MidiMessageType.controlChange:
        return 'CH${channel + 1} CC#$number';
      case MidiMessageType.noteOn:
      case MidiMessageType.noteOff:
        return 'CH${channel + 1} Note#$number';
      case MidiMessageType.pitchBend:
        return 'CH${channel + 1} Pitch';
      default:
        return 'CH${channel + 1} #$number';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'channel': channel,
        'number': number,
      };

  factory MidiControl.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'controlChange';
    return MidiControl(
      type: MidiMessageType.values.firstWhere(
        (e) => e.name == typeName,
        orElse: () => MidiMessageType.controlChange,
      ),
      channel: json['channel'] as int? ?? 0,
      number: json['number'] as int? ?? 0,
    );
  }

  /// Build a MidiControl from a received MidiMessage.
  factory MidiControl.fromMessage(MidiMessage message) => MidiControl(
        type: message.type,
        channel: message.channel,
        number: message.number,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiControl &&
          other.type == type &&
          other.channel == channel &&
          other.number == number;

  @override
  int get hashCode => Object.hash(type, channel, number);

  @override
  String toString() => 'MidiControl($label)';
}

/// Describes how a MIDI message maps to a camera action.
@immutable
class MidiTarget {
  const MidiTarget({
    required this.actionId,
    this.minValue = 0.0,
    this.maxValue = 1.0,
    this.invert = false,
  });

  /// ID matching a [MidiAction] in the registry.
  final String actionId;

  /// Minimum scaled value (0.0–1.0 range, applied after CC normalisation).
  final double minValue;

  /// Maximum scaled value (0.0–1.0 range).
  final double maxValue;

  /// Whether to invert the value (1.0 − normalised) before scaling.
  final bool invert;

  /// Normalise a raw MIDI value (0–127 for CC, 0–16383 for pitch bend)
  /// into the target range, applying inversion and min/max scaling.
  double normalize(int rawValue, {bool isPitchBend = false}) {
    final maxRaw = isPitchBend ? 16383.0 : 127.0;
    var norm = rawValue.clamp(0, maxRaw.toInt()) / maxRaw;
    if (invert) norm = 1.0 - norm;
    return minValue + norm * (maxValue - minValue);
  }

  Map<String, dynamic> toJson() => {
        'actionId': actionId,
        'minValue': minValue,
        'maxValue': maxValue,
        'invert': invert,
      };

  factory MidiTarget.fromJson(Map<String, dynamic> json) => MidiTarget(
        actionId: json['actionId'] as String? ?? '',
        minValue: (json['minValue'] as num?)?.toDouble() ?? 0.0,
        maxValue: (json['maxValue'] as num?)?.toDouble() ?? 1.0,
        invert: json['invert'] as bool? ?? false,
      );

  MidiTarget copyWith({
    String? actionId,
    double? minValue,
    double? maxValue,
    bool? invert,
  }) =>
      MidiTarget(
        actionId: actionId ?? this.actionId,
        minValue: minValue ?? this.minValue,
        maxValue: maxValue ?? this.maxValue,
        invert: invert ?? this.invert,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiTarget &&
          other.actionId == actionId &&
          other.minValue == minValue &&
          other.maxValue == maxValue &&
          other.invert == invert;

  @override
  int get hashCode => Object.hash(actionId, minValue, maxValue, invert);
}

/// A single MIDI → camera-control mapping.
@immutable
class MidiMapping {
  const MidiMapping({required this.source, required this.target});

  final MidiControl source;
  final MidiTarget target;

  Map<String, dynamic> toJson() => {
        'source': source.toJson(),
        'target': target.toJson(),
      };

  factory MidiMapping.fromJson(Map<String, dynamic> json) => MidiMapping(
        source:
            MidiControl.fromJson(json['source'] as Map<String, dynamic>? ?? {}),
        target:
            MidiTarget.fromJson(json['target'] as Map<String, dynamic>? ?? {}),
      );

  MidiMapping copyWith({MidiControl? source, MidiTarget? target}) =>
      MidiMapping(
        source: source ?? this.source,
        target: target ?? this.target,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMapping && other.source == source && other.target == target;

  @override
  int get hashCode => Object.hash(source, target);
}

/// A named collection of MIDI mappings that can be saved/loaded.
@immutable
class MidiMappingProfile {
  const MidiMappingProfile({
    required this.name,
    required this.mappings,
    DateTime? created,
  }) : _created = created;

  final String name;
  final List<MidiMapping> mappings;
  final DateTime? _created;

  static const String version = '1.0';

  DateTime get created => _created ?? DateTime.now();

  /// Empty profile with the given name.
  factory MidiMappingProfile.empty(String name) =>
      MidiMappingProfile(name: name, mappings: const []);

  MidiMappingProfile copyWith({
    String? name,
    List<MidiMapping>? mappings,
  }) =>
      MidiMappingProfile(
        name: name ?? this.name,
        mappings: mappings ?? this.mappings,
        created: _created,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'created': created.toIso8601String(),
        'mappings': mappings.map((m) => m.toJson()).toList(),
      };

  /// Serialise to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  factory MidiMappingProfile.fromJson(Map<String, dynamic> json) =>
      MidiMappingProfile(
        name: json['name'] as String? ?? 'Unnamed',
        mappings: (json['mappings'] as List<dynamic>? ?? [])
            .map((e) => MidiMapping.fromJson(e as Map<String, dynamic>))
            .toList(),
        created: json['created'] != null
            ? DateTime.tryParse(json['created'] as String)
            : null,
      );

  /// Parse from a JSON string.
  factory MidiMappingProfile.fromJsonString(String jsonString) =>
      MidiMappingProfile.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MidiMappingProfile &&
          other.name == name &&
          listEquals(other.mappings, mappings);

  @override
  int get hashCode => Object.hash(name, Object.hashAll(mappings));

  @override
  String toString() =>
      'MidiMappingProfile(name: $name, mappings: ${mappings.length})';
}

/// Stub MIDI service for non-web platforms.
///
/// All methods are no-ops; MIDI is only available on web.
library;

import 'dart:async';
import 'midi_message.dart';
import 'midi_mapping.dart';

export 'midi_message.dart';
export 'midi_mapping.dart';

class MidiService {
  final _devicesController =
      StreamController<List<MidiInputDevice>>.broadcast();
  final _messagesController = StreamController<MidiMessage>.broadcast();

  List<MidiInputDevice> get devices => const [];

  Stream<List<MidiInputDevice>> get deviceChanges =>
      _devicesController.stream;

  Stream<MidiMessage> get messages => _messagesController.stream;

  bool get isMidiAvailable => false;

  Future<bool> requestAccess() async => false;

  Future<void> selectDevice(String? deviceId) async {}

  Future<void> exportProfile(MidiMappingProfile profile) async {}

  Future<String?> importProfileJson() async => null;

  void dispose() {
    _devicesController.close();
    _messagesController.close();
  }
}

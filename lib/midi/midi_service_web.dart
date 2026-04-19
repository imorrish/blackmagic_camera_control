// ignore_for_file: avoid_web_libraries_in_flutter
// This file is only compiled on web (dart.library.html is available).

library;

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_interop';

import 'midi_js_interop.dart';
import 'midi_message.dart';
import 'midi_mapping.dart';

export 'midi_message.dart';
export 'midi_mapping.dart';

class MidiService {
  JSMidiAccess? _midiAccess;
  JSMidiInput? _selectedInput;
  String? _selectedDeviceId;

  final _devicesController =
      StreamController<List<MidiInputDevice>>.broadcast();
  final _messagesController = StreamController<MidiMessage>.broadcast();

  List<MidiInputDevice> _devices = [];

  List<MidiInputDevice> get devices => List.unmodifiable(_devices);

  Stream<List<MidiInputDevice>> get deviceChanges =>
      _devicesController.stream;

  Stream<MidiMessage> get messages => _messagesController.stream;

  bool get isMidiAvailable => _midiAccess != null;

  /// Request Web MIDI access from the browser.
  ///
  /// Returns true on success.  The device list is populated immediately after.
  Future<bool> requestAccess() async {
    final access = await requestMidiAccess();
    if (access == null) return false;

    _midiAccess = access;

    // React to plug/unplug events.
    access.onstatechange = (JSAny? event) {
      _refreshDevices();
    }.toJS;

    _refreshDevices();
    return true;
  }

  /// Re-enumerates connected MIDI inputs and updates the devices list.
  void _refreshDevices() {
    if (_midiAccess == null) return;
    final inputs = enumerateMidiInputs(_midiAccess!.inputs);
    _devices = inputs
        .map((t) =>
            MidiInputDevice(id: t.$1, name: t.$2, manufacturer: t.$3))
        .toList();

    _devicesController.add(_devices);

    // If the selected device disconnected, clear the selection.
    if (_selectedDeviceId != null) {
      final stillPresent = _devices.any((d) => d.id == _selectedDeviceId);
      if (!stillPresent) {
        selectDevice(null);
      }
    }
  }

  /// Attach a MIDI message listener to the device with [deviceId].
  ///
  /// Pass null to detach from all devices.
  Future<void> selectDevice(String? deviceId) async {
    // Detach from the current input first.
    _selectedInput?.onmidimessage = null;
    _selectedInput = null;
    _selectedDeviceId = deviceId;

    if (deviceId == null || _midiAccess == null) return;

    final input = getMidiInputById(_midiAccess!.inputs, deviceId);
    if (input == null) return;

    _selectedInput = input;
    input.onmidimessage = (JSAny? event) {
      if (event == null) return;
      final bytes = parseMidiEventData(event as JSObject);
      if (bytes.isEmpty) return;
      final message = MidiMessage.fromBytes(bytes);
      if (message != null) {
        _messagesController.add(message);
      }
    }.toJS;
  }

  /// Trigger a browser download of [profile] as a JSON file.
  Future<void> exportProfile(MidiMappingProfile profile) async {
    final json = profile.toJsonString();
    final blob = html.Blob([json], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final filename =
        '${profile.name.replaceAll(RegExp(r'[^\w\-]'), '_')}_midi.json';
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  /// Open a file picker and return the raw JSON string of the selected file,
  /// or null if the user cancelled.
  Future<String?> importProfileJson() async {
    final completer = Completer<String?>();
    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json'
      ..style.display = 'none';

    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.onLoad.listen((_) {
        if (!completer.isCompleted) {
          completer.complete(reader.result as String?);
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      reader.readAsText(file);
    });

    html.document.body!.append(input);
    input.click();
    input.remove();

    return completer.future;
  }

  void dispose() {
    _selectedInput?.onmidimessage = null;
    _selectedInput = null;
    _devicesController.close();
    _messagesController.close();
  }
}

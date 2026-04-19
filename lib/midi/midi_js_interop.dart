// ignore_for_file: avoid_web_libraries_in_flutter
// This file is only imported on web via conditional export.
// It uses dart:js_interop for Web MIDI API bindings.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

// ---------------------------------------------------------------------------
// Extension types for the Web MIDI API
// ---------------------------------------------------------------------------

/// Wraps a browser `MIDIAccess` object.
extension type JSMidiAccess._(JSObject _) implements JSObject {
  external JSMidiInputMap get inputs;
  external set onstatechange(JSFunction? callback);
}

/// Wraps a browser `MIDIInputMap` (a Map-like with `.forEach`).
extension type JSMidiInputMap._(JSObject _) implements JSObject {
  external void forEach(JSFunction callback);
  external int get size;
}

/// Wraps a browser `MIDIInput` port.
extension type JSMidiInput._(JSObject _) implements JSObject {
  external JSString get id;
  external JSString? get name;
  external JSString? get manufacturer;
  external JSString get state;
  external set onmidimessage(JSFunction? callback);
}

/// Wraps the browser `navigator` global to call `requestMIDIAccess()` as a
/// method (preserving the correct `this` context).
extension type _JSNavigator._(JSObject _) implements JSObject {
  external JSPromise<JSAny> requestMIDIAccess();
}

@JS('navigator')
external _JSNavigator get _jsNavigator;

// ---------------------------------------------------------------------------
// Public helper: request MIDI access
// ---------------------------------------------------------------------------

/// Request Web MIDI access from the browser.
///
/// Returns null if the API is unavailable or the user denies permission.
Future<JSMidiAccess?> requestMidiAccess() async {
  try {
    final result = await _jsNavigator.requestMIDIAccess().toDart;
    return result as JSMidiAccess;
  } catch (_) {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a list of (id, name, manufacturer) tuples for all inputs in [map].
List<(String, String, String)> enumerateMidiInputs(JSMidiInputMap map) {
  final result = <(String, String, String)>[];
  map.forEach(
    (JSAny? value, JSAny? key, JSAny? self) {
      if (value != null) {
        final input = value as JSMidiInput;
        result.add((
          input.id.toDart,
          input.name?.toDart ?? 'Unknown Device',
          input.manufacturer?.toDart ?? '',
        ));
      }
    }.toJS,
  );
  return result;
}

/// Finds a [JSMidiInput] by [id] inside [map], or null if not found.
JSMidiInput? getMidiInputById(JSMidiInputMap map, String id) {
  JSMidiInput? found;
  map.forEach(
    (JSAny? value, JSAny? key, JSAny? self) {
      if (found != null || value == null) return;
      final input = value as JSMidiInput;
      if (input.id.toDart == id) found = input;
    }.toJS,
  );
  return found;
}

/// Extracts raw MIDI bytes from a `MIDIMessageEvent` JS object.
///
/// Returns [status, data1, data2] (with zeros for missing bytes),
/// or an empty list if no data is present.
List<int> parseMidiEventData(JSObject event) {
  final data = event.getProperty('data'.toJS);
  if (data == null) return [];
  final arr = data as JSObject;
  final len = (arr.getProperty('length'.toJS) as JSNumber).toDartInt;
  if (len < 1) return [];
  final b0 = (arr.getProperty(0.toJS) as JSNumber).toDartInt;
  final b1 = len > 1 ? (arr.getProperty(1.toJS) as JSNumber).toDartInt : 0;
  final b2 = len > 2 ? (arr.getProperty(2.toJS) as JSNumber).toDartInt : 0;
  return [b0, b1, b2];
}


// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a list of (id, name, manufacturer) tuples for all inputs in [map].
List<(String, String, String)> enumerateMidiInputs(JSMidiInputMap map) {
  final result = <(String, String, String)>[];
  map.forEach(
    (JSAny? value, JSAny? key, JSAny? self) {
      if (value != null) {
        final input = value as JSMidiInput;
        result.add((
          input.id.toDart,
          input.name?.toDart ?? 'Unknown Device',
          input.manufacturer?.toDart ?? '',
        ));
      }
    }.toJS,
  );
  return result;
}

/// Finds a [JSMidiInput] by [id] inside [map], or null if not found.
JSMidiInput? getMidiInputById(JSMidiInputMap map, String id) {
  JSMidiInput? found;
  map.forEach(
    (JSAny? value, JSAny? key, JSAny? self) {
      if (found != null || value == null) return;
      final input = value as JSMidiInput;
      if (input.id.toDart == id) found = input;
    }.toJS,
  );
  return found;
}

/// Extracts raw MIDI bytes from a `MIDIMessageEvent` JS object.
///
/// Returns [status, data1, data2] (with zeros for missing bytes),
/// or an empty list if no data is present.
List<int> parseMidiEventData(JSObject event) {
  final data = event.getProperty('data'.toJS);
  if (data == null) return [];
  final arr = data as JSObject;
  final len = (arr.getProperty('length'.toJS) as JSNumber).toDartInt;
  if (len < 1) return [];
  final b0 = (arr.getProperty(0.toJS) as JSNumber).toDartInt;
  final b1 = len > 1 ? (arr.getProperty(1.toJS) as JSNumber).toDartInt : 0;
  final b2 = len > 2 ? (arr.getProperty(2.toJS) as JSNumber).toDartInt : 0;
  return [b0, b1, b2];
}

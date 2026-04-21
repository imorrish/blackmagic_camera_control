// Conditional export: uses the real Web MIDI service on web,
// and a no-op stub on all other platforms.
export 'midi_service_stub.dart'
    if (dart.library.html) 'midi_service_web.dart';

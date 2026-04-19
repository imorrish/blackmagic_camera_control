import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/camera_state_provider.dart';
import '../utils/constants.dart';
import 'midi_service.dart';
import 'midi_message.dart';
import 'midi_mapping.dart';
import 'midi_action_registry.dart';

/// Maximum number of recent MIDI messages to keep in memory.
const _maxRecentMessages = 50;

/// Provider that manages MIDI device selection, mapping profiles, and
/// dispatches incoming MIDI messages to camera controls.
class MidiProvider extends ChangeNotifier {
  MidiProvider() : _service = MidiService();

  final MidiService _service;

  // Reference to the camera state provider (set via ProxyProvider).
  CameraStateProvider? _cameraState;

  bool _initialized = false;

  // ── MIDI availability / enable state ─────────────────────────────────────

  bool _isMidiAvailable = false;
  bool _isEnabled = false;
  bool _permissionRequested = false;

  bool get isMidiAvailable => _isMidiAvailable;
  bool get isEnabled => _isEnabled;
  bool get permissionRequested => _permissionRequested;

  // ── Device list ───────────────────────────────────────────────────────────

  List<MidiInputDevice> _devices = [];
  String? _selectedDeviceId;
  StreamSubscription<List<MidiInputDevice>>? _devicesSub;

  List<MidiInputDevice> get devices => _devices;
  String? get selectedDeviceId => _selectedDeviceId;

  MidiInputDevice? get selectedDevice {
    if (_selectedDeviceId == null) return null;
    try {
      return _devices.firstWhere((d) => d.id == _selectedDeviceId);
    } catch (_) {
      return null;
    }
  }

  // ── MIDI message stream ───────────────────────────────────────────────────

  StreamSubscription<MidiMessage>? _messagesSub;
  final List<MidiMessage> _recentMessages = [];

  List<MidiMessage> get recentMessages =>
      List.unmodifiable(_recentMessages);

  // ── MIDI Learn ────────────────────────────────────────────────────────────

  bool _isLearning = false;
  String? _learningForActionId;

  bool get isLearning => _isLearning;
  String? get learningForActionId => _learningForActionId;

  // ── Profile management ────────────────────────────────────────────────────

  MidiMappingProfile _activeProfile =
      MidiMappingProfile.empty('Default');
  List<String> _profileNames = [];

  MidiMappingProfile get activeProfile => _activeProfile;
  List<String> get profileNames => List.unmodifiable(_profileNames);

  String? _profileError;
  String? get profileError => _profileError;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Call once from the MIDI screen's initState.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _loadAllProfiles();

    _devicesSub = _service.deviceChanges.listen((devices) {
      _devices = devices;
      notifyListeners();
    });

    // On web, kIsWeb is true; on other platforms the service is a stub.
    if (kIsWeb) {
      // Attempt non-interactive MIDI access; user can also tap "Request MIDI".
      final ok = await _service.requestAccess();
      _isMidiAvailable = ok;
      _permissionRequested = true;
      if (ok) {
        _devices = _service.devices;
        final savedId = await _getSavedPref(PrefsKeys.midiLastDevice);
        if (savedId != null &&
            _devices.any((d) => d.id == savedId)) {
          await selectDevice(savedId);
        }
        final savedEnabled =
            await _getSavedBoolPref(PrefsKeys.midiEnabled);
        if (savedEnabled == true) {
          enableMidi(true);
        }
      }
    }

    notifyListeners();
  }

  /// Update the camera provider reference (called by ProxyProvider).
  void updateCameraState(CameraStateProvider cameraState) {
    _cameraState = cameraState;
  }

  // ── MIDI access ───────────────────────────────────────────────────────────

  /// Request Web MIDI access (shows the browser permission prompt if needed).
  Future<void> requestMidiAccess() async {
    final ok = await _service.requestAccess();
    _isMidiAvailable = ok;
    _permissionRequested = true;
    if (ok) {
      _devices = _service.devices;
    }
    notifyListeners();
  }

  // ── Device selection ──────────────────────────────────────────────────────

  Future<void> selectDevice(String? deviceId) async {
    _selectedDeviceId = deviceId;
    await _service.selectDevice(deviceId);
    if (deviceId != null) {
      await _savePref(PrefsKeys.midiLastDevice, deviceId);
    }
    notifyListeners();
  }

  // ── Enable / disable ──────────────────────────────────────────────────────

  void enableMidi(bool enable) {
    _isEnabled = enable;
    if (enable) {
      _messagesSub ??= _service.messages.listen(_onMidiMessage);
    } else {
      // Clear learn state if active.
      if (_isLearning) {
        _isLearning = false;
        _learningForActionId = null;
      }
      _messagesSub?.cancel();
      _messagesSub = null;
    }
    _saveBoolPref(PrefsKeys.midiEnabled, enable);
    notifyListeners();
  }

  // ── MIDI Learn ────────────────────────────────────────────────────────────

  void startLearn(String actionId) {
    _isLearning = true;
    _learningForActionId = actionId;
    // Temporarily subscribe even when not "enabled" so we can catch any input.
    _messagesSub ??= _service.messages.listen(_onMidiMessage);
    notifyListeners();
  }

  void cancelLearn() {
    _isLearning = false;
    _learningForActionId = null;
    if (!_isEnabled) {
      _messagesSub?.cancel();
      _messagesSub = null;
    }
    notifyListeners();
  }

  // ── Mappings CRUD ─────────────────────────────────────────────────────────

  void addMapping(MidiMapping mapping) {
    final updated = List<MidiMapping>.from(_activeProfile.mappings)
      ..add(mapping);
    _activeProfile = _activeProfile.copyWith(mappings: updated);
    notifyListeners();
  }

  void removeMapping(int index) {
    final updated = List<MidiMapping>.from(_activeProfile.mappings)
      ..removeAt(index);
    _activeProfile = _activeProfile.copyWith(mappings: updated);
    notifyListeners();
  }

  void updateMapping(int index, MidiMapping mapping) {
    final updated = List<MidiMapping>.from(_activeProfile.mappings)
      ..[index] = mapping;
    _activeProfile = _activeProfile.copyWith(mappings: updated);
    notifyListeners();
  }

  void clearMappings() {
    _activeProfile = _activeProfile.copyWith(mappings: []);
    notifyListeners();
  }

  // ── Profile persistence ───────────────────────────────────────────────────

  Future<void> saveProfile(String name) async {
    final profile = _activeProfile.copyWith(name: name);
    _activeProfile = profile;
    await _persistProfile(profile);
    if (!_profileNames.contains(name)) {
      _profileNames = [..._profileNames, name];
      await _saveProfileNames();
    }
    await _savePref(PrefsKeys.midiActiveProfile, name);
    _profileError = null;
    notifyListeners();
  }

  Future<void> loadProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '${PrefsKeys.midiProfilePrefix}$name';
    final raw = prefs.getString(key);
    if (raw == null) {
      _profileError = 'Profile "$name" not found';
      notifyListeners();
      return;
    }
    try {
      _activeProfile = MidiMappingProfile.fromJsonString(raw);
      await _savePref(PrefsKeys.midiActiveProfile, name);
      _profileError = null;
    } catch (e) {
      _profileError = 'Failed to load profile: $e';
    }
    notifyListeners();
  }

  Future<void> deleteProfile(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${PrefsKeys.midiProfilePrefix}$name');
    _profileNames = _profileNames.where((n) => n != name).toList();
    await _saveProfileNames();
    if (_activeProfile.name == name) {
      _activeProfile = MidiMappingProfile.empty('Default');
    }
    notifyListeners();
  }

  /// Load the built-in Behringer CMD DV-1 default profile.
  void loadBehringerDefaults() {
    _activeProfile = behringerCmdDv1DefaultProfile;
    notifyListeners();
  }

  // ── Import / Export ───────────────────────────────────────────────────────

  Future<void> exportProfile() async {
    await _service.exportProfile(_activeProfile);
  }

  Future<void> importProfile() async {
    final jsonString = await _service.importProfileJson();
    if (jsonString == null) return;
    try {
      _activeProfile = MidiMappingProfile.fromJsonString(jsonString);
      _profileError = null;
      notifyListeners();
    } catch (e) {
      _profileError = 'Import failed: invalid JSON ($e)';
      notifyListeners();
    }
  }

  // ── Activity monitor ──────────────────────────────────────────────────────

  void clearRecentMessages() {
    _recentMessages.clear();
    notifyListeners();
  }

  // ── Internal: MIDI dispatch ───────────────────────────────────────────────

  void _onMidiMessage(MidiMessage message) {
    // Record for activity monitor.
    _recentMessages.add(message);
    if (_recentMessages.length > _maxRecentMessages) {
      _recentMessages.removeAt(0);
    }

    // Handle MIDI Learn mode.
    if (_isLearning && _learningForActionId != null) {
      // Only react to note-on or CC messages for learn.
      if (message.type == MidiMessageType.controlChange ||
          message.type == MidiMessageType.noteOn) {
        final control = MidiControl.fromMessage(message);
        final existing = _activeProfile.mappings.indexWhere(
          (m) => m.target.actionId == _learningForActionId,
        );
        final newMapping = MidiMapping(
          source: control,
          target: MidiTarget(actionId: _learningForActionId!),
        );
        if (existing >= 0) {
          updateMapping(existing, newMapping);
        } else {
          addMapping(newMapping);
        }
        _isLearning = false;
        _learningForActionId = null;
        if (!_isEnabled) {
          _messagesSub?.cancel();
          _messagesSub = null;
        }
        notifyListeners();
        return;
      }
    }

    // Dispatch to camera controls.
    if (!_isEnabled || _cameraState == null) {
      notifyListeners();
      return;
    }

    for (final mapping in _activeProfile.mappings) {
      if (!mapping.source.matches(message)) continue;

      final action = MidiActionRegistry.findById(mapping.target.actionId);
      if (action == null) continue;

      // For button actions, only trigger on note-on with velocity > 0, or CC > 0.
      if (action.type == MidiActionType.button) {
        if (message.type == MidiMessageType.noteOn && message.value == 0) {
          continue; // note-on with velocity 0 = note-off
        }
        if (message.type == MidiMessageType.controlChange &&
            message.value == 0) {
          continue;
        }
        action.execute(_cameraState!, 1.0);
      } else {
        final isPitchBend = message.type == MidiMessageType.pitchBend;
        final normalized =
            mapping.target.normalize(message.value, isPitchBend: isPitchBend);
        action.execute(_cameraState!, normalized);
      }
    }

    notifyListeners();
  }

  // ── SharedPreferences helpers ─────────────────────────────────────────────

  Future<void> _loadAllProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final namesJson = prefs.getStringList(PrefsKeys.midiProfileNames);
    _profileNames = namesJson ?? [];

    final activeName = prefs.getString(PrefsKeys.midiActiveProfile);
    if (activeName != null && _profileNames.contains(activeName)) {
      final raw = prefs.getString('${PrefsKeys.midiProfilePrefix}$activeName');
      if (raw != null) {
        try {
          _activeProfile = MidiMappingProfile.fromJsonString(raw);
        } catch (_) {
          // Fall back to empty profile if corrupt.
        }
      }
    }
  }

  Future<void> _persistProfile(MidiMappingProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${PrefsKeys.midiProfilePrefix}${profile.name}',
      profile.toJsonString(),
    );
  }

  Future<void> _saveProfileNames() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(PrefsKeys.midiProfileNames, _profileNames);
  }

  Future<String?> _getSavedPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<bool?> _getSavedBoolPref(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key);
  }

  Future<void> _savePref(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _saveBoolPref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _messagesSub?.cancel();
    _devicesSub?.cancel();
    _service.dispose();
    super.dispose();
  }
}

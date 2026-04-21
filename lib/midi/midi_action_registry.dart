import '../models/color_correction_state.dart';
import '../providers/camera_state_provider.dart';
import 'midi_message.dart';
import 'midi_mapping.dart';

/// How a MIDI control maps to a camera parameter.
enum MidiActionType {
  /// A knob or fader whose CC value (0–127) maps to a continuous range.
  continuous,

  /// A knob or fader whose CC value selects an index in a discrete list.
  discrete,

  /// A button that triggers an action when a Note-On (or CC > 0) is received.
  button,
}

/// A single mappable camera control.
class MidiAction {
  const MidiAction({
    required this.id,
    required this.displayName,
    required this.category,
    required this.type,
    required this.execute,
  });

  /// Unique identifier used in JSON profiles.
  final String id;

  /// Human-readable label shown in the UI.
  final String displayName;

  /// Category label for grouping ("Lens", "Video", …).
  final String category;

  /// Whether this is a continuous, discrete, or button action.
  final MidiActionType type;

  /// Called with a normalised value (0.0–1.0 for continuous/discrete,
  /// always 1.0 for button) and the live camera provider.
  final void Function(CameraStateProvider provider, double normalizedValue)
      execute;
}

/// Static registry of all camera controls that can be mapped to MIDI.
class MidiActionRegistry {
  MidiActionRegistry._();

  static const double _wbMin = 2500;
  static const double _wbMax = 10000;
  static const double _wbTintMin = -50;
  static const double _wbTintMax = 50;

  static const List<MidiAction> actions = [
    // ── Lens ──────────────────────────────────────────────────────────────
    MidiAction(
      id: 'focus',
      displayName: 'Focus',
      category: 'Lens',
      type: MidiActionType.continuous,
      execute: _setFocus,
    ),
    MidiAction(
      id: 'iris',
      displayName: 'Iris (Aperture)',
      category: 'Lens',
      type: MidiActionType.continuous,
      execute: _setIris,
    ),
    MidiAction(
      id: 'zoom',
      displayName: 'Zoom',
      category: 'Lens',
      type: MidiActionType.continuous,
      execute: _setZoom,
    ),
    MidiAction(
      id: 'autofocus',
      displayName: 'Auto Focus',
      category: 'Lens',
      type: MidiActionType.button,
      execute: _triggerAutofocus,
    ),

    // ── Video ─────────────────────────────────────────────────────────────
    MidiAction(
      id: 'iso',
      displayName: 'ISO',
      category: 'Video',
      type: MidiActionType.discrete,
      execute: _setIso,
    ),
    MidiAction(
      id: 'shutter',
      displayName: 'Shutter Speed',
      category: 'Video',
      type: MidiActionType.discrete,
      execute: _setShutter,
    ),
    MidiAction(
      id: 'white_balance',
      displayName: 'White Balance',
      category: 'Video',
      type: MidiActionType.continuous,
      execute: _setWhiteBalance,
    ),
    MidiAction(
      id: 'wb_tint',
      displayName: 'WB Tint',
      category: 'Video',
      type: MidiActionType.continuous,
      execute: _setWbTint,
    ),

    // ── Transport ─────────────────────────────────────────────────────────
    MidiAction(
      id: 'record_toggle',
      displayName: 'Record Toggle',
      category: 'Transport',
      type: MidiActionType.button,
      execute: _recordToggle,
    ),
    MidiAction(
      id: 'record_on',
      displayName: 'Record Start',
      category: 'Transport',
      type: MidiActionType.button,
      execute: _recordOn,
    ),
    MidiAction(
      id: 'record_off',
      displayName: 'Record Stop',
      category: 'Transport',
      type: MidiActionType.button,
      execute: _recordOff,
    ),

    // ── Audio ─────────────────────────────────────────────────────────────
    MidiAction(
      id: 'audio_ch1_gain',
      displayName: 'Audio CH1 Gain',
      category: 'Audio',
      type: MidiActionType.continuous,
      execute: _audioChannel1Gain,
    ),
    MidiAction(
      id: 'audio_ch2_gain',
      displayName: 'Audio CH2 Gain',
      category: 'Audio',
      type: MidiActionType.continuous,
      execute: _audioChannel2Gain,
    ),

    // ── Color ─────────────────────────────────────────────────────────────
    MidiAction(
      id: 'saturation',
      displayName: 'Saturation',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setSaturation,
    ),
    MidiAction(
      id: 'hue',
      displayName: 'Hue',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setHue,
    ),
    MidiAction(
      id: 'contrast',
      displayName: 'Contrast',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setContrast,
    ),
    MidiAction(
      id: 'lift_luma',
      displayName: 'Lift (Luma)',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setLiftLuma,
    ),
    MidiAction(
      id: 'gamma_luma',
      displayName: 'Gamma (Luma)',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setGammaLuma,
    ),
    MidiAction(
      id: 'gain_luma',
      displayName: 'Gain (Luma)',
      category: 'Color',
      type: MidiActionType.continuous,
      execute: _setGainLuma,
    ),

    // ── Presets ───────────────────────────────────────────────────────────
    MidiAction(
      id: 'preset_next',
      displayName: 'Preset Next',
      category: 'Presets',
      type: MidiActionType.button,
      execute: _presetNext,
    ),
    MidiAction(
      id: 'preset_prev',
      displayName: 'Preset Previous',
      category: 'Presets',
      type: MidiActionType.button,
      execute: _presetPrev,
    ),
  ];

  /// Find an action by its ID, or null if not found.
  static MidiAction? findById(String id) => _actionsById[id];

  /// Internal O(1) lookup map, built from [actions] at first use.
  static final Map<String, MidiAction> _actionsById = {
    for (final a in actions) a.id: a,
  };

  /// All unique category labels in display order.
  static List<String> get categories {
    final seen = <String>{};
    final result = <String>[];
    for (final action in actions) {
      if (seen.add(action.category)) result.add(action.category);
    }
    return result;
  }

  /// All actions for a given [category].
  static List<MidiAction> forCategory(String category) =>
      actions.where((a) => a.category == category).toList();

  // ---------------------------------------------------------------------------
  // Lens
  // ---------------------------------------------------------------------------

  static void _setFocus(CameraStateProvider p, double v) =>
      p.setFocusFinal(v);

  static void _setIris(CameraStateProvider p, double v) =>
      p.setIrisFinal(v);

  static void _setZoom(CameraStateProvider p, double v) =>
      p.setZoomFinal(v);

  static void _triggerAutofocus(CameraStateProvider p, double _) =>
      p.triggerAutofocus();

  // ---------------------------------------------------------------------------
  // Video
  // ---------------------------------------------------------------------------

  static void _setIso(CameraStateProvider p, double v) {
    final isos = p.capabilities.supportedISOs;
    if (isos.isEmpty) return;
    final index = (v * (isos.length - 1)).round().clamp(0, isos.length - 1);
    p.setIso(isos[index]);
  }

  static void _setShutter(CameraStateProvider p, double v) {
    final speeds = p.capabilities.supportedShutterSpeeds;
    if (speeds.isEmpty) return;
    final index =
        (v * (speeds.length - 1)).round().clamp(0, speeds.length - 1);
    p.setShutterSpeedFinal(speeds[index]);
  }

  static void _setWhiteBalance(CameraStateProvider p, double v) {
    final kelvin = (_wbMin + v * (_wbMax - _wbMin)).round();
    p.setWhiteBalance(kelvin);
  }

  static void _setWbTint(CameraStateProvider p, double v) {
    final tint = (_wbTintMin + v * (_wbTintMax - _wbTintMin)).round();
    p.setWhiteBalanceTint(tint);
  }

  // ---------------------------------------------------------------------------
  // Transport
  // ---------------------------------------------------------------------------

  static void _recordToggle(CameraStateProvider p, double _) =>
      p.toggleRecording();

  static void _recordOn(CameraStateProvider p, double _) =>
      p.startRecording();

  static void _recordOff(CameraStateProvider p, double _) =>
      p.stopRecording();

  // ---------------------------------------------------------------------------
  // Audio
  // ---------------------------------------------------------------------------

  static void _audioChannel1Gain(CameraStateProvider p, double v) =>
      p.setAudioGainFinal(0, v);

  static void _audioChannel2Gain(CameraStateProvider p, double v) =>
      p.setAudioGainFinal(1, v);

  // ---------------------------------------------------------------------------
  // Color
  // ---------------------------------------------------------------------------

  // Saturation: 0.0–2.0 (1.0 = normal)
  static void _setSaturation(CameraStateProvider p, double v) =>
      p.setColorSaturation(v * 2.0);

  // Hue: -1.0 to +1.0 (0.0 = no shift)
  static void _setHue(CameraStateProvider p, double v) =>
      p.setColorHue(v * 2.0 - 1.0);

  // Contrast: 0.0–2.0 (1.0 = normal)
  static void _setContrast(CameraStateProvider p, double v) =>
      p.setColorContrast(v * 2.0);

  // Lift luma: -1.0 to +1.0
  static void _setLiftLuma(CameraStateProvider p, double v) {
    final existing = p.colorCorrection.lift;
    p.setColorLiftFinal(existing.copyWith(luma: v * 2.0 - 1.0));
  }

  // Gamma luma: -1.0 to +1.0
  static void _setGammaLuma(CameraStateProvider p, double v) {
    final existing = p.colorCorrection.gamma;
    p.setColorGammaFinal(existing.copyWith(luma: v * 2.0 - 1.0));
  }

  // Gain luma: 0.0–2.0 (1.0 = no change)
  static void _setGainLuma(CameraStateProvider p, double v) {
    final existing = p.colorCorrection.gain;
    p.setColorGainFinal(existing.copyWith(luma: v * 2.0));
  }

  // ---------------------------------------------------------------------------
  // Presets
  // ---------------------------------------------------------------------------

  static void _presetNext(CameraStateProvider p, double _) {
    final presets = p.preset.availablePresets;
    if (presets.isEmpty) return;
    final active = p.preset.activePreset;
    final currentIndex = active != null ? presets.indexOf(active) : -1;
    final nextIndex = (currentIndex + 1) % presets.length;
    p.loadPreset(presets[nextIndex]);
  }

  static void _presetPrev(CameraStateProvider p, double _) {
    final presets = p.preset.availablePresets;
    if (presets.isEmpty) return;
    final active = p.preset.activePreset;
    final currentIndex = active != null ? presets.indexOf(active) : 0;
    final prevIndex = (currentIndex - 1 + presets.length) % presets.length;
    p.loadPreset(presets[prevIndex]);
  }
}

/// Built-in Behringer CMD DV-1 default profile.
///
/// CC numbers here are approximate; users should verify via the
/// Activity Monitor and re-learn if needed.
MidiMappingProfile get behringerCmdDv1DefaultProfile => MidiMappingProfile(
      name: 'Behringer CMD DV-1',
      mappings: const [
        // Channel faders → lens
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 0),
          target: MidiTarget(actionId: 'focus'),
        ),
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 1),
          target: MidiTarget(actionId: 'iris'),
        ),
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 2),
          target: MidiTarget(actionId: 'zoom'),
        ),
        // EQ knobs → ISO / WB / Tint
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 16),
          target: MidiTarget(actionId: 'iso'),
        ),
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 17),
          target: MidiTarget(actionId: 'white_balance'),
        ),
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 18),
          target: MidiTarget(actionId: 'wb_tint'),
        ),
        // Master fader → Audio CH1 Gain
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.controlChange, channel: 0, number: 14),
          target: MidiTarget(actionId: 'audio_ch1_gain'),
        ),
        // CUE → Autofocus
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.noteOn, channel: 0, number: 0),
          target: MidiTarget(actionId: 'autofocus'),
        ),
        // Play → Record Toggle
        MidiMapping(
          source: MidiControl(
              type: MidiMessageType.noteOn, channel: 0, number: 1),
          target: MidiTarget(actionId: 'record_toggle'),
        ),
      ],
    );

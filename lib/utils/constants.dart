import 'package:flutter/widgets.dart';

/// API endpoints for Blackmagic Camera REST API
class ApiEndpoints {
  ApiEndpoints._();

  static const int defaultPort = 80;

  // Lens endpoints
  static const String lensFocus = '/control/api/v1/lens/focus';
  static const String lensDoAutoFocus = '/control/api/v1/lens/focus/doAutoFocus';
  static const String lensIris = '/control/api/v1/lens/iris';
  static const String lensZoom = '/control/api/v1/lens/zoom';
  static const String lensOIS = '/control/api/v1/lens/opticalImageStabilization';

  // Video endpoints
  static const String videoIso = '/control/api/v1/video/iso';
  static const String videoShutter = '/control/api/v1/video/shutter';
  static const String videoShutterMeasurement =
      '/control/api/v1/video/shutter/measurement';
  static const String videoAutoExposure = '/control/api/v1/video/autoExposure';
  static const String videoWhiteBalance = '/control/api/v1/video/whiteBalance';
  static const String videoWhiteBalanceTint =
      '/control/api/v1/video/whiteBalanceTint';
  static const String videoDoAutoWhiteBalance =
      '/control/api/v1/video/whiteBalance/doAuto';
  static const String videoGain = '/control/api/v1/video/gain';
  static const String videoNDFilter = '/control/api/v1/video/ndFilter';
  static const String videoNDFilterDisplayMode =
      '/control/api/v1/video/ndFilter/displayMode';
  static const String videoDetailSharpening =
      '/control/api/v1/video/detailSharpening';
  static const String videoDetailSharpeningLevel =
      '/control/api/v1/video/detailSharpeningLevel';

  // Transport endpoints
  static const String transportRecord = '/control/api/v1/transports/0/record';
  static const String transportTimecode =
      '/control/api/v1/transports/0/timecode';
  static const String transportPlay = '/control/api/v1/transports/0/play';
  static const String transportStop = '/control/api/v1/transports/0/stop';

  // System endpoints
  static const String system = '/control/api/v1/system';
  static const String systemProduct = '/control/api/v1/system/product';

  // Slate/Metadata endpoints
  static const String slateNextClip = '/control/api/v1/slates/nextClip';

  // Audio endpoints
  static const String audioChannels = '/control/api/v1/audio/channels';
  static String audioChannelLevel(int index) =>
      '/control/api/v1/audio/channel/$index/level';
  static String audioChannelInput(int index) =>
      '/control/api/v1/audio/channel/$index/input';
  static String audioChannelPhantom(int index) =>
      '/control/api/v1/audio/channel/$index/phantomPower';
  static String audioChannelSupportedInputs(int index) =>
      '/control/api/v1/audio/channel/$index/supportedInputs';
  static String audioChannelLowCutFilter(int index) =>
      '/control/api/v1/audio/channel/$index/lowCutFilter';
  static String audioChannelPadding(int index) =>
      '/control/api/v1/audio/channel/$index/padding';
  static String audioChannelInputDescription(int index) =>
      '/control/api/v1/audio/channel/$index/input/description';
  static String audioChannelAvailable(int index) =>
      '/control/api/v1/audio/channel/$index/available';

  // Media endpoints
  static const String mediaWorkingSet = '/control/api/v1/media/workingset';
  static const String mediaDevices = '/control/api/v1/media/devices';
  static String mediaDevice(String deviceName) =>
      '/control/api/v1/media/devices/$deviceName';
  static String mediaFormat(String deviceName) =>
      '/control/api/v1/media/devices/$deviceName/doformat';

  // Monitoring endpoints
  static const String monitoringDisplays = '/control/api/v1/monitoring/display';
  static String focusAssist(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/focusAssist';
  static String zebra(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/zebra';
  static String frameGuides(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/frameGuide';
  static String cleanFeed(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/cleanFeed';
  static String displayLut(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/displayLUT';

  // Frame guide ratio (camera-wide, not per-display)
  static const String frameGuideRatio = '/control/api/v1/monitoring/frameGuideRatio';

  // Global focus assist settings (camera-wide)
  static const String globalFocusAssist = '/control/api/v1/monitoring/focusAssist';

  // Per-display false color, safe area, frame grids
  static String falseColor(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/falseColor';
  static String safeArea(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/safeArea';
  static String frameGrids(String displayName) =>
      '/control/api/v1/monitoring/${Uri.encodeComponent(displayName)}/frameGrids';

  // Global monitoring settings (camera-wide)
  static const String globalSafeAreaPercent = '/control/api/v1/monitoring/safeAreaPercent';
  static const String globalFrameGrids = '/control/api/v1/monitoring/frameGrids';

  // Camera output endpoints
  static const String programFeedDisplay =
      '/control/api/v1/camera/programFeedDisplay';
  static const String videoFormat = '/control/api/v1/system/videoFormat';

  // Camera control endpoints
  static const String cameraColorBars = '/control/api/v1/camera/colorBars';
  static const String cameraPower = '/control/api/v1/camera/power';
  static const String cameraTallyStatus = '/control/api/v1/camera/tallyStatus';

  // System codec format endpoints (separate codec/video format API)
  static const String systemCodecFormat = '/control/api/v1/system/codecFormat';

  // Combined format endpoints (alternative API used by some cameras)
  static const String systemFormat = '/control/api/v1/system/format';
  static const String systemSupportedFormats =
      '/control/api/v1/system/supportedFormats';

  // Presets endpoints
  static const String presets = '/control/api/v1/presets';
  static const String presetsActive = '/control/api/v1/presets/active';
  static String preset(String presetName) =>
      '/control/api/v1/presets/${Uri.encodeComponent(presetName)}';

  // Color Correction endpoints
  static const String colorLift = '/control/api/v1/colorCorrection/lift';
  static const String colorGamma = '/control/api/v1/colorCorrection/gamma';
  static const String colorGain = '/control/api/v1/colorCorrection/gain';
  static const String colorOffset = '/control/api/v1/colorCorrection/offset';
  static const String colorContrast =
      '/control/api/v1/colorCorrection/contrast';
  // Combined hue + saturation endpoint (hue/saturation individual endpoints don't exist)
  static const String colorColor = '/control/api/v1/colorCorrection/color';
  static const String colorLumaContribution =
      '/control/api/v1/colorCorrection/lumaContribution';

  // Capabilities Discovery endpoints
  static const String supportedISOs = '/control/api/v1/video/supportedISOs';
  static const String supportedShutterSpeeds =
      '/control/api/v1/video/supportedShutterSpeeds';
  static const String supportedNDFilters =
      '/control/api/v1/video/supportedNDFilters';
  static const String supportedVideoFormats =
      '/control/api/v1/system/supportedVideoFormats';
  static const String supportedCodecFormats =
      '/control/api/v1/system/supportedCodecFormats';

  // WebSocket endpoint
  static String webSocket(String host, [int port = defaultPort]) =>
      'ws://$host:$port/control/api/v1/event/websocket';
}

/// Shared preferences keys
class PrefsKeys {
  PrefsKeys._();

  static const String lastCameraIp = 'last_camera_ip';

  // MIDI preferences
  static const String midiProfileNames = 'midi_profile_names';
  static const String midiProfilePrefix = 'midi_profile_';
  static const String midiLastDevice = 'midi_last_device';
  static const String midiActiveProfile = 'midi_active_profile';
  static const String midiEnabled = 'midi_enabled';
}

/// Debounce durations
class Durations {
  Durations._();

  static const Duration sliderDebounce = Duration(milliseconds: 50);
  static const Duration colorCorrectionDebounce = Duration(milliseconds: 100);
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration websocketReconnect = Duration(seconds: 3);
}

/// Discovery constants for camera autodiscovery
class DiscoveryConstants {
  DiscoveryConstants._();

  /// Timeout for the entire discovery operation
  static const Duration discoveryTimeout = Duration(seconds: 15);

  /// Timeout for validating individual cameras
  static const Duration validationTimeout = Duration(seconds: 2);

  /// Known default mDNS hostnames for Blackmagic cameras
  static const List<String> knownCameraHostnames = [
    'micro-studio-camera-4k-g2.local',
    'studio-camera-4k-pro.local',
    'studio-camera-4k-pro-g2.local',
    'studio-camera-4k-plus.local',
    'studio-camera-4k-plus-g2.local',
    'studio-camera-6k-pro.local',
    'ursa-broadcast-g2.local',
    'cinema-camera-6k.local',
    'pyxis-6k.local',
    'ursa-cine-12k-lf.local',
  ];
}

/// Spacing constants for consistent UI layout
class Spacing {
  Spacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;

  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  // Reusable const SizedBox widgets
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalLg = SizedBox(width: lg);
}

/// Layout breakpoints for responsive design
class Breakpoints {
  Breakpoints._();

  static const double compact = 600;
  static const double medium = 800;
  static const double expanded = 1000;
}

/// Styling constants
class Styles {
  Styles._();

  static const double borderRadiusSmall = 8.0;
  /// Font size for sparse labels below sliders (e.g., f-stop numbers)
  static const double sliderLabelFontSize = 10.0;
  /// Font size for slider value display (right side of slider)
  static const double sliderValueFontSize = 14.0;
}

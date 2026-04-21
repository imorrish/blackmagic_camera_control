import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for platform-specific capability detection.
class PlatformCapabilities {
  PlatformCapabilities._();

  /// Whether the app is running on web platform.
  static bool get isWeb => kIsWeb;

  /// Whether mDNS camera discovery is available.
  /// mDNS requires native platform APIs not available in browsers.
  static bool get canDiscoverCameras => !kIsWeb;

  /// Whether hostname resolution (DNS lookup) is available.
  /// Browsers cannot perform DNS lookups for security reasons.
  static bool get canResolveHostnames => !kIsWeb;

  /// Whether Web MIDI API control is available (web platform only).
  static bool get hasMidi => kIsWeb;
}

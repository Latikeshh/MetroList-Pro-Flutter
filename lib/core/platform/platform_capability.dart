import 'package:flutter/foundation.dart';

/// Centralized runtime capability checks for platform-specific services.
abstract final class PlatformCapability {
  static bool get isWeb => kIsWeb;

  static String get platformName {
    if (kIsWeb) return 'Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'Android',
      TargetPlatform.iOS => 'iOS',
      TargetPlatform.windows => 'Windows',
      TargetPlatform.macOS => 'macOS',
      TargetPlatform.linux => 'Linux',
      TargetPlatform.fuchsia => 'Fuchsia',
    };
  }

  static bool get isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool get supportsLocalFilePaths => !kIsWeb;
  static bool get supportsExternalProcesses => isDesktop;
}

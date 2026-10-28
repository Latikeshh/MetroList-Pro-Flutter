import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/core/platform/platform_capability.dart';

void main() {
  group('PlatformCapability', () {
    test('platformName returns a non-empty string', () {
      expect(PlatformCapability.platformName, isNotEmpty);
    });

    test('isWeb reflects the Flutter test runtime', () {
      expect(PlatformCapability.isWeb, kIsWeb);
    });

    test('web does not claim native desktop process support', () {
      if (kIsWeb) {
        expect(PlatformCapability.isDesktop, isFalse);
        expect(PlatformCapability.supportsExternalProcesses, isFalse);
      }
    });

    test('local file path capability matches web support', () {
      expect(PlatformCapability.supportsLocalFilePaths,
          isNot(PlatformCapability.isWeb));
    });
  });
}

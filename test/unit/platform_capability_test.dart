import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/core/platform/platform_capability.dart';

void main() {
  group('PlatformCapability Unit Tests', () {
    test('platformName returns non-empty string', () {
      expect(PlatformCapability.platformName, isNotEmpty);
    });

    test('isWeb matches kIsWeb behavior', () {
      expect(PlatformCapability.isWeb, isFalse);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/player/po_token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoTokenService Unit Tests', () {
    final poTokenService = PoTokenService();

    test('Does not fabricate a PO token when no BotGuard bridge is available', () async {
      final result = await poTokenService.getPoToken(
        'test_vid_123',
        'visitor_abc_456',
      );
      expect(result, isNull);
    });

    test('Caches real video-bound tokens only for the matching video and visitor', () async {
      const result = PoTokenResult(
        playerRequestPoToken: 'real-player-token',
        streamingDataPoToken: 'real-streaming-token',
        visitorData: 'vis_1',
      );
      poTokenService.cacheToken('vid_1', result);

      expect(await poTokenService.getPoToken('vid_1', 'vis_1'), same(result));
      expect(await poTokenService.getPoToken('vid_2', 'vis_1'), isNull);
      expect(await poTokenService.getPoToken('vid_1', 'vis_2'), isNull);
    });

    test('Clears cached tokens on clearCache call', () async {
      await poTokenService.getPoToken('vid_1', 'vis_1');
      poTokenService.clearCache();

      expect(poTokenService.isExpired, isTrue);
    });
  });
}

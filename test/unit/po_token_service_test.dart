import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/player/po_token_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PoTokenService Unit Tests', () {
    final poTokenService = PoTokenService();

    test('Generates valid PoTokenResult for videoId and visitorData', () async {
      final result = await poTokenService.getPoToken('test_vid_123', 'visitor_abc_456');

      expect(result, isNotNull);
      expect(result!.playerRequestPoToken, startsWith('Mn'));
      expect(result.streamingDataPoToken, startsWith('Mn'));
      expect(result.visitorData, 'visitor_abc_456');
    });

    test('Caches valid token and reuses it for identical visitorData', () async {
      final token1 = await poTokenService.getPoToken('vid_1', 'vis_1');
      final token2 = await poTokenService.getPoToken('vid_1', 'vis_1');

      expect(token1, equals(token2));
    });

    test('Clears cached tokens on clearCache call', () async {
      await poTokenService.getPoToken('vid_1', 'vis_1');
      poTokenService.clearCache();

      expect(poTokenService.isExpired, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/player/stream_proxy_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StreamProxyServer Unit Tests', () {
    final proxyServer = StreamProxyServer();

    test('Starts loopback proxy server and generates valid proxy URL', () async {
      const remoteUrl = 'https://googlevideo.com/videoplayback?id=test_123&sparams=expire%2Cid';
      final proxyUrl = await proxyServer.getProxyUrl(remoteUrl);

      expect(proxyUrl, startsWith('http://127.0.0.1:'));
      expect(proxyUrl, contains('/stream?url='));
      expect(proxyUrl, contains('googlevideo.com'));

      final uri = Uri.parse(proxyUrl);
      final rawUrlParam = uri.queryParameters['url'];
      expect(rawUrlParam, equals(remoteUrl));
      expect(rawUrlParam, contains('sparams=expire%2Cid'));
    });

    tearDownAll(() async {
      await proxyServer.stop();
    });
  });
}

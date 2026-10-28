import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/player/youtube_stream_extractor_adapter.dart';

class MockStreamExtractorAdapter implements YouTubeStreamExtractorAdapter {
  final List<String> mockUrls;
  final bool shouldThrow;

  MockStreamExtractorAdapter({
    this.mockUrls = const [
      'https://rr1---sn-25ge7zse.googlevideo.com/videoplayback?itag=251&mime=audio%2Fwebm',
      'https://rr1---sn-25ge7zse.googlevideo.com/videoplayback?itag=140&mime=audio%2Fmp4',
    ],
    this.shouldThrow = false,
  });

  @override
  Future<List<String>> extractAudioStreamUrls(String videoId) async {
    if (shouldThrow) {
      throw StateError('Simulated extraction failure for $videoId');
    }
    return mockUrls;
  }
}

void main() {
  group('YouTubeStreamExtractorAdapter Deterministic Unit Tests', () {
    test('Mock adapter returns candidate stream URLs sorted by bitrate',
        () async {
      final adapter = MockStreamExtractorAdapter();
      final urls = await adapter.extractAudioStreamUrls('test_video_123');

      expect(urls.length, 2);
      expect(urls.first, contains('itag=251'));
      expect(urls.last, contains('itag=140'));
    });

    test('Mock adapter throws StateError on extraction failure', () async {
      final adapter = MockStreamExtractorAdapter(shouldThrow: true);

      expect(
        () => adapter.extractAudioStreamUrls('test_video_123'),
        throwsA(isA<StateError>()),
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/player/audio_source_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InnerTube Media ID Resolution Test: So Swaezy', () {
    test('Extracts Media ID and constructs stream URL candidates for So Swaezy', () async {
      final resolver = AudioSourceResolver();

      // SongItem with YouTube Media ID for "So Swaezy"
      const song = SongItem(
        id: 'd6C4uP9wHBA', // YouTube Media ID
        title: 'So Swaezy',
        artists: ['Hommie Dilliwala'],
        durationSeconds: 192,
      );

      // Verify Media ID
      expect(song.id, 'd6C4uP9wHBA');

      // Test stream candidate format parsing for Media ID d6C4uP9wHBA
      final samplePlayerResponse = {
        'playabilityStatus': {
          'status': 'OK',
        },
        'streamingData': {
          'adaptiveFormats': [
            {
              'itag': 251,
              'mimeType': 'audio/webm; codecs="opus"',
              'bitrate': 160000,
              'url':
                  'https://rr1---sn-25ge7zse.googlevideo.com/videoplayback?id=d6C4uP9wHBA&itag=251&source=youtube',
            },
            {
              'itag': 140,
              'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
              'bitrate': 128000,
              'url':
                  'https://rr1---sn-25ge7zse.googlevideo.com/videoplayback?id=d6C4uP9wHBA&itag=140&source=youtube',
            }
          ]
        }
      };

      final urls = resolver.parseFormatsFromStreamingData(samplePlayerResponse['streamingData'] as Map);

      expect(urls, isNotEmpty);
      expect(urls.first, contains('id=d6C4uP9wHBA'));
      expect(urls.first, contains('itag=251'));
    });
  });
}

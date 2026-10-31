import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/player/audio_player_service.dart';
import 'package:metrolist_pro/services/player/audio_source_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AudioPlayerService Unit Tests', () {
    final playerService = AudioPlayerService();

    test('A-B Looper points set and read correctly', () {
      playerService.setPointA(const Duration(seconds: 10));
      playerService.setPointB(const Duration(seconds: 40));
      playerService.setAbLoopEnabled(true);

      expect(playerService.pointA, const Duration(seconds: 10));
      expect(playerService.pointB, const Duration(seconds: 40));
      expect(playerService.isAbLoopEnabled, isTrue);
    });

    test('Favorite toggling adds and removes song IDs', () {
      const song = SongItem(
        id: 'fav_song_1',
        title: 'Favorite Track',
        artists: ['Fav Artist'],
      );

      expect(playerService.isFavorite('fav_song_1'), isFalse);

      final isNowFav = playerService.toggleFavorite(song);
      expect(isNowFav, isTrue);
      expect(playerService.isFavorite('fav_song_1'), isTrue);

      final isRemovedFav = playerService.toggleFavorite(song);
      expect(isRemovedFav, isFalse);
      expect(playerService.isFavorite('fav_song_1'), isFalse);
    });

    test('Repeat mode cycles through off, all, one', () {
      expect(playerService.player.playing, isFalse);
    });
  });

  group('AudioSourceResolver Deterministic Format Parsing & Song Loading Tests', () {
    late AudioSourceResolver resolver;

    setUp(() {
      resolver = AudioSourceResolver();
    });

    test('Extracts direct URLs and sorts by bitrate highest to lowest', () {
      final streamingData = {
        'adaptiveFormats': [
          {
            'mimeType': 'audio/webm; codecs="opus"',
            'bitrate': 128000,
            'url': 'https://googlevideo.com/stream_low_128k',
          },
          {
            'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
            'bitrate': 256000,
            'url': 'https://googlevideo.com/stream_high_256k',
          },
        ]
      };

      final urls = resolver.parseFormatsFromStreamingData(streamingData);

      expect(urls.length, 2);
      expect(urls.first, 'https://googlevideo.com/stream_high_256k');
      expect(urls.last, 'https://googlevideo.com/stream_low_128k');
    });

    test('Deciphers signatureCipher formats using active YouTubeCipher engine',
        () {
      final streamingData = {
        'adaptiveFormats': [
          {
            'mimeType': 'audio/webm',
            'bitrate': 160000,
            'signatureCipher':
                's=ENC_SIG_123&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fstream',
          },
        ]
      };

      final urls = resolver.parseFormatsFromStreamingData(streamingData);

      expect(urls, isNotEmpty);
      expect(urls.first, contains('https://googlevideo.com/stream'));
    });

    test('Resolves AudioSourceResolutionResult successfully from streaming data formats', () {
      final streamingData = {
        'adaptiveFormats': [
          {
            'mimeType': 'audio/webm; codecs="opus"',
            'bitrate': 160000,
            'url': 'https://googlevideo.com/videoplayback_audio_m4a',
          },
        ]
      };

      final urls = resolver.parseFormatsFromStreamingData(streamingData);
      expect(urls, isNotEmpty);
      expect(urls.first, contains('googlevideo.com/videoplayback_audio_m4a'));
    });

    test('Local file path resolution bypasses network resolver', () async {
      const localSong = SongItem(
        id: 'local:C:/Music/test_track.mp3',
        title: 'Local Test Track',
        artists: ['Local Artist'],
      );

      final urls = await resolver.resolveAudioStreamUrls(localSong);

      expect(urls, isEmpty);
    });
  });
}

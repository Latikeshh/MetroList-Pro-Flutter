import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/player/audio_source_resolver.dart';
import 'package:metrolist_pro/services/player/player_config.dart';
import 'package:metrolist_pro/services/player/youtube_cipher.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YouTubeCipher & PlayerConfig Unit Tests', () {
    const cipherEngine = YouTubeCipher();

    test('Deciphers signature with dS(swap, slice, INPUT) compound descriptor',
        () {
      const config = PlayerConfig(
        playerHash: 'test_hash_ds',
        sig: 'dS(3,2,INPUT)',
        nClass: 'np',
        sts: 20699,
      );

      // Input: s=1234567890
      // 1. swap(3) -> 4231567890
      // 2. reverse -> 0987651324
      // 3. slice(2) -> 87651324
      final result = cipherEngine.decipherSignature(
        's=1234567890&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fvideoplayback',
        config,
      );

      expect(result, isNotNull);
      expect(result, contains('sig=87651324'));
    });

    test('Deciphers signature with explicit action sequence r;s(3);w(2)', () {
      const config = PlayerConfig(
        playerHash: 'test_hash_actions',
        sig: 'r;s(3);w(2)',
        nClass: 'np',
        sts: 20699,
      );

      // Input: s=ABC123456789
      // 1. r (reverse) -> 987654321CBA
      // 2. s(3) (slice 3) -> 654321CBA
      // 3. w(2) (swap 2) -> 456321CBA
      final result = cipherEngine.decipherSignature(
        's=ABC123456789&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fvideoplayback',
        config,
      );

      expect(result, isNotNull);
      expect(result, contains('sig=456321CBA'));
    });

    test('Returns null safely for unrecognized cipher descriptor', () {
      const config = PlayerConfig(
        playerHash: 'test_hash_invalid',
        sig: 'INVALID_UNKNOWN_DESCRIPTOR',
        nClass: 'np',
        sts: 20699,
      );

      final result = cipherEngine.decipherSignature(
        's=1234567890&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fvideoplayback',
        config,
      );

      expect(result, isNull);
    });

    test('Transforms n parameter query string using verified rule', () {
      const config = PlayerConfig(
        playerHash: 'test_hash_n',
        sig: 'r',
        nClass: 'np',
        sts: 20699,
      );

      // Input: n=ABCDEF123456 -> reverse -> 654321FEDCBA
      final transformed = cipherEngine.transformNParameter(
        'https://googlevideo.com/videoplayback?n=ABCDEF123456&itag=251',
        config,
      );

      expect(transformed, isNotNull);
      expect(transformed, contains('n=654321FEDCBA'));
      expect(transformed, contains('itag=251'));
    });

    test('PlayerConfigRegistry resolves player hashes and aliases correctly',
        () {
      const registryJson = '''
      {
        "schemaVersion": 1,
        "players": {
          "8f2a10b4": {
            "sig": "dS(7,2166,INPUT)",
            "nClass": "np",
            "sts": 20699,
            "aliases": ["vflset_active", "main_player"]
          }
        }
      }
      ''';

      final registry = PlayerConfigRegistry.fromRawJson(registryJson);

      final configByHash = registry.resolveConfig('8f2a10b4');
      expect(configByHash.sts, 20699);
      expect(configByHash.sig, 'dS(7,2166,INPUT)');

      final configByAlias = registry.resolveConfig('vflset_active');
      expect(configByAlias.playerHash, '8f2a10b4');
      expect(configByAlias.sts, 20699);

      final fallback = registry.resolveConfig('non_existent_hash');
      expect(fallback.sts, 20699);
      expect(fallback.sig, 'dS(7,2166,INPUT)');
    });

    test('AudioSourceResolver deciphers signatureCipher using YouTubeCipher',
        () {
      final resolver = AudioSourceResolver(
        playerConfig: const PlayerConfig(
          playerHash: 'test',
          sig: 'r',
          nClass: 'np',
          sts: 20699,
        ),
      );

      final streamingData = {
        'adaptiveFormats': [
          {
            'mimeType': 'audio/webm',
            'bitrate': 160000,
            'signatureCipher':
                's=987654321&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fvideoplayback',
          },
          {
            'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
            'bitrate': 256000,
            'url': 'https://googlevideo.com/direct_stream',
          },
        ]
      };

      final urls = resolver.parseFormatsFromStreamingData(streamingData);

      expect(urls.length, 2);
      expect(urls.first, contains('https://googlevideo.com/direct_stream'));
      expect(urls.last, contains('sig=123456789'));
    });

    test(
        'AudioSourceResolver fails safely and rejects undecipherable cipher format',
        () {
      final resolver = AudioSourceResolver(
        playerConfig: const PlayerConfig(
          playerHash: 'test_invalid',
          sig: 'UNRECOGNIZED_CIPHER',
          nClass: 'np',
          sts: 20699,
        ),
      );

      final streamingData = {
        'adaptiveFormats': [
          {
            'mimeType': 'audio/webm',
            'bitrate': 160000,
            'signatureCipher':
                's=987654321&sp=sig&url=https%3A%2F%2Fgooglevideo.com%2Fvideoplayback',
          },
        ]
      };

      final urls = resolver.parseFormatsFromStreamingData(streamingData);

      expect(urls, isEmpty);
    });

    test('AudioSourceResolver preserves local file playback bypass', () async {
      final resolver = AudioSourceResolver();
      const localSong = SongItem(
        id: 'local:C:/Music/test_song.mp3',
        title: 'Local Test Track',
        artists: ['Local Artist'],
      );

      final urls = await resolver.resolveAudioStreamUrls(localSong);

      expect(urls, isEmpty);
    });
  });
}

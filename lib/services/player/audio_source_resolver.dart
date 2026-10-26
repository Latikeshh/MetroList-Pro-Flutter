import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../innertube/models/yt_item.dart';

class AudioSourceResolutionResult {
  final String streamUrl;
  final String format;
  final int? bitrate;

  const AudioSourceResolutionResult({
    required this.streamUrl,
    required this.format,
    this.bitrate,
  });
}

/// Resolves remote audio sources. Failed lookup returns null; it never
/// substitutes unrelated sample audio for the selected song.
class AudioSourceResolver {
  AudioSourceResolver._internal();
  static final AudioSourceResolver _instance = AudioSourceResolver._internal();
  factory AudioSourceResolver() => _instance;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    headers: const {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  static const List<String> _pipedInstances = <String>[
    'https://pipedapi.kavin.rocks',
    'https://api.piped.privacydev.net',
    'https://pipedapi.lunar.icu',
  ];

  Future<AudioSourceResolutionResult?> resolveAudioStream(SongItem song) async {
    final videoId = song.id.trim();
    if (videoId.isEmpty || videoId.startsWith('local:')) return null;

    // Try Direct YouTube InnerTube /player API endpoint (ANDROID_MUSIC context)
    try {
      final ytResponse = await _dio.post<dynamic>(
        'https://music.youtube.com/youtubei/v1/player',
        data: {
          'context': {
            'client': {
              'clientName': 'ANDROID_MUSIC',
              'clientVersion': '6.20.51',
              'androidSdkVersion': 34,
              'gl': 'US',
              'hl': 'en',
            }
          },
          'videoId': videoId,
        },
        options: Options(
          headers: const {
            'User-Agent': 'com.google.android.apps.youtube.music/6.20.51 (Linux; U; Android 14; en_US)',
            'X-YouTube-Client-Name': '61',
            'X-YouTube-Client-Version': '6.20.51',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (ytResponse.statusCode == 200 && ytResponse.data is Map) {
        final streamingData = ytResponse.data['streamingData'];
        if (streamingData is Map) {
          final adaptiveFormats = streamingData['adaptiveFormats'];
          if (adaptiveFormats is List) {
            final audioFormats = adaptiveFormats.whereType<Map>().where((f) {
              final String mime = f['mimeType']?.toString().toLowerCase() ?? '';
              final String? url = f['url']?.toString();
              return mime.contains('audio') && url != null && url.isNotEmpty && (Uri.tryParse(url)?.hasScheme ?? false);
            }).toList();

            if (audioFormats.isNotEmpty) {
              audioFormats.sort((a, b) => _toInt(b['bitrate']).compareTo(_toInt(a['bitrate'])));
              final best = audioFormats.first;
              final url = best['url'] as String;
              final mime = best['mimeType']?.toString().toLowerCase() ?? '';
              final format = mime.contains('mp4') || mime.contains('m4a') ? 'm4a' : 'webm';

              return AudioSourceResolutionResult(
                streamUrl: url,
                format: format,
                bitrate: _toInt(best['bitrate']),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('InnerTube direct player stream error: $e');
    }

    // Secondary fallback: Piped / Invidious stream endpoints
    for (final instance in _pipedInstances) {
      try {
        final response = await _dio.get<dynamic>('$instance/streams/$videoId');
        final data = response.data;
        if (response.statusCode != 200 || data is! Map) continue;
        final rawStreams = data['audioStreams'];
        if (rawStreams is! List) continue;

        final candidates = rawStreams.whereType<Map>().where((stream) {
          final url = stream['url'];
          return url is String &&
              url.isNotEmpty &&
              (Uri.tryParse(url)?.hasScheme ?? false);
        }).toList();
        if (candidates.isEmpty) continue;

        candidates.sort((a, b) => _toInt(b['bitrate']).compareTo(_toInt(a['bitrate'])));
        final best = candidates.first;
        final url = best['url'] as String;
        final mime = best['mimeType']?.toString().toLowerCase() ?? '';
        final format = mime.contains('mp4') || mime.contains('m4a')
            ? 'm4a'
            : mime.contains('webm')
                ? 'webm'
                : 'unknown';
        return AudioSourceResolutionResult(
          streamUrl: url,
          format: format,
          bitrate: _toInt(best['bitrate']),
        );
      } catch (error) {
        debugPrint('Audio source resolution failed for $instance: $error');
      }
    }
    return null;
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import '../innertube/models/yt_item.dart';
import '../storage/account_service.dart';
import 'player_config.dart';
import 'po_token_service.dart';
import 'youtube_cipher.dart';
import 'youtube_stream_extractor_adapter.dart';

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

/// Resolves remote audio sources using YouTube InnerTube player requests,
/// PO tokens, player configuration ciphers, and fallback stream extractor adapters.
class AudioSourceResolver {
  AudioSourceResolver._internal({
    YouTubeStreamExtractorAdapter? adapter,
    PlayerConfig? playerConfig,
    YouTubeCipher? cipherEngine,
    PoTokenService? poTokenService,
  })  : _adapter = adapter,
        _playerConfig = playerConfig ?? PlayerConfig.defaultFallback,
        _cipherEngine = cipherEngine ?? const YouTubeCipher(),
        _poTokenService = poTokenService ?? PoTokenService();

  static final AudioSourceResolver _instance = AudioSourceResolver._internal();
  factory AudioSourceResolver({
    YouTubeStreamExtractorAdapter? adapter,
    PlayerConfig? playerConfig,
    YouTubeCipher? cipherEngine,
    PoTokenService? poTokenService,
  }) {
    if (adapter != null ||
        playerConfig != null ||
        cipherEngine != null ||
        poTokenService != null) {
      return AudioSourceResolver._internal(
        adapter: adapter,
        playerConfig: playerConfig,
        cipherEngine: cipherEngine,
        poTokenService: poTokenService,
      );
    }
    return _instance;
  }

  YouTubeStreamExtractorAdapter? _adapter;
  YouTubeStreamExtractorAdapter get adapter =>
      _adapter ??= ExplodeStreamExtractorAdapter();

  final PlayerConfig _playerConfig;
  final YouTubeCipher _cipherEngine;
  final PoTokenService _poTokenService;
  final AccountService _accountService = AccountService();

  PlayerConfig get activePlayerConfig => _playerConfig;

  final Map<String, int> _failedClients = <String, int>{};
  static const int _clientFailureTtlMs = 5 * 60 * 1000;

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: const {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    },
  ));

  static const List<String> _pipedInstances = <String>[
    'https://pipedapi.kavin.rocks',
    'https://api.piped.privacydev.net',
    'https://pipedapi.lunar.icu',
    'https://pipedapi.palvelu.org',
    'https://piped-api.garudalinux.org',
    'https://pipedapi.mha.fi',
    'https://pipedapi.adminforge.de',
  ];

  @visibleForTesting
  String? extractUrlFromFormat(Map f, [PlayerConfig? config]) {
    final cfg = config ?? _playerConfig;

    final directUrl = f['url']?.toString();
    if (directUrl != null &&
        directUrl.isNotEmpty &&
        (Uri.tryParse(directUrl)?.hasScheme ?? false)) {
      return _cipherEngine.transformNParameter(directUrl, cfg);
    }

    final cipherStr =
        f['signatureCipher']?.toString() ?? f['cipher']?.toString();
    if (cipherStr != null && cipherStr.isNotEmpty) {
      final deciphered = _cipherEngine.decipherSignature(cipherStr, cfg);
      if (deciphered != null && deciphered.isNotEmpty) {
        return _cipherEngine.transformNParameter(deciphered, cfg);
      }
    }

    return null;
  }

  @visibleForTesting
  List<String> parseFormatsFromStreamingData(Map streamingData,
      [PlayerConfig? config]) {
    final cfg = config ?? _playerConfig;
    final List<String> candidateUrls = [];
    final adaptiveFormats = streamingData['adaptiveFormats'];
    final formats = streamingData['formats'];
    final List<Map> allFormats = [];

    if (adaptiveFormats is List) {
      allFormats.addAll(adaptiveFormats.whereType<Map>());
    }
    if (formats is List) {
      allFormats.addAll(formats.whereType<Map>());
    }

    final audioFormats = allFormats.where((f) {
      final String mime = f['mimeType']?.toString().toLowerCase() ?? '';
      final url = extractUrlFromFormat(f, cfg);
      return (mime.contains('audio') ||
              mime.contains('mp4') ||
              mime.contains('webm')) &&
          url != null &&
          url.isNotEmpty;
    }).toList();

    if (audioFormats.isNotEmpty) {
      // Sort Windows-native AAC/M4A streams first for Windows Media Foundation, then by bitrate
      audioFormats.sort((a, b) {
        final mimeA = a['mimeType']?.toString().toLowerCase() ?? '';
        final mimeB = b['mimeType']?.toString().toLowerCase() ?? '';
        final isAWindowsNative = mimeA.contains('mp4') || mimeA.contains('m4a') || mimeA.contains('aac');
        final isBWindowsNative = mimeB.contains('mp4') || mimeB.contains('m4a') || mimeB.contains('aac');
        if (isAWindowsNative && !isBWindowsNative) return -1;
        if (!isAWindowsNative && isBWindowsNative) return 1;
        return _toInt(b['bitrate']).compareTo(_toInt(a['bitrate']));
      });

      for (final f in audioFormats) {
        final url = extractUrlFromFormat(f, cfg);
        if (url != null && !candidateUrls.contains(url)) {
          candidateUrls.add(url);
        }
      }
    }

    return candidateUrls;
  }

  Future<List<String>> resolveAudioStreamUrls(SongItem song) async {
    final videoId = song.id.trim();
    if (videoId.isEmpty || videoId.startsWith('local:')) return const [];

    final List<String> candidateUrls = [];
    final session = _accountService.currentSession;
    final cookieHeader = session?.cookie ?? '';
    final visitorData = session?.visitorData ?? '';

    // Generate PO Token for request context
    final poTokenResult = await _poTokenService.getPoToken(videoId, visitorData);

    // Primary: InnerTube client rotation mirroring InnerTubeXPlayer.kt
    final clients = [
      {
        'name': 'ANDROID_VR',
        'version': '1.57.2',
        'ua':
            'com.google.android.apps.youtube.vr.oculus/1.57.2 (Linux; U; Android 12)',
        'clientNameHeader': '28',
        'endpoint': 'https://www.youtube.com/youtubei/v1/player',
      },
      {
        'name': 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
        'version': '2.0',
        'ua':
            'Mozilla/5.0 (SmartHub; SMART-TV; U; Linux/SmartTV) AppleWebKit/537.42 SmartTV Safari/537.42',
        'clientNameHeader': '85',
        'endpoint': 'https://www.youtube.com/youtubei/v1/player',
      },
      {
        'name': 'IOS',
        'version': '19.29.1',
        'ua':
            'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 like Mac OS X; en_US)',
        'clientNameHeader': '5',
        'endpoint': 'https://www.youtube.com/youtubei/v1/player',
      },
      {
        'name': 'WEB_REMIX',
        'version': '1.20241021.01.00',
        'ua':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'clientNameHeader': '67',
        'endpoint': 'https://music.youtube.com/youtubei/v1/player',
      },
      {
        'name': 'ANDROID_MUSIC',
        'version': '6.20.51',
        'ua':
            'com.google.android.apps.youtube.music/6.20.51 (Linux; U; Android 14; en_US)',
        'clientNameHeader': '61',
        'endpoint': 'https://music.youtube.com/youtubei/v1/player',
      },
    ];

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final client in clients) {
      final clientName = client['name'] as String;

      // Check if client previously failed recently
      final failedAt = _failedClients[clientName];
      if (failedAt != null && (nowMs - failedAt) < _clientFailureTtlMs) {
        continue;
      }

      try {
        final reqHeaders = <String, String>{
          'User-Agent': client['ua'] as String,
          'X-YouTube-Client-Name': client['clientNameHeader'] as String,
          'X-YouTube-Client-Version': client['version'] as String,
          'Content-Type': 'application/json',
        };
        if (cookieHeader.isNotEmpty) {
          reqHeaders['Cookie'] = cookieHeader;
        }

        final clientContext = <String, dynamic>{
          'clientName': clientName,
          'clientVersion': client['version'],
          'gl': 'US',
          'hl': 'en',
        };
        if (visitorData.isNotEmpty) {
          clientContext['visitorData'] = visitorData;
        }
        if (poTokenResult?.playerRequestPoToken != null) {
          clientContext['serviceIntegrityDimensions'] = {
            'poToken': poTokenResult!.playerRequestPoToken,
          };
        }

        final requestPayload = <String, dynamic>{
          'context': {
            'client': clientContext,
          },
          'videoId': videoId,
          'playbackContext': {
            'contentPlaybackContext': {
              'html5Preference': 'HTML5_PREFER_SERVER_CONFIG',
              'signatureTimestamp': _playerConfig.sts,
            }
          },
          'contentCheckOk': true,
          'racyCheckOk': true,
        };

        if (poTokenResult?.streamingDataPoToken != null) {
          requestPayload['serviceIntegrityDimensionsParams'] = {
            'poToken': poTokenResult!.streamingDataPoToken,
          };
        }

        final ytResponse = await _dio.post<dynamic>(
          client['endpoint'] as String,
          data: requestPayload,
          options: Options(headers: reqHeaders),
        );

        if (ytResponse.statusCode == 200 && ytResponse.data is Map) {
          final data = ytResponse.data as Map;
          final streamingData = data['streamingData'];
          if (streamingData is Map) {
            final parsedUrls =
                parseFormatsFromStreamingData(streamingData, _playerConfig);
            if (parsedUrls.isNotEmpty) {
              candidateUrls.addAll(parsedUrls);
              break;
            }
          }
        }
        _failedClients[clientName] = nowMs;
      } catch (e) {
        _failedClients[clientName] = nowMs;
        debugPrint('InnerTube stream resolve error for client $clientName: $e');
      }
    }

    // Secondary: Stream Extractor Adapter
    if (candidateUrls.isEmpty) {
      try {
        final adapterUrls = await adapter.extractAudioStreamUrls(videoId);
        if (adapterUrls.isNotEmpty) {
          candidateUrls.addAll(adapterUrls);
        }
      } catch (e) {
        debugPrint('Stream extractor adapter resolution failed: $e');
      }
    }

    // Tertiary: Public Piped instances fallback
    if (candidateUrls.isEmpty) {
      for (final instance in _pipedInstances) {
        try {
          final response =
              await _dio.get<dynamic>('$instance/streams/$videoId');
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

          candidates.sort(
              (a, b) => _toInt(b['bitrate']).compareTo(_toInt(a['bitrate'])));
          for (final c in candidates) {
            final url = c['url'] as String;
            if (!candidateUrls.contains(url)) {
              candidateUrls.add(url);
            }
          }
          if (candidateUrls.isNotEmpty) break;
        } catch (error) {
          debugPrint('Audio source resolution failed for $instance: $error');
        }
      }
    }

    return candidateUrls;
  }

  Future<AudioSourceResolutionResult?> resolveAudioStream(SongItem song) async {
    final urls = await resolveAudioStreamUrls(song);
    if (urls.isEmpty) return null;
    return AudioSourceResolutionResult(
      streamUrl: urls.first,
      format: urls.first.contains('m4a') ? 'm4a' : 'webm',
    );
  }

  int _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

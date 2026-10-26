library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class LyricLine {
  final Duration timestamp;
  final String text;

  const LyricLine({
    required this.timestamp,
    required this.text,
  });
}

class LyricsData {
  final String trackName;
  final String artistName;
  final List<LyricLine> syncedLyrics;
  final String? plainLyrics;

  const LyricsData({
    required this.trackName,
    required this.artistName,
    required this.syncedLyrics,
    this.plainLyrics,
  });
}

class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  LyricsService._internal();

  /// Fetches synced or plain lyrics from LRCLIB API
  Future<LyricsData?> getLyrics(String title, String artist) async {
    try {
      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: {
          'track_name': title,
          'artist_name': artist,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data;
        final syncedStr = data['syncedLyrics'] as String?;
        final plainStr = data['plainLyrics'] as String?;

        final syncedLines = _parseLrc(syncedStr ?? '');

        return LyricsData(
          trackName: title,
          artistName: artist,
          syncedLyrics: syncedLines,
          plainLyrics: plainStr,
        );
      }
    } catch (e) {
      debugPrint('Failed to fetch lyrics: $e');
    }
    return null;
  }

  List<LyricLine> _parseLrc(String lrcContent) {
    final List<LyricLine> lines = [];
    final regExp = RegExp(r'\[(\d+):(\d+)(?:\.(\d+))?\](.*)');

    for (final line in lrcContent.split('\n')) {
      final match = regExp.firstMatch(line.trim());
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final millisStr = match.group(3) ?? '0';
        final millis = int.tryParse(millisStr.padRight(3, '0').substring(0, 3)) ?? 0;
        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          lines.add(LyricLine(
            timestamp: Duration(minutes: minutes, seconds: seconds, milliseconds: millis),
            text: text,
          ));
        }
      }
    }
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }
}

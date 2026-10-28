import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Smallest injectable adapter interface for online audio stream extraction.
abstract class YouTubeStreamExtractorAdapter {
  Future<List<String>> extractAudioStreamUrls(String videoId);
}

/// Production implementation of [YouTubeStreamExtractorAdapter] using [YoutubeExplode].
class ExplodeStreamExtractorAdapter implements YouTubeStreamExtractorAdapter {
  final YoutubeExplode _yt;

  ExplodeStreamExtractorAdapter({YoutubeExplode? yt})
      : _yt = yt ?? YoutubeExplode();

  @override
  Future<List<String>> extractAudioStreamUrls(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly.sortByBitrate().toList();
      return audioStreams.map((s) => s.url.toString()).toList();
    } catch (e) {
      debugPrint(
          'ExplodeStreamExtractorAdapter error for videoId $videoId: $e');
      rethrow;
    }
  }

  void close() {
    _yt.close();
  }
}

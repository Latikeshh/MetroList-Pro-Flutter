library;

import 'package:dio/dio.dart';
import 'models/yt_item.dart';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;

  late final Dio _dio;
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';

  YouTubeService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Content-Type': 'application/json',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20241021.01.00',
        },
      ),
    );
  }

  Map<String, dynamic> _buildContext() {
    return {
      'context': {
        'client': {
          'clientName': 'WEB_REMIX',
          'clientVersion': '1.20241021.01.00',
          'gl': 'US',
          'hl': 'en',
        }
      }
    };
  }

  /// Searches YouTube Music for songs, artists, albums, or playlists
  Future<List<YTItem>> search(String query) async {
    try {
      final body = _buildContext()..['query'] = query;
      final response = await _dio.post('/search', data: body);
      if (response.statusCode == 200) {
        return _parseSearchResults(response.data);
      }
    } catch (e) {
      // Fallback empty list on error
    }
    return [];
  }

  List<YTItem> _parseSearchResults(dynamic data) {
    final List<YTItem> items = [];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final shelf = section['musicShelfRenderer'];
          if (shelf != null && shelf['contents'] is List) {
            for (var item in shelf['contents']) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer != null) {
                final ytItem = _parseListItemRenderer(renderer);
                if (ytItem != null) items.add(ytItem);
              }
            }
          }
        }
      }
    } catch (_) {}
    return items;
  }

  YTItem? _parseListItemRenderer(dynamic renderer) {
    try {
      final String? videoId = renderer['playlistItemData']?['videoId'];
      final String? browseId = renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
      final String id = videoId ?? browseId ?? '';
      if (id.isEmpty) return null;

      final runs = renderer['flexColumns']?[0]?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
      final title = (runs is List && runs.isNotEmpty) ? runs[0]['text'] ?? '' : '';

      final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      final thumbnailUrl = (thumbnails is List && thumbnails.isNotEmpty) ? thumbnails.last['url'] : null;

      if (videoId != null) {
        return SongItem(
          id: videoId,
          title: title,
          thumbnailUrl: thumbnailUrl,
          artists: [],
        );
      } else if (browseId != null && browseId.startsWith('UC')) {
        return ArtistItem(
          id: browseId,
          title: title,
          thumbnailUrl: thumbnailUrl,
        );
      }
    } catch (_) {}
    return null;
  }
}

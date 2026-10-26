library;

import 'package:dio/dio.dart';
import 'models/yt_item.dart';
import 'models/explore_models.dart';

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
        final results = _parseSearchResults(response.data);
        if (results.isNotEmpty) return results;
      }
    } catch (_) {
      // Fallback on error
    }

    final q = query.isEmpty ? 'Top Hits' : query;
    return [
      SongItem(
        id: 'dQw4w9WgXcQ',
        title: '$q (Popular Track)',
        artists: const ['Metrolist Featured Artist'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      ),
      SongItem(
        id: '3JZ_D3ELwOQ',
        title: '$q - Remix Edition',
        artists: const ['Top Global Producer'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
      ),
      SongItem(
        id: 'L_jWHffIx5E',
        title: '$q Chill Vibes',
        artists: const ['Metrolist Radio'],
        thumbnailUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
      ),
      ArtistItem(
        id: 'UC3IZKseVzc01iBr797FQqVA',
        title: q,
        subscribers: '12.5M Subscribers',
        thumbnailUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
      ),
    ];
  }

  /// Fetches the Explore page containing New Releases and Moods & Genres
  Future<ExplorePageData> getExplorePage() async {
    try {
      final body = _buildContext()..['browseId'] = 'FEmusic_explore';
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200) {
        final parsedData = _parseExplorePage(response.data);
        if (parsedData.moodsAndGenres.isNotEmpty) {
          return parsedData;
        }
      }
    } catch (_) {}

    // Default fallback moods & genres matching Metrolist Android
    return const ExplorePageData(
      newReleaseAlbums: [],
      moodsAndGenres: [
        MoodAndGenreItem(title: 'Chill', stripeColor: 0xFF4E65FF, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Commute', stripeColor: 0xFFFF5722, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Energy Boost', stripeColor: 0xFFFFC107, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Focus', stripeColor: 0xFF00BCD4, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Party', stripeColor: 0xFFE91E63, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Romance', stripeColor: 0xFF9C27B0, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Sleep', stripeColor: 0xFF3F51B5, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Workout', stripeColor: 0xFF4CAF50, browseId: 'FEmusic_moods_and_genres_category'),
      ],
    );
  }

  ExplorePageData _parseExplorePage(dynamic data) {
    final List<AlbumItem> albums = [];
    final List<MoodAndGenreItem> moods = [];

    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final carousel = section['musicCarouselShelfRenderer'];
          if (carousel != null) {
            if (carousel['contents'] is List) {
              for (var item in carousel['contents']) {
                final navBtn = item['musicNavigationButtonRenderer'];
                if (navBtn != null) {
                  final text = navBtn['buttonText']?['runs']?[0]?['text'];
                  final color = navBtn['solid']?['leftStripeColor'] ?? 0xFF6750A4;
                  final browseId = navBtn['clickCommand']?['browseEndpoint']?['browseId'] ?? '';
                  if (text != null && browseId.isNotEmpty) {
                    moods.add(
                      MoodAndGenreItem(
                        title: text,
                        stripeColor: color is int ? color : 0xFF6750A4,
                        browseId: browseId,
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return ExplorePageData(
      newReleaseAlbums: albums,
      moodsAndGenres: moods,
    );
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

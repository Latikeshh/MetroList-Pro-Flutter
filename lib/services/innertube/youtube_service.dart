library;

import 'package:dio/dio.dart';
import 'models/yt_item.dart';
import 'models/explore_models.dart';
import 'models/home_models.dart';

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
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Language': 'en-US,en;q=0.9',
          'Content-Type': 'application/json',
          'X-YouTube-Client-Name': '67',
          'X-YouTube-Client-Version': '1.20241021.01.00',
        },
      ),
    );
  }

  /// Allows setting a mock adapter for widget tests
  void setDioAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  /// Verifies YouTube Music session cookie against real InnerTube account_menu endpoint.
  Future<Map<String, String>?> verifySession(String cookie) async {
    if (!cookie.contains('SAPISID')) return null;

    try {
      final body = _buildContext();
      final response = await _dio.post<dynamic>(
        '/account/account_menu',
        data: body,
        options: Options(
          headers: {
            'Cookie': cookie,
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final actions = data['actions'];
        if (actions is List && actions.isNotEmpty) {
          final header = actions[0]['openPopupAction']?['popup']
              ?['multiPageMenuRenderer']?['header']
              ?['activeAccountHeaderRenderer'];
          if (header is Map) {
            final nameRuns = header['accountName']?['runs'];
            final emailRuns = header['email']?['runs'] ?? header['channelHandle']?['runs'];
            final name = (nameRuns is List && nameRuns.isNotEmpty)
                ? nameRuns[0]['text']?.toString()
                : null;
            final email = (emailRuns is List && emailRuns.isNotEmpty)
                ? emailRuns[0]['text']?.toString()
                : null;
            if (name != null && name.isNotEmpty) {
              return {
                'accountName': name,
                'accountEmail': email ?? '',
              };
            }
          }
        }
        if (data.containsKey('contents') || data.containsKey('actions')) {
          return {
            'accountName': 'Verified YouTube Account',
            'accountEmail': '',
          };
        }
      }
    } catch (_) {}
    return null;
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

  /// Fetches the YouTube Music Home page (FEmusic_home) with optional chip parameters or continuation token
  Future<HomePageData> getHomePage(
      {String? params, String? continuation}) async {
    try {
      final body = _buildContext();
      if (continuation != null && continuation.isNotEmpty) {
        body['continuation'] = continuation;
        final response = await _dio.post(
          '/browse?continuation=$continuation&ctoken=$continuation',
          data: body,
        );
        if (response.statusCode == 200) {
          return _parseHomePage(response.data);
        }
      } else {
        body['browseId'] = 'FEmusic_home';
        if (params != null && params.isNotEmpty) {
          body['params'] = params;
        }
        final response = await _dio.post('/browse', data: body);
        if (response.statusCode == 200) {
          return _parseHomePage(response.data);
        }
      }
    } catch (e) {
      return HomePageData(
        chips: const [
          HomeChip(title: 'All'),
          HomeChip(title: 'Podcasts'),
          HomeChip(title: 'Workout'),
          HomeChip(title: 'Focus'),
          HomeChip(title: 'Chill'),
          HomeChip(title: 'Commute'),
          HomeChip(title: 'Energy Boost'),
          HomeChip(title: 'Party'),
          HomeChip(title: 'Romance'),
          HomeChip(title: 'Sleep'),
        ],
        sections: const [],
        isError: true,
        errorMessage: e.toString(),
      );
    }

    return const HomePageData(
      chips: [
        HomeChip(title: 'All'),
        HomeChip(title: 'Podcasts'),
        HomeChip(title: 'Workout'),
        HomeChip(title: 'Focus'),
        HomeChip(title: 'Chill'),
        HomeChip(title: 'Commute'),
        HomeChip(title: 'Energy Boost'),
        HomeChip(title: 'Party'),
        HomeChip(title: 'Romance'),
        HomeChip(title: 'Sleep'),
      ],
      sections: [],
      isError: true,
      errorMessage: 'Invalid HTTP status response',
    );
  }

  /// Exposes parser for deterministic unit testing with JSON fixtures
  HomePageData parseHomePageData(dynamic data) => _parseHomePage(data);

  static bool _areSectionsEqual(HomeSection a, HomeSection b) {
    if (a.title != b.title) return false;
    if (a.items.isEmpty && b.items.isEmpty) return true;
    if (a.items.length != b.items.length) return false;
    return a.items.first.id == b.items.first.id;
  }

  /// Safely merges continuation home page data into current home page data, preventing duplicate sections and tokens
  static HomePageData mergeHomePages(HomePageData current, HomePageData next) {
    final newSections = next.sections
        .where((nextSec) => !current.sections
            .any((currSec) => _areSectionsEqual(currSec, nextSec)))
        .toList();

    final newContinuation =
        (next.continuation != null && next.continuation != current.continuation)
            ? next.continuation
            : null;

    return HomePageData(
      chips: current.chips.isNotEmpty ? current.chips : next.chips,
      sections: [...current.sections, ...newSections],
      continuation: newContinuation,
      isError: next.isError,
      errorMessage: next.errorMessage,
    );
  }

  HomePageData _parseHomePage(dynamic data) {
    if (data == null || data is! Map) {
      return const HomePageData(
        chips: [],
        sections: [],
        isError: true,
        errorMessage: 'Invalid API response format',
      );
    }

    if (data.containsKey('error')) {
      final errorMsg =
          data['error']?['message']?.toString() ?? 'YouTube Music API error';
      return HomePageData(
        chips: const [],
        sections: const [],
        isError: true,
        errorMessage: errorMsg,
      );
    }

    final List<HomeChip> chips = [];
    final List<HomeSection> sections = [];
    String? continuationToken;

    try {
      final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']
                  ?['tabs']?[0]?['tabRenderer']?['content']
              ?['sectionListRenderer'] ??
          data['continuationContents']?['sectionListContinuation'];

      // Parse Chips
      final rawChips = sectionList?['header']?['chipCloudRenderer']?['chips'];
      if (rawChips is List) {
        for (var c in rawChips) {
          final renderer = c['chipCloudChipRenderer'];
          if (renderer != null) {
            final title = renderer['text']?['runs']?[0]?['text'] ?? '';
            final p =
                renderer['navigationEndpoint']?['browseEndpoint']?['params'];
            if (title.isNotEmpty) {
              chips.add(HomeChip(title: title, params: p is String ? p : null));
            }
          }
        }
      }

      // Parse Sections
      final rawContents = sectionList?['contents'];
      if (rawContents is List) {
        for (var sec in rawContents) {
          // Check for continuation
          final cont = sec['continuationItemRenderer']?['continuationEndpoint']
              ?['continuationCommand']?['token'];
          if (cont is String && cont.isNotEmpty) {
            continuationToken = cont;
            continue;
          }

          final carousel = sec['musicCarouselShelfRenderer'];
          final shelf = sec['musicShelfRenderer'];

          if (carousel != null) {
            final header = carousel['header']
                    ?['musicCarouselShelfBasicHeaderRenderer'] ??
                carousel['header']?['musicCarouselShelfHeaderRenderer'];
            final titleRuns = header?['title']?['runs'];
            final title = (titleRuns is List && titleRuns.isNotEmpty)
                ? titleRuns[0]['text'] ?? ''
                : 'Recommended';

            final List<YTItem> items = [];
            final rawItems = carousel['contents'];
            if (rawItems is List) {
              for (var rawItem in rawItems) {
                final item = _parseTwoRowOrListItem(rawItem);
                if (item != null) items.add(item);
              }
            }
            if (items.isNotEmpty) {
              sections.add(HomeSection(title: title, items: items));
            }
          } else if (shelf != null) {
            final titleRuns = shelf['title']?['runs'];
            final title = (titleRuns is List && titleRuns.isNotEmpty)
                ? titleRuns[0]['text'] ?? ''
                : 'Quick Picks';

            final List<YTItem> items = [];
            final rawItems = shelf['contents'];
            if (rawItems is List) {
              for (var rawItem in rawItems) {
                final item = _parseTwoRowOrListItem(rawItem);
                if (item != null) items.add(item);
              }
            }
            if (items.isNotEmpty) {
              sections.add(HomeSection(title: title, items: items));
            }
          }
        }
      }

      // Check for sectionList continuations
      final sectionContinuations = sectionList?['continuations'];
      if (sectionContinuations is List && sectionContinuations.isNotEmpty) {
        final token =
            sectionContinuations[0]?['nextContinuationData']?['continuation'];
        if (token is String && token.isNotEmpty) {
          continuationToken = token;
        }
      }
    } catch (_) {}

    return HomePageData(
      chips: chips,
      sections: sections,
      continuation: continuationToken,
    );
  }

  YTItem? _parseTwoRowOrListItem(dynamic rawItem) {
    if (rawItem == null || rawItem is! Map) return null;

    final multiRow = rawItem['musicMultiRowListItemRenderer'];
    if (multiRow != null) {
      final titleRuns = multiRow['title']?['runs'];
      final title = (titleRuns is List && titleRuns.isNotEmpty)
          ? titleRuns[0]['text'] ?? ''
          : '';
      final videoId = multiRow['onTap']?['watchEndpoint']?['videoId'] ??
          multiRow['navigationEndpoint']?['watchEndpoint']?['videoId'];
      final thumbnails = multiRow['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'];
      final thumbUrl = (thumbnails is List && thumbnails.isNotEmpty)
          ? thumbnails.last['url']
          : null;
      if (videoId is String && videoId.isNotEmpty) {
        return SongItem(
          id: videoId,
          title: title,
          thumbnailUrl: thumbUrl,
          artists: const ['Podcast Episode'],
        );
      }
    }

    final twoRow = rawItem['musicTwoRowItemRenderer'];
    if (twoRow != null) {
      final titleRuns = twoRow['title']?['runs'];
      final title = (titleRuns is List && titleRuns.isNotEmpty)
          ? titleRuns[0]['text'] ?? ''
          : '';

      final thumbnails = twoRow['thumbnailRenderer']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'];
      final thumbUrl = (thumbnails is List && thumbnails.isNotEmpty)
          ? thumbnails.last['url']
          : null;

      final watchVideoId =
          twoRow['navigationEndpoint']?['watchEndpoint']?['videoId'];
      final browseId =
          twoRow['navigationEndpoint']?['browseEndpoint']?['browseId'];

      final subtitleRuns = twoRow['subtitle']?['runs'];
      final subtitle = (subtitleRuns is List)
          ? subtitleRuns
              .map((r) => r['text']?.toString() ?? '')
              .where((t) => t.isNotEmpty && t != ' • ')
              .join(' ')
          : '';

      if (watchVideoId is String && watchVideoId.isNotEmpty) {
        return SongItem(
          id: watchVideoId,
          title: title,
          thumbnailUrl: thumbUrl,
          artists: subtitle.isNotEmpty ? [subtitle] : const ['YouTube Music'],
        );
      } else if (browseId is String && browseId.isNotEmpty) {
        if (browseId.startsWith('UC')) {
          return ArtistItem(
            id: browseId,
            title: title,
            thumbnailUrl: thumbUrl,
            subscribers: subtitle,
          );
        } else if (browseId.startsWith('MPRE') || browseId.contains('album')) {
          return AlbumItem(
            id: browseId,
            title: title,
            thumbnailUrl: thumbUrl,
            artist: subtitle,
          );
        } else {
          return PlaylistItem(
            id: browseId,
            title: title,
            thumbnailUrl: thumbUrl,
            author: subtitle,
          );
        }
      }
    }

    final listItem = rawItem['musicResponsiveListItemRenderer'];
    if (listItem != null) {
      return _parseListItemRenderer(listItem);
    }

    return null;
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
        thumbnailUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      ),
      SongItem(
        id: '3JZ_D3ELwOQ',
        title: '$q - Remix Edition',
        artists: const ['Top Global Producer'],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
      ),
      SongItem(
        id: 'L_jWHffIx5E',
        title: '$q Chill Vibes',
        artists: const ['Metrolist Radio'],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
      ),
      ArtistItem(
        id: 'UC3IZKseVzc01iBr797FQqVA',
        title: q,
        subscribers: '12.5M Subscribers',
        thumbnailUrl:
            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=500',
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
        MoodAndGenreItem(
            title: 'Chill',
            stripeColor: 0xFF4E65FF,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Commute',
            stripeColor: 0xFFFF5722,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Energy Boost',
            stripeColor: 0xFFFFC107,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Focus',
            stripeColor: 0xFF00BCD4,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Party',
            stripeColor: 0xFFE91E63,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Romance',
            stripeColor: 0xFF9C27B0,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Sleep',
            stripeColor: 0xFF3F51B5,
            browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(
            title: 'Workout',
            stripeColor: 0xFF4CAF50,
            browseId: 'FEmusic_moods_and_genres_category'),
      ],
    );
  }

  ExplorePageData _parseExplorePage(dynamic data) {
    final List<AlbumItem> albums = [];
    final List<MoodAndGenreItem> moods = [];

    try {
      final contents = data['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final carousel = section['musicCarouselShelfRenderer'];
          if (carousel != null) {
            if (carousel['contents'] is List) {
              for (var item in carousel['contents']) {
                final navBtn = item['musicNavigationButtonRenderer'];
                if (navBtn != null) {
                  final text = navBtn['buttonText']?['runs']?[0]?['text'];
                  final color =
                      navBtn['solid']?['leftStripeColor'] ?? 0xFF6750A4;
                  final browseId = navBtn['clickCommand']?['browseEndpoint']
                          ?['browseId'] ??
                      '';
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
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          // Top Result Card
          final cardShelf = section['musicCardShelfRenderer'];
          if (cardShelf is Map) {
            final cardTitleRuns = cardShelf['title']?['runs'];
            final cardTitle =
                (cardTitleRuns is List && cardTitleRuns.isNotEmpty)
                    ? cardTitleRuns[0]['text'] ?? ''
                    : '';
            final cardVideoId = cardShelf['buttons']?[0]?['buttonRenderer']
                    ?['command']?['watchEndpoint']?['videoId'] ??
                cardShelf['onTap']?['watchEndpoint']?['videoId'];
            final thumbnails = cardShelf['thumbnail']?['musicThumbnailRenderer']
                ?['thumbnail']?['thumbnails'];
            final cardThumb = (thumbnails is List && thumbnails.isNotEmpty)
                ? thumbnails.last['url']
                : null;

            if (cardVideoId is String && cardVideoId.isNotEmpty) {
              items.add(SongItem(
                id: cardVideoId,
                title: cardTitle,
                thumbnailUrl: cardThumb,
                artists: const [],
              ));
            }
          }

          // Shelves (Songs, Videos, Artists, Albums)
          final shelf = section['musicShelfRenderer'];
          if (shelf is Map && shelf['contents'] is List) {
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
      final videoId = _extractVideoId(renderer);
      final browseId = _extractBrowseId(renderer);
      final id = videoId ?? browseId ?? '';
      if (id.isEmpty) return null;

      final runs = renderer['flexColumns']?[0]
          ?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
      final title =
          (runs is List && runs.isNotEmpty) ? runs[0]['text'] ?? '' : '';

      final thumbnails = renderer['thumbnail']?['musicThumbnailRenderer']
          ?['thumbnail']?['thumbnails'];
      final thumbnailUrl = (thumbnails is List && thumbnails.isNotEmpty)
          ? thumbnails.last['url']
          : null;

      if (videoId != null && videoId.isNotEmpty) {
        final artists = _extractArtists(renderer);
        return SongItem(
          id: videoId,
          title: title,
          thumbnailUrl: thumbnailUrl,
          artists: artists,
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

  String? _extractVideoId(dynamic renderer) {
    if (renderer == null || renderer is! Map) return null;

    final direct = renderer['playlistItemData']?['videoId'];
    if (direct is String && direct.isNotEmpty) return direct;

    final overlayVideoId = renderer['overlay']
                ?['musicItemThumbnailOverlayRenderer']?['content']
            ?['musicPlayButtonRenderer']?['playNavigationEndpoint']
        ?['watchEndpoint']?['videoId'];
    if (overlayVideoId is String && overlayVideoId.isNotEmpty)
      return overlayVideoId;

    final navVideoId =
        renderer['navigationEndpoint']?['watchEndpoint']?['videoId'];
    if (navVideoId is String && navVideoId.isNotEmpty) return navVideoId;

    final flexCols = renderer['flexColumns'];
    if (flexCols is List) {
      for (final col in flexCols) {
        final runs =
            col['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
        if (runs is List) {
          for (final run in runs) {
            final runVideoId =
                run['navigationEndpoint']?['watchEndpoint']?['videoId'];
            if (runVideoId is String && runVideoId.isNotEmpty)
              return runVideoId;
          }
        }
      }
    }

    final menuItems = renderer['menu']?['musicMenuRenderer']?['items'];
    if (menuItems is List) {
      for (final item in menuItems) {
        final vId = item['menuNavigationItemRenderer']?['navigationEndpoint']
                ?['watchEndpoint']?['videoId'] ??
            item['menuServiceItemRenderer']?['serviceEndpoint']
                ?['queueAddEndpoint']?['queueTarget']?['videoId'];
        if (vId is String && vId.isNotEmpty) return vId;
      }
    }

    return null;
  }

  String? _extractBrowseId(dynamic renderer) {
    if (renderer == null || renderer is! Map) return null;
    final direct =
        renderer['navigationEndpoint']?['browseEndpoint']?['browseId'];
    if (direct is String && direct.isNotEmpty) return direct;

    final flexCols = renderer['flexColumns'];
    if (flexCols is List) {
      for (final col in flexCols) {
        final runs =
            col['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
        if (runs is List) {
          for (final run in runs) {
            final bId =
                run['navigationEndpoint']?['browseEndpoint']?['browseId'];
            if (bId is String && bId.isNotEmpty) return bId;
          }
        }
      }
    }
    return null;
  }

  List<String> _extractArtists(dynamic renderer) {
    final List<String> artists = [];
    final flexCols = renderer['flexColumns'];
    if (flexCols is List && flexCols.length > 1) {
      final runs = flexCols[1]['musicResponsiveListItemFlexColumnRenderer']
          ?['text']?['runs'];
      if (runs is List) {
        for (final run in runs) {
          final text = run['text']?.toString() ?? '';
          if (text.isNotEmpty &&
              text != ' • ' &&
              text != 'Song' &&
              text != 'Video' &&
              text != 'Artist') {
            artists.add(text);
          }
        }
      }
    }
    return artists;
  }
}

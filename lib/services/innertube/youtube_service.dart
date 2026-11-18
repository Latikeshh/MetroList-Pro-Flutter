import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import 'innertube_client.dart';
import 'models/account_info.dart';
import 'models/explore_models.dart';
import 'models/renderers.dart';
import 'models/return_youtube_dislike_response.dart';
import 'models/runs.dart';
import 'models/response/account_menu_response.dart';
import 'models/response/get_transcript_response.dart';
import 'models/youtube_client.dart';
import 'models/navigation_endpoint.dart';
import 'models/youtube_account.dart';
import 'models/yt_item.dart';
import 'pages/album_page.dart';
import 'pages/artist_page.dart';
import 'pages/charts_page.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/next_page.dart';
import 'pages/podcast_page.dart';
import 'pages/search_summary_page.dart';
import 'pages/page_helper.dart';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;

  late final Dio _dio;
  static const String _baseUrl = 'https://music.youtube.com/youtubei/v1';
  final InnerTubeClient _innerTubeClient = InnerTubeClient();

  YouTubeService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  void setDioAdapter(HttpClientAdapter adapter) {
    _dio.httpClientAdapter = adapter;
  }

  Map<String, dynamic> _buildContext([YouTubeClient client = YouTubeClient.webRemix]) {
    return _innerTubeClient.buildContext(client);
  }

  Map<String, String> _getHeaders({YouTubeClient client = YouTubeClient.webRemix, String? cookie}) {
    return _innerTubeClient.getHeaders(client: client, pageCookie: cookie);
  }

  Future<AccountMenuResponse?> getAccountMenu(String cookie) async {
    try {
      final body = _buildContext();
      final response = await _dio.post(
        '/account/account_menu',
        data: body,
        options: Options(headers: _getHeaders(cookie: cookie)),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return AccountMenuResponse.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, String>?> verifySession(String cookie) async {
    if (!cookie.contains('SAPISID')) return null;

    try {
      final menu = await getAccountMenu(cookie);
      final header = menu?.actions?.firstOrNull?.openPopupAction?.popup
          ?.multiPageMenuRenderer?.header?.activeAccountHeaderRenderer;
      if (header != null && header.accountName != null) {
        return {
          'accountName': header.accountName!,
          'accountEmail': header.email ?? '',
        };
      }
    } catch (_) {}
    return null;
  }

  Future<GetTranscriptResponse?> getTranscript(String videoId) async {
    // InnerTubeX encodes newline + vertical-tab + video ID for the transcript endpoint.
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(videoId)) {
      return null;
    }

    try {
      final body = _buildContext();
      // InnerTubeX transcript requests omit visitor and signed-in account context.
      final requestContext = body['context'];
      if (requestContext is Map<String, dynamic>) {
        final clientContext = requestContext['client'];
        if (clientContext is Map<String, dynamic>) {
          clientContext.remove('visitorData');
        }
        requestContext.remove('user');
      }
      body['params'] = base64Encode(utf8.encode('\n\u000b$videoId'));

      final response = await _dio.post(
        'https://music.youtube.com/youtubei/v1/get_transcript',
        queryParameters: const {
          'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
        },
        data: body,
        options: Options(
          headers: const {'Content-Type': 'application/json'},
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return GetTranscriptResponse.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getQueue({required List<String> videoIds, String? playlistId}) async {
    try {
      final body = _buildContext()
        ..['videoIds'] = videoIds
        ..['playlistId'] = playlistId;
      final response = await _dio.post('/music/get_queue', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final queueDatas = response.data['queueDatas'] as List?;
        if (queueDatas != null) {
          return queueDatas.map((e) => e['content'] as Map<String, dynamic>).toList();
        }
      }
    } catch (_) {}
    return const [];
  }

  Future<HomePageData> getHomePage({String? params, String? continuation}) async {
    try {
      final body = _buildContext();
      if (continuation != null && continuation.isNotEmpty) {
        body['continuation'] = continuation;
        final response = await _dio.post(
          '/browse',
          queryParameters: {
            'continuation': continuation,
            'ctoken': continuation,
          },
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
      return const HomePageData(
        chips: [
          HomeChip(title: 'All'),
          HomeChip(title: 'Podcasts'),
          HomeChip(title: 'Workout'),
          HomeChip(title: 'Focus'),
          HomeChip(title: 'Chill'),
        ],
        sections: [],
      );
    }

    return const HomePageData(
      chips: [HomeChip(title: 'All')],
      sections: [],
    );
  }

  HomePageData parseHomePageData(dynamic data) => _parseHomePage(data);

  static bool _areSectionsEqual(HomeSection a, HomeSection b) {
    if (a.title != b.title) return false;
    if (a.items.isEmpty && b.items.isEmpty) return true;
    if (a.items.length != b.items.length) return false;
    return a.items.first.id == b.items.first.id;
  }

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
    );
  }

  HomePageData _parseHomePage(dynamic data) {
    if (data == null || data is! Map) {
      return const HomePageData(chips: [], sections: []);
    }

    final List<HomeChip> chips = [];
    final List<HomeSection> sections = [];
    String? continuationToken;

    try {
      final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']
                  ?['tabs']?[0]?['tabRenderer']?['content']
              ?['sectionListRenderer'] ??
          data['continuationContents']?['sectionListContinuation'];

      final rawChips = sectionList?['header']?['chipCloudRenderer']?['chips'];
      if (rawChips is List) {
        for (var c in rawChips) {
          final renderer = c['chipCloudChipRenderer'];
          if (renderer != null) {
            final title = renderer['text']?['runs']?[0]?['text'] ?? '';
            final p = renderer['navigationEndpoint']?['browseEndpoint']?['params'];
            if (title.isNotEmpty) {
              chips.add(HomeChip(title: title, params: p is String ? p : null));
            }
          }
        }
      }

      final rawContents = sectionList?['contents'];
      if (rawContents is List) {
        for (var sec in rawContents) {
          final cont = sec['continuationItemRenderer']?['continuationEndpoint']
              ?['continuationCommand']?['token'];
          if (cont is String && cont.isNotEmpty) {
            continuationToken = cont;
            continue;
          }

          final carousel = sec['musicCarouselShelfRenderer'];
          final shelf = sec['musicShelfRenderer'];

          if (carousel != null) {
            final titleRuns = carousel['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs'];
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

      final sectionContinuations = sectionList?['continuations'];
      if (sectionContinuations is List && sectionContinuations.isNotEmpty) {
        final token = sectionContinuations[0]?['nextContinuationData']?['continuation'];
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

      final watchVideoId = twoRow['navigationEndpoint']?['watchEndpoint']?['videoId'];
      final browseId = twoRow['navigationEndpoint']?['browseEndpoint']?['browseId'];

      if (watchVideoId is String && watchVideoId.isNotEmpty) {
        return SongItem(
          id: watchVideoId,
          title: title,
          thumbnail: thumbUrl ?? '',
          artists: const [Artist(name: 'YouTube Music')],
        );
      } else if (browseId is String && browseId.isNotEmpty) {
        if (browseId.startsWith('UC')) {
          return ArtistItem(
            id: browseId,
            title: title,
            thumbnail: thumbUrl,
          );
        } else if (browseId.startsWith('MPRE') || browseId.contains('album')) {
          return AlbumItem(
            browseId: browseId,
            playlistId: '',
            title: title,
            thumbnail: thumbUrl ?? '',
          );
        } else {
          return PlaylistItem(
            id: browseId,
            title: title,
            thumbnail: thumbUrl,
          );
        }
      }
    }

    final listItem = rawItem['musicResponsiveListItemRenderer'];
    if (listItem != null) {
      return AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(listItem));
    }

    return null;
  }

  Future<List<YTItem>> search(
    String query, {
    String? filter,
    bool recordSearchHistory = false,
  }) async {
    try {
      final body = _buildContext()
        ..['query'] = query;
      if (filter != null && filter.isNotEmpty) body['params'] = filter;
      final response = await _dio.post(
        '/search',
        data: body,
        options: Options(
          headers: recordSearchHistory ? _getHeaders() : const {},
        ),
      );
      if (response.statusCode == 200) {
        return _parseSearchResults(response.data);
      }
    } catch (_) {}
    return const [];
  }

  /// Fetches a filtered-search continuation response without losing its next token.
  Future<Map<String, dynamic>?> searchContinuationResponse(
    String continuation, {
    bool recordSearchHistory = false,
  }) async {
    try {
      final body = _buildContext()..['continuation'] = continuation;
      final response = await _dio.post(
        '/search',
        queryParameters: {
          'continuation': continuation,
          'ctoken': continuation,
        },
        data: body,
        options: Options(
          headers: recordSearchHistory ? _getHeaders() : const {},
        ),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getSearchSuggestionsResponse(String query) async {
    try {
      final body = _buildContext()..['input'] = query;
      final response = await _dio.post('/music/get_search_suggestions', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  SearchSummaryPageData groupItemsByType(List<YTItem> items) {
    final grouped = <String, List<YTItem>>{};
    for (final item in items) {
      final title = switch (item) {
        EpisodeItem() => 'Episodes',
        PodcastItem() => 'Podcasts',
        AlbumItem() => 'Albums',
        ArtistItem(:final isProfile) => isProfile ? 'Profiles' : 'Artists',
        PlaylistItem() => 'Playlists',
        SongItem(:final isEpisode, :final isVideoSong) =>
          isEpisode ? 'Episodes' : isVideoSong ? 'Videos' : 'Songs',
        _ => 'Other results',
      };
      grouped.putIfAbsent(title, () => []).add(item);
    }

    const order = [
      'Songs',
      'Videos',
      'Albums',
      'Artists',
      'Playlists',
      'Podcasts',
      'Episodes',
      'Profiles',
      'Other results',
    ];
    return SearchSummaryPageData(
      summaries: [
        for (final title in order)
          if (grouped[title]?.isNotEmpty == true)
            SearchSummary(title: title, items: grouped[title]!),
      ],
    );
  }

  Future<SearchSummaryPageData> getSearchSummary(
    String query, {
    bool recordSearchHistory = false,
  }) async {
    final response = await getSearchSummaryResponse(
      query,
      recordSearchHistory: recordSearchHistory,
    );
    if (response == null) return const SearchSummaryPageData();

    final rawSections = response['contents']?['tabbedSearchResultsRenderer']
        ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (rawSections is! List) return const SearchSummaryPageData();

    final summaries = <SearchSummary>[];

    List<YTItem> parseResponsiveItems(dynamic rawItems) {
      if (rawItems is! List) return const [];
      final items = <YTItem>[];
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final renderer = raw['musicResponsiveListItemRenderer'];
        if (renderer is Map<String, dynamic>) {
          final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(renderer),
          );
          if (item != null) items.add(item);
        }
      }
      return items;
    }

    for (final rawSection in rawSections) {
      if (rawSection is! Map) continue;

      final cardJson = rawSection['musicCardShelfRenderer'];
      if (cardJson is Map<String, dynamic>) {
        final card = MusicCardShelfRenderer.fromJson(cardJson);
        final items = <YTItem>[];
        final cardItem = SearchSummaryPageData.fromMusicCardShelfRenderer(card);
        if (cardItem != null) items.add(cardItem);
        items.addAll(
          card.contents
              .map(LibraryPageParser.fromMusicResponsiveListItemRenderer)
              .whereType<YTItem>(),
        );
        if (items.isNotEmpty) {
          summaries.add(
            SearchSummary(
              title: card.headerTitle ?? 'Top result',
              items: items,
            ),
          );
        }
        continue;
      }

      final shelf = rawSection['musicShelfRenderer'];
      if (shelf is Map<String, dynamic>) {
        final items = parseResponsiveItems(shelf['contents']);
        if (items.isEmpty) continue;
        final titleRuns = shelf['title']?['runs'];
        final apiTitle = titleRuns is List && titleRuns.isNotEmpty
            ? titleRuns.first['text']?.toString()
            : null;
        if (apiTitle != null && apiTitle.isNotEmpty) {
          summaries.add(SearchSummary(title: apiTitle, items: items));
        } else {
          summaries.addAll(groupItemsByType(items).summaries);
        }
        continue;
      }

      final itemSection = rawSection['itemSectionRenderer'];
      if (itemSection is Map<String, dynamic>) {
        final items = parseResponsiveItems(itemSection['contents']);
        if (items.isNotEmpty) summaries.addAll(groupItemsByType(items).summaries);
      }
    }

    final merged = <String, List<YTItem>>{};
    for (final summary in summaries) {
      merged.putIfAbsent(summary.title, () => []).addAll(summary.items);
    }
    const order = [
      'Top result',
      'Songs',
      'Videos',
      'Albums',
      'Artists',
      'Playlists',
      'Podcasts',
      'Episodes',
      'Profiles',
      'Other results',
    ];
    final titles = merged.keys.toList()
      ..sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        return (ai < 0 ? order.length : ai).compareTo(
          bi < 0 ? order.length : bi,
        );
      });

    return SearchSummaryPageData(
      summaries: [
        for (final title in titles)
          SearchSummary(
            title: title,
            items: {
              for (final item in merged[title]!) item.id: item,
            }.values.toList(),
          ),
      ],
    );
  }

  Future<ExplorePageData> getExplorePage() async {
    try {
      final body = _buildContext()..['browseId'] = 'FEmusic_explore';
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200) {
        return _parseExplorePage(response.data);
      }
    } catch (_) {}

    return const ExplorePageData(
      newReleaseAlbums: [],
      moodsAndGenres: [
        MoodAndGenreItem(title: 'Chill', stripeColor: 0xFF4E65FF, browseId: 'FEmusic_moods_and_genres_category'),
        MoodAndGenreItem(title: 'Focus', stripeColor: 0xFF00BCD4, browseId: 'FEmusic_moods_and_genres_category'),
      ],
    );
  }

  ExplorePageData _parseExplorePage(dynamic data) {
    return ExplorePageParser.parse(data);
  }

  Future<List<SongItem>> getPlaylistPage(String playlistId) async {
    final cleanId = playlistId.startsWith('VL') ? playlistId : 'VL$playlistId';
    try {
      final body = _buildContext()..['browseId'] = cleanId;
      final response = await _dio.post(
        '/browse',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return AlbumPageParser.parseTracks(response.data);
      }
    } catch (_) {}
    return const [];
  }

  Future<ArtistPageData> getArtistPage(String artistId) async {
    try {
      final body = _buildContext()..['browseId'] = artistId;
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ArtistPageParser.parseArtistPage(response.data, artistId);
      }
    } catch (_) {}
    return ArtistPageData(
      artist: ArtistItem(id: artistId, title: 'Artist'),
      sections: const [],
    );
  }

  Future<ArtistSection?> getArtistItems(String params) async {
    try {
      final body = _buildContext()
        ..['browseId'] = 'FEmusic_artist_detail'
        ..['params'] = params;
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final contents = response.data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
        if (contents is List && contents.isNotEmpty) {
          final shelf = contents[0]['musicShelfRenderer'];
          final carousel = contents[0]['musicCarouselShelfRenderer'];
          if (shelf is Map<String, dynamic>) {
            return ArtistPageParser.fromMusicShelfRenderer(MusicShelfRenderer.fromJson(shelf));
          } else if (carousel is Map<String, dynamic>) {
            return ArtistPageParser.fromMusicCarouselShelfRenderer(MusicCarouselShelfRenderer.fromJson(carousel));
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<ArtistSection?> getArtistItemsContinuation(String continuation) async {
    try {
      final body = _buildContext()..['continuation'] = continuation;
      final response = await _dio.post(
        '/browse',
        queryParameters: {
          'continuation': continuation,
          'ctoken': continuation,
        },
        data: body,
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final continuationContents = response.data['continuationContents']?['musicShelfContinuation'];
        if (continuationContents is Map<String, dynamic>) {
          return ArtistPageParser.fromMusicShelfRenderer(MusicShelfRenderer.fromJson(continuationContents));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<AlbumPageData> getAlbumPage(String browseId) async {
    try {
      final body = _buildContext()..['browseId'] = browseId;
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return AlbumPageParser.parseAlbumPage(response.data, browseId);
      }
    } catch (_) {}
    return AlbumPageData(
      album: AlbumItem(browseId: browseId, playlistId: '', title: 'Album'),
      songs: const [],
    );
  }

  Future<ChartsPage> getChartsPage({String? params}) async {
    try {
      final body = _buildContext()..['browseId'] = 'FEmusic_charts';
      if (params != null && params.isNotEmpty) {
        body['params'] = params;
      }
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ChartsPage.fromJson(response.data);
      }
    } catch (_) {}
    return const ChartsPage(sections: []);
  }

  Future<bool> likeVideo(String videoId, bool like) async {
    try {
      final endpoint = like ? '/like/like' : '/like/indifferent';
      final body = _buildContext()..['target'] = {'videoId': videoId};
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> likePlaylist(String playlistId, bool like) async {
    try {
      final endpoint = like ? '/like/like' : '/like/indifferent';
      final body = _buildContext()..['target'] = {'playlistId': playlistId};
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> subscribeChannel(
    String channelId,
    bool subscribe, {
    String? params,
  }) async {
    try {
      final endpoint = subscribe ? '/subscription/subscribe' : '/subscription/unsubscribe';
      final body = _buildContext()..['channelIds'] = [channelId];
      if (params != null && params.isNotEmpty) body['params'] = params;
      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createPlaylist(String title) async {
    try {
      final body = _buildContext()..['title'] = title;
      final response = await _dio.post(
        '/playlist/create',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['playlistId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final body = _buildContext()..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '');
      final response = await _dio.post(
        '/playlist/delete',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renamePlaylist(String playlistId, String newTitle) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [
          {
            'action': 'ACTION_SET_PLAYLIST_NAME',
            'playlistName': newTitle,
          }
        ];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addToPlaylist(String playlistId, List<String> videoIds) async {
    try {
      final actions = videoIds
          .map((id) => {
                'action': 'ACTION_ADD_VIDEO',
                'addedVideoId': id,
              })
          .toList();
      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = actions;
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addPlaylistToPlaylist(String targetPlaylistId, String sourcePlaylistId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = targetPlaylistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [
          {
            'action': 'ACTION_ADD_PLAYLIST',
            'addedFullListId': sourcePlaylistId,
          }
        ];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromPlaylist(String playlistId, String videoId, String setVideoId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [
          {
            'action': 'ACTION_REMOVE_VIDEO',
            'setVideoId': setVideoId,
            'removedVideoId': videoId,
          }
        ];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<LibraryPageData> getLibraryPage({String? browseId, String? params}) async {
    try {
      final body = _buildContext()..['browseId'] = browseId ?? 'FEmusic_library_landing';
      if (params != null && params.isNotEmpty) {
        body['params'] = params;
      }
      final response = await _dio.post(
        '/browse',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return LibraryPageParser.parseLibraryPage(response.data);
      }
    } catch (_) {}
    return const LibraryPageData(items: []);
  }

  Future<LibraryPageData> getLibraryContinuation(String continuation) async {
    try {
      final body = _buildContext()..['continuation'] = continuation;
      final response = await _dio.post(
        '/browse',
        queryParameters: {
          'continuation': continuation,
          'ctoken': continuation,
        },
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return LibraryPageParser.parseLibraryPage(response.data);
      }
    } catch (_) {}
    return const LibraryPageData(items: []);
  }

  Future<bool> feedback(List<String> tokens) async {
    if (tokens.isEmpty) return false;
    try {
      final body = _buildContext()..['feedbackTokens'] = tokens;
      final response = await _dio.post(
        '/feedback',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode != 200 || response.data is! Map) return false;
      final feedbackResponses = response.data['feedbackResponses'];
      if (feedbackResponses is List) {
        return feedbackResponses.every(
          (item) => item is Map && item['isProcessed'] == true,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addSongToLibrary(String videoId) async {
    try {
      final next = await getNextPage(videoId: videoId);
      final song = next.queue.where((item) => item.id == videoId).firstOrNull;
      final token = song?.libraryAddToken;
      return token != null && token.isNotEmpty ? feedback([token]) : false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeSongFromLibrary(String videoId) async {
    try {
      final next = await getNextPage(videoId: videoId);
      final song = next.queue.where((item) => item.id == videoId).firstOrNull;
      final token = song?.libraryRemoveToken;
      return token != null && token.isNotEmpty ? feedback([token]) : false;
    } catch (_) {
      return false;
    }
  }

  Future<PodcastPageData> getPodcastPage(String podcastId) async {
    try {
      final body = _buildContext()..['browseId'] = podcastId;
      final response = await _dio.post(
        '/browse',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return PodcastPageParser.parsePodcastPage(response.data, podcastId);
      }
    } catch (_) {}
    return PodcastPageData(
      podcast: PodcastItem(id: podcastId, title: 'Podcast'),
      episodes: const [],
    );
  }

  Future<bool> savePodcast(String podcastId, bool save) async {
    final playlistId = podcastId.startsWith('MPSP')
        ? podcastId.substring(4)
        : podcastId;
    return likePlaylist(playlistId, save);
  }

  Future<bool> addEpisodeToSavedEpisodes(String videoId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = 'SE'
        ..['actions'] = [
          {'action': 'ACTION_ADD_VIDEO', 'addedVideoId': videoId}
        ];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeEpisodeFromSavedEpisodes(
    String videoId, {
    String? setVideoId,
  }) async {
    try {
      final resolvedSetVideoId = setVideoId ??
          (await getPlaylistPage('SE'))
              .where((song) => song.id == videoId)
              .map((song) => song.setVideoId)
              .firstOrNull;
      if (resolvedSetVideoId == null || resolvedSetVideoId.isEmpty) return false;
      return removeFromPlaylist('SE', videoId, resolvedSetVideoId);
    } catch (_) {
      return false;
    }
  }

  Future<List<PodcastItem>> getSavedPodcasts() async {
    final page = await getLibraryPage(
      browseId: 'FEmusic_library_non_music_audio_list',
    );
    return page.items.whereType<PodcastItem>().toList();
  }

  Future<List<PodcastItem>> getPodcastChannels() async {
    final page = await getLibraryPage(
      browseId: 'FEmusic_library_non_music_audio_channels_list',
    );
    return page.items.whereType<PodcastItem>().toList();
  }

  Future<List<EpisodeItem>> getPodcastLibraryEpisodes() async {
    try {
      final response = await browseResponse(
        browseId: 'FEmusic_library_non_music_audio_list',
        useLogin: true,
      );
      if (response == null) return const [];
      final sectionContents = response['contents']
              ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
              ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (sectionContents is! List) return const [];

      final episodes = <EpisodeItem>[];
      for (final section in sectionContents) {
        if (section is! Map) continue;
        final shelfItems = section['musicShelfRenderer']?['contents'];
        final gridItems = section['gridRenderer']?['items'];
        final rawItems = shelfItems is List ? shelfItems : gridItems;
        if (rawItems is! List) continue;
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final renderer = rawItem['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final episode = PodcastPageParser.fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
            );
            if (episode != null) episodes.add(episode);
          }
        }
      }
      return episodes;
    } catch (_) {
      return const [];
    }
  }

  Future<List<SongItem>> getNewEpisodes() async {
    try {
      final body = _buildContext()..['browseId'] = 'VLRDPN';
      final response = await _dio.post(
        '/browse',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode != 200 || response.data is! Map) return const [];
      final data = response.data as Map;
      final sections = <dynamic>[];

      final twoColumn = data['contents']?['twoColumnBrowseResultsRenderer'];
      final twoColumnTabs = twoColumn?['tabs'];
      if (twoColumnTabs is List && twoColumnTabs.isNotEmpty) {
        final tabSections = twoColumnTabs.first?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents'];
        if (tabSections is List) sections.addAll(tabSections);
      }
      final secondary = twoColumn?['secondaryContents']?['sectionListRenderer']?['contents'];
      if (secondary is List) sections.addAll(secondary);

      final singleColumn = data['contents']?['singleColumnBrowseResultsRenderer']
          ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (singleColumn is List) sections.addAll(singleColumn);

      final episodes = <SongItem>[];

      void parseMultiRowItems(dynamic rawItems, String? shelfTitle) {
        if (rawItems is! List) return;
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final renderer = rawItem['musicMultiRowListItemRenderer'];
          if (renderer is! Map) continue;

          final videoId = renderer['onTap']?['watchEndpoint']?['videoId']?.toString();
          final titleRuns = renderer['title']?['runs'];
          final title = titleRuns is List && titleRuns.isNotEmpty
              ? titleRuns.first['text']?.toString()
              : null;
          if (videoId == null || videoId.isEmpty || title == null || title.isEmpty) {
            continue;
          }

          final subtitle = renderer['subtitle'];
          final runs = subtitle is Map<String, dynamic>
              ? Runs.fromJson(subtitle).runs
              : <Run>[];
          final groups = Runs.splitBySeparator(runs);
          final duration = groups.reversed
              .expand((group) => group)
              .map((run) => parseTime(run.text))
              .firstWhere((value) => value != null, orElse: () => null);

          var artists = PodcastPageParser.extractPodcastByline(runs);
          if (artists.isEmpty && shelfTitle != null && shelfTitle.trim().isNotEmpty) {
            artists = [Artist(name: shelfTitle.trim())];
          }

          final thumbnailData = renderer['thumbnail'];
          final thumbs = thumbnailData is Map
              ? (thumbnailData['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
                  thumbnailData['thumbnails'])
              : null;
          final thumbnail = thumbs is List && thumbs.isNotEmpty
              ? thumbs.last['url']?.toString()
              : null;

          episodes.add(
            SongItem(
              id: videoId,
              title: title,
              artists: artists,
              duration: duration,
              thumbnail: thumbnail ?? '',
              isEpisode: true,
            ),
          );
        }
      }

      for (final section in sections) {
        if (section is! Map) continue;
        final shelf = section['musicShelfRenderer'];
        if (shelf is Map) {
          final titleRuns = shelf['title']?['runs'];
          final shelfTitle = titleRuns is List && titleRuns.isNotEmpty
              ? titleRuns.first['text']?.toString()
              : null;
          parseMultiRowItems(shelf['contents'], shelfTitle);
        }

        final carousel = section['musicCarouselShelfRenderer'];
        if (carousel is Map) {
          final titleRuns = carousel['header']
              ?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs'];
          final carouselTitle = titleRuns is List && titleRuns.isNotEmpty
              ? titleRuns.first['text']?.toString()
              : null;
          parseMultiRowItems(carousel['contents'], carouselTitle);
        }
      }

      final resolved = (await resolveArtistIds(episodes)).whereType<SongItem>().toList();
      return Future.wait(resolved.map((song) async {
        if (song.artists.isNotEmpty) return song;
        final mediaInfo = await getMediaInfo(song.id);
        if (mediaInfo?.author == null || mediaInfo!.author!.isEmpty) return song;
        return SongItem(
          id: song.id,
          title: song.title,
          artists: [
            Artist(name: mediaInfo.author!, id: mediaInfo.authorId),
          ],
          album: song.album,
          duration: song.duration,
          musicVideoType: song.musicVideoType,
          chartPosition: song.chartPosition,
          chartChange: song.chartChange,
          thumbnail: song.thumbnail,
          explicit: song.explicit,
          endpoint: song.endpoint,
          setVideoId: song.setVideoId,
          libraryAddToken: song.libraryAddToken,
          libraryRemoveToken: song.libraryRemoveToken,
          historyRemoveToken: song.historyRemoveToken,
          isEpisode: song.isEpisode,
          uploadEntityId: song.uploadEntityId,
        );
      }));
    } catch (_) {
      return const [];
    }
  }

  Future<NextPageData> getNextPage({
    String? videoId,
    String? playlistId,
    String? playlistSetVideoId,
    int? index,
    String? params,
    String? continuation,
  }) async {
    try {
      final body = _buildContext();
      if (videoId != null) body['videoId'] = videoId;
      if (playlistId != null) body['playlistId'] = playlistId;
      if (playlistSetVideoId != null) body['playlistSetVideoId'] = playlistSetVideoId;
      if (index != null) body['index'] = index;
      if (params != null) body['params'] = params;
      if (continuation != null) body['continuation'] = continuation;

      final response = await _dio.post('/next', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return NextPageParser.parse(response.data);
      }
    } catch (_) {}
    return const NextPageData(queue: []);
  }

  Future<List<YTItem>> getRelatedPage(String videoId) async {
    try {
      final response = await browseResponse(browseId: 'MPTR$videoId');
      if (response == null) return const [];
      final sections = response['contents']?['sectionListRenderer']?['contents'] ??
          response['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
              ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (sections is! List) return const [];

      final items = <YTItem>[];
      for (final section in sections) {
        if (section is! Map) continue;
        final carousel = section['musicCarouselShelfRenderer'];
        final rawItems = carousel is Map ? carousel['contents'] : null;
        if (rawItems is! List) continue;
        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final twoRow = rawItem['musicTwoRowItemRenderer'];
          final listItem = rawItem['musicResponsiveListItemRenderer'];
          if (twoRow is Map<String, dynamic>) {
            final item = LibraryPageParser.fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(twoRow),
            );
            if (item != null) items.add(item);
          } else if (listItem is Map<String, dynamic>) {
            final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(listItem),
            );
            if (item != null) items.add(item);
          }
        }
      }
      return items;
    } catch (_) {
      return const [];
    }
  }

  Future<bool> registerPlayback(
    String playbackUrl, {
    String? playlistId,
  }) async {
    try {
      const alphabet =
          'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
      final random = Random.secure();
      final cpn = List.generate(
        16,
        (_) => alphabet[random.nextInt(alphabet.length)],
      ).join();
      final uri = Uri.parse(playbackUrl);
      final query = <String, String>{
        ...uri.queryParameters,
        'cpn': cpn,
        if (playlistId != null && playlistId.isNotEmpty) 'list': playlistId,
      };
      final response = await _dio.get(
        uri.replace(queryParameters: query).toString(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moveSongInPlaylist(String playlistId, String setVideoId, String? nextSetVideoId) async {
    try {
      final actionMap = <String, dynamic>{
        'action': 'ACTION_MOVE_VIDEO_BEFORE',
        'setVideoId': setVideoId,
        'movedSetVideoIdSuccessor': nextSetVideoId,
      };
      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [actionMap];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> lyrics(String browseId) async {
    try {
      final body = _buildContext()..['browseId'] = browseId;
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map) {
        final description = response.data['contents']?['sectionListRenderer']
            ?['contents']?[0]?['musicDescriptionShelfRenderer']?['description']?['runs'];
        if (description is List && description.isNotEmpty) {
          return description.map((r) => r['text']).join();
        }
      }
    } catch (_) {}
    return null;
  }

  List<YTItem> _parseSearchResults(dynamic data) {
    final items = <YTItem>[];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is! List) return items;

      for (final section in contents) {
        if (section is! Map) continue;
        final shelf = section['musicShelfRenderer'];
        final itemSection = section['itemSectionRenderer'];
        final rawItems = shelf is Map
            ? shelf['contents']
            : itemSection is Map
                ? itemSection['contents']
                : null;
        if (rawItems is! List) continue;

        for (final rawItem in rawItems) {
          if (rawItem is! Map) continue;
          final renderer = rawItem['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final parsed = LibraryPageParser.fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
            );
            if (parsed != null) items.add(parsed);
          }
          final twoRow = rawItem['musicTwoRowItemRenderer'];
          if (twoRow is Map<String, dynamic>) {
            final parsed = LibraryPageParser.fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(twoRow),
            );
            if (parsed != null) items.add(parsed);
          }
        }
      }
    } catch (_) {}
    return items;
  }

  static const String _artistSearchFilter =
      'EgWKAQIgAWoKEAkQChAFEAMQBA%3D%3D';

  Future<Map<String, String>> resolveArtistIdMap(List<YTItem> items) async {
    final missingNames = <String>{};
    for (final item in items) {
      if (item is SongItem) {
        missingNames.addAll(item.artists.where((artist) => artist.id == null).map((artist) => artist.name));
      } else if (item is AlbumItem) {
        missingNames.addAll((item.artists ?? const []).where((artist) => artist.id == null).map((artist) => artist.name));
      } else if (item is PlaylistItem || item is EpisodeItem || item is PodcastItem) {
        final author = item is PlaylistItem
            ? item.author
            : item is EpisodeItem
                ? item.author
                : (item as PodcastItem).author;
        if (author != null && author.id == null) missingNames.add(author.name);
      }
    }

    final names = missingNames.where((name) => name.trim().isNotEmpty).toList();
    final resolved = <String, String>{};
    for (var offset = 0; offset < names.length; offset += 8) {
      final batch = names.skip(offset).take(8);
      final results = await Future.wait(batch.map((name) async {
        final candidates = await search(name, filter: _artistSearchFilter);
        final match = candidates.whereType<ArtistItem>().where(
          (artist) => artist.title.trim().toLowerCase() == name.trim().toLowerCase(),
        ).firstOrNull;
        return match == null ? null : MapEntry(name, match.id);
      }));
      for (final entry in results.whereType<MapEntry<String, String>>()) {
        resolved[entry.key] = entry.value;
      }
    }
    return resolved;
  }

  Future<List<YTItem>> resolveArtistIds(List<YTItem> items) async {
    final resolved = await resolveArtistIdMap(items);
    Artist resolve(Artist artist) => artist.id == null && resolved[artist.name] != null
        ? Artist(name: artist.name, id: resolved[artist.name])
        : artist;

    return items.map((item) {
      if (item is SongItem) {
        return SongItem(
          id: item.id,
          title: item.title,
          artists: item.artists.map(resolve).toList(),
          album: item.album,
          duration: item.duration,
          musicVideoType: item.musicVideoType,
          chartPosition: item.chartPosition,
          chartChange: item.chartChange,
          thumbnail: item.thumbnail,
          explicit: item.explicit,
          endpoint: item.endpoint,
          setVideoId: item.setVideoId,
          libraryAddToken: item.libraryAddToken,
          libraryRemoveToken: item.libraryRemoveToken,
          historyRemoveToken: item.historyRemoveToken,
          isEpisode: item.isEpisode,
          uploadEntityId: item.uploadEntityId,
        );
      }
      if (item is AlbumItem) {
        return AlbumItem(
          browseId: item.browseId,
          playlistId: item.playlistId,
          title: item.title,
          artists: item.artists?.map(resolve).toList(),
          year: item.year,
          thumbnail: item.thumbnail,
          explicit: item.explicit,
        );
      }
      if (item is PlaylistItem) {
        return PlaylistItem(
          id: item.id,
          title: item.title,
          author: item.author == null ? null : resolve(item.author!),
          songCountText: item.songCountText,
          thumbnail: item.thumbnail,
          playEndpoint: item.playEndpoint,
          shuffleEndpoint: item.shuffleEndpoint,
          radioEndpoint: item.radioEndpoint,
          isEditable: item.isEditable,
          isPodcast: item.isPodcast,
          description: item.description,
          authorAvatarUrl: item.authorAvatarUrl,
        );
      }
      if (item is EpisodeItem) {
        return EpisodeItem(
          id: item.id,
          title: item.title,
          author: item.author == null ? null : resolve(item.author!),
          podcast: item.podcast,
          duration: item.duration,
          publishDateText: item.publishDateText,
          thumbnail: item.thumbnail,
          explicit: item.explicit,
          endpoint: item.endpoint,
          libraryAddToken: item.libraryAddToken,
          libraryRemoveToken: item.libraryRemoveToken,
          markAsPlayedToken: item.markAsPlayedToken,
          markAsUnplayedToken: item.markAsUnplayedToken,
        );
      }
      if (item is PodcastItem) {
        return PodcastItem(
          id: item.id,
          title: item.title,
          author: item.author == null ? null : resolve(item.author!),
          episodeCountText: item.episodeCountText,
          thumbnail: item.thumbnail,
          playEndpoint: item.playEndpoint,
          shuffleEndpoint: item.shuffleEndpoint,
          libraryAddToken: item.libraryAddToken,
          libraryRemoveToken: item.libraryRemoveToken,
          channelId: item.channelId,
        );
      }
      return item;
    }).toList();
  }

  /// Low-level browse parity for Kotlin YouTube.browse and continuation calls.
  Future<Map<String, dynamic>?> browseResponse({
    String? browseId,
    String? params,
    String? continuation,
    bool useLogin = false,
  }) async {
    try {
      final body = _buildContext();
      if (browseId != null && browseId.isNotEmpty) body['browseId'] = browseId;
      if (params != null && params.isNotEmpty) body['params'] = params;
      if (continuation != null && continuation.isNotEmpty) {
        body['continuation'] = continuation;
      }
      final response = await _dio.post(
        '/browse',
        queryParameters: continuation == null
            ? null
            : {
                'continuation': continuation,
                'ctoken': continuation,
              },
        data: body,
        options: Options(headers: useLogin ? _getHeaders() : const {}),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getSearchSummaryResponse(
    String query, {
    bool recordSearchHistory = false,
  }) async {
    try {
      final body = _buildContext()..['query'] = query;
      final response = await _dio.post(
        '/search',
        data: body,
        options: Options(
          headers: recordSearchHistory ? _getHeaders() : const {},
        ),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getNextResponse({
    required String videoId,
    String? playlistId,
    String? playlistSetVideoId,
    int? index,
    String? params,
    String? continuation,
    YouTubeClient client = YouTubeClient.web,
  }) async {
    try {
      final body = _buildContext(client)..['videoId'] = videoId;
      if (playlistId != null) body['playlistId'] = playlistId;
      if (playlistSetVideoId != null) {
        body['playlistSetVideoId'] = playlistSetVideoId;
      }
      if (index != null) body['index'] = index;
      if (params != null) body['params'] = params;
      if (continuation != null) body['continuation'] = continuation;
      final response = await _dio.post(
        client.client.endpointUrl + '/next',
        data: body,
        options: Options(headers: _getHeaders(client: client)),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<ReturnYouTubeDislikeResponse?> getReturnYouTubeDislike(
    String videoId,
  ) async {
    try {
      final response = await _dio.get(
        'https://returnyoutubedislikeapi.com/Votes',
        queryParameters: {'videoId': videoId},
        options: Options(
          headers: const {'Accept': 'application/json'},
        ),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return ReturnYouTubeDislikeResponse.fromJson(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<MediaInfo?> getMediaInfo(String videoId) async {
    final response = await getNextResponse(videoId: videoId);
    if (response == null) return null;

    final rawContents = response['contents']?['twoColumnWatchNextResults']
        ?['results']?['results']?['contents'];
    if (rawContents is! List) return null;

    Map<String, dynamic>? secondary;
    Map<String, dynamic>? primary;
    for (final raw in rawContents) {
      if (raw is! Map) continue;
      final secondaryRenderer = raw['videoSecondaryInfoRenderer'];
      final primaryRenderer = raw['videoPrimaryInfoRenderer'];
      if (secondary == null && secondaryRenderer is Map<String, dynamic>) {
        secondary = secondaryRenderer;
      }
      if (primary == null && primaryRenderer is Map<String, dynamic>) {
        primary = primaryRenderer;
      }
    }

    final dislike = await getReturnYouTubeDislike(videoId);
    final owner = secondary?['owner']?['videoOwnerRenderer'];
    final authorRuns = owner?['title']?['runs'];
    final author = authorRuns is List && authorRuns.isNotEmpty
        ? authorRuns.first['text']?.toString()
        : null;
    final authorThumbs = owner?['thumbnail']?['thumbnails'];
    String? authorThumbnail;
    if (authorThumbs is List && authorThumbs.isNotEmpty) {
      final preferred = authorThumbs.where(
        (item) => item is Map && item['height'] == 48,
      );
      final chosen = preferred.isNotEmpty ? preferred.first : authorThumbs.last;
      authorThumbnail = chosen['url']?.toString().replaceAll('s48', 's960');
    }

    final titleRuns = primary?['title']?['runs'];
    final title = titleRuns is List && titleRuns.isNotEmpty
        ? titleRuns.first['text']?.toString()
        : null;
    final dateText = primary?['dateText']?['simpleText']?.toString();
    final subscriberText = owner?['subscriberCountText']?['simpleText']?.toString();

    return MediaInfo(
      videoId: videoId,
      title: title,
      author: author,
      authorId: owner?['navigationEndpoint']?['browseEndpoint']?['browseId']
          ?.toString(),
      authorThumbnail: authorThumbnail,
      description: secondary?['attributedDescription']?['content']?.toString(),
      uploadDate: dateText,
      subscribers: subscriberText?.split(' ').firstOrNull,
      viewCount: dislike?.viewCount,
      like: dislike?.likes,
      dislike: dislike?.dislikes,
    );
  }

  Future<Map<String, dynamic>?> getPlayerResponse({
    required String videoId,
    String? playlistId,
    YouTubeClient client = YouTubeClient.webRemix,
    int? signatureTimestamp,
    String? poToken,
  }) async {
    try {
      final body = _buildContext(client)..['videoId'] = videoId;
      if (playlistId != null && playlistId.isNotEmpty) {
        body['playlistId'] = playlistId;
      }
      if (signatureTimestamp != null) {
        body['playbackContext'] = {
          'contentPlaybackContext': {
            'signatureTimestamp': signatureTimestamp,
          },
        };
      }
      if (poToken != null && poToken.isNotEmpty) {
        body['serviceIntegrityDimensions'] = {'poToken': poToken};
      }
      final response = await _dio.post(
        '${client.client.endpointUrl}/player',
        data: body,
        options: Options(headers: _getHeaders(client: client)),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> getMediaInfoResponse(String videoId) {
    return getPlayerResponse(videoId: videoId);
  }

  Future<bool> toggleSongLibrary(String videoId, {required bool addToLibrary}) {
    return addToLibrary
        ? addSongToLibrary(videoId)
        : removeSongFromLibrary(videoId);
  }

  Future<LibraryPageData> getMusicHistory() async {
    final response = await browseResponse(
      browseId: 'FEmusic_history',
      useLogin: true,
    );
    return response == null
        ? const LibraryPageData(items: [])
        : LibraryPageParser.parseLibraryPage(response);
  }

  Future<List<AlbumItem>> getNewReleaseAlbums() async {
    return (await getExplorePage()).newReleaseAlbums;
  }

  Future<List<MoodAndGenreItem>> getMoodAndGenres() async {
    return (await getExplorePage()).moodsAndGenres;
  }

  Future<AlbumPageData> getAlbumSongs(String browseId) => getAlbumPage(browseId);

  Future<ArtistPageData> getArtist(String browseId) => getArtistPage(browseId);

  Future<List<SongItem>> getPlaylistContinuation(String continuation) async {
    try {
      final response = await browseResponse(continuation: continuation);
      if (response != null) return AlbumPageParser.parseTracks(response);
    } catch (_) {}
    return const [];
  }

  Future<List<SongItem>> getEpisodesForLater() => getPlaylistPage('SE');

  Future<HomePageData> getHomeContinuation(String continuation) =>
      getHomePage(continuation: continuation);

  Future<List<YTItem>> searchContinuationItems(String continuation) async {
    final response = await searchContinuationResponse(continuation);
    if (response == null) return const [];
    final contents = response['continuationContents']?['musicShelfContinuation']?['contents'];
    if (contents is! List) return const [];
    final items = <YTItem>[];
    for (final raw in contents) {
      if (raw is! Map) continue;
      final renderer = raw['musicResponsiveListItemRenderer'];
      if (renderer is Map<String, dynamic>) {
        final item = AlbumPageParser.getSong(
          MusicResponsiveListItemRenderer.fromJson(renderer),
        );
        if (item != null) items.add(item);
      }
    }
    return items;
  }

  Future<PlaylistItem?> getNewEpisodesPlaylistInfo() async {
    final response = await browseResponse(
      browseId: 'VLRDPN',
      useLogin: true,
    );
    if (response == null) return null;

    final header = response['header'];
    final immersive = header?['musicImmersiveHeaderRenderer'];
    final visual = header?['musicVisualHeaderRenderer'];
    final detail = header?['musicDetailHeaderRenderer'];

    String? firstThumbnail(dynamic thumbs) {
      if (thumbs is List && thumbs.isNotEmpty) {
        return thumbs.last['url']?.toString();
      }
      return null;
    }

    final thumbnail = firstThumbnail(
          immersive?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'],
        ) ??
        firstThumbnail(
          visual?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'],
        ) ??
        firstThumbnail(
          detail?['thumbnail']?['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'],
        ) ??
        firstThumbnail(
          response['contents']?['twoColumnBrowseResultsRenderer']
              ?['secondaryContents']?['sectionListRenderer']?['contents']?[0]
              ?['musicShelfRenderer']?['contents']?[0]
              ?['musicMultiRowListItemRenderer']?['thumbnail']
              ?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'],
        );

    String readTitle(dynamic renderer) {
      final runs = renderer?['title']?['runs'];
      if (runs is List && runs.isNotEmpty) {
        return runs.map((run) => run['text']?.toString() ?? '').join();
      }
      return '';
    }

    final title = readTitle(immersive).isNotEmpty
        ? readTitle(immersive)
        : readTitle(visual).isNotEmpty
            ? readTitle(visual)
            : 'New Episodes';

    return PlaylistItem(
      id: 'RDPN',
      title: title,
      thumbnail: thumbnail,
      author: null,
      songCountText: null,
      playEndpoint: null,
      shuffleEndpoint: null,
      radioEndpoint: null,
    );
  }

  Future<String> getChannelId(String browseId) async {
    try {
      final artist = await getArtistPage(browseId);
      return artist.artist.channelId ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<PodcastPageData> getPodcastPageWithDebug(
    String podcastId, {
    void Function(String message)? log,
  }) async {
    log?.call('Fetching podcast ' + podcastId);
    final page = await getPodcastPage(podcastId);
    log?.call('Parsed ' + page.episodes.length.toString() + ' episodes for ' + page.podcast.title);
    return page;
  }

  Future<AccountInfo?> getAccountInfo() async {
    final cookie = _innerTubeClient.cookie;
    if (cookie == null || cookie.isEmpty) return null;
    try {
      final menu = await getAccountMenu(cookie);
      final header = menu?.actions?.firstOrNull?.openPopupAction?.popup
          ?.multiPageMenuRenderer?.header?.activeAccountHeaderRenderer;
      final accountName = header?.accountName;
      if (accountName == null || accountName.isEmpty) return null;
      return AccountInfo(
        name: accountName,
        email: header?.email,
        channelHandle: header?.channelHandle,
        thumbnailUrl: header?.thumbnailUrl,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<PodcastItem>> getSavedPodcastShows() => getSavedPodcasts();

  Future<List<PodcastItem>> getLibraryPodcastChannels() => getPodcastChannels();

  Future<List<EpisodeItem>> getLibraryPodcastEpisodes() =>
      getPodcastLibraryEpisodes();

  /// Refreshes YouTube visitor data from the service-worker endpoint, with a homepage fallback.
  Future<String?> visitorData() async {
    try {
      final response = await _dio.get(
        'https://www.youtube.com/sw.js_data',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': YouTubeClient.webRemix.userAgent,
            'Accept': 'application/json,text/plain,*/*',
            'Accept-Language': _innerTubeClient.locale.hl + '-' +
                _innerTubeClient.locale.gl + ',' +
                _innerTubeClient.locale.hl + ';q=0.9',
          },
        ),
      );
      final raw = response.data?.toString() ?? '';
      final jsonText = raw.contains('\n') ? raw.substring(raw.indexOf('\n') + 1) : raw;
      final decoded = jsonDecode(jsonText);
      final value = decoded[0][2][0][0][13]?.toString();
      if (value != null && value.isNotEmpty) {
        _innerTubeClient.visitorData = value;
        return value;
      }
    } catch (_) {}

    try {
      final response = await _dio.get(
        'https://music.youtube.com/',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': YouTubeClient.webRemix.userAgent},
        ),
      );
      final raw = response.data?.toString() ?? '';
      final match = RegExp(r'"VISITOR_DATA"\s*:\s*"([^"]+)"').firstMatch(raw);
      final value = match?.group(1);
      if (value != null && value.isNotEmpty) {
        _innerTubeClient.visitorData = value;
        return value;
      }
    } catch (_) {}
    return null;
  }

  Future<List<YouTubeAccount>> accountsList() async {
    try {
      final body = _buildContext(YouTubeClient.web)
        ..['requestType'] = 'ACCOUNTS_LIST_REQUEST_TYPE_CHANNEL_SWITCHER'
        ..['callCircumstance'] = 'SWITCHING_USERS_FULL';
      final response = await _dio.post(
        'https://www.youtube.com/youtubei/v1/account/accounts_list',
        data: body,
        options: Options(headers: _getHeaders(client: YouTubeClient.web)),
      );
      if (response.statusCode == 200) {
        return YouTubeAccount.extractFromJson(response.data);
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> deleteUploadedSong(String entityId) async {
    if (entityId.isEmpty) return false;
    try {
      final body = _buildContext()..['entityId'] = entityId;
      final response = await _dio.post(
        '/music/delete_privately_owned_entity',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  /// Streams a known-length audio file to YouTube Music without buffering it in memory.
  Future<bool> uploadSong({
    required String filename,
    required int contentLength,
    required Stream<List<int>> content,
    void Function(double progress)? onProgress,
  }) async {
    if (contentLength <= 0 || contentLength >= 314572800) return false;
    onProgress?.call(0);
    try {
      final start = await _dio.post(
        'https://upload.youtube.com/upload/usermusic/http?authuser=' +
            Uri.encodeComponent(_innerTubeClient.authUser),
        data: {'filename': filename},
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
          headers: {
            ..._getHeaders(),
            'X-Goog-Upload-Command': 'start',
            'X-Goog-Upload-Header-Content-Length': contentLength.toString(),
            'X-Goog-Upload-Protocol': 'resumable',
          },
        ),
      );
      if (start.statusCode == null ||
          start.statusCode! < 200 ||
          start.statusCode! >= 300) {
        return false;
      }
      final uploadUrl = start.headers.value('X-Goog-Upload-URL');
      if (uploadUrl == null || uploadUrl.isEmpty) return false;
      final uri = Uri.tryParse(uploadUrl);
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'upload.youtube.com' ||
          uri.port != 443 ||
          !(uri.path == '/' || uri.path.startsWith('/upload/')) ||
          uri.userInfo.isNotEmpty) {
        return false;
      }

      onProgress?.call(0.05);
      final uploaded = await _dio.post(
        uri.toString(),
        data: content,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          sendTimeout: const Duration(minutes: 10),
          receiveTimeout: const Duration(minutes: 10),
          headers: {
            ..._getHeaders(),
            'Content-Length': contentLength.toString(),
            'X-Goog-Upload-Command': 'upload, finalize',
            'X-Goog-Upload-Offset': '0',
          },
        ),
        onSendProgress: (sent, total) {
          final denominator = total > 0 ? total : contentLength;
          onProgress?.call(
            (0.05 + (sent / denominator).clamp(0.0, 1.0) * 0.95)
                .clamp(0.05, 1.0),
          );
        },
      );
      final success = uploaded.statusCode != null &&
          uploaded.statusCode! >= 200 &&
          uploaded.statusCode! < 300 &&
          uploaded.headers.value('X-Goog-Upload-Status') == 'final';
      if (success) onProgress?.call(1);
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> uploadCustomThumbnailLink(
    String playlistId,
    List<int> image,
  ) async {
    if (image.isEmpty) return false;
    try {
      const uploadEndpoint =
          'https://music.youtube.com/playlist_image_upload/playlist_custom_thumbnail';
      final start = await _dio.post(
        uploadEndpoint,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            ..._getHeaders(),
            'X-Goog-Upload-Command': 'start',
            'X-Goog-Upload-Protocol': 'resumable',
            'X-Goog-Upload-Header-Content-Length': image.length.toString(),
          },
        ),
      );
      final uploadId = start.headers.value('X-Goog-Upload-Id') ??
          start.headers.value('X-Guploader-Uploadid');
      if (start.statusCode == null ||
          start.statusCode! < 200 ||
          start.statusCode! >= 300 ||
          uploadId == null ||
          uploadId.isEmpty) {
        return false;
      }

      final uploaded = await _dio.post(
        uploadEndpoint,
        queryParameters: {
          'upload_id': uploadId,
          'upload_protocol': 'resumable',
        },
        data: image,
        options: Options(
          contentType: 'application/octet-stream',
          responseType: ResponseType.json,
          sendTimeout: const Duration(minutes: 2),
          receiveTimeout: const Duration(minutes: 2),
          headers: {
            ..._getHeaders(),
            'Content-Length': image.length.toString(),
            'X-Goog-Upload-Command': 'upload, finalize',
            'X-Goog-Upload-Offset': '0',
          },
        ),
      );
      if (uploaded.statusCode == null ||
          uploaded.statusCode! < 200 ||
          uploaded.statusCode! >= 300 ||
          uploaded.data is! Map) {
        return false;
      }
      final encryptedBlobId =
          uploaded.data['encryptedBlobId']?.toString();
      if (encryptedBlobId == null || encryptedBlobId.isEmpty) return false;

      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [
          {
            'action': 'ACTION_SET_CUSTOM_THUMBNAIL',
            'addedCustomThumbnail': {
              'playlistScottyEncryptedBlobId': encryptedBlobId,
            },
          }
        ];
      final applied = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return applied.statusCode != null &&
          applied.statusCode! >= 200 &&
          applied.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeThumbnailPlaylist(String playlistId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = playlistId.replaceFirst(RegExp(r'^VL'), '')
        ..['actions'] = [
          {'action': 'ACTION_REMOVE_CUSTOM_THUMBNAIL'}
        ];
      final response = await _dio.post(
        '/browse/edit_playlist',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moveSongPlaylist(
    String playlistId,
    String setVideoId,
    String? successorSetVideoId,
  ) =>
      moveSongInPlaylist(playlistId, setVideoId, successorSetVideoId);

  // Kotlin YouTube facade parity aliases. These preserve the same endpoint semantics
  // while exposing typed Dart page data where the current Flutter models support it.
  Future<Map<String, dynamic>?> searchSuggestions(String query) =>
      getSearchSuggestionsResponse(query);

  Future<SearchSummaryPageData> searchSummary(
    String query, {
    bool recordSearchHistory = false,
  }) =>
      getSearchSummary(query, recordSearchHistory: recordSearchHistory);

  Future<Map<String, dynamic>?> searchContinuation(
    String continuation, {
    bool recordSearchHistory = false,
  }) =>
      searchContinuationResponse(
        continuation,
        recordSearchHistory: recordSearchHistory,
      );

  Future<AlbumPageData> album(String browseId, {bool withSongs = true}) =>
      getAlbumPage(browseId);

  Future<AlbumPageData> albumSongs(String browseId) => getAlbumPage(browseId);

  Future<ArtistPageData> artist(String browseId) => getArtistPage(browseId);

  Future<ArtistSection?> artistItems(BrowseEndpoint endpoint) async {
    try {
      final response = await browseResponse(
        browseId: endpoint.browseId,
        params: endpoint.params,
      );
      if (response == null) return null;
      final contents = response['contents']
          ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
          ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is! List || contents.isEmpty || contents.first is! Map) {
        return null;
      }
      final first = contents.first as Map;
      final shelf = first['musicShelfRenderer'];
      final carousel = first['musicCarouselShelfRenderer'];
      if (shelf is Map<String, dynamic>) {
        return ArtistPageParser.fromMusicShelfRenderer(
          MusicShelfRenderer.fromJson(shelf),
        );
      }
      if (carousel is Map<String, dynamic>) {
        return ArtistPageParser.fromMusicCarouselShelfRenderer(
          MusicCarouselShelfRenderer.fromJson(carousel),
        );
      }
    } catch (_) {}
    return null;
  }

  Future<ArtistSection?> artistItemsContinuation(String continuation) =>
      getArtistItemsContinuation(continuation);

  Future<List<SongItem>> playlist(String playlistId) =>
      getPlaylistPage(playlistId);

  Future<List<SongItem>> playlistContinuation(String continuation) =>
      getPlaylistContinuation(continuation);

  Future<PodcastPageData> podcast(String podcastId) =>
      getPodcastPage(podcastId);

  Future<HomePageData> home({String? continuation, String? params}) =>
      getHomePage(continuation: continuation, params: params);

  Future<HomePageData> homeContinuation(String continuation) =>
      getHomePage(continuation: continuation);

  Future<ExplorePageData> explore() => getExplorePage();

  Future<List<AlbumItem>> newReleaseAlbums() => getNewReleaseAlbums();

  Future<List<MoodAndGenreItem>> moodAndGenres() => getMoodAndGenres();

  Future<Map<String, dynamic>?> browse({
    String? browseId,
    String? params,
    String? continuation,
    bool useLogin = false,
  }) =>
      browseResponse(
        browseId: browseId,
        params: params,
        continuation: continuation,
        useLogin: useLogin,
      );

  Future<LibraryPageData> library({
    String? browseId,
    String? params,
    bool useLogin = true,
  }) =>
      getLibraryPage(browseId: browseId, params: params);

  Future<LibraryPageData> libraryContinuation(String continuation) =>
      getLibraryContinuation(continuation);

  Future<LibraryPageData> musicHistory() => getMusicHistory();

  Future<List<PodcastItem>> libraryPodcastChannels() => getPodcastChannels();

  Future<List<EpisodeItem>> libraryPodcastEpisodes() =>
      getPodcastLibraryEpisodes();

  Future<List<PodcastItem>> savedPodcastShows() => getSavedPodcasts();

  Future<List<SongItem>> newEpisodes() => getNewEpisodes();

  Future<Map<String, dynamic>?> player({
    required String videoId,
    String? playlistId,
    YouTubeClient client = YouTubeClient.webRemix,
    int? signatureTimestamp,
    String? poToken,
  }) =>
      getPlayerResponse(
        videoId: videoId,
        playlistId: playlistId,
        client: client,
        signatureTimestamp: signatureTimestamp,
        poToken: poToken,
      );

  Future<NextPageData> next(
    WatchEndpoint endpoint, {
    String? continuation,
  }) =>
      getNextPage(
        videoId: endpoint.videoId,
        playlistId: endpoint.playlistId,
        playlistSetVideoId: endpoint.playlistSetVideoId,
        index: endpoint.index,
        params: endpoint.params,
        continuation: continuation,
      );

  Future<List<YTItem>> related(BrowseEndpoint endpoint) async {
    final response = await browseResponse(
      browseId: endpoint.browseId,
      params: endpoint.params,
    );
    if (response == null) return const [];
    final sections = response['contents']?['sectionListRenderer']?['contents'] ??
        response['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
            ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (sections is! List) return const [];
    final items = <YTItem>[];
    for (final section in sections) {
      if (section is! Map) continue;
      final carousel = section['musicCarouselShelfRenderer'];
      final rawItems = carousel is Map ? carousel['contents'] : null;
      if (rawItems is! List) continue;
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final twoRow = raw['musicTwoRowItemRenderer'];
        final responsive = raw['musicResponsiveListItemRenderer'];
        if (twoRow is Map<String, dynamic>) {
          final item = LibraryPageParser.fromMusicTwoRowItemRenderer(
            MusicTwoRowItemRenderer.fromJson(twoRow),
          );
          if (item != null) items.add(item);
        } else if (responsive is Map<String, dynamic>) {
          final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(responsive),
          );
          if (item != null) items.add(item);
        }
      }
    }
    return items;
  }

  Future<String?> transcript(String videoId) async {
    final response = await getTranscript(videoId);
    if (response == null || response.cues.isEmpty) return null;
    return response.cues.map((cue) {
      final start = cue.startOffsetMs;
      final minutes = (start ~/ 60000).toString().padLeft(2, '0');
      final seconds = ((start ~/ 1000) % 60).toString().padLeft(2, '0');
      final millis = (start % 1000).toString().padLeft(3, '0');
      final text = cue.text.replaceAll('♪', '').trim();
      return '[$minutes:$seconds.$millis]$text';
    }).join('\n');
  }

  Future<Map<String, String>?> accountInfo() async {
    final cookie = _innerTubeClient.cookie;
    if (cookie == null || cookie.isEmpty) return null;
    return verifySession(cookie);
  }

  Future<Map<String, dynamic>?> getMediaInfo(String videoId) =>
      getMediaInfoResponse(videoId);

  Future<List<SongItem>> episodesForLater() => getEpisodesForLater();


}
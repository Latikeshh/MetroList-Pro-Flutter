import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';

import 'innertube_client.dart';
import 'models/explore_models.dart';
import 'models/renderers.dart';
import 'models/response/account_menu_response.dart';
import 'models/response/get_transcript_response.dart';
import 'models/youtube_client.dart';
import 'models/yt_item.dart';
import 'pages/album_page.dart';
import 'pages/artist_page.dart';
import 'pages/charts_page.dart';
import 'pages/explore_page.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/next_page.dart';
import 'pages/podcast_page.dart';

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
      final response = await _dio.post('/get_queue', data: body);
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
        '/search?continuation=$continuation&ctoken=$continuation',
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
      final response = await _dio.post('/browse', data: body);
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
      final response = await _dio.post('/browse?continuation=$continuation&ctoken=$continuation', data: body);
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
      final response = await _dio.post(endpoint, data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> likePlaylist(String playlistId, bool like) async {
    try {
      final endpoint = like ? '/like/like' : '/like/indifferent';
      final body = _buildContext()..['target'] = {'playlistId': playlistId};
      final response = await _dio.post(endpoint, data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> subscribeChannel(
    String channelId,
    bool subscribe, {
    String params = 'EgIIAhgA',
  }) async {
    try {
      final endpoint = subscribe ? '/subscription/subscribe' : '/subscription/unsubscribe';
      final body = _buildContext()
        ..['channelIds'] = [channelId]
        ..['params'] = params;
      final response = await _dio.post(endpoint, data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<String?> createPlaylist(String title) async {
    try {
      final body = _buildContext()..['title'] = title;
      final response = await _dio.post('/playlist/create', data: body);
      if (response.statusCode == 200 && response.data is Map) {
        return response.data['playlistId']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final body = _buildContext()..['playlistId'] = playlistId;
      final response = await _dio.post('/playlist/delete', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> renamePlaylist(String playlistId, String newTitle) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = playlistId
        ..['actions'] = [
          {
            'action': 'ACTION_SET_PLAYLIST_NAME',
            'playlistName': newTitle,
          }
        ];
      final response = await _dio.post('/browse/edit_playlist', data: body);
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
        ..['playlistId'] = playlistId
        ..['actions'] = actions;
      final response = await _dio.post('/browse/edit_playlist', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addPlaylistToPlaylist(String targetPlaylistId, String sourcePlaylistId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = targetPlaylistId
        ..['actions'] = [
          {
            'action': 'ACTION_ADD_PLAYLIST',
            'addedFullListId': sourcePlaylistId,
          }
        ];
      final response = await _dio.post('/browse/edit_playlist', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeFromPlaylist(String playlistId, String videoId, String setVideoId) async {
    try {
      final body = _buildContext()
        ..['playlistId'] = playlistId
        ..['actions'] = [
          {
            'action': 'ACTION_REMOVE_VIDEO',
            'setVideoId': setVideoId,
            'removedVideoId': videoId,
          }
        ];
      final response = await _dio.post('/browse/edit_playlist', data: body);
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
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return LibraryPageParser.parseLibraryPage(response.data);
      }
    } catch (_) {}
    return const LibraryPageData(items: []);
  }

  Future<LibraryPageData> getLibraryContinuation(String continuation) async {
    try {
      final body = _buildContext()..['continuation'] = continuation;
      final response = await _dio.post('/browse?continuation=$continuation&ctoken=$continuation', data: body);
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
      final response = await _dio.post('/feedback', data: body);
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
      final response = await _dio.post('/browse', data: body);
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
      final response = await _dio.post('/browse/edit_playlist', data: body);
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

  Future<List<EpisodeItem>> getNewEpisodes() async {
    try {
      final body = _buildContext()..['browseId'] = 'VLRDPN';
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode != 200 || response.data is! Map) return const [];
      final data = response.data as Map;
      final sections = <dynamic>[];
      final twoColumn = data['contents']?['twoColumnBrowseResultsRenderer'];
      final tabs = twoColumn?['tabs'];
      if (tabs is List && tabs.isNotEmpty) {
        final tabContents = tabs.first?['tabRenderer']?['content']
            ?['sectionListRenderer']?['contents'];
        if (tabContents is List) sections.addAll(tabContents);
      }
      final secondary = twoColumn?['secondaryContents']?['sectionListRenderer']?['contents'];
      if (secondary is List) sections.addAll(secondary);
      final episodes = <EpisodeItem>[];
      for (final section in sections) {
        final shelf = section is Map ? section['musicShelfRenderer'] : null;
        final items = shelf is Map ? shelf['contents'] : null;
        if (items is! List) continue;
        for (final item in items) {
          final renderer = item is Map ? item['musicResponsiveListItemRenderer'] : null;
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
        'action': 'ACTION_MOVE_VIDEO',
        'setVideoId': setVideoId,
      };
      if (nextSetVideoId != null) {
        actionMap['movedSetVideoIdPreceding'] = nextSetVideoId;
      }
      final body = _buildContext()
        ..['playlistId'] = playlistId
        ..['actions'] = [actionMap];
      final response = await _dio.post('/browse/edit_playlist', data: body);
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
      final path = continuation == null
          ? '/browse'
          : '/browse?continuation=$continuation&ctoken=$continuation';
      final response = await _dio.post(
        path,
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
        '/player',
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

  Future<Map<String, dynamic>?> getNewEpisodesPlaylistInfo() =>
      browseResponse(browseId: 'VLRDPN', useLogin: true);

  Future<Map<String, String>?> getAccountInfo() async {
    final cookie = _innerTubeClient.cookie;
    if (cookie == null || cookie.isEmpty) return null;
    return verifySession(cookie);
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

  Future<Map<String, dynamic>?> accountsList() async {
    try {
      final body = _buildContext()
        ..['requestType'] = 'ACCOUNTS_LIST_REQUEST_TYPE_CHANNEL_SWITCHER'
        ..['callCircumstance'] = 'SWITCHING_USERS_FULL';
      final response = await _dio.post(
        '/account/accounts_list',
        data: body,
        options: Options(headers: _getHeaders()),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (_) {}
    return null;
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
          uploaded.statusCode! < 300;
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
          responseType: ResponseType.json,
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


}
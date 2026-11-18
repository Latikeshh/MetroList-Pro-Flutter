import 'dart:convert';

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
    // Match InnerTubeX's WEB transcript request: params encode newline + VT + video ID.
    if (!RegExp(r'^[A-Za-z0-9_-]{1,64}
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

  Future<List<YTItem>> search(String query) async {
    try {
      final body = _buildContext()..['query'] = query;
      final response = await _dio.post('/search', data: body);
      if (response.statusCode == 200) {
        final results = _parseSearchResults(response.data);
        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    return const [];
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

  Future<bool> subscribeChannel(String channelId, bool subscribe) async {
    try {
      final endpoint = subscribe ? '/subscription/subscribe' : '/subscription/unsubscribe';
      final body = _buildContext()..['channelIds'] = [channelId];
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

  Future<bool> removeFromPlaylist(String playlistId, String setVideoId, String videoId) async {
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

  Future<bool> addSongToLibrary(String videoId) async {
    try {
      final body = _buildContext()..['feedbackTokens'] = ['add_to_library'];
      final response = await _dio.post('/feedback', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeSongFromLibrary(String videoId) async {
    try {
      final body = _buildContext()..['feedbackTokens'] = ['remove_from_library'];
      final response = await _dio.post('/feedback', data: body);
      return response.statusCode == 200;
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
    return subscribeChannel(podcastId, save);
  }

  Future<bool> addEpisodeToSavedEpisodes(String videoId) async {
    return likeVideo(videoId, true);
  }

  Future<bool> removeEpisodeFromSavedEpisodes(String videoId) async {
    return likeVideo(videoId, false);
  }

  Future<List<PodcastItem>> getSavedPodcasts() async {
    final page = await getLibraryPage(browseId: 'FEmusic_liked_podcasts');
    return page.items.whereType<PodcastItem>().toList();
  }

  Future<List<EpisodeItem>> getNewEpisodes() async {
    final page = await getPodcastPage('FEmusic_new_episodes');
    return page.episodes;
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
      final body = _buildContext()..['browseId'] = 'MPTR$videoId';
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _parseSearchResults(response.data);
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> registerPlayback(String playbackUrl) async {
    try {
      final response = await _dio.get(playbackUrl);
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
    final List<YTItem> items = [];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final shelf = section['musicShelfRenderer'];
          if (shelf is Map && shelf['contents'] is List) {
            for (var item in shelf['contents']) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer != null) {
                final song = AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(renderer));
                if (song != null) items.add(song);
              }
            }
          }
        }
      }
    } catch (_) {}
    return items;
  }
}
).hasMatch(videoId)) {
      return null;
    }

    try {
      final body = _buildContext();
      // InnerTubeX deliberately omits visitorData and account identity for captions.
      final clientContext = body['context']?['client'];
      if (clientContext is Map<String, dynamic>) {
        clientContext.remove('visitorData');
      }
      body['params'] = base64Encode(utf8.encode('\n\u000b$videoId'));

      final response = await _dio.post(
        'https://music.youtube.com/youtubei/v1/get_transcript',
        queryParameters: const {
          'key': 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30',
        },
        data: body,
        options: Options(
          headers: _getHeaders(client: YouTubeClient.webRemix),
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

  Future<List<YTItem>> search(String query) async {
    try {
      final body = _buildContext()..['query'] = query;
      final response = await _dio.post('/search', data: body);
      if (response.statusCode == 200) {
        final results = _parseSearchResults(response.data);
        if (results.isNotEmpty) return results;
      }
    } catch (_) {}

    return const [];
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

  Future<bool> subscribeChannel(String channelId, bool subscribe) async {
    try {
      final endpoint = subscribe ? '/subscription/subscribe' : '/subscription/unsubscribe';
      final body = _buildContext()..['channelIds'] = [channelId];
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

  Future<bool> removeFromPlaylist(String playlistId, String setVideoId, String videoId) async {
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

  Future<bool> addSongToLibrary(String videoId) async {
    try {
      final body = _buildContext()..['feedbackTokens'] = ['add_to_library'];
      final response = await _dio.post('/feedback', data: body);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeSongFromLibrary(String videoId) async {
    try {
      final body = _buildContext()..['feedbackTokens'] = ['remove_from_library'];
      final response = await _dio.post('/feedback', data: body);
      return response.statusCode == 200;
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
    return subscribeChannel(podcastId, save);
  }

  Future<bool> addEpisodeToSavedEpisodes(String videoId) async {
    return likeVideo(videoId, true);
  }

  Future<bool> removeEpisodeFromSavedEpisodes(String videoId) async {
    return likeVideo(videoId, false);
  }

  Future<List<PodcastItem>> getSavedPodcasts() async {
    final page = await getLibraryPage(browseId: 'FEmusic_liked_podcasts');
    return page.items.whereType<PodcastItem>().toList();
  }

  Future<List<EpisodeItem>> getNewEpisodes() async {
    final page = await getPodcastPage('FEmusic_new_episodes');
    return page.episodes;
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
      final body = _buildContext()..['browseId'] = 'MPTR$videoId';
      final response = await _dio.post('/browse', data: body);
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return _parseSearchResults(response.data);
      }
    } catch (_) {}
    return const [];
  }

  Future<bool> registerPlayback(String playbackUrl) async {
    try {
      final response = await _dio.get(playbackUrl);
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
    final List<YTItem> items = [];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final shelf = section['musicShelfRenderer'];
          if (shelf is Map && shelf['contents'] is List) {
            for (var item in shelf['contents']) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer != null) {
                final song = AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(renderer));
                if (song != null) items.add(song);
              }
            }
          }
        }
      }
    } catch (_) {}
    return items;
  }
}

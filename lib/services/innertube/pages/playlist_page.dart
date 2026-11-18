library;

import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'artist_items_page.dart';
import 'playlist_continuation_page.dart';

class PlaylistPageData {
  final PlaylistItem playlist;
  final List<SongItem> songs;
  final String? songsContinuation;
  final String? continuation;

  const PlaylistPageData({
    required this.playlist,
    required this.songs,
    this.songsContinuation,
    this.continuation,
  });
}

class PlaylistPageParser {
  static PlaylistPageData parsePlaylistPage(
    dynamic data,
    String playlistId,
  ) {
    if (data is! Map) {
      return PlaylistPageData(
        playlist: PlaylistItem(id: playlistId, title: '', thumbnail: ''),
        songs: const [],
      );
    }

    final twoColumn = data['contents']?['twoColumnBrowseResultsRenderer'];
    final primarySections = twoColumn?['tabs']?[0]?['tabRenderer']?['content']
        ?['sectionListRenderer']?['contents'];
    final secondarySections = twoColumn?['secondaryContents']
        ?['sectionListRenderer']?['contents'];
    final singleSections = data['contents']
        ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
        ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    final base = primarySections is List && primarySections.isNotEmpty
        ? primarySections.first
        : singleSections is List && singleSections.isNotEmpty
            ? singleSections.first
            : null;
    final secondaryShelfSection =
        secondarySections is List && secondarySections.isNotEmpty
            ? secondarySections.first
            : null;
    final singleShelfSection =
        singleSections is List && singleSections.isNotEmpty
            ? singleSections.first
            : null;

    final editableHeader = base?['musicEditablePlaylistDetailHeaderRenderer'];
    final header = base?['musicResponsiveHeaderRenderer'] ??
        editableHeader?['header']?['musicResponsiveHeaderRenderer'];
    final musicHeader = data['header']?['musicHeaderRenderer'];
    final detailHeader = editableHeader?['header']?['musicDetailHeaderRenderer'] ??
        data['header']?['musicDetailHeaderRenderer'];

    String readRuns(dynamic runs) {
      if (runs is! List) return '';
      return runs.map((run) => run['text']?.toString() ?? '').join();
    }

    List<dynamic> readRunsList(dynamic runs) =>
        runs is List ? runs : const [];

    String? thumbnailFrom(dynamic values) {
      if (values is List && values.isNotEmpty) {
        return values.last['url']?.toString();
      }
      return null;
    }

    final title = readRuns(header?['title']?['runs']).isNotEmpty
        ? readRuns(header?['title']?['runs'])
        : readRuns(musicHeader?['title']?['runs']);
    final description = readRuns(
      header?['description']?['musicDescriptionShelfRenderer']?['description']?['runs'],
    ).isNotEmpty
        ? readRuns(
            header?['description']?['musicDescriptionShelfRenderer']?['description']?['runs'],
          )
        : readRuns(detailHeader?['description']?['runs']);

    final strapline = readRunsList(header?['straplineTextOne']?['runs']);
    final detailSubtitle = readRunsList(detailHeader?['subtitle']?['runs']);
    final headerSubtitle = readRunsList(header?['subtitle']?['runs']);
    final authorRuns = strapline.isNotEmpty
        ? strapline
        : detailSubtitle.isNotEmpty
            ? detailSubtitle
            : headerSubtitle;
    Artist? author;
    for (final run in authorRuns) {
      final browse = run['navigationEndpoint']?['browseEndpoint'];
      final name = run['text']?.toString().trim() ?? '';
      if (name.isNotEmpty) {
        author = Artist(
          name: name,
          id: browse is Map ? browse['browseId']?.toString() : null,
        );
        break;
      }
    }

    final facepile = header?['facepile']?['avatarStackViewModel'];
    if (author == null) {
      final facepileName = facepile?['text']?['content']?.toString();
      if (facepileName != null && facepileName.isNotEmpty) {
        final browseId = facepile?['rendererContext']?['commandContext']
            ?['onTap']?['innertubeCommand']?['browseEndpoint']?['browseId'];
        author = Artist(name: facepileName, id: browseId?.toString());
      }
    }

    final countRuns = readRunsList(header?['secondSubtitle']?['runs']).isNotEmpty
        ? readRunsList(header?['secondSubtitle']?['runs'])
        : readRunsList(musicHeader?['secondSubtitle']?['runs']);
    String? songCountText;
    for (final run in countRuns.reversed) {
      final value = run['text']?.toString() ?? '';
      if (RegExp(r'\d').hasMatch(value) &&
          !value.toLowerCase().contains('view') &&
          !value.toLowerCase().contains('hour') &&
          !value.toLowerCase().contains('minute')) {
        songCountText = value;
        break;
      }
    }

    final thumbnail = thumbnailFrom(
          header?['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'],
        ) ??
        thumbnailFrom(
          musicHeader?['thumbnail']?['musicThumbnailRenderer']?['thumbnails'],
        ) ??
        thumbnailFrom(
          detailHeader?['thumbnail']?['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'],
        ) ??
        '';

    final buttons = header?['buttons'] is List
        ? header['buttons'] as List
        : musicHeader?['buttons'] is List
            ? musicHeader['buttons'] as List
            : const [];
    WatchEndpoint? shuffleEndpoint;
    WatchEndpoint? radioEndpoint;
    if (buttons.isNotEmpty) {
      final lastMenuItems = buttons.last?['menuRenderer']?['items'];
      if (lastMenuItems is List && lastMenuItems.isNotEmpty) {
        final endpoint = lastMenuItems.first?['menuNavigationItemRenderer']
            ?['navigationEndpoint']?['watchPlaylistEndpoint'];
        if (endpoint is Map<String, dynamic>) {
          shuffleEndpoint = WatchEndpoint.fromJson(endpoint);
        }
      }
      if (buttons.length > 2) {
        final mixItems = buttons[2]?['menuRenderer']?['items'];
        if (mixItems is List) {
          for (final item in mixItems) {
            if (item?['menuNavigationItemRenderer']?['icon']?['iconType'] == 'MIX') {
              final endpoint = item['menuNavigationItemRenderer']
                  ?['navigationEndpoint']?['watchPlaylistEndpoint'];
              if (endpoint is Map<String, dynamic>) {
                radioEndpoint = WatchEndpoint.fromJson(endpoint);
              }
              break;
            }
          }
        }
      }
    }

    final shelf = secondaryShelfSection?['musicPlaylistShelfRenderer'] ??
        secondaryShelfSection?['musicShelfRenderer'] ??
        singleShelfSection?['musicPlaylistShelfRenderer'] ??
        singleShelfSection?['musicShelfRenderer'];
    final rawSongs = shelf is Map ? shelf['contents'] : null;
    final songs = <SongItem>[];
    if (rawSongs is List) {
      for (final raw in rawSongs) {
        if (raw is! Map) continue;
        final renderer = raw['musicResponsiveListItemRenderer'];
        if (renderer is Map<String, dynamic>) {
          final song = ArtistItemsPage.fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(renderer),
          );
          if (song != null) songs.add(song);
        }
      }
    }

    String? continuationFrom(dynamic values) {
      if (values is! List) return null;
      for (final entry in values) {
        final token = entry?['nextContinuationData']?['continuation']?.toString() ??
            entry?['continuationItemRenderer']?['continuationEndpoint']
                ?['continuationCommand']?['token']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
      return null;
    }

    return PlaylistPageData(
      playlist: PlaylistItem(
        id: playlistId.replaceFirst(RegExp(r'^VL'), ''),
        title: title,
        author: author,
        songCountText: songCountText,
        thumbnail: thumbnail,
        shuffleEndpoint: shuffleEndpoint,
        radioEndpoint: radioEndpoint,
        isEditable: editableHeader != null,
        description: description.isEmpty ? null : description,
        authorAvatarUrl: thumbnailFrom(
          facepile?['avatars']?.firstOrNull?['avatarViewModel']?['image']?['sources'],
        ),
      ),
      songs: songs,
      songsContinuation: continuationFrom(shelf is Map ? shelf['continuations'] : null) ??
          continuationFrom(rawSongs),
      continuation: continuationFrom(
        twoColumn?['secondaryContents']?['sectionListRenderer']?['continuations'],
      ),
    );
  }
  static PlaylistContinuationPage parseContinuation(dynamic data) {
    if (data is! Map) {
      return const PlaylistContinuationPage(songs: []);
    }

    final contents = data['continuationContents'];
    final allRawItems = <dynamic>[];

    final sectionList = contents?['sectionListContinuation'];
    final sections = sectionList is Map ? sectionList['contents'] : null;
    if (sections is List) {
      for (final section in sections) {
        if (section is! Map) continue;
        final shelf = section['musicPlaylistShelfRenderer'] ??
            section['musicShelfRenderer'];
        final items = shelf is Map ? shelf['contents'] : null;
        if (items is List) allRawItems.addAll(items);
      }
    }

    for (final key in [
      'musicPlaylistShelfContinuation',
      'musicShelfContinuation',
    ]) {
      final shelf = contents is Map ? contents[key] : null;
      final items = shelf is Map ? shelf['contents'] : null;
      if (items is List) allRawItems.addAll(items);
    }

    final actions = data['onResponseReceivedActions'];
    if (actions is List) {
      for (final action in actions) {
        final appended = action?['appendContinuationItemsAction']?['continuationItems'];
        if (appended is List) allRawItems.addAll(appended);
      }
    }

    final songs = <SongItem>[];
    for (final raw in allRawItems) {
      if (raw is! Map) continue;
      final renderer = raw['musicResponsiveListItemRenderer'];
      if (renderer is Map<String, dynamic>) {
        final song = ArtistItemsPage.fromMusicResponsiveListItemRenderer(
          MusicResponsiveListItemRenderer.fromJson(renderer),
        );
        if (song != null && song.setVideoId != null) songs.add(song);
      }
    }

    String? nextContinuation(dynamic values) {
      if (values is! List) return null;
      for (final entry in values) {
        final token = entry?['nextContinuationData']?['continuation']?.toString() ??
            entry?['continuationItemRenderer']?['continuationEndpoint']
                ?['continuationCommand']?['token']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
      return null;
    }

    final continuation = nextContinuation(sectionList?['continuations']) ??
        nextContinuation(contents?['musicPlaylistShelfContinuation']?['continuations']) ??
        nextContinuation(contents?['musicShelfContinuation']?['continuations']) ??
        nextContinuation(actions?.expand((action) {
          final appended = action?['appendContinuationItemsAction']?['continuationItems'];
          return appended is List ? appended : const [];
        }).toList());

    return PlaylistContinuationPage(
      songs: songs,
      continuation: continuation,
    );
  }

  static List<SongItem> parseTracks(dynamic data) {
    final List<SongItem> songs = [];
    if (data is! Map<String, dynamic>) return songs;

    try {
      final contents = data['contents']
          ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']
          ?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (final section in contents) {
          final shelf = section['musicShelfRenderer'] ?? section['musicPlaylistShelfRenderer'];
          if (shelf is Map<String, dynamic> && shelf['contents'] is List) {
            for (final rawItem in shelf['contents']) {
              final renderer = rawItem['musicResponsiveListItemRenderer'];
              if (renderer is Map<String, dynamic>) {
                final song = ArtistItemsPage.fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer.fromJson(renderer));
                if (song != null) songs.add(song);
              }
            }
          }
        }
      }
    } catch (_) {}

    return songs;
  }
}

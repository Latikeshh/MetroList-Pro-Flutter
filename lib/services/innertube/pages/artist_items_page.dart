library;

import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class ArtistItemsPage {
  final String title;
  final List<YTItem> items;
  final String? continuation;

  const ArtistItemsPage({
    required this.title,
    required this.items,
    this.continuation,
  });

  static SongItem? fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer renderer) {
    if (renderer.flexColumns.isEmpty) return null;

    final title = renderer.flexColumns.first.text?.runs.firstOrNull?.text;
    final videoId = renderer.videoId;
    if (title == null || title.isEmpty || videoId == null || videoId.isEmpty) return null;

    final subtitleRuns = renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs : null;
    final artists = PageHelper.extractArtists(subtitleRuns);

    Album? album;
    if (renderer.flexColumns.length > 2) {
      final albumRun = renderer.flexColumns.last.text?.runs.firstOrNull;
      final albumId = albumRun?.navigationEndpoint?.browseEndpoint?.browseId;
      if (albumRun != null && albumId != null) {
        album = Album(name: albumRun.text, id: albumId);
      }
    }

    return SongItem(
      id: videoId,
      title: title,
      artists: artists,
      album: album,
      thumbnail: renderer.thumbnail?.getThumbnailUrl() ?? '',
      musicVideoType: renderer.musicVideoType,
      endpoint: renderer.overlay?.playNavigationEndpoint?.watchEndpoint,
      isEpisode: renderer.isEpisode,
    );
  }

  static YTItem? fromMusicTwoRowItemRenderer(MusicTwoRowItemRenderer renderer) {
    final title = renderer.title.runs.firstOrNull?.text;
    if (title == null || title.isEmpty) return null;

    if (renderer.isAlbum) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;

      final yearText = renderer.subtitle?.runs.lastOrNull?.text;
      final year = yearText != null ? int.tryParse(yearText) : null;

      return AlbumItem(
        browseId: browseId,
        playlistId: '',
        title: title,
        year: year,
        thumbnail: renderer.thumbnailRenderer?.getThumbnailUrl() ?? '',
      );
    } else if (renderer.isSong) {
      final videoId = renderer.navigationEndpoint?.watchEndpoint?.videoId;
      if (videoId == null) return null;

      final artists = PageHelper.extractArtists(renderer.subtitle?.runs);

      return SongItem(
        id: videoId,
        title: title,
        artists: artists,
        thumbnail: renderer.thumbnailRenderer?.getThumbnailUrl() ?? '',
        endpoint: renderer.navigationEndpoint?.watchEndpoint,
        musicVideoType: renderer.musicVideoType,
      );
    } else if (renderer.isPlaylist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;

      return PlaylistItem(
        id: browseId.startsWith('VL') ? browseId.substring(2) : browseId,
        title: title,
        thumbnail: renderer.thumbnailRenderer?.getThumbnailUrl() ?? '',
      );
    }

    return null;
  }
}



class ArtistItemsPageParser {
  static ArtistItemsPage parse(dynamic data) {
    if (data is! Map) return const ArtistItemsPage(title: '', items: []);
    final root = data['contents']?['singleColumnBrowseResultsRenderer']
        ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    final section = root is List && root.isNotEmpty ? root.first : null;
    if (section is! Map) return const ArtistItemsPage(title: '', items: []);

    String readTitle(dynamic runs) {
      if (runs is List && runs.isNotEmpty) {
        return runs.first['text']?.toString() ?? '';
      }
      return '';
    }

    String? readContinuation(dynamic values) {
      if (values is! List) return null;
      for (final value in values) {
        final token = value?['nextContinuationData']?['continuation']?.toString();
        if (token != null && token.isNotEmpty) return token;
      }
      return null;
    }

    final grid = section['gridRenderer'];
    if (grid is Map) {
      final items = <YTItem>[];
      final rawItems = grid['items'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicTwoRowItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(renderer),
            );
            if (item != null) items.add(item);
          }
        }
      }
      return ArtistItemsPage(
        title: readTitle(grid['header']?['gridHeaderRenderer']?['title']?['runs']),
        items: items,
        continuation: readContinuation(grid['continuations']),
      );
    }

    final carousel = section['musicCarouselShelfRenderer'];
    if (carousel is Map) {
      final items = <YTItem>[];
      final rawItems = carousel['contents'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final twoRow = raw['musicTwoRowItemRenderer'];
          final responsive = raw['musicResponsiveListItemRenderer'];
          YTItem? item;
          if (twoRow is Map<String, dynamic>) {
            item = fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(twoRow),
            );
          } else if (responsive is Map<String, dynamic>) {
            item = fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(responsive),
            );
          }
          if (item != null) items.add(item);
        }
      }
      return ArtistItemsPage(
        title: readTitle(
          carousel['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs'],
        ),
        items: items,
      );
    }

    final shelf = section['musicShelfRenderer'] ??
        section['musicPlaylistShelfRenderer'];
    if (shelf is Map) {
      final items = <YTItem>[];
      final rawItems = shelf['contents'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
            );
            if (item != null) items.add(item);
          }
        }
      }
      final headerTitle = data['header']?['musicHeaderRenderer']?['title']?['runs'];
      return ArtistItemsPage(
        title: readTitle(shelf['title']?['runs']).isNotEmpty
            ? readTitle(shelf['title']?['runs'])
            : readTitle(headerTitle),
        items: items,
        continuation: readContinuation(shelf['continuations']),
      );
    }

    return ArtistItemsPage(
      title: readTitle(data['header']?['musicHeaderRenderer']?['title']?['runs']),
      items: const [],
    );
  }
}

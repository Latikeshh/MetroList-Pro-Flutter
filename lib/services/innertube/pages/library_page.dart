import '../models/menu.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class LibraryPageData {
  final List<YTItem> items;
  final String? continuation;
  final bool isUploaded;

  const LibraryPageData({
    required this.items,
    this.continuation,
    this.isUploaded = false,
  });
}

class LibraryPageParser {
  static YTItem? fromMusicTwoRowItemRenderer(MusicTwoRowItemRenderer renderer) {
    if (renderer.isAlbum) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null || thumb == null) return null;

      final playlistId = renderer.thumbnailOverlay?.playNavigationEndpoint?.watchPlaylistEndpoint?.playlistId ?? '';
      final yearText = renderer.subtitle?.runs.lastOrNull?.text;

      return AlbumItem(
        browseId: browseId,
        playlistId: playlistId,
        title: title,
        artists: PageHelper.extractArtists(renderer.subtitle?.runs),
        year: yearText != null ? int.tryParse(yearText) : null,
        thumbnail: thumb,
        explicit: renderer.subtitleBadges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      );
    }

    if (renderer.isPlaylist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null || thumb == null) return null;

      final isEditable = renderer.menu?.items?.any(
            (i) => i.menuNavigationItemRenderer?.icon?.iconType == 'EDIT',
          ) ??
          false;

      return PlaylistItem(
        id: browseId.replaceFirst(RegExp(r'^VL'), ''),
        title: title,
        songCountText: renderer.subtitle?.runs.lastOrNull?.text,
        thumbnail: thumb,
        playEndpoint: renderer.thumbnailOverlay?.playNavigationEndpoint?.watchPlaylistEndpoint,
        isEditable: isEditable,
      );
    }

    if (renderer.isArtist || renderer.isUserChannel) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.lastOrNull?.text ?? renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null) return null;

      return ArtistItem(
        id: browseId,
        title: title,
        thumbnail: thumb,
      );
    }

    if (renderer.isPodcast) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null) return null;

      final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);

      return PodcastItem(
        id: browseId,
        title: title,
        episodeCountText: renderer.subtitle?.runs.lastOrNull?.text,
        thumbnail: thumb,
        playEndpoint: renderer.thumbnailOverlay?.playNavigationEndpoint?.watchPlaylistEndpoint,
        libraryAddToken: libraryTokens.addToken,
        libraryRemoveToken: libraryTokens.removeToken,
      );
    }

    if (renderer.isEpisode || renderer.isSong) {
      final videoId = renderer.thumbnailOverlay?.playNavigationEndpoint?.watchEndpoint?.videoId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (videoId == null || title == null || thumb == null) return null;

      final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);
      final subtitleGroups = Runs.splitBySeparator(renderer.subtitle?.runs ?? const []);
      final artists = PageHelper.extractArtists(subtitleGroups.isNotEmpty ? subtitleGroups.first : null);

      Album? songAlbum;
      if (subtitleGroups.length > 1 && subtitleGroups[1].isNotEmpty) {
        final albumRun = subtitleGroups[1].first;
        songAlbum = Album(
          name: albumRun.text,
          id: albumRun.navigationEndpoint?.browseEndpoint?.browseId ?? '',
        );
      }

      final durationText = subtitleGroups.isNotEmpty ? subtitleGroups.last.firstOrNull?.text : null;

      return SongItem(
        id: videoId,
        title: title,
        artists: artists,
        album: songAlbum,
        duration: durationText != null ? parseTime(durationText) : null,
        thumbnail: thumb,
        explicit: renderer.subtitleBadges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
        endpoint: renderer.thumbnailOverlay?.playNavigationEndpoint?.watchEndpoint,
        libraryAddToken: libraryTokens.addToken,
        libraryRemoveToken: libraryTokens.removeToken,
        isEpisode: renderer.isEpisode,
      );
    }

    return null;
  }

  static YTItem? fromMusicResponsiveListItemRenderer(
    MusicResponsiveListItemRenderer renderer, {
    bool isUploaded = false,
  }) {
    final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);

    if (renderer.isSong) {
      final videoId = renderer.videoId;
      final title = renderer.flexColumns.isNotEmpty ? renderer.flexColumns.first.text?.runs.firstOrNull?.text : null;
      final thumbUrl = renderer.thumbnail?.getThumbnailUrl();
      if (videoId == null || title == null || thumbUrl == null) return null;

      final artistRuns = renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs : null;
      final albumRun = renderer.flexColumns.length > 2 ? renderer.flexColumns[2].text?.runs.firstOrNull : null;

      final album = albumRun != null
          ? Album(name: albumRun.text, id: albumRun.navigationEndpoint?.browseEndpoint?.browseId ?? '')
          : null;

      final artists = PageHelper.extractArtists(artistRuns);

      final uploadEntityId = renderer.menu?.items?.firstWhere(
        (i) => i.menuNavigationItemRenderer?.navigationEndpoint?.urlEndpoint != null,
        orElse: () => const MenuItem(),
      ).menuNavigationItemRenderer?.navigationEndpoint?.urlEndpoint?.url;

      return SongItem(
        id: videoId,
        title: title,
        artists: artists,
        album: album,
        duration: parseTime(renderer.fixedColumns?.firstOrNull?.text?.runs.firstOrNull?.text),
        musicVideoType: renderer.musicVideoType,
        thumbnail: thumbUrl,
        explicit: renderer.badges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
        endpoint: renderer.overlay?.playNavigationEndpoint?.watchEndpoint,
        libraryAddToken: libraryTokens.addToken,
        libraryRemoveToken: libraryTokens.removeToken,
        isEpisode: renderer.isEpisode,
        uploadEntityId: uploadEntityId,
      );
    }

    if (renderer.isArtist || renderer.isUserChannel) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
      final thumb = renderer.thumbnail?.getThumbnailUrl();
      if (browseId == null || title == null) return null;

      return ArtistItem(
        id: browseId,
        title: title,
        thumbnail: thumb,
      );
    }

    if (renderer.isPodcast) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
      final thumb = renderer.thumbnail?.getThumbnailUrl();
      if (browseId == null || title == null) return null;

      return PodcastItem(
        id: browseId,
        title: title,
        episodeCountText: renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs.lastOrNull?.text : null,
        thumbnail: thumb,
        playEndpoint: renderer.overlay?.playNavigationEndpoint?.watchPlaylistEndpoint,
        libraryAddToken: libraryTokens.addToken,
        libraryRemoveToken: libraryTokens.removeToken,
      );
    }

    return null;
  }

  static LibraryPageData parseLibraryPage(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return const LibraryPageData(items: []);
    }

    final items = <YTItem>[];
    String? continuationToken;

    final gridContents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']?[0]?['gridRenderer']?['items'] ??
        data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']?[0]?['musicShelfRenderer']?['contents'];

    if (gridContents is List) {
      for (final c in gridContents) {
        if (c is Map<String, dynamic>) {
          final twoRow = c['musicTwoRowItemRenderer'];
          final listItem = c['musicResponsiveListItemRenderer'];

          if (twoRow is Map<String, dynamic>) {
            final parsed = fromMusicTwoRowItemRenderer(MusicTwoRowItemRenderer.fromJson(twoRow));
            if (parsed != null) items.add(parsed);
          } else if (listItem is Map<String, dynamic>) {
            final parsed = fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer.fromJson(listItem));
            if (parsed != null) items.add(parsed);
          }
        }
      }
    }

    final continuations = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['continuations'] ??
        data['continuationContents']?['gridContinuation']?['continuations'];

    if (continuations is List && continuations.isNotEmpty) {
      continuationToken = continuations[0]['nextContinuationData']?['continuation'];
    }

    return LibraryPageData(
      items: items,
      continuation: continuationToken,
    );
  }
}

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

class ArtistItemsContinuationPage {
  final List<YTItem> items;
  final String? continuation;

  const ArtistItemsContinuationPage({
    required this.items,
    this.continuation,
  });
}

import '../models/yt_item.dart';
import 'page_helper.dart';

class NewReleaseAlbumPage {
  static AlbumItem? fromMusicTwoRowItemRenderer(Map<String, dynamic> renderer) {
    try {
      final endpointMap = renderer['navigationEndpoint']?['browseEndpoint'];
      final browseId = endpointMap?['browseId'] as String?;
      if (browseId == null) return null;

      final playlistId = renderer['thumbnailOverlay']
          ?['musicItemThumbnailOverlayRenderer']
          ?['content']
          ?['musicPlayButtonRenderer']
          ?['playNavigationEndpoint']
          ?['watchPlaylistEndpoint']
          ?['playlistId'] as String?;
      if (playlistId == null) return null;

      final titleRuns = renderer['title']?['runs'] as List?;
      final title = (titleRuns != null && titleRuns.isNotEmpty)
          ? titleRuns.first['text'] as String?
          : null;
      if (title == null) return null;

      final subtitleRuns = renderer['subtitle']?['runs'] as List?;
      final artists = PageHelper.extractArtists(subtitleRuns);
      final yearStr = (subtitleRuns != null && subtitleRuns.isNotEmpty)
          ? subtitleRuns.last['text'] as String?
          : null;
      final year = yearStr != null ? int.tryParse(yearStr) : null;

      final thumbs = renderer['thumbnailRenderer']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] as List?;
      final thumbnail = (thumbs != null && thumbs.isNotEmpty) ? thumbs.last['url'] as String? : null;
      if (thumbnail == null) return null;

      final badges = renderer['subtitleBadges'] as List?;
      final explicit = badges?.any((b) =>
              b['musicInlineBadgeRenderer']?['icon']?['iconType'] == 'MUSIC_EXPLICIT_BADGE') ??
          false;

      return AlbumItem(
        id: browseId,
        title: title,
        artists: artists,
        thumbnail: thumbnail,
        year: year,
        explicit: explicit,
      );
    } catch (_) {
      return null;
    }
  }
}

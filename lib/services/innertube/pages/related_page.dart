library;

import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class RelatedPageData {
  final List<SongItem> songs;
  final List<AlbumItem> albums;
  final List<ArtistItem> artists;
  final List<PlaylistItem> playlists;

  const RelatedPageData({
    this.songs = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
  });
}

class RelatedPageParser {
  static SongItem? fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer renderer) {
    final videoId = renderer.videoId;
    final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
    final thumb = renderer.thumbnail?.getThumbnailUrl();
    if (videoId == null || title == null || thumb == null) return null;

    final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);
    final secondaryRuns = renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs : null;
    final groups = Runs.splitBySeparator(secondaryRuns ?? const []);

    return SongItem(
      id: videoId,
      title: title,
      artists: PageHelper.extractArtists(groups.isNotEmpty ? groups.first : null),
      duration: parseTime(renderer.fixedColumns?.firstOrNull?.text?.runs.firstOrNull?.text),
      musicVideoType: renderer.musicVideoType,
      thumbnail: thumb,
      explicit: renderer.badges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      libraryAddToken: libraryTokens.addToken,
      libraryRemoveToken: libraryTokens.removeToken,
      isEpisode: renderer.isEpisode,
    );
  }
}

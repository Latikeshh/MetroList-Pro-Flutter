library;

import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';
import 'library_page.dart';

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
  static RelatedPageData parse(dynamic data) {
    if (data is! Map) return const RelatedPageData();
    final rawSections = data['contents']?['sectionListRenderer']?['contents'] ??
        data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
            ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (rawSections is! List) return const RelatedPageData();

    final songs = <SongItem>[];
    final albums = <AlbumItem>[];
    final artists = <ArtistItem>[];
    final playlists = <PlaylistItem>[];

    for (final section in rawSections) {
      if (section is! Map) continue;
      final carousel = section['musicCarouselShelfRenderer'];
      final rawItems = carousel is Map ? carousel['contents'] : null;
      if (rawItems is! List) continue;
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final responsive = raw['musicResponsiveListItemRenderer'];
        final twoRow = raw['musicTwoRowItemRenderer'];
        YTItem? item;
        if (responsive is Map<String, dynamic>) {
          item = fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(responsive),
          );
        } else if (twoRow is Map<String, dynamic>) {
          item = LibraryPageParser.fromMusicTwoRowItemRenderer(
            MusicTwoRowItemRenderer.fromJson(twoRow),
          );
        }
        if (item is SongItem) {
          if (item.musicVideoType == 'MUSIC_VIDEO_TYPE_ATV') songs.add(item);
        } else if (item is AlbumItem) {
          albums.add(item);
        } else if (item is ArtistItem) {
          artists.add(item);
        } else if (item is PlaylistItem) {
          playlists.add(item);
        }
      }
    }
    return RelatedPageData(
      songs: songs,
      albums: albums,
      artists: artists,
      playlists: playlists,
    );
  }

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

import '../models/menu.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class HistorySection {
  final String title;
  final List<SongItem> songs;

  const HistorySection({
    required this.title,
    required this.songs,
  });
}

class HistoryPageData {
  final List<HistorySection> sections;

  const HistoryPageData({this.sections = const []});
}

class HistoryPageParser {
  static HistoryPageData parseHistoryPage(dynamic data) {
    if (data is! Map) return const HistoryPageData();
    final rawSections = data['contents']
        ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]
        ?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (rawSections is! List) return const HistoryPageData();

    final sections = <HistorySection>[];
    for (final raw in rawSections) {
      if (raw is! Map) continue;
      final shelf = raw['musicShelfRenderer'];
      if (shelf is Map<String, dynamic>) {
        final section = fromMusicShelfRenderer(
          MusicShelfRenderer.fromJson(shelf),
        );
        if (section != null) sections.add(section);
      }
    }
    return HistoryPageData(sections: sections);
  }

  static HistorySection? fromMusicShelfRenderer(MusicShelfRenderer renderer) {
    final title = renderer.title?.runs.firstOrNull?.text;
    if (title == null || renderer.contents == null) return null;

    final songs = <SongItem>[];
    for (final item in renderer.contents!) {
      final song = _fromMusicResponsiveListItemRenderer(item);
      if (song != null) songs.add(song);
    }

    return HistorySection(
      title: title,
      songs: songs,
    );
  }

  static SongItem? _fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer renderer) {
    final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);
    final videoId = renderer.videoId;
    final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
    final thumb = renderer.thumbnail?.getThumbnailUrl();

    if (videoId == null || title == null || thumb == null) return null;

    final secondaryRuns = renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs : null;
    final groups = Runs.splitBySeparator(secondaryRuns ?? const []);
    final artists = PageHelper.extractArtists(groups.isNotEmpty ? groups.first : null);

    final historyRemoveToken = renderer.menu?.items?.firstWhere(
      (i) => i.menuServiceItemRenderer?.icon?.iconType == 'REMOVE_FROM_HISTORY',
      orElse: () => const MenuItem(),
    ).menuServiceItemRenderer?.serviceEndpoint?.feedbackEndpoint?.feedbackToken;

    return SongItem(
      id: videoId,
      title: title,
      artists: artists,
      duration: parseTime(renderer.fixedColumns?.firstOrNull?.text?.runs.firstOrNull?.text),
      musicVideoType: renderer.musicVideoType,
      thumbnail: thumb,
      explicit: renderer.badges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      endpoint: renderer.overlay?.playNavigationEndpoint?.watchEndpoint,
      libraryAddToken: libraryTokens.addToken,
      libraryRemoveToken: libraryTokens.removeToken,
      historyRemoveToken: historyRemoveToken,
      isEpisode: renderer.isEpisode,
    );
  }
}

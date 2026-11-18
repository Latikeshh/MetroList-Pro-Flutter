library;

import '../models/menu.dart';
import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class NextPageData {
  final List<SongItem> queue;
  final String? lyricsEndpoint;
  final String? relatedEndpoint;
  final String? continuation;
  final String? title;
  final int? currentIndex;

  const NextPageData({
    required this.queue,
    this.lyricsEndpoint,
    this.relatedEndpoint,
    this.continuation,
    this.title,
    this.currentIndex,
  });
}

class NextPageParser {
  static NextPageData parse(dynamic data) {
    if (data is! Map) return const NextPageData(queue: []);

    final watchNext = data['contents']?['singleColumnMusicWatchNextResultsRenderer'];
    final tabs = watchNext?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
    final queueRenderer = watchNext?['tabbedRenderer']?['watchNextTabbedResultsRenderer']
        ?['tabs']?[0]?['tabRenderer']?['content']?['musicQueueRenderer'];
    final panel = data['continuationContents']?['playlistPanelContinuation'] ??
        queueRenderer?['content']?['playlistPanelRenderer'];
    final rawItems = panel?['contents'];
    final queue = <SongItem>[];
    var currentIndex = -1;

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is! Map) continue;
        final renderer = item['playlistPanelVideoRenderer'];
        if (renderer is! Map) continue;
        final song = fromPlaylistPanelVideoRenderer(renderer);
        if (song == null) continue;
        if (renderer['selected'] == true) currentIndex = queue.length;
        queue.add(song);
      }
    }

    String? endpointId(int index) {
      if (tabs is! List || tabs.length <= index) return null;
      final endpoint = tabs[index]?['tabRenderer']?['endpoint']?['browseEndpoint'];
      return endpoint is Map ? endpoint['browseId']?.toString() : null;
    }

    final continuationList = panel?['continuations'];
    String? continuation;
    if (continuationList is List && continuationList.isNotEmpty) {
      continuation = continuationList.first?['nextContinuationData']?['continuation']?.toString();
    }

    final subtitleRuns = queueRenderer?['header']?['musicQueueHeaderRenderer']?['subtitle']?['runs'];
    final title = subtitleRuns is List && subtitleRuns.isNotEmpty
        ? subtitleRuns.first['text']?.toString()
        : null;

    return NextPageData(
      queue: queue,
      lyricsEndpoint: endpointId(1),
      relatedEndpoint: endpointId(2),
      continuation: continuation,
      title: title,
      currentIndex: currentIndex < 0 ? null : currentIndex,
    );
  }

  static SongItem? parsePlaylistPanelVideoRenderer(
    Map<String, dynamic> content,
  ) {
    final renderer = content['playlistPanelVideoRenderer'];
    if (renderer is! Map) return null;
    return _parsePlaylistVideo(renderer);
  }

  static SongItem? fromPlaylistPanelVideoRenderer(Map renderer) {
    final navigation = renderer['navigationEndpoint'];
    final watch = navigation is Map ? navigation['watchEndpoint'] : null;
    final videoId = renderer['videoId']?.toString() ??
        (watch is Map ? watch['videoId']?.toString() : null);
    final titleRuns = renderer['title']?['runs'];
    final title = titleRuns is List && titleRuns.isNotEmpty
        ? titleRuns.first['text']?.toString()
        : null;
    if (videoId == null || title == null || title.isEmpty) return null;

    final rawByline = renderer['longBylineText'];
    final byline = rawByline is Map<String, dynamic>
        ? Runs.fromJson(rawByline).runs
        : <Run>[];
    final rawThumbs = renderer['thumbnail']?['thumbnails'] ??
        renderer['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
    final thumbnail = rawThumbs is List && rawThumbs.isNotEmpty
        ? rawThumbs.last['url']?.toString()
        : null;
    final lengthRuns = renderer['lengthText']?['runs'];
    final durationText = lengthRuns is List && lengthRuns.isNotEmpty
        ? lengthRuns.first['text']?.toString()
        : null;
    final rawMenu = renderer['menu'];
    final menu = rawMenu is Map<String, dynamic> ? Menu.fromJson(rawMenu) : null;
    final tokens = PageHelper.extractLibraryTokensFromMenuItems(menu?.items);
    final endpoint = navigation is Map<String, dynamic>
        ? NavigationEndpoint.fromJson(navigation).watchEndpoint
        : null;
    final albumRun = Runs.splitBySeparator(byline).skip(1).expand((g) => g).firstWhere(
          (run) => run.navigationEndpoint?.browseEndpoint != null,
          orElse: () => const Run(text: ''),
        );
    final albumEndpoint = albumRun.navigationEndpoint?.browseEndpoint;

    return SongItem(
      id: videoId,
      title: title,
      artists: PageHelper.extractArtists(byline),
      album: albumEndpoint == null ? null : Album(name: albumRun.text, id: albumEndpoint.browseId),
      duration: parseTime(durationText),
      musicVideoType: endpoint?.musicVideoType,
      thumbnail: thumbnail,
      explicit: (renderer['badges'] as List?)?.any(
            (badge) => badge is Map &&
                badge['musicInlineBadgeRenderer']?['icon']?['iconType'] == 'MUSIC_EXPLICIT_BADGE',
          ) ??
          false,
      endpoint: endpoint,
      setVideoId: renderer['playlistItemData']?['playlistSetVideoId']?.toString() ??
          renderer['playlistSetVideoId']?.toString(),
      libraryAddToken: tokens.addToken,
      libraryRemoveToken: tokens.removeToken,
    );
  }
}

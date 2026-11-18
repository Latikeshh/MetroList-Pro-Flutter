library;

import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class PodcastPageData {
  final PodcastItem podcast;
  final List<EpisodeItem> episodes;
  final String? continuation;
  final bool isChannelSubscribed;

  const PodcastPageData({
    required this.podcast,
    required this.episodes,
    this.continuation,
    this.isChannelSubscribed = false,
  });
}

class PodcastPageParser {
  static List<Artist> extractPodcastByline(List<Run>? runs) {
    final linked = PageHelper.extractArtists(runs);
    if (linked.isNotEmpty) return linked;

    final podcast = runs?.firstWhere(
      (r) => r.text.trim().isNotEmpty && r.navigationEndpoint?.browseEndpoint?.isPodcastEndpoint == true,
      orElse: () => const Run(text: ''),
    );
    if (podcast != null && podcast.text.isNotEmpty) {
      return [Artist(name: podcast.text.trim())];
    }

    final groups = Runs.splitBySeparator(runs ?? const []);
    if (groups.isNotEmpty && groups.first.isNotEmpty) {
      final channel = groups.first.first;
      if (channel.text.trim().isNotEmpty && channel.navigationEndpoint == null) {
        return [Artist(name: channel.text.trim())];
      }
    }
    return const [];
  }

  static EpisodeItem? fromMusicResponsiveListItemRenderer(
    MusicResponsiveListItemRenderer renderer, {
    PodcastItem? podcast,
  }) {
    final videoId = renderer.videoId;
    final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
    final thumb = renderer.thumbnail?.getThumbnailUrl();
    if (videoId == null || title == null || thumb == null) return null;

    final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);
    final secondaryLineRuns = renderer.flexColumns.length > 1 ? renderer.flexColumns[1].text?.runs : null;
    final groups = Runs.splitBySeparator(secondaryLineRuns ?? const []);

    final author = podcast?.author ?? extractPodcastByline(groups.isNotEmpty ? groups.first : null).firstOrNull;
    final podcastAlbum = podcast != null ? Album(name: podcast.title, id: podcast.id) : null;

    final durationText = groups.length > 1 ? groups.last.firstOrNull?.text : null;
    final pubDate = groups.length > 1 ? groups[1].firstOrNull?.text : null;

    return EpisodeItem(
      id: videoId,
      title: title,
      author: author,
      podcast: podcastAlbum,
      duration: durationText != null ? parseTime(durationText) : null,
      publishDateText: pubDate,
      thumbnail: thumb,
      explicit: renderer.badges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      endpoint: renderer.overlay?.playNavigationEndpoint?.watchEndpoint ?? WatchEndpoint(videoId: videoId),
      libraryAddToken: libraryTokens.addToken,
      libraryRemoveToken: libraryTokens.removeToken,
    );
  }

  static EpisodeItem? fromMusicMultiRowListItemRenderer(
    Map<String, dynamic> renderer, {
    PodcastItem? podcast,
  }) {
    final videoId = renderer['onTap']?['watchEndpoint']?['videoId']?.toString();
    final title = Runs.fromJson(renderer['title']).runs.firstOrNull?.text;
    if (videoId == null || videoId.isEmpty || title == null || title.isEmpty) {
      return null;
    }

    final subtitleRuns = Runs.fromJson(renderer['subtitle']).runs;
    final secondaryRuns = Runs.fromJson(renderer['secondSubtitle']).runs;
    final author = podcast?.author ??
        extractPodcastByline(subtitleRuns).firstOrNull ??
        extractPodcastByline(secondaryRuns).firstOrNull;
    final groups = Runs.splitBySeparator(subtitleRuns);
    int? duration;
    for (final group in groups.reversed) {
      duration = PageHelper.extractDuration(group);
      if (duration != null) break;
    }

    final thumbnailData = renderer['thumbnail'];
    final thumbs = thumbnailData is Map
        ? (thumbnailData['musicThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
            thumbnailData['thumbnails'])
        : null;
    final thumbnail = thumbs is List && thumbs.isNotEmpty
        ? thumbs.last['url']?.toString()
        : null;

    final onTap = renderer['onTap'];
    final endpoint = onTap is Map<String, dynamic>
        ? NavigationEndpoint.fromJson(onTap).watchEndpoint
        : null;

    return EpisodeItem(
      id: videoId,
      title: title,
      author: author,
      podcast: podcast == null ? null : Album(name: podcast.title, id: podcast.id),
      duration: duration,
      publishDateText: secondaryRuns.firstOrNull?.text,
      thumbnail: thumbnail,
      endpoint: endpoint ?? WatchEndpoint(videoId: videoId),
    );
  }

  static PodcastPageData parsePodcastPage(dynamic data, String podcastId) {
    if (data is! Map<String, dynamic>) {
      return PodcastPageData(
        podcast: PodcastItem(id: podcastId, title: 'Podcast'),
        episodes: const [],
      );
    }

    final twoColumnSections = data['contents']?['twoColumnBrowseResultsRenderer']
        ?['secondaryContents']?['sectionListRenderer']?['contents'];
    final singleColumnSections = data['contents']?['singleColumnBrowseResultsRenderer']
        ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];

    dynamic firstHeader(List<dynamic>? sections) {
      if (sections == null || sections.isEmpty) return null;
      final first = sections.first;
      if (first is! Map) return null;
      return first['musicResponsiveHeaderRenderer'] ??
          first['musicDetailHeaderRenderer'];
    }

    final header = data['header']?['musicDetailHeaderRenderer'] ??
        data['header']?['musicResponsiveHeaderRenderer'] ??
        firstHeader(twoColumnSections is List ? twoColumnSections : null) ??
        firstHeader(singleColumnSections is List ? singleColumnSections : null);

    String title = 'Podcast';
    String? thumbnail;
    Artist? author;
    String? episodeCountText;
    if (header is Map<String, dynamic>) {
      final titleRuns = header['title']?['runs'];
      if (titleRuns is List && titleRuns.isNotEmpty) {
        title = titleRuns.map((run) => run['text']?.toString() ?? '').join();
      }

      final thumbs = header['thumbnail']?['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
          header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      if (thumbs is List && thumbs.isNotEmpty) {
        thumbnail = thumbs.last['url']?.toString();
      }

      final authorRun = Runs.fromJson(header['straplineTextOne']).runs.firstOrNull;
      if (authorRun != null && authorRun.text.trim().isNotEmpty) {
        final browseId = authorRun.navigationEndpoint?.browseEndpoint?.browseId;
        author = Artist(name: authorRun.text.trim(), id: browseId);
      }

      episodeCountText = Runs.fromJson(header['secondSubtitle']).runs.firstOrNull?.text;
    }

    final podcastItem = PodcastItem(
      id: podcastId,
      title: title,
      author: author,
      episodeCountText: episodeCountText,
      thumbnail: thumbnail,
    );

    dynamic episodeContents;
    dynamic episodeShelf;
    if (twoColumnSections is List && twoColumnSections.isNotEmpty) {
      final first = twoColumnSections.first;
      if (first is Map) {
        episodeShelf = first['musicShelfRenderer'] ??
            first['musicPlaylistShelfRenderer'];
        episodeContents = episodeShelf?['contents'];
      }
    }
    if (episodeContents == null && singleColumnSections is List) {
      for (final section in singleColumnSections) {
        if (section is! Map) continue;
        episodeShelf = section['musicShelfRenderer'] ??
            section['musicPlaylistShelfRenderer'];
        episodeContents = episodeShelf?['contents'];
        if (episodeContents is List) break;
      }
    }

    String? continuation;
    final continuationList = episodeShelf?['continuations'];
    if (continuationList is List && continuationList.isNotEmpty) {
      continuation = continuationList.first?['nextContinuationData']?['continuation']
          ?.toString();
    }
    final subscribed = header?['subscriptionButton']?['subscribeButtonRenderer']
            ?['subscribed'] == true ||
        header?['buttons']?.any(
              (button) =>
                  button['subscribeButtonRenderer']?['subscribed'] == true,
            ) ==
            true;

    final episodes = <EpisodeItem>[];
    if (episodeContents is List) {
      for (final item in episodeContents) {
        if (item is! Map) continue;
        final responsive = item['musicResponsiveListItemRenderer'];
        if (responsive is Map<String, dynamic>) {
          final episode = fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(responsive),
            podcast: podcastItem,
          );
          if (episode != null) episodes.add(episode);
          continue;
        }
        final multiRow = item['musicMultiRowListItemRenderer'];
        if (multiRow is Map<String, dynamic>) {
          final episode = fromMusicMultiRowListItemRenderer(
            multiRow,
            podcast: podcastItem,
          );
          if (episode != null) episodes.add(episode);
        }
      }
    }

    return PodcastPageData(
      podcast: podcastItem,
      episodes: episodes,
      continuation: continuation,
      isChannelSubscribed: subscribed,
    );
  }

  static List<EpisodeItem> parsePodcastContinuation(
    dynamic data, {
    PodcastItem? podcast,
  }) {
    if (data is! Map) return const [];
    final rawItems = data['continuationContents']?['musicShelfContinuation']?['contents'] ??
        data['continuationContents']?['musicPlaylistShelfContinuation']?['contents'];
    if (rawItems is! List) return const [];
    final episodes = <EpisodeItem>[];
    for (final raw in rawItems) {
      if (raw is! Map) continue;
      final responsive = raw['musicResponsiveListItemRenderer'];
      if (responsive is Map<String, dynamic>) {
        final episode = fromMusicResponsiveListItemRenderer(
          MusicResponsiveListItemRenderer.fromJson(responsive),
          podcast: podcast,
        );
        if (episode != null) episodes.add(episode);
        continue;
      }
      final multiRow = raw['musicMultiRowListItemRenderer'];
      if (multiRow is Map<String, dynamic>) {
        final episode = fromMusicMultiRowListItemRenderer(
          multiRow,
          podcast: podcast,
        );
        if (episode != null) episodes.add(episode);
      }
    }
    return episodes;
  }

}

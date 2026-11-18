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

  static PodcastPageData parsePodcastPage(dynamic data, String podcastId) {
    if (data is! Map<String, dynamic>) {
      return PodcastPageData(
        podcast: PodcastItem(id: podcastId, title: 'Podcast'),
        episodes: const [],
      );
    }

    String title = 'Podcast';
    String? thumb;
    final episodes = <EpisodeItem>[];

    final header = data['header']?['musicDetailHeaderRenderer'] ?? data['header']?['musicResponsiveHeaderRenderer'];
    if (header is Map<String, dynamic>) {
      final titleRuns = header['title']?['runs'];
      if (titleRuns is List && titleRuns.isNotEmpty) {
        title = titleRuns[0]['text'] ?? 'Podcast';
      }
      final thumbs = header['thumbnail']?['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
          header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      if (thumbs is List && thumbs.isNotEmpty) {
        thumb = thumbs.last['url'];
      }
    }

    final podcastItem = PodcastItem(id: podcastId, title: title, thumbnail: thumb);

    final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents']?[0]?['musicShelfRenderer']?['contents'];
    if (contents is List) {
      for (final c in contents) {
        if (c is Map<String, dynamic>) {
          final renderer = c['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final episode = fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
              podcast: podcastItem,
            );
            if (episode != null) episodes.add(episode);
          }
        }
      }
    }

    return PodcastPageData(
      podcast: podcastItem,
      episodes: episodes,
    );
  }
}

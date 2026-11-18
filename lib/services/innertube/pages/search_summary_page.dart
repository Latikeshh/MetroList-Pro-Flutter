library;

import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';
import 'podcast_page.dart';

class SearchSummary {
  final String title;
  final List<YTItem> items;

  const SearchSummary({
    required this.title,
    required this.items,
  });
}

class SearchSummaryPageData {
  final List<SearchSummary> summaries;

  const SearchSummaryPageData({this.summaries = const []});

  SearchSummaryPageData filterExplicit(bool enabled) {
    if (!enabled) return this;
    return SearchSummaryPageData(
      summaries: summaries
          .map((summary) => SearchSummary(
                title: summary.title,
                items: summary.items.filterExplicit(),
              ))
          .where((summary) => summary.items.isNotEmpty)
          .toList(),
    );
  }

  SearchSummaryPageData filterVideoSongs(bool disableVideos) {
    if (!disableVideos) return this;
    return SearchSummaryPageData(
      summaries: summaries
          .map((summary) => SearchSummary(
                title: summary.title,
                items: summary.items.filterVideoSongs(true),
              ))
          .where((summary) => summary.items.isNotEmpty)
          .toList(),
    );
  }

  SearchSummaryPageData filterYoutubeShorts([bool enabled = false]) {
    if (!enabled) return this;
    return SearchSummaryPageData(
      summaries: summaries
          .map((summary) => SearchSummary(
                title: summary.title,
                items: summary.items.filterYoutubeShorts(true),
              ))
          .where((summary) => summary.items.isNotEmpty)
          .toList(),
    );
  }

  static YTItem? fromMusicCardShelfRenderer(MusicCardShelfRenderer renderer) {
    final endpoint = renderer.onTap;
    final browse = endpoint?.browseEndpoint;
    final watch = endpoint?.watchEndpoint;
    final title = renderer.title?.runs.firstOrNull?.text;
    final thumbnail = renderer.thumbnail?.getThumbnailUrl();
    if (title == null || title.isEmpty || thumbnail == null) return null;

    WatchEndpoint? buttonEndpoint(String iconType) {
      for (final button in renderer.buttons) {
        final buttonRenderer = button['buttonRenderer'];
        if (buttonRenderer is! Map) continue;
        final icon = buttonRenderer['icon'];
        if (icon is! Map || icon['iconType'] != iconType) continue;
        final command = buttonRenderer['command'];
        if (command is! Map) continue;
        final rawEndpoint = command['watchPlaylistEndpoint'] ??
            command['watchEndpoint'] ??
            command['anyWatchEndpoint'];
        if (rawEndpoint is Map<String, dynamic>) {
          return WatchEndpoint.fromJson(rawEndpoint);
        }
      }
      return null;
    }

    final subtitleRuns = renderer.subtitle?.runs ?? const <Run>[];
    final explicit = renderer.subtitleBadges?.any(
          (badge) => badge.icon?.iconType == 'MUSIC_EXPLICIT_BADGE',
        ) ??
        false;

    if (watch?.videoId != null) {
      final groups = Runs.splitBySeparator(subtitleRuns);
      final albumRun = groups.length > 2 ? groups[2].firstOrNull : null;
      final albumEndpoint = albumRun?.navigationEndpoint?.browseEndpoint;
      return SongItem(
        id: watch!.videoId!,
        title: title,
        artists: PageHelper.extractArtists(subtitleRuns),
        album: albumEndpoint == null
            ? null
            : Album(name: albumRun!.text, id: albumEndpoint.browseId),
        duration: PageHelper.extractDuration(subtitleRuns),
        musicVideoType: watch.musicVideoType,
        thumbnail: thumbnail,
        explicit: explicit,
      );
    }

    if (browse == null || browse.browseId.isEmpty) return null;
    if (browse.isArtistEndpoint || browse.pageType == BrowseEndpoint.musicPageTypeLibraryArtist) {
      return ArtistItem(
        id: browse.browseId,
        title: title,
        thumbnail: thumbnail,
        shuffleEndpoint: buttonEndpoint('MUSIC_SHUFFLE'),
        radioEndpoint: buttonEndpoint('MIX'),
      );
    }
    if (browse.isAlbumEndpoint) {
      return AlbumItem(
        browseId: browse.browseId,
        playlistId: buttonEndpoint('PLAY_ARROW')?.playlistId ?? '',
        title: title,
        artists: PageHelper.extractArtists(subtitleRuns),
        thumbnail: thumbnail,
        explicit: explicit,
      );
    }
    if (browse.isPlaylistEndpoint) {
      return PlaylistItem(
        id: browse.browseId.replaceFirst(RegExp(r'^VL'), ''),
        title: renderer.headerTitle ?? title,
        author: PageHelper.extractArtists(subtitleRuns).firstOrNull,
        thumbnail: thumbnail,
        playEndpoint: buttonEndpoint('PLAY_ARROW'),
        shuffleEndpoint: buttonEndpoint('MUSIC_SHUFFLE'),
      );
    }
    if (browse.isPodcastEndpoint) {
      return PodcastItem(
        id: browse.browseId,
        title: renderer.headerTitle ?? title,
        author: PodcastPageParser.extractPodcastByline(subtitleRuns).firstOrNull,
        thumbnail: thumbnail,
        playEndpoint: buttonEndpoint('PLAY_ARROW'),
        shuffleEndpoint: buttonEndpoint('MUSIC_SHUFFLE'),
      );
    }
    return null;
  }
}

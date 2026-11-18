library;

import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'album_page.dart';
import 'page_helper.dart';

class HomeChip {
  final String title;
  final String? params;
  final BrowseEndpoint? endpoint;
  final BrowseEndpoint? deselectEndpoint;

  const HomeChip({
    required this.title,
    this.params,
    this.endpoint,
    this.deselectEndpoint,
  });

  factory HomeChip.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HomeChip(title: '');
    final chip = json['chipCloudChipRenderer'];
    if (chip is Map<String, dynamic>) {
      final text = chip['text']?['runs']?[0]?['text']?.toString() ?? '';
      final navEndpoint = chip['navigationEndpoint'] is Map<String, dynamic>
          ? BrowseEndpoint.fromJson(chip['navigationEndpoint']?['browseEndpoint'])
          : null;
      final deselectEndpoint = chip['onDeselectedCommand'] is Map<String, dynamic>
          ? BrowseEndpoint.fromJson(chip['onDeselectedCommand']?['browseEndpoint'])
          : null;
      return HomeChip(
        title: text,
        params: navEndpoint?.params,
        endpoint: navEndpoint,
        deselectEndpoint: deselectEndpoint,
      );
    }
    return const HomeChip(title: '');
  }
}

class HomeSection {
  final String title;
  final String? label;
  final String? thumbnail;
  final BrowseEndpoint? endpoint;
  final List<YTItem> items;

  const HomeSection({
    required this.title,
    this.label,
    this.thumbnail,
    this.endpoint,
    required this.items,
  });

  factory HomeSection.fromMusicCarouselShelfRenderer(MusicCarouselShelfRenderer renderer) {
    final title = renderer.title?.runs.firstOrNull?.text ?? '';
    final items = <YTItem>[];

    if (renderer.contents != null) {
      for (final content in renderer.contents!) {
        if (content is Map<String, dynamic>) {
          final twoRow = content['musicTwoRowItemRenderer'];
          final multiRow = content['musicMultiRowListItemRenderer'];
          final listItem = content['musicResponsiveListItemRenderer'];

          if (twoRow is Map<String, dynamic>) {
            final parsed = _parseTwoRow(MusicTwoRowItemRenderer.fromJson(twoRow));
            if (parsed != null) items.add(parsed);
          } else if (multiRow is Map<String, dynamic>) {
            final parsed = _parseMultiRow(multiRow);
            if (parsed != null) items.add(parsed);
          } else if (listItem is Map<String, dynamic>) {
            final song = AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(listItem));
            if (song != null) items.add(song);
          }
        }
      }
    }

    return HomeSection(
      title: title,
      items: items,
    );
  }

  static EpisodeItem? _parseMultiRow(Map<String, dynamic> json) {
    final videoId = json['onTap']?['watchEndpoint']?['videoId']?.toString();
    final title = json['title']?['runs']?[0]?['text']?.toString();
    final thumb = json['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails']?.last?['url']?.toString();
    if (videoId == null || title == null || thumb == null) return null;

    final subtitleRuns = json['subtitle'] != null ? Runs.fromJson(json['subtitle']).runs : const <Run>[];
    final groups = Runs.splitBySeparator(subtitleRuns);
    final pubDate = groups.isNotEmpty && groups.first.isNotEmpty ? groups.first.first.text : null;
    final durationText = groups.length > 1 && groups.last.isNotEmpty ? groups.last.first.text : null;

    return EpisodeItem(
      id: videoId,
      title: title,
      thumbnail: thumb,
      publishDateText: pubDate,
      duration: durationText != null ? parseTime(durationText) : null,
      endpoint: WatchEndpoint(videoId: videoId),
    );
  }

  static YTItem? _parseTwoRow(MusicTwoRowItemRenderer renderer) {
    if (renderer.isSong) {
      final videoId = renderer.navigationEndpoint?.watchEndpoint?.videoId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (videoId == null || title == null || thumb == null) return null;

      final subtitleRuns = renderer.subtitle?.runs;
      final artists = PageHelper.extractArtists(subtitleRuns);

      return SongItem(
        id: videoId,
        title: title,
        artists: artists,
        thumbnail: thumb,
        explicit: renderer.subtitleBadges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      );
    }

    if (renderer.isAlbum) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null || thumb == null) return null;

      final playlistId = renderer.thumbnailOverlay?.playNavigationEndpoint?.anyWatchEndpoint?.playlistId ?? '';

      return AlbumItem(
        browseId: browseId,
        playlistId: playlistId,
        title: title,
        artists: PageHelper.extractArtists(renderer.subtitle?.runs),
        thumbnail: thumb,
        explicit: renderer.subtitleBadges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
      );
    }

    if (renderer.isPlaylist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null || thumb == null) return null;

      return PlaylistItem(
        id: browseId.replaceFirst(RegExp(r'^VL'), ''),
        title: title,
        thumbnail: thumb,
        playEndpoint: renderer.thumbnailOverlay?.playNavigationEndpoint?.watchPlaylistEndpoint,
      );
    }

    if (renderer.isArtist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.lastOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null || thumb == null) return null;

      return ArtistItem(
        id: browseId,
        title: title,
        thumbnail: thumb,
      );
    }

    if (renderer.isEpisode) {
      final videoId = renderer.thumbnailOverlay?.playNavigationEndpoint?.watchEndpoint?.videoId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (videoId == null || title == null || thumb == null) return null;

      return EpisodeItem(
        id: videoId,
        title: title,
        thumbnail: thumb,
        endpoint: WatchEndpoint(videoId: videoId),
      );
    }

    if (renderer.isPodcast) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (browseId == null || title == null) return null;

      return PodcastItem(
        id: browseId,
        title: title,
        thumbnail: thumb,
        playEndpoint: renderer.thumbnailOverlay?.playNavigationEndpoint?.watchPlaylistEndpoint,
      );
    }

    return null;
  }
}

class HomePageData {
  final List<HomeChip> chips;
  final List<HomeSection> sections;
  final String? continuation;
  final bool isError;
  final String? errorMessage;

  const HomePageData({
    this.chips = const [],
    this.sections = const [],
    this.continuation,
    this.isError = false,
    this.errorMessage,
  });
}

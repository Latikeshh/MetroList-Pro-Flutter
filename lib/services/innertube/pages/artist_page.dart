library;

import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'album_page.dart';
import 'page_helper.dart';

class ArtistSection {
  final String title;
  final List<YTItem> items;
  final BrowseEndpoint? moreEndpoint;

  const ArtistSection({
    required this.title,
    required this.items,
    this.moreEndpoint,
  });
}

class ArtistPageData {
  final ArtistItem artist;
  final List<ArtistSection> sections;
  final String? description;
  final String? subscriberCountText;
  final String? monthlyListenerCount;
  final bool isSubscribed;

  const ArtistPageData({
    required this.artist,
    required this.sections,
    this.description,
    this.subscriberCountText,
    this.monthlyListenerCount,
    this.isSubscribed = false,
  });
}

class ArtistPageParser {
  static ArtistSection? fromMusicShelfRenderer(MusicShelfRenderer renderer) {
    final title = renderer.title?.runs.firstOrNull?.text ?? '';
    if (renderer.contents == null) return null;

    final items = <YTItem>[];
    for (final itemRenderer in renderer.contents!) {
      final song = AlbumPageParser.getSong(itemRenderer);
      if (song != null) items.add(song);
    }
    if (items.isEmpty) return null;

    return ArtistSection(
      title: title,
      items: items,
      moreEndpoint: renderer.title?.runs.firstOrNull?.navigationEndpoint?.browseEndpoint,
    );
  }

  static ArtistSection? fromMusicCarouselShelfRenderer(MusicCarouselShelfRenderer renderer) {
    final title = renderer.title?.runs.firstOrNull?.text;
    if (title == null || renderer.contents == null) return null;

    final items = <YTItem>[];
    for (final content in renderer.contents!) {
      if (content is Map<String, dynamic>) {
        final twoRow = content['musicTwoRowItemRenderer'];
        final listItem = content['musicResponsiveListItemRenderer'];

        if (twoRow is Map<String, dynamic>) {
          final parsed = _fromMusicTwoRowItemRenderer(MusicTwoRowItemRenderer.fromJson(twoRow));
          if (parsed != null) items.add(parsed);
        } else if (listItem is Map<String, dynamic>) {
          final song = AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(listItem));
          if (song != null) items.add(song);
        }
      }
    }
    if (items.isEmpty) return null;

    return ArtistSection(
      title: title,
      items: items,
    );
  }

  static YTItem? _fromMusicTwoRowItemRenderer(MusicTwoRowItemRenderer renderer) {
    if (renderer.isSong) {
      final subtitleRuns = renderer.subtitle?.runs;
      final videoId = renderer.navigationEndpoint?.watchEndpoint?.videoId;
      final title = renderer.title.runs.firstOrNull?.text;
      final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
      if (videoId == null || title == null || thumb == null) return null;

      return SongItem(
        id: videoId,
        title: title,
        artists: PageHelper.extractArtists(subtitleRuns),
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
      final yearText = renderer.subtitle?.runs.lastOrNull?.text;

      return AlbumItem(
        browseId: browseId,
        playlistId: playlistId,
        title: title,
        year: yearText != null ? int.tryParse(yearText) : null,
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

    return null;
  }

  static List<SongItem> parseTopSongs(dynamic data) {
    if (data is! Map<String, dynamic>) return const [];
    final items = <SongItem>[];
    final contents = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (contents is List) {
      for (final c in contents) {
        if (c is Map<String, dynamic>) {
          final shelf = c['musicShelfRenderer'];
          if (shelf is Map<String, dynamic>) {
            final parsedSection = fromMusicShelfRenderer(MusicShelfRenderer.fromJson(shelf));
            if (parsedSection != null) {
              items.addAll(parsedSection.items.whereType<SongItem>());
            }
          }
        }
      }
    }
    return items;
  }

  static ArtistPageData parseArtistPage(dynamic data, String artistId) {
    if (data is! Map<String, dynamic>) {
      return ArtistPageData(
        artist: ArtistItem(id: artistId, title: 'Artist'),
        sections: const [],
      );
    }

    String title = 'Artist';
    String? thumb;
    String? description;
    String? subscriberCount;
    String? monthlyListeners;

    final header = data['header']?['musicImmersiveHeaderRenderer'] ?? data['header']?['musicHeaderRenderer'];
    if (header is Map<String, dynamic>) {
      final titleRuns = header['title']?['runs'];
      if (titleRuns is List && titleRuns.isNotEmpty) {
        title = titleRuns[0]['text'] ?? 'Artist';
      }
      final thumbs = header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      if (thumbs is List && thumbs.isNotEmpty) {
        thumb = thumbs.last['url'];
      }
      final descRuns = header['description']?['runs'];
      if (descRuns is List && descRuns.isNotEmpty) {
        description = descRuns.map((r) => r['text'] ?? '').join();
      }
      final subRuns = header['subscriptionButton']?['subscribeButtonRenderer']?['subscriberCountText']?['runs'];
      if (subRuns is List && subRuns.isNotEmpty) {
        subscriberCount = subRuns[0]['text'];
      }
    }

    final sections = <ArtistSection>[];
    final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (sectionList is List) {
      for (final s in sectionList) {
        if (s is Map<String, dynamic>) {
          final shelf = s['musicShelfRenderer'];
          final carousel = s['musicCarouselShelfRenderer'];
          if (shelf is Map<String, dynamic>) {
            final parsed = fromMusicShelfRenderer(MusicShelfRenderer.fromJson(shelf));
            if (parsed != null) sections.add(parsed);
          } else if (carousel is Map<String, dynamic>) {
            final parsed = fromMusicCarouselShelfRenderer(MusicCarouselShelfRenderer.fromJson(carousel));
            if (parsed != null) sections.add(parsed);
          }
        }
      }
    }

    return ArtistPageData(
      artist: ArtistItem(id: artistId, title: title, thumbnail: thumb),
      sections: sections,
      description: description,
      subscriberCountText: subscriberCount,
      monthlyListenerCount: monthlyListeners,
    );
  }
}

import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import '../models/navigation_endpoint.dart';
import 'page_helper.dart';

class SearchResult {
  final List<YTItem> items;
  final String? continuation;

  const SearchResult({
    required this.items,
    this.continuation,
  });
}

class SearchPageParser {
  static SearchResult parseResult(dynamic data) {
    final List<YTItem> items = [];
    String? continuationToken;

    if (data is! Map<String, dynamic>) {
      return SearchResult(items: items);
    }

    try {
      final sectionList = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
              ?[0]?['tabRenderer']?['content']?['sectionListRenderer'] ??
          data['contents']?['sectionListRenderer'];

      if (sectionList is Map<String, dynamic>) {
        if (sectionList['continuations'] is List && (sectionList['continuations'] as List).isNotEmpty) {
          final firstCont = sectionList['continuations'][0];
          continuationToken = firstCont?['nextContinuationData']?['continuation'] ??
              firstCont?['reloadContinuationData']?['continuation'];
        }

        final contents = sectionList['contents'];
        if (contents is List) {
          for (var section in contents) {
            final cardShelf = section['musicCardShelfRenderer'];
            if (cardShelf is Map<String, dynamic>) {
              final cardTitleRuns = cardShelf['title']?['runs'];
              final cardTitle = (cardTitleRuns is List && cardTitleRuns.isNotEmpty)
                  ? cardTitleRuns[0]['text'] ?? ''
                  : '';
              final cardVideoId = cardShelf['buttons']?[0]?['buttonRenderer']
                      ?['command']?['watchEndpoint']?['videoId'] ??
                  cardShelf['onTap']?['watchEndpoint']?['videoId'];
              final thumbnails = cardShelf['thumbnail']?['musicThumbnailRenderer']
                  ?['thumbnail']?['thumbnails'];
              final cardThumb = (thumbnails is List && thumbnails.isNotEmpty)
                  ? thumbnails.last['url']
                  : null;

              if (cardVideoId is String && cardVideoId.length >= 11) {
                items.add(SongItem(
                  id: cardVideoId,
                  title: cardTitle,
                  thumbnailUrl: cardThumb,
                  artists: const [],
                ));
              }
            }

            final shelf = section['musicShelfRenderer'];
            if (shelf is Map<String, dynamic> && shelf['contents'] is List) {
              for (var item in shelf['contents']) {
                final rendererJson = item['musicResponsiveListItemRenderer'];
                if (rendererJson is Map<String, dynamic>) {
                  final renderer = MusicResponsiveListItemRenderer.fromJson(rendererJson);
                  final parsedItem = toYTItem(renderer);
                  if (parsedItem != null) items.add(parsedItem);
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return SearchResult(
      items: items,
      continuation: continuationToken,
    );
  }

  static List<YTItem> parse(dynamic data) => parseResult(data).items;

  static YTItem? toYTItem(MusicResponsiveListItemRenderer renderer, {List<Artist> fallbackArtists = const []}) {
    final title = renderer.flexColumns.firstOrNull?.text?.runs.firstOrNull?.text;
    if (title == null || title.isEmpty) return null;

    final thumbUrl = renderer.thumbnail?.getThumbnailUrl() ?? '';

    if (renderer.isEpisode) {
      final videoId = renderer.videoId;
      if (videoId == null) return null;
      return EpisodeItem(
        id: videoId,
        title: title,
        thumbnailUrl: thumbUrl,
        endpoint: renderer.navigationEndpoint?.watchEndpoint,
      );
    }

    if (renderer.isSong) {
      final videoId = renderer.videoId;
      if (videoId == null) return null;

      final metadataRuns = renderer.flexColumns
          .skip(1)
          .expand((col) => col.text?.runs ?? <Run>[])
          .toList();

      final artists = PageHelper.extractArtists(metadataRuns);

      return SongItem(
        id: videoId,
        title: title,
        artists: artists.isNotEmpty ? artists : fallbackArtists,
        thumbnailUrl: thumbUrl,
        endpoint: renderer.navigationEndpoint?.watchEndpoint,
        musicVideoType: renderer.musicVideoType,
        isEpisode: false,
      );
    }

    if (renderer.isArtist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;
      return ArtistItem(
        id: browseId,
        title: title,
        thumbnailUrl: thumbUrl,
      );
    }

    if (renderer.isUserChannel) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;
      return ArtistItem(
        id: browseId,
        title: title,
        thumbnailUrl: thumbUrl,
        isProfile: true,
      );
    }

    if (renderer.isAlbum) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;
      return AlbumItem(
        browseId: browseId,
        playlistId: renderer.overlay?.playNavigationEndpoint?.watchEndpoint?.playlistId ?? '',
        title: title,
        thumbnailUrl: thumbUrl,
      );
    }

    if (renderer.isPlaylist) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;
      final playlistId = browseId.startsWith('VL') ? browseId.substring(2) : browseId;
      return PlaylistItem(
        id: playlistId,
        title: title,
        thumbnailUrl: thumbUrl,
      );
    }

    if (renderer.isPodcast) {
      final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
      if (browseId == null) return null;
      return PodcastItem(
        id: browseId,
        title: title,
        thumbnailUrl: thumbUrl,
      );
    }

    return null;
  }
}


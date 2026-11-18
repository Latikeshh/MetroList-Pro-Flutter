import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'artist_items_page.dart';

class ArtistItemsContinuationPage {
  final List<YTItem> items;
  final String? continuation;

  const ArtistItemsContinuationPage({
    required this.items,
    this.continuation,
  });
}

class ArtistItemsContinuationPageParser {
  static ArtistItemsContinuationPage parse(dynamic data) {
    if (data is! Map) {
      return const ArtistItemsContinuationPage(items: []);
    }

    final continuationContents = data['continuationContents'];
    final items = <YTItem>[];
    dynamic rawItems;
    dynamic rawContinuations;

    final grid = continuationContents?['gridContinuation'];
    final playlistShelf = continuationContents?['musicPlaylistShelfContinuation'];
    final musicShelf = continuationContents?['musicShelfContinuation'];

    if (grid is Map) {
      rawItems = grid['items'];
      rawContinuations = grid['continuations'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicTwoRowItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = ArtistItemsPage.fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(renderer),
            );
            if (item != null) items.add(item);
          }
        }
      }
    } else {
      final shelf = playlistShelf is Map ? playlistShelf : musicShelf;
      if (shelf is Map) {
        rawItems = shelf['contents'];
        rawContinuations = shelf['continuations'];
      } else {
        final actions = data['onResponseReceivedActions'];
        if (actions is List && actions.isNotEmpty) {
          final append = actions.first?['appendContinuationItemsAction'];
          rawItems = append?['continuationItems'];
          rawContinuations = rawItems;
        }
      }
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = ArtistItemsPage.fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
            );
            if (item != null) items.add(item);
          }
        }
      }
    }

    String? nextToken;
    if (rawContinuations is List) {
      for (final entry in rawContinuations) {
        final token = entry?['nextContinuationData']?['continuation']?.toString();
        if (token != null && token.isNotEmpty) {
          nextToken = token;
          break;
        }
      }
    }
    return ArtistItemsContinuationPage(
      items: items,
      continuation: items.isEmpty ? null : nextToken,
    );
  }
}

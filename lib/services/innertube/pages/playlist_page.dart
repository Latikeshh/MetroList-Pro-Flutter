library;

import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'artist_items_page.dart';
import 'playlist_continuation_page.dart';

class PlaylistPageParser {
  static PlaylistContinuationPage parseContinuation(dynamic data) {
    if (data is! Map) {
      return const PlaylistContinuationPage(songs: []);
    }
    final continuationContents = data['continuationContents'];
    final shelf = continuationContents?['musicPlaylistShelfContinuation'] ??
        continuationContents?['musicShelfContinuation'];
    dynamic rawItems = shelf is Map ? shelf['contents'] : null;
    dynamic rawContinuations = shelf is Map ? shelf['continuations'] : null;
    if (rawItems is! List) {
      final actions = data['onResponseReceivedActions'];
      if (actions is List && actions.isNotEmpty) {
        final append = actions.first?['appendContinuationItemsAction'];
        rawItems = append?['continuationItems'];
        rawContinuations = rawItems;
      }
    }

    final songs = <SongItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final renderer = raw['musicResponsiveListItemRenderer'];
        if (renderer is Map<String, dynamic>) {
          final song = ArtistItemsPage.fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer.fromJson(renderer));
          if (song != null) songs.add(song);
        }
      }
    }

    String? continuation;
    if (rawContinuations is List) {
      for (final entry in rawContinuations) {
        final token = entry?['nextContinuationData']?['continuation']?.toString() ??
            entry?['continuationItemRenderer']?['continuationEndpoint']
                ?['continuationCommand']?['token']?.toString();
        if (token != null && token.isNotEmpty) {
          continuation = token;
          break;
        }
      }
    }
    return PlaylistContinuationPage(
      songs: songs,
      continuation: songs.isEmpty ? null : continuation,
    );
  }

  static List<SongItem> parseTracks(dynamic data) {
    final List<SongItem> songs = [];
    if (data is! Map<String, dynamic>) return songs;

    try {
      final contents = data['contents']
          ?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']
          ?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (final section in contents) {
          final shelf = section['musicShelfRenderer'] ?? section['musicPlaylistShelfRenderer'];
          if (shelf is Map<String, dynamic> && shelf['contents'] is List) {
            for (final rawItem in shelf['contents']) {
              final renderer = rawItem['musicResponsiveListItemRenderer'];
              if (renderer is Map<String, dynamic>) {
                final song = ArtistItemsPage.fromMusicResponsiveListItemRenderer(MusicResponsiveListItemRenderer.fromJson(renderer));
                if (song != null) songs.add(song);
              }
            }
          }
        }
      }
    } catch (_) {}

    return songs;
  }
}

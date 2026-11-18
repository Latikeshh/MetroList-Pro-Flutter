library;

import '../models/yt_item.dart';
import 'page_helper.dart';

class PlaylistPageParser {
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
                final song = PageHelper.parseSongItemFromListItem(renderer);
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

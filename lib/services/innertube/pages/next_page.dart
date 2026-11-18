library;

import '../models/yt_item.dart';

class NextPageData {
  final List<SongItem> queue;
  final String? lyricsEndpoint;

  const NextPageData({
    required this.queue,
    this.lyricsEndpoint,
  });
}

class NextPageParser {
  static NextPageData parse(dynamic data) {
    final List<SongItem> queue = [];
    String? lyrics;

    if (data is Map<String, dynamic>) {
      try {
        final tabs = data['contents']?['singleColumnMusicWatchNextResultsRenderer']
            ?['tabbedRenderer']?['watchNextTabbedResultsRenderer']?['tabs'];
        if (tabs is List) {
          for (final tab in tabs) {
            final title = tab['tabRenderer']?['title']?['runs']?[0]?['text'];
            if (title == 'Lyrics') {
              lyrics = tab['tabRenderer']?['endpoint']?['browseEndpoint']?['browseId'];
            }
          }
        }
      } catch (_) {}
    }

    return NextPageData(queue: queue, lyricsEndpoint: lyrics);
  }
}

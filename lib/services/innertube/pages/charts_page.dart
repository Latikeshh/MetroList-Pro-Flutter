library;

import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'album_page.dart';

enum ChartType {
  trending,
  top,
  genre,
  newReleases,
}

class ChartSection {
  final String title;
  final List<YTItem> items;
  final ChartType chartType;

  const ChartSection({
    required this.title,
    required this.items,
    this.chartType = ChartType.top,
  });
}

class ChartsPage {
  final List<ChartSection> sections;
  final String? continuation;

  const ChartsPage({
    required this.sections,
    this.continuation,
  });

  factory ChartsPage.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ChartsPage(sections: []);
    final List<ChartSection> sections = [];
    String? continuationToken;

    try {
      final contents = json['contents']?['singleColumnBrowseResultsRenderer']
              ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
          ?['contents'];

      if (contents is List) {
        for (var section in contents) {
          final shelf = section['musicShelfRenderer'] ?? section['musicCarouselShelfRenderer'];
          if (shelf is Map<String, dynamic>) {
            final titleRuns = shelf['title']?['runs'] ??
                shelf['header']?['musicCarouselShelfBasicHeaderRenderer']?['title']?['runs'];
            final title = (titleRuns is List && titleRuns.isNotEmpty)
                ? titleRuns[0]['text']?.toString() ?? 'Charts'
                : 'Charts';

            final List<YTItem> items = [];
            final rawItems = shelf['contents'];
            if (rawItems is List) {
              for (var rawItem in rawItems) {
                final item = rawItem['musicResponsiveListItemRenderer'];
                if (item != null) {
                  final song = AlbumPageParser.getSong(MusicResponsiveListItemRenderer.fromJson(item));
                  if (song != null) items.add(song);
                }
              }
            }
            if (items.isNotEmpty) {
              sections.add(ChartSection(title: title, items: items));
            }
          }
        }
      }
    } catch (_) {}

    return ChartsPage(
      sections: sections,
      continuation: continuationToken,
    );
  }
}

class ChartsPageParser {
  static List<SongItem> parseTopCharts(dynamic data) {
    if (data is Map<String, dynamic>) {
      final chartsPage = ChartsPage.fromJson(data);
      if (chartsPage.sections.isNotEmpty) {
        return chartsPage.sections.first.items.whereType<SongItem>().toList();
      }
    }
    return const [];
  }
}

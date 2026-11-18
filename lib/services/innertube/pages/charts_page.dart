library;

import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'album_page.dart';
import 'library_page.dart';

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

            final chartType = title.toLowerCase().contains('trending')
                ? ChartType.trending
                : title.toLowerCase().contains('top')
                    ? ChartType.top
                    : ChartType.genre;

            final List<YTItem> items = [];
            final rawItems = shelf['contents'];
            if (rawItems is List) {
              for (final rawItem in rawItems) {
                if (rawItem is! Map<String, dynamic>) continue;
                final responsive = rawItem['musicResponsiveListItemRenderer'];
                final twoRow = rawItem['musicTwoRowItemRenderer'];
                if (responsive is Map<String, dynamic>) {
                  final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
                    MusicResponsiveListItemRenderer.fromJson(responsive),
                  );
                  if (item != null) items.add(item);
                } else if (twoRow is Map<String, dynamic>) {
                  final item = LibraryPageParser.fromMusicTwoRowItemRenderer(
                    MusicTwoRowItemRenderer.fromJson(twoRow),
                  );
                  if (item != null) items.add(item);
                }
              }
            }
            if (items.isNotEmpty) {
              sections.add(
                ChartSection(title: title, items: items, chartType: chartType),
              );
            }
          }
        }
      }
    } catch (_) {}

    final continuationContents =
        json['continuationContents']?['musicShelfContinuation'] ??
            json['continuationContents']?['musicCarouselShelfContinuation'];
    final continuationItems = continuationContents?['contents'];
    if (continuationItems is List) {
      final items = <YTItem>[];
      for (final rawItem in continuationItems) {
        if (rawItem is! Map<String, dynamic>) continue;
        final responsive = rawItem['musicResponsiveListItemRenderer'];
        final twoRow = rawItem['musicTwoRowItemRenderer'];
        if (responsive is Map<String, dynamic>) {
          final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
            MusicResponsiveListItemRenderer.fromJson(responsive),
          );
          if (item != null) items.add(item);
        } else if (twoRow is Map<String, dynamic>) {
          final item = LibraryPageParser.fromMusicTwoRowItemRenderer(
            MusicTwoRowItemRenderer.fromJson(twoRow),
          );
          if (item != null) items.add(item);
        }
      }
      if (items.isNotEmpty) {
        sections.add(ChartSection(title: 'More', items: items));
      }
    }

    final sectionList = json['contents']?['singleColumnBrowseResultsRenderer']
        ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer'];
    final continuations = sectionList?['continuations'] ??
        continuationContents?['continuations'];
    if (continuations is List && continuations.isNotEmpty) {
      continuationToken = continuations.first?['nextContinuationData']?['continuation']
          ?.toString();
    }

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

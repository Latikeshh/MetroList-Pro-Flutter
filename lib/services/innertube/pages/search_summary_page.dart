library;

import '../models/yt_item.dart';

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
}

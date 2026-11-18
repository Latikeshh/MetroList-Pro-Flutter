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
}

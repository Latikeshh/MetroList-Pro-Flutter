library;

import '../models/runs.dart';

class SearchSuggestion {
  final String query;
  final Runs? runs;

  const SearchSuggestion({
    required this.query,
    this.runs,
  });
}

class SearchSuggestionPageData {
  final List<SearchSuggestion> suggestions;

  const SearchSuggestionPageData({this.suggestions = const []});
}

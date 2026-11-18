library;

import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'library_page.dart';

class SearchSuggestion {
  final String query;
  final Runs? runs;
  final YTItem? item;

  const SearchSuggestion({
    required this.query,
    this.runs,
    this.item,
  });
}

class SearchSuggestionPageData {
  final List<SearchSuggestion> suggestions;

  const SearchSuggestionPageData({this.suggestions = const []});

  static SearchSuggestionPageData parse(dynamic data) {
    if (data is! Map) return const SearchSuggestionPageData();
    final sections = data['contents']?['searchSuggestionsSectionRenderer']?['contents'] ??
        data['contents']?[0]?['searchSuggestionsSectionRenderer']?['contents'];
    if (sections is! List) return const SearchSuggestionPageData();

    final suggestions = <SearchSuggestion>[];
    for (final section in sections) {
      if (section is! Map) continue;

      final rawSuggestion = section['searchSuggestionRenderer'];
      if (rawSuggestion is Map<String, dynamic>) {
        final rawRuns = rawSuggestion['suggestion'];
        final runs = rawRuns is Map<String, dynamic>
            ? Runs.fromJson(rawRuns)
            : const Runs(runs: []);
        final query = runs.runs.map((run) => run.text).join().trim();
        if (query.isNotEmpty) {
          suggestions.add(SearchSuggestion(query: query, runs: runs));
        }
      }

      final rawItem = section['musicResponsiveListItemRenderer'];
      if (rawItem is Map<String, dynamic>) {
        final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
          MusicResponsiveListItemRenderer.fromJson(rawItem),
        );
        if (item != null) {
          suggestions.add(SearchSuggestion(query: item.title, item: item));
        }
      }
    }
    return SearchSuggestionPageData(suggestions: suggestions);
  }
}

class SearchSuggestions {
  final List<String> suggestions;

  SearchSuggestions({required this.suggestions});

  factory SearchSuggestions.fromJson(Map<String, dynamic> json) {
    return SearchSuggestions(
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

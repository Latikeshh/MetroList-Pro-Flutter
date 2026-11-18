class GetSearchSuggestionsResponse {
  final List<Map<String, dynamic>>? contents;

  GetSearchSuggestionsResponse({this.contents});

  factory GetSearchSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return GetSearchSuggestionsResponse(
      contents: (json['contents'] as List?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

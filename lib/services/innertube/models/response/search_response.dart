class SearchResponse {
  final Map<String, dynamic>? contents;
  final Map<String, dynamic>? continuationContents;

  SearchResponse({this.contents, this.continuationContents});

  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      contents: json['contents'] as Map<String, dynamic>?,
      continuationContents: json['continuationContents'] as Map<String, dynamic>?,
    );
  }
}

class BrowseResponse {
  final Map<String, dynamic>? contents;
  final Map<String, dynamic>? continuationContents;
  final List<dynamic>? onResponseReceivedActions;
  final Map<String, dynamic>? header;
  final Map<String, dynamic>? microformat;
  final Map<String, dynamic>? responseContext;
  final Map<String, dynamic>? background;

  BrowseResponse({
    this.contents,
    this.continuationContents,
    this.onResponseReceivedActions,
    this.header,
    this.microformat,
    this.responseContext,
    this.background,
  });

  factory BrowseResponse.fromJson(Map<String, dynamic> json) {
    return BrowseResponse(
      contents: json['contents'] as Map<String, dynamic>?,
      continuationContents: json['continuationContents'] as Map<String, dynamic>?,
      onResponseReceivedActions: json['onResponseReceivedActions'] as List?,
      header: json['header'] as Map<String, dynamic>?,
      microformat: json['microformat'] as Map<String, dynamic>?,
      responseContext: json['responseContext'] as Map<String, dynamic>?,
      background: json['background'] as Map<String, dynamic>?,
    );
  }
}

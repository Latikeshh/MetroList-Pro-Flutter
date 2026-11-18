class NextResponse {
  final Map<String, dynamic>? contents;
  final Map<String, dynamic>? continuationContents;
  final Map<String, dynamic>? currentVideoEndpoint;

  NextResponse({
    this.contents,
    this.continuationContents,
    this.currentVideoEndpoint,
  });

  factory NextResponse.fromJson(Map<String, dynamic> json) {
    return NextResponse(
      contents: json['contents'] as Map<String, dynamic>?,
      continuationContents: json['continuationContents'] as Map<String, dynamic>?,
      currentVideoEndpoint: json['currentVideoEndpoint'] as Map<String, dynamic>?,
    );
  }
}

class YouTubeDataPage {
  final Map<String, dynamic>? contents;

  YouTubeDataPage({this.contents});

  factory YouTubeDataPage.fromJson(Map<String, dynamic> json) {
    return YouTubeDataPage(
      contents: json['contents'] as Map<String, dynamic>?,
    );
  }
}

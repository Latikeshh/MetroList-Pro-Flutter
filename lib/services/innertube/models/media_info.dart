class MediaInfo {
  final String title;
  final String author;

  MediaInfo({required this.title, required this.author});

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
    );
  }
}

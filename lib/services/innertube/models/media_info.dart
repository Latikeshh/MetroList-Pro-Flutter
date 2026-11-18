class MediaInfo {
  final String videoId;
  final String? title;
  final String? author;
  final String? authorId;
  final String? authorThumbnail;
  final String? description;
  final String? uploadDate;
  final String? subscribers;
  final int? viewCount;
  final int? like;
  final int? dislike;

  const MediaInfo({
    required this.videoId,
    this.title,
    this.author,
    this.authorId,
    this.authorThumbnail,
    this.description,
    this.uploadDate,
    this.subscribers,
    this.viewCount,
    this.like,
    this.dislike,
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      videoId: json['videoId']?.toString() ?? '',
      title: json['title']?.toString(),
      author: json['author']?.toString(),
      authorId: json['authorId']?.toString(),
      authorThumbnail: json['authorThumbnail']?.toString(),
      description: json['description']?.toString(),
      uploadDate: json['uploadDate']?.toString(),
      subscribers: json['subscribers']?.toString(),
      viewCount: (json['viewCount'] as num?)?.toInt(),
      like: (json['like'] as num?)?.toInt(),
      dislike: (json['dislike'] as num?)?.toInt(),
    );
  }
}

class ReturnYouTubeDislikeResponse {
  final String? id;
  final String? dateCreated;
  final int? likes;
  final int? dislikes;
  final double? rating;
  final int? viewCount;
  final bool? deleted;

  const ReturnYouTubeDislikeResponse({
    this.id,
    this.dateCreated,
    this.likes,
    this.dislikes,
    this.rating,
    this.viewCount,
    this.deleted,
  });

  factory ReturnYouTubeDislikeResponse.fromJson(Map<String, dynamic> json) {
    return ReturnYouTubeDislikeResponse(
      id: json['id']?.toString(),
      dateCreated: json['dateCreated']?.toString(),
      likes: (json['likes'] as num?)?.toInt(),
      dislikes: (json['dislikes'] as num?)?.toInt(),
      rating: (json['rating'] as num?)?.toDouble(),
      viewCount: int.tryParse(json['viewCount']?.toString() ?? ''),
      deleted: json['deleted'] as bool?,
    );
  }
}

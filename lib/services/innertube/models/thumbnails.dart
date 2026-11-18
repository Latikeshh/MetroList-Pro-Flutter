library;

class Thumbnail {
  final String url;
  final int? width;
  final int? height;

  const Thumbnail({
    required this.url,
    this.width,
    this.height,
  });

  factory Thumbnail.fromJson(Map<String, dynamic> json) {
    return Thumbnail(
      url: json['url']?.toString() ?? '',
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
    );
  }
}

class Thumbnails {
  final List<Thumbnail> thumbnails;

  const Thumbnails({required this.thumbnails});

  factory Thumbnails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Thumbnails(thumbnails: []);
    final rawList = json['thumbnails'];
    if (rawList is List) {
      final parsed = rawList
          .whereType<Map<String, dynamic>>()
          .map((t) => Thumbnail.fromJson(t))
          .toList();
      return Thumbnails(thumbnails: parsed);
    }
    return const Thumbnails(thumbnails: []);
  }

  String? get highestQualityUrl {
    if (thumbnails.isEmpty) return null;
    return thumbnails.last.url;
  }
}

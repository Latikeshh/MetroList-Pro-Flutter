import 'package:flutter_test/flutter_test.dart';

class ReturnYouTubeDislikeResponse {
  final String id;
  final int likes;
  final int dislikes;
  final double rating;
  final int viewCount;

  const ReturnYouTubeDislikeResponse({
    required this.id,
    required this.likes,
    required this.dislikes,
    required this.rating,
    required this.viewCount,
  });

  factory ReturnYouTubeDislikeResponse.fromJson(Map<String, dynamic> json) {
    return ReturnYouTubeDislikeResponse(
      id: json['id'] as String? ?? '',
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      dislikes: (json['dislikes'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
    );
  }

  double get likeRatioPercentage {
    final total = likes + dislikes;
    if (total == 0) return 0.0;
    return (likes / total) * 100.0;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Likes & Dislikes API Test: So Swaezy (d6C4uP9wHBA)', () {
    test('Parses Likes, Dislikes, Rating, and View Count for So Swaezy', () {
      final rydResponseJson = {
        'id': 'd6C4uP9wHBA',
        'dateCreated': '2023-08-15T00:00:00Z',
        'likes': 42500,
        'dislikes': 850,
        'rating': 4.90,
        'viewCount': 2150000,
        'deleted': false
      };

      final rydData = ReturnYouTubeDislikeResponse.fromJson(rydResponseJson);

      expect(rydData.id, 'd6C4uP9wHBA');
      expect(rydData.likes, 42500);
      expect(rydData.dislikes, 850);
      expect(rydData.viewCount, 2150000);
      expect(rydData.rating, 4.90);
      expect(rydData.likeRatioPercentage, closeTo(98.04, 0.1));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/home_models.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

void main() {
  group('Home Page Feature & API Parity Tests', () {
    test('HomePageData holds chips and sections correctly', () {
      const pageData = HomePageData(
        chips: [
          HomeChip(title: 'All', params: null),
          HomeChip(title: 'Podcasts', params: 'g_podcast'),
        ],
        sections: [
          HomeSection(
            title: 'Quick Picks',
            items: [
              SongItem(id: 'song_1', title: 'Song 1', artists: ['Artist 1']),
              AlbumItem(id: 'album_1', title: 'Album 1', artist: 'Artist 1'),
            ],
          ),
        ],
        continuation: 'continuation_token_123',
      );

      expect(pageData.chips.length, 2);
      expect(pageData.chips.first.title, 'All');
      expect(pageData.chips.last.params, 'g_podcast');

      expect(pageData.sections.length, 1);
      expect(pageData.sections.first.title, 'Quick Picks');
      expect(pageData.sections.first.items.length, 2);

      expect(pageData.continuation, 'continuation_token_123');
    });

    test('YouTubeService returns valid Home Page fallback or API data', () async {
      final service = YouTubeService();
      final pageData = await service.getHomePage();

      expect(pageData, isNotNull);
      expect(pageData.chips, isNotEmpty);
      expect(pageData.chips.any((chip) => chip.title == 'All'), isTrue);
    });
  });
}

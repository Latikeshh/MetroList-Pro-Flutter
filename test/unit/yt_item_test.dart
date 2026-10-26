import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';

void main() {
  group('YTItem Model Tests', () {
    test('SongItem model properties are created correctly', () {
      const song = SongItem(
        id: 'test_song_1',
        title: 'Test Title',
        artists: ['Artist A', 'Artist B'],
        album: 'Test Album',
        durationSeconds: 180,
        thumbnailUrl: 'https://example.com/thumb.jpg',
      );

      expect(song.id, 'test_song_1');
      expect(song.title, 'Test Title');
      expect(song.artists, ['Artist A', 'Artist B']);
      expect(song.album, 'Test Album');
      expect(song.durationSeconds, 180);
      expect(song.thumbnailUrl, 'https://example.com/thumb.jpg');
    });

    test('ArtistItem model properties are created correctly', () {
      const artist = ArtistItem(
        id: 'UC123456',
        title: 'Test Artist',
        subscribers: '10M Subscribers',
      );

      expect(artist.id, 'UC123456');
      expect(artist.title, 'Test Artist');
      expect(artist.subscribers, '10M Subscribers');
    });
  });
}

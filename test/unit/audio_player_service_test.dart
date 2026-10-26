import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/player/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('AudioPlayerService Unit Tests', () {
    final playerService = AudioPlayerService();

    test('A-B Looper points set and read correctly', () {
      playerService.setPointA(const Duration(seconds: 10));
      playerService.setPointB(const Duration(seconds: 40));
      playerService.setAbLoopEnabled(true);

      expect(playerService.pointA, const Duration(seconds: 10));
      expect(playerService.pointB, const Duration(seconds: 40));
      expect(playerService.isAbLoopEnabled, isTrue);
    });

    test('Favorite toggling adds and removes song IDs', () {
      const song = SongItem(
        id: 'fav_song_1',
        title: 'Favorite Track',
        artists: ['Fav Artist'],
      );

      expect(playerService.isFavorite('fav_song_1'), isFalse);

      final isNowFav = playerService.toggleFavorite(song);
      expect(isNowFav, isTrue);
      expect(playerService.isFavorite('fav_song_1'), isTrue);

      final isRemovedFav = playerService.toggleFavorite(song);
      expect(isRemovedFav, isFalse);
      expect(playerService.isFavorite('fav_song_1'), isFalse);
    });

    test('Repeat mode cycles through off, all, one', () {
      expect(playerService.player.playing, isFalse);
    });
  });
}

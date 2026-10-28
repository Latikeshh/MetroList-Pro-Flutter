import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/storage/local_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalDatabaseService Backup Export/Import Tests', () {
    late LocalDatabaseService db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = LocalDatabaseService();
    });

    test('Export produces valid JSON with version and items', () async {
      const song1 = SongItem(
        id: 'test_song_1',
        title: 'Test Song 1',
        artists: ['Artist A'],
      );
      await db.addLikedSong(song1);
      await db.addToHistory(song1);

      final backupJson = await db.exportBackupJson();
      expect(backupJson, isNotEmpty);

      final decoded = jsonDecode(backupJson);
      expect(decoded, isA<Map>());
      expect(decoded['version'], 'metrolist.backup.v1');
      expect(decoded['likedSongs'], isA<List>());
      expect(decoded['history'], isA<List>());
    });

    test('Import restores liked songs and history from valid JSON', () async {
      final backupPayload = jsonEncode({
        'version': 'metrolist.backup.v1',
        'likedSongs': [
          {
            'id': 'restored_song_1',
            'title': 'Restored Song',
            'artists': ['Restored Artist'],
          }
        ],
        'history': [
          {
            'id': 'restored_history_1',
            'title': 'Restored History Track',
            'artists': ['History Artist'],
          }
        ],
      });

      final success = await db.importBackupJson(backupPayload);
      expect(success, isTrue);

      final liked = await db.getLikedSongs();
      expect(liked.length, 1);
      expect(liked.first.id, 'restored_song_1');

      final history = await db.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 'restored_history_1');
    });

    test('Import returns false for malformed JSON', () async {
      final success = await db.importBackupJson('invalid_json_payload');
      expect(success, isFalse);
    });
  });
}

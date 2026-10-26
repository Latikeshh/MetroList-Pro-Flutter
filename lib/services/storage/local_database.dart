library;

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../core/platform/platform_capability.dart';
import '../innertube/models/yt_item.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;

  Database? _db;

  LocalDatabaseService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (PlatformCapability.isWeb) {
      // In-memory or web storage fallback
      return openDatabase(inMemoryDatabasePath, version: 1, onCreate: _onCreate);
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'metrolist_pro.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE liked_songs (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artists TEXT,
        thumbnailUrl TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE history (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artists TEXT,
        thumbnailUrl TEXT,
        timestamp INTEGER
      )
    ''');
  }

  Future<void> addLikedSong(SongItem song) async {
    try {
      final db = await database;
      await db.insert(
        'liked_songs',
        {
          'id': song.id,
          'title': song.title,
          'artists': song.artists.join(', '),
          'thumbnailUrl': song.thumbnailUrl ?? '',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  Future<void> removeLikedSong(String songId) async {
    try {
      final db = await database;
      await db.delete('liked_songs', where: 'id = ?', whereArgs: [songId]);
    } catch (_) {}
  }

  Future<List<SongItem>> getLikedSongs() async {
    try {
      final db = await database;
      final maps = await db.query('liked_songs');
      return maps.map((map) {
        return SongItem(
          id: map['id'] as String,
          title: map['title'] as String,
          artists: ((map['artists'] as String?) ?? '').split(', ').where((a) => a.isNotEmpty).toList(),
          thumbnailUrl: (map['thumbnailUrl'] as String?)?.ifEmpty(() => null),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addToHistory(SongItem song) async {
    try {
      final db = await database;
      await db.insert(
        'history',
        {
          'id': song.id,
          'title': song.title,
          'artists': song.artists.join(', '),
          'thumbnailUrl': song.thumbnailUrl ?? '',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }
}

extension _StringExt on String {
  String? ifEmpty(String? Function() fallback) {
    return isEmpty ? fallback() : this;
  }
}

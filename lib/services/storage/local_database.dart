import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../innertube/models/yt_item.dart';

/// Cross-platform persistent metadata storage. Audio files are never stored here.
class LocalDatabaseService {
  LocalDatabaseService._internal();
  static final LocalDatabaseService _instance =
      LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;

  static const _likedSongsKey = 'metrolist.likedSongs.v1';
  static const _historyKey = 'metrolist.history.v1';
  static const _maxHistoryItems = 500;

  Future<List<SongItem>> getLikedSongs() => _readSongs(_likedSongsKey);
  Future<List<SongItem>> getHistory() => _readSongs(_historyKey);

  Future<void> addLikedSong(SongItem song) async {
    final songs = await getLikedSongs();
    await _writeSongs(_likedSongsKey, <SongItem>[
      song,
      ...songs.where((item) => item.id != song.id),
    ]);
  }

  Future<void> removeLikedSong(String songId) async {
    final songs = await getLikedSongs();
    await _writeSongs(
      _likedSongsKey,
      songs.where((song) => song.id != songId).toList(),
    );
  }

  Future<void> addToHistory(SongItem song) async {
    final songs = await getHistory();
    await _writeSongs(
        _historyKey,
        <SongItem>[
          song,
          ...songs.where((item) => item.id != song.id),
        ].take(_maxHistoryItems).toList());
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<String> exportBackupJson() async {
    final liked = await getLikedSongs();
    final history = await getHistory();
    return jsonEncode({
      'version': 'metrolist.backup.v1',
      'timestamp': DateTime.now().toIso8601String(),
      'likedSongs': liked.map(_songToJson).toList(),
      'history': history.map(_songToJson).toList(),
    });
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) return false;
      final rawLiked = decoded['likedSongs'];
      final rawHistory = decoded['history'];

      if (rawLiked is List) {
        final liked = rawLiked
            .whereType<Map>()
            .map((entry) => _songFromJson(Map<String, dynamic>.from(entry)))
            .toList();
        await _writeSongs(_likedSongsKey, liked);
      }
      if (rawHistory is List) {
        final history = rawHistory
            .whereType<Map>()
            .map((entry) => _songFromJson(Map<String, dynamic>.from(entry)))
            .toList();
        await _writeSongs(_historyKey, history);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<SongItem>> _readSongs(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return <SongItem>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <SongItem>[];
      return decoded
          .whereType<Map>()
          .map((entry) => _songFromJson(Map<String, dynamic>.from(entry)))
          .where((song) => song.id.isNotEmpty && song.title.isNotEmpty)
          .toList();
    } on FormatException {
      return <SongItem>[];
    } on TypeError {
      return <SongItem>[];
    }
  }

  Future<void> _writeSongs(String key, List<SongItem> songs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode(songs.map(_songToJson).toList()),
    );
  }

  Map<String, Object?> _songToJson(SongItem song) => <String, Object?>{
        'id': song.id,
        'title': song.title,
        'artists': song.artists,
        'thumbnailUrl': song.thumbnailUrl,
        'album': song.album,
        'durationSeconds': song.durationSeconds,
      };

  SongItem _songFromJson(Map<String, dynamic> json) {
    final rawArtists = json['artists'];
    final artists = rawArtists is List
        ? rawArtists.whereType<String>().toList()
        : <String>[];
    final duration = json['durationSeconds'];
    return SongItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      artists: artists,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      album: json['album'] as String?,
      durationSeconds: duration is num ? duration.toInt() : null,
    );
  }
}

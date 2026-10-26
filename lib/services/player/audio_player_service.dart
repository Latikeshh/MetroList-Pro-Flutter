import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../innertube/models/yt_item.dart';
import '../storage/local_database.dart';
import 'audio_source_resolver.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  PositionData(this.position, this.bufferedPosition, this.duration);
}

enum AppRepeatMode { off, one, all }

class AudioPlayerService {
  AudioPlayerService._internal() {
    _player.positionStream.listen(_handlePosition);
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        unawaited(_handleTrackCompletion());
      }
    });
    unawaited(_loadFavorites());
  }

  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final AudioSourceResolver _resolver = AudioSourceResolver();
  final LocalDatabaseService _database = LocalDatabaseService();
  final Random _random = Random();

  final BehaviorSubject<SongItem?> _songSubject =
      BehaviorSubject<SongItem?>.seeded(null);
  final BehaviorSubject<List<SongItem>> _queueSubject =
      BehaviorSubject<List<SongItem>>.seeded(<SongItem>[]);
  final BehaviorSubject<AppRepeatMode> _repeatModeSubject =
      BehaviorSubject<AppRepeatMode>.seeded(AppRepeatMode.off);
  final BehaviorSubject<bool> _isShuffleSubject =
      BehaviorSubject<bool>.seeded(false);
  final BehaviorSubject<List<SongItem>> _favoriteSongsSubject =
      BehaviorSubject<List<SongItem>>.seeded(<SongItem>[]);
  final BehaviorSubject<String?> _playbackErrorSubject =
      BehaviorSubject<String?>.seeded(null);
  final Map<String, SongItem> _favoriteSongs = <String, SongItem>{};

  SongItem? _currentSong;
  String? _currentStreamUrl;
  List<SongItem> _queue = <SongItem>[];
  int _currentIndex = -1;
  Duration? _pointA;
  Duration? _pointB;
  bool _isAbLoopEnabled = false;
  bool _isSeekingForLoop = false;

  AudioPlayer get player => _player;
  SongItem? get currentSong => _currentSong;
  String? get currentStreamUrl => _currentStreamUrl;
  List<SongItem> get queue => List<SongItem>.unmodifiable(_queue);
  Duration? get pointA => _pointA;
  Duration? get pointB => _pointB;
  bool get isAbLoopEnabled => _isAbLoopEnabled;
  bool get hasValidAbRange =>
      _pointA != null &&
      _pointB != null &&
      _pointA! >= Duration.zero &&
      _pointB! > _pointA!;

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<SongItem?> get currentSongStream => _songSubject.stream;
  Stream<List<SongItem>> get queueStream => _queueSubject.stream;
  Stream<AppRepeatMode> get repeatModeStream => _repeatModeSubject.stream;
  Stream<bool> get isShuffleStream => _isShuffleSubject.stream;
  Stream<List<SongItem>> get favoriteSongsStream => _favoriteSongsSubject.stream;
  Stream<String?> get playbackErrorStream => _playbackErrorSubject.stream;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      );

  Future<void> _loadFavorites() async {
    try {
      final songs = await _database.getLikedSongs();
      _favoriteSongs
        ..clear()
        ..addEntries(songs.map((song) => MapEntry(song.id, song)));
      _favoriteSongsSubject.add(_favoriteSongs.values.toList(growable: false));
    } catch (error) {
      debugPrint('Unable to load favorites: $error');
    }
  }

  void _handlePosition(Duration position) {
    final end = _pointB;
    final start = _pointA;
    if (!_isAbLoopEnabled ||
        _isSeekingForLoop ||
        end == null ||
        start == null ||
        end <= start ||
        position < end) {
      return;
    }
    _isSeekingForLoop = true;
    _player.seek(start).whenComplete(() => _isSeekingForLoop = false);
  }

  void setPointA(Duration? position) {
    _pointA = position != null && position >= Duration.zero ? position : null;
    if (!hasValidAbRange) _isAbLoopEnabled = false;
  }

  void setPointB(Duration? position) {
    _pointB = position != null && position >= Duration.zero ? position : null;
    if (!hasValidAbRange) _isAbLoopEnabled = false;
  }

  void setAbLoopEnabled(bool enabled) {
    _isAbLoopEnabled = enabled && hasValidAbRange;
  }

  bool isFavorite(String songId) => _favoriteSongs.containsKey(songId);

  bool toggleFavorite(SongItem song) {
    if (_favoriteSongs.remove(song.id) != null) {
      unawaited(_database.removeLikedSong(song.id));
      _favoriteSongsSubject.add(_favoriteSongs.values.toList(growable: false));
      return false;
    }
    _favoriteSongs[song.id] = song;
    unawaited(_database.addLikedSong(song));
    _favoriteSongsSubject.add(_favoriteSongs.values.toList(growable: false));
    return true;
  }

  Future<bool> playSong(SongItem song, {List<SongItem>? newQueue}) async {
    _playbackErrorSubject.add(null);

    if (newQueue != null && newQueue.isNotEmpty) {
      _queue = List<SongItem>.from(newQueue);
      _currentIndex = _queue.indexWhere((item) => item.id == song.id);
      if (_currentIndex == -1) {
        _queue.insert(0, song);
        _currentIndex = 0;
      }
      _queueSubject.add(List<SongItem>.unmodifiable(_queue));
    } else {
      final existingIndex = _queue.indexWhere((item) => item.id == song.id);
      if (existingIndex >= 0) {
        _currentIndex = existingIndex;
      } else {
        _queue.add(song);
        _currentIndex = _queue.length - 1;
        _queueSubject.add(List<SongItem>.unmodifiable(_queue));
      }
    }

    _currentSong = song;
    _songSubject.add(song);
    _pointA = null;
    _pointB = null;
    _isAbLoopEnabled = false;

    try {
      await _database.addToHistory(song);
      final String sourceUrl;
      if (song.id.startsWith('local:')) {
        final path = song.id.substring('local:'.length);
        if (path.isEmpty) throw StateError('Local audio file path is empty.');
        sourceUrl = Uri.file(path).toString();
      } else {
        final resolution = await _resolver.resolveAudioStream(song);
        if (resolution == null || resolution.streamUrl.isEmpty) {
          throw StateError('No playable audio source found for "${song.title}".');
        }
        sourceUrl = resolution.streamUrl;
      }

      _currentStreamUrl = sourceUrl;
      await _player.setUrl(sourceUrl);
      await _player.play();
      return true;
    } catch (error) {
      _currentStreamUrl = null;
      _playbackErrorSubject.add(error.toString());
      debugPrint('Playback failed for "${song.title}": $error');
      return false;
    }
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    if (_isShuffleSubject.value && _queue.length > 1) {
      var nextIndex = _currentIndex;
      while (nextIndex == _currentIndex) {
        nextIndex = _random.nextInt(_queue.length);
      }
      _currentIndex = nextIndex;
    } else if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
    } else if (_repeatModeSubject.value == AppRepeatMode.all) {
      _currentIndex = 0;
    } else {
      return;
    }
    await playSong(_queue[_currentIndex]);
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }
    if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else if (_repeatModeSubject.value == AppRepeatMode.all) {
      _currentIndex = _queue.length - 1;
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> _handleTrackCompletion() async {
    if (_isAbLoopEnabled && hasValidAbRange) {
      await seek(_pointA!);
      await _player.play();
    } else if (_repeatModeSubject.value == AppRepeatMode.one) {
      await seek(Duration.zero);
      await _player.play();
    } else if (_currentIndex < _queue.length - 1 ||
        _repeatModeSubject.value == AppRepeatMode.all ||
        (_isShuffleSubject.value && _queue.length > 1)) {
      await skipToNext();
    }
  }

  void toggleRepeatMode() {
    final next = switch (_repeatModeSubject.value) {
      AppRepeatMode.off => AppRepeatMode.all,
      AppRepeatMode.all => AppRepeatMode.one,
      AppRepeatMode.one => AppRepeatMode.off,
    };
    _repeatModeSubject.add(next);
  }

  void toggleShuffle() => _isShuffleSubject.add(!_isShuffleSubject.value);

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position < Duration.zero ? Duration.zero : position);
  }

  Future<void> stop() async => _player.stop();
}

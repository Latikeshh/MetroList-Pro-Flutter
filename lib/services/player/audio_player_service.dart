library;

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../innertube/models/yt_item.dart';
import 'audio_source_resolver.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

enum AppRepeatMode { off, one, all }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final AudioSourceResolver _resolver = AudioSourceResolver();

  final BehaviorSubject<SongItem?> _songSubject = BehaviorSubject<SongItem?>.seeded(null);
  final BehaviorSubject<List<SongItem>> _queueSubject = BehaviorSubject<List<SongItem>>.seeded([]);
  final BehaviorSubject<AppRepeatMode> _repeatModeSubject = BehaviorSubject<AppRepeatMode>.seeded(AppRepeatMode.off);
  final BehaviorSubject<bool> _isShuffleSubject = BehaviorSubject<bool>.seeded(false);

  final Set<String> _favoriteSongIds = {};

  SongItem? _currentSong;
  List<SongItem> _queue = [];
  int _currentIndex = -1;

  Duration? _pointA;
  Duration? _pointB;
  bool _isAbLoopEnabled = false;

  AudioPlayerService._internal() {
    _player.positionStream.listen((pos) {
      if (_isAbLoopEnabled && _pointB != null && pos >= _pointB!) {
        _player.seek(_pointA ?? Duration.zero);
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      }
    });
  }

  AudioPlayer get player => _player;
  SongItem? get currentSong => _currentSong;
  List<SongItem> get queue => List.unmodifiable(_queue);

  Duration? get pointA => _pointA;
  Duration? get pointB => _pointB;
  bool get isAbLoopEnabled => _isAbLoopEnabled;

  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<SongItem?> get currentSongStream => _songSubject.stream;
  Stream<List<SongItem>> get queueStream => _queueSubject.stream;
  Stream<AppRepeatMode> get repeatModeStream => _repeatModeSubject.stream;
  Stream<bool> get isShuffleStream => _isShuffleSubject.stream;

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  void setPointA(Duration? pos) => _pointA = pos;
  void setPointB(Duration? pos) => _pointB = pos;
  void setAbLoopEnabled(bool enabled) => _isAbLoopEnabled = enabled;

  bool isFavorite(String songId) => _favoriteSongIds.contains(songId);

  bool toggleFavorite(SongItem song) {
    if (_favoriteSongIds.contains(song.id)) {
      _favoriteSongIds.remove(song.id);
      return false;
    } else {
      _favoriteSongIds.add(song.id);
      return true;
    }
  }

  Future<bool> playSong(SongItem song, {List<SongItem>? newQueue}) async {
    try {
      if (newQueue != null && newQueue.isNotEmpty) {
        _queue = List.from(newQueue);
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) {
          _queue.insert(0, song);
          _currentIndex = 0;
        }
        _queueSubject.add(_queue);
      } else if (!_queue.any((s) => s.id == song.id)) {
        _queue.add(song);
        _currentIndex = _queue.length - 1;
        _queueSubject.add(_queue);
      }

      _currentSong = song;
      _songSubject.add(song);

      final resolution = await _resolver.resolveAudioStream(song);
      if (resolution != null && resolution.streamUrl.isNotEmpty) {
        await _player.setUrl(resolution.streamUrl);
        await _player.play();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> skipToNext() async {
    if (_queue.isEmpty) return;
    if (_isShuffleSubject.value) {
      _currentIndex = (_currentIndex + 1) % _queue.length;
    } else {
      if (_currentIndex < _queue.length - 1) {
        _currentIndex++;
      } else if (_repeatModeSubject.value == AppRepeatMode.all) {
        _currentIndex = 0;
      } else {
        return;
      }
    }
    await playSong(_queue[_currentIndex]);
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_currentIndex > 0) {
      _currentIndex--;
      await playSong(_queue[_currentIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  void _handleTrackCompletion() {
    if (_repeatModeSubject.value == AppRepeatMode.one) {
      seek(Duration.zero);
      _player.play();
    } else if (_currentIndex < _queue.length - 1 || _repeatModeSubject.value == AppRepeatMode.all) {
      skipToNext();
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

  void toggleShuffle() {
    _isShuffleSubject.add(!_isShuffleSubject.value);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> stop() async {
    await _player.stop();
  }
}

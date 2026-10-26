library;

import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import '../innertube/models/yt_item.dart';

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  SongItem? _currentSong;

  AudioPlayerService._internal();

  AudioPlayer get player => _player;
  SongItem? get currentSong => _currentSong;

  Stream<bool> get isPlayingStream => _player.playingStream;

  Stream<SongItem?> get currentSongStream =>
      BehaviorSubject<SongItem?>.seeded(_currentSong);

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

  Future<void> playSong(SongItem song, String audioUrl) async {
    try {
      _currentSong = song;
      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      // Handle playback stream error gracefully
    }
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

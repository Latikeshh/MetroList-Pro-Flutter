library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';
import 'ab_looper_sheet.dart';

class DesktopPlayerBar extends StatefulWidget {
  final VoidCallback? onExpandPlayer;

  const DesktopPlayerBar({
    super.key,
    this.onExpandPlayer,
  });

  @override
  State<DesktopPlayerBar> createState() => _DesktopPlayerBarState();
}

class _DesktopPlayerBarState extends State<DesktopPlayerBar> {
  final AudioPlayerService _playerService = AudioPlayerService();
  double _volume = 1.0;

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _openAbLooperDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'A-B Looper',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const AbLooperSheet(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<SongItem?>(
      stream: _playerService.currentSongStream,
      builder: (context, songSnapshot) {
        final song = _playerService.currentSong;
        if (song == null) return const SizedBox.shrink();

        return Container(
          height: 88,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Left: Song Info & Like Button (Fixed Width)
              SizedBox(
                width: 260,
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.thumbnailUrl != null
                          ? Image.network(
                              song.thumbnailUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                color: colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 28),
                              ),
                            )
                          : Container(
                              width: 56,
                              height: 56,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note, size: 28),
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artists.isNotEmpty
                                ? song.artists.join(', ')
                                : 'Metrolist Pro',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<List<SongItem>>(
                      stream: _playerService.favoriteSongsStream,
                      builder: (context, favSnapshot) {
                        final isFav = _playerService.isFavorite(song.id);
                        return IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav
                                ? Colors.redAccent
                                : colorScheme.onSurfaceVariant,
                          ),
                          tooltip: isFav
                              ? 'Remove from Favorites'
                              : 'Add to Favorites',
                          onPressed: () => _playerService.toggleFavorite(song),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Middle: Playback Controls & Timeline Slider
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Control Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Shuffle Button
                        StreamBuilder<bool>(
                          stream: _playerService.isShuffleStream,
                          builder: (context, shuffleSnapshot) {
                            final isShuffle = shuffleSnapshot.data ?? false;
                            return IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                size: 20,
                                color: isShuffle
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Shuffle',
                              onPressed: _playerService.toggleShuffle,
                            );
                          },
                        ),

                        // Skip Previous
                        IconButton(
                          icon:
                              const Icon(Icons.skip_previous_rounded, size: 26),
                          tooltip: 'Previous',
                          onPressed: _playerService.skipToPrevious,
                        ),

                        const SizedBox(width: 8),

                        // Play / Pause Button
                        StreamBuilder<bool>(
                          stream: _playerService.isPlayingStream,
                          builder: (context, playingSnapshot) {
                            final isPlaying = playingSnapshot.data ?? false;
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colorScheme.primary,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  size: 28,
                                  color: colorScheme.onPrimary,
                                ),
                                onPressed: _playerService.togglePlayPause,
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 8),

                        // Skip Next
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 26),
                          tooltip: 'Next',
                          onPressed: _playerService.skipToNext,
                        ),

                        // Repeat Button
                        StreamBuilder<AppRepeatMode>(
                          stream: _playerService.repeatModeStream,
                          builder: (context, repeatSnapshot) {
                            final mode =
                                repeatSnapshot.data ?? AppRepeatMode.off;
                            final icon = switch (mode) {
                              AppRepeatMode.off => Icons.repeat,
                              AppRepeatMode.all => Icons.repeat,
                              AppRepeatMode.one => Icons.repeat_one,
                            };
                            return IconButton(
                              icon: Icon(
                                icon,
                                size: 20,
                                color: mode != AppRepeatMode.off
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Repeat: ${mode.name}',
                              onPressed: _playerService.toggleRepeatMode,
                            );
                          },
                        ),
                      ],
                    ),

                    // Seek Slider & Time Indicators
                    StreamBuilder<PositionData>(
                      stream: _playerService.positionDataStream,
                      builder: (context, positionSnapshot) {
                        final positionData = positionSnapshot.data;
                        final position =
                            positionData?.position ?? Duration.zero;
                        final duration =
                            positionData?.duration ?? Duration.zero;

                        return SizedBox(
                          height: 22,
                          child: Row(
                            children: [
                              Text(
                                _formatDuration(position),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 12,
                                    ),
                                  ),
                                  child: Slider(
                                    value: (duration.inMilliseconds > 0)
                                        ? position.inMilliseconds
                                            .toDouble()
                                            .clamp(
                                                0.0,
                                                duration.inMilliseconds
                                                    .toDouble())
                                        : 0.0,
                                    min: 0.0,
                                    max: (duration.inMilliseconds > 0)
                                        ? duration.inMilliseconds.toDouble()
                                        : 1.0,
                                    onChanged: (value) {
                                      _playerService.seek(
                                        Duration(milliseconds: value.toInt()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right: Volume & Tools (Fixed Width)
              SizedBox(
                width: 240,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // A-B Looper Button
                    IconButton(
                      icon: Icon(
                        Icons.loop_rounded,
                        size: 20,
                        color: _playerService.isAbLoopEnabled
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'A-B Looper Tool',
                      onPressed: _openAbLooperDialog,
                    ),

                    // Expand Player Fullscreen
                    if (widget.onExpandPlayer != null)
                      IconButton(
                        icon: Icon(
                          Icons.open_in_full_rounded,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        tooltip: 'Expand Player',
                        onPressed: widget.onExpandPlayer,
                      ),

                    const SizedBox(width: 8),

                    // Volume Mute/Unmute Icon
                    Icon(
                      _volume == 0
                          ? Icons.volume_off_rounded
                          : (_volume < 0.5
                              ? Icons.volume_down_rounded
                              : Icons.volume_up_rounded),
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),

                    // Volume Slider
                    SizedBox(
                      width: 100,
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                            _playerService.setVolume(value);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

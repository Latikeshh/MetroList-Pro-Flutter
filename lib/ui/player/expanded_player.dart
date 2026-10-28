library;

import 'package:flutter/material.dart';
import '../../services/player/audio_player_service.dart';
import 'ab_looper_sheet.dart';
import 'lyrics_sheet.dart';
import 'equalizer_sheet.dart';

class ExpandedPlayer extends StatefulWidget {
  const ExpandedPlayer({super.key});

  @override
  State<ExpandedPlayer> createState() => _ExpandedPlayerState();
}

class _ExpandedPlayerState extends State<ExpandedPlayer> {
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playerService = AudioPlayerService();
    final song = playerService.currentSong;

    if (song == null) return const SizedBox.shrink();

    final isFav = playerService.isFavorite(song.id);
    final isDesktopWidth = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Playing from Metrolist',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined),
            tooltip: 'Lyrics',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const LyricsSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Equalizer',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const EqualizerSheet(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.repeat_one_rounded),
            tooltip: 'A-B Looper',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AbLooperSheet(),
              );
            },
          ),
        ],
      ),
      body: isDesktopWidth
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48.0, vertical: 24.0),
              child: Row(
                children: [
                  // Left Column: Album Art & Track Info
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24.0),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 360,
                                maxHeight: 360,
                              ),
                              child: song.thumbnailUrl != null
                                  ? Image.network(
                                      song.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                        child: const Icon(Icons.music_note,
                                            size: 80),
                                      ),
                                    )
                                  : Container(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      child: const Icon(Icons.music_note,
                                          size: 80),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          song.artists.isNotEmpty
                              ? song.artists.join(', ')
                              : 'Metrolist Pro',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48),

                  // Right Column: Controls, Seek Slider & Actions
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 28,
                                color: isFav ? Colors.redAccent : null,
                              ),
                              tooltip: isFav
                                  ? 'Remove from Favorites'
                                  : 'Add to Favorites',
                              onPressed: () {
                                setState(() {
                                  playerService.toggleFavorite(song);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Timeline Slider
                        StreamBuilder<PositionData>(
                          stream: playerService.positionDataStream,
                          builder: (context, snapshot) {
                            final positionData = snapshot.data;
                            final position =
                                positionData?.position ?? Duration.zero;
                            final duration =
                                positionData?.duration ?? Duration.zero;

                            return Column(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 6),
                                  ),
                                  child: Slider(
                                    value: position.inMilliseconds
                                        .toDouble()
                                        .clamp(
                                            0.0,
                                            duration.inMilliseconds
                                                .toDouble()
                                                .clamp(1.0, double.infinity)),
                                    max: duration.inMilliseconds
                                        .toDouble()
                                        .clamp(1.0, double.infinity),
                                    onChanged: (value) {
                                      playerService.seek(Duration(
                                          milliseconds: value.round()));
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(position),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        _formatDuration(duration),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 32),

                        // Playback Transport Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StreamBuilder<bool>(
                              stream: playerService.isShuffleStream,
                              builder: (context, snapshot) {
                                final isShuffle = snapshot.data ?? false;
                                return IconButton(
                                  icon: Icon(
                                    Icons.shuffle_rounded,
                                    size: 24,
                                    color: isShuffle
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                                  tooltip: 'Shuffle',
                                  onPressed: playerService.toggleShuffle,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded,
                                  size: 36),
                              tooltip: 'Previous',
                              onPressed: playerService.skipToPrevious,
                            ),
                            StreamBuilder<bool>(
                              stream: playerService.isPlayingStream,
                              builder: (context, snapshot) {
                                final isPlaying = snapshot.data ?? false;
                                return FloatingActionButton.large(
                                  elevation: 4,
                                  onPressed: playerService.togglePlayPause,
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 40,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.skip_next_rounded, size: 36),
                              tooltip: 'Next',
                              onPressed: playerService.skipToNext,
                            ),
                            StreamBuilder<AppRepeatMode>(
                              stream: playerService.repeatModeStream,
                              builder: (context, snapshot) {
                                final mode = snapshot.data ?? AppRepeatMode.off;
                                final icon = mode == AppRepeatMode.one
                                    ? Icons.repeat_one_rounded
                                    : Icons.repeat_rounded;
                                final color = mode != AppRepeatMode.off
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant;
                                return IconButton(
                                  icon: Icon(icon, size: 24, color: color),
                                  tooltip: 'Repeat',
                                  onPressed: playerService.toggleRepeatMode,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  const Spacer(),
                  Center(
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 320,
                            maxHeight: 320,
                          ),
                          child: song.thumbnailUrl != null
                              ? Image.network(
                                  song.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    child:
                                        const Icon(Icons.music_note, size: 80),
                                  ),
                                )
                              : Container(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                                  child: const Icon(Icons.music_note, size: 80),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              song.artists.isNotEmpty
                                  ? song.artists.join(', ')
                                  : 'Metrolist Pro',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 28,
                          color: isFav ? Colors.redAccent : null,
                        ),
                        onPressed: () {
                          setState(() {
                            playerService.toggleFavorite(song);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<PositionData>(
                    stream: playerService.positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      final position = positionData?.position ?? Duration.zero;
                      final duration = positionData?.duration ?? Duration.zero;

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                            ),
                            child: Slider(
                              value: position.inMilliseconds.toDouble().clamp(
                                  0.0,
                                  duration.inMilliseconds
                                      .toDouble()
                                      .clamp(1.0, double.infinity)),
                              max: duration.inMilliseconds
                                  .toDouble()
                                  .clamp(1.0, double.infinity),
                              onChanged: (value) {
                                playerService.seek(
                                    Duration(milliseconds: value.round()));
                              },
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(position),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StreamBuilder<bool>(
                        stream: playerService.isShuffleStream,
                        builder: (context, snapshot) {
                          final isShuffle = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              size: 24,
                              color: isShuffle
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            onPressed: playerService.toggleShuffle,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 36),
                        onPressed: playerService.skipToPrevious,
                      ),
                      StreamBuilder<bool>(
                        stream: playerService.isPlayingStream,
                        builder: (context, snapshot) {
                          final isPlaying = snapshot.data ?? false;
                          return FloatingActionButton.large(
                            elevation: 4,
                            onPressed: playerService.togglePlayPause,
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 36),
                        onPressed: playerService.skipToNext,
                      ),
                      StreamBuilder<AppRepeatMode>(
                        stream: playerService.repeatModeStream,
                        builder: (context, snapshot) {
                          final mode = snapshot.data ?? AppRepeatMode.off;
                          final icon = mode == AppRepeatMode.one
                              ? Icons.repeat_one_rounded
                              : Icons.repeat_rounded;
                          final color = mode != AppRepeatMode.off
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant;
                          return IconButton(
                            icon: Icon(icon, size: 24, color: color),
                            onPressed: playerService.toggleRepeatMode,
                          );
                        },
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
            ),
    );
  }
}

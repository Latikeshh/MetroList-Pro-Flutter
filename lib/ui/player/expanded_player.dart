library;

import 'package:flutter/material.dart';
import '../../services/player/audio_player_service.dart';
import 'ab_looper_sheet.dart';

class ExpandedPlayer extends StatelessWidget {
  const ExpandedPlayer({super.key});

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Playing from Search',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.repeat_one_rounded),
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
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            const Spacer(),

            // Cover Art Card
            Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24.0),
                  child: song.thumbnailUrl != null
                      ? Image.network(
                          song.thumbnailUrl!,
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.width * 0.8,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            height: MediaQuery.of(context).size.width * 0.8,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note, size: 80),
                          ),
                        )
                      : Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.width * 0.8,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.music_note, size: 80),
                        ),
                ),
              ),
            ),

            const Spacer(),

            // Song Title & Artist
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artists.isNotEmpty ? song.artists.join(', ') : 'Metrolist Pro',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite_border_rounded, size: 28),
                  onPressed: () {},
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seek Slider & Duration Labels
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
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: position.inMilliseconds
                            .toDouble()
                            .clamp(0.0, duration.inMilliseconds.toDouble().clamp(1.0, double.infinity)),
                        max: duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                        onChanged: (value) {
                          playerService.seek(Duration(milliseconds: value.round()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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

            // Playback Transport Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded, size: 24),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                  onPressed: () {},
                ),
                StreamBuilder<bool>(
                  stream: playerService.isPlayingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return FloatingActionButton.large(
                      elevation: 4,
                      onPressed: () {
                        playerService.togglePlayPause();
                      },
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 40,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.repeat_rounded, size: 24),
                  onPressed: () {},
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

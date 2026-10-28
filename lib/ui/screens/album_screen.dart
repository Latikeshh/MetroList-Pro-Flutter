library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class AlbumScreen extends StatelessWidget {
  final String albumId;
  final String title;
  final String? artist;
  final String? thumbnailUrl;
  final String? year;

  const AlbumScreen({
    super.key,
    required this.albumId,
    required this.title,
    this.artist,
    this.thumbnailUrl,
    this.year,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final playerService = AudioPlayerService();

    final sampleTracks = List.generate(
      10,
      (index) => SongItem(
        id: 'album_track_${albumId}_$index',
        title: '$title - Track ${index + 1}',
        artists: [artist ?? 'Metrolist Artist'],
        thumbnailUrl: thumbnailUrl,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied link for $title')),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Album Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: thumbnailUrl != null
                        ? Image.network(
                            thumbnailUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 200,
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.album_rounded, size: 80),
                            ),
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.album_rounded, size: 80),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artist ?? 'Metrolist Artist'} • ${year ?? '2026'} • 10 Tracks',
                    style: TextStyle(
                        color: colorScheme.onSurfaceVariant, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play All'),
                        onPressed: () {
                          playerService.playSong(sampleTracks.first,
                              newQueue: sampleTracks);
                        },
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Shuffle'),
                        onPressed: () {
                          playerService.toggleShuffle();
                          playerService.playSong(sampleTracks.first,
                              newQueue: sampleTracks);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Tracklist
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = sampleTracks[index];
                  return ListTile(
                    leading: SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(track.artists.join(', ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        playerService.playSong(track, newQueue: sampleTracks);
                      },
                    ),
                    onTap: () {
                      playerService.playSong(track, newQueue: sampleTracks);
                    },
                  );
                },
                childCount: sampleTracks.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

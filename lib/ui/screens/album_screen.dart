library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/innertube/youtube_service.dart';
import '../../services/player/audio_player_service.dart';

class AlbumScreen extends StatefulWidget {
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
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();
  late Future<List<SongItem>> _tracksFuture;

  @override
  void initState() {
    super.initState();
    _tracksFuture = _ytService.getPlaylistPage(widget.albumId);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Album'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied link for ${widget.title}')),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<SongItem>>(
        future: _tracksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tracks = snapshot.data ?? [];

          return CustomScrollView(
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
                        child: widget.thumbnailUrl != null &&
                                widget.thumbnailUrl!.isNotEmpty
                            ? Image.network(
                                widget.thumbnailUrl!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 200,
                                  height: 200,
                                  color: colorScheme.surfaceContainerHighest,
                                  child:
                                      const Icon(Icons.album_rounded, size: 80),
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
                        widget.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.artist ?? 'Artist'} • ${widget.year ?? ''} • ${tracks.length} Tracks',
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      if (tracks.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilledButton.icon(
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Play All'),
                              onPressed: () {
                                _playerService.playSong(tracks.first,
                                    newQueue: tracks);
                              },
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.shuffle_rounded),
                              label: const Text('Shuffle'),
                              onPressed: () {
                                _playerService.toggleShuffle();
                                _playerService.playSong(tracks.first,
                                    newQueue: tracks);
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Tracklist
              if (tracks.isNotEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final track = tracks[index];
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
                          subtitle: Text(track.artists.map((a) => a.name).join(', ')),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () {
                              _playerService.playSong(track, newQueue: tracks);
                            },
                          ),
                          onTap: () {
                            _playerService.playSong(track, newQueue: tracks);
                          },
                        );
                      },
                      childCount: tracks.length,
                    ),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No tracks found for this album.'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

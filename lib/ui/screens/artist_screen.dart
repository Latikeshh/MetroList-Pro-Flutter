library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/innertube/youtube_service.dart';
import '../../services/player/audio_player_service.dart';

class ArtistScreen extends StatefulWidget {
  final String artistId;
  final String name;
  final String? thumbnailUrl;
  final String? subscribers;

  const ArtistScreen({
    super.key,
    required this.artistId,
    required this.name,
    this.thumbnailUrl,
    this.subscribers,
  });

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();

  late Future<List<SongItem>> _artistSongsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _artistSongsFuture = _ytService.search(widget.name).then((results) {
      return results.whereType<SongItem>().toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Top Songs'),
            Tab(text: 'Albums & Singles'),
          ],
        ),
      ),
      body: FutureBuilder<List<SongItem>>(
        future: _artistSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final topSongs = snapshot.data ?? [];

          return Column(
            children: [
              // Artist Banner & Header
              Container(
                padding: const EdgeInsets.all(20),
                color: colorScheme.surfaceContainerHigh,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: widget.thumbnailUrl != null &&
                              widget.thumbnailUrl!.isNotEmpty
                          ? NetworkImage(widget.thumbnailUrl!)
                          : null,
                      child: widget.thumbnailUrl == null ||
                              widget.thumbnailUrl!.isEmpty
                          ? const Icon(Icons.person_rounded, size: 44)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subscribers ?? 'Artist Discography',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (topSongs.isNotEmpty)
                                FilledButton.icon(
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Radio'),
                                  onPressed: () {
                                    _playerService.playSong(topSongs.first,
                                        newQueue: topSongs);
                                  },
                                ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                icon:
                                    const Icon(Icons.favorite_border_rounded),
                                label: const Text('Subscribe'),
                                onPressed: () {
                                  _ytService.subscribeChannel(
                                      widget.artistId, true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Subscribed to ${widget.name}'),
                                    ),
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
              ),

              // Tabs Body
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Top Songs List
                    if (topSongs.isNotEmpty)
                      ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: topSongs.length,
                        itemBuilder: (context, index) {
                          final song = topSongs[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 24,
                              child: Text(
                                '#${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              song.artists.map((a) => a.name).join(', '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: () => _playerService.playSong(song,
                                  newQueue: topSongs),
                            ),
                            onTap: () => _playerService.playSong(song,
                                newQueue: topSongs),
                          );
                        },
                      )
                    else
                      const Center(child: Text('No songs found for artist')),

                    // Tab 2: Discography / Catalog
                    if (topSongs.isNotEmpty)
                      ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: topSongs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final song = topSongs[index];
                          return ListTile(
                            leading: const Icon(Icons.album_rounded),
                            title: Text(song.title),
                            subtitle: Text(song.artists.map((a) => a.name).join(', ')),
                            onTap: () => _playerService.playSong(song),
                          );
                        },
                      )
                    else
                      const Center(child: Text('No albums or EPs found')),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

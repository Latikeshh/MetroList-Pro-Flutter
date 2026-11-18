library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/innertube/youtube_service.dart';
import '../../services/player/audio_player_service.dart';

class MoodDetailScreen extends StatefulWidget {
  final String moodTitle;
  final Color stripeColor;

  const MoodDetailScreen({
    super.key,
    required this.moodTitle,
    this.stripeColor = const Color(0xFF6750A4),
  });

  @override
  State<MoodDetailScreen> createState() => _MoodDetailScreenState();
}

class _MoodDetailScreenState extends State<MoodDetailScreen> {
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();
  late Future<List<SongItem>> _moodSongsFuture;

  @override
  void initState() {
    super.initState();
    _moodSongsFuture = _ytService.search(widget.moodTitle).then((results) {
      return results.whereType<SongItem>().toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moodTitle),
      ),
      body: FutureBuilder<List<SongItem>>(
        future: _moodSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final moodSongs = snapshot.data ?? [];

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Banner
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [widget.stripeColor, widget.stripeColor.withOpacity(0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.moodTitle} Mix & Stations',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hand-curated tracks matching your ${widget.moodTitle} mood.',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 16),
                            if (moodSongs.isNotEmpty)
                              FilledButton.tonalIcon(
                                icon: const Icon(Icons.radio_rounded),
                                label: Text('Start ${widget.moodTitle} Radio'),
                                onPressed: () {
                                  _playerService.playSong(moodSongs.first,
                                      newQueue: moodSongs);
                                },
                              ),
                          ],
                        ),
                      ),
                      const Icon(Icons.music_note_rounded,
                          size: 72, color: Colors.white30),
                    ],
                  ),
                ),
              ),

              // Track Grid / List
              if (moodSongs.isNotEmpty)
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: isDesktop
                      ? SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            childAspectRatio: 0.78,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = moodSongs[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                color: colorScheme.surfaceContainer,
                                child: InkWell(
                                  onTap: () => _playerService.playSong(song,
                                      newQueue: moodSongs),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Container(
                                          color: widget.stripeColor
                                              .withOpacity(0.3),
                                          child: const Center(
                                            child: Icon(Icons.music_note,
                                                size: 48),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Text(song.title,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            maxLines: 1),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            childCount: moodSongs.length,
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final song = moodSongs[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      widget.stripeColor.withOpacity(0.2),
                                  child: Icon(Icons.music_note_rounded,
                                      color: widget.stripeColor),
                                ),
                                title: Text(song.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    song.artists.map((a) => a.name).join(', ')),
                                trailing: IconButton(
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  onPressed: () => _playerService.playSong(song,
                                      newQueue: moodSongs),
                                ),
                                onTap: () => _playerService.playSong(song,
                                    newQueue: moodSongs),
                              );
                            },
                            childCount: moodSongs.length,
                          ),
                        ),
                )
              else
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('No tracks found for this mood category.'),
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

library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class MoodDetailScreen extends StatelessWidget {
  final String moodTitle;
  final Color stripeColor;

  const MoodDetailScreen({
    super.key,
    required this.moodTitle,
    this.stripeColor = const Color(0xFF6750A4),
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;
    final playerService = AudioPlayerService();

    final sampleSongs = List.generate(
      8,
      (index) => SongItem(
        id: 'mood_${moodTitle}_$index',
        title: '$moodTitle Essential Track #${index + 1}',
        artists: [moodTitle, 'Metrolist Radio'],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(moodTitle),
      ),
      body: CustomScrollView(
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
                  colors: [stripeColor, stripeColor.withOpacity(0.4)],
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
                          '$moodTitle Mix & Stations',
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
                          'Hand-curated tracks and playlists matching your $moodTitle mood.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.radio_rounded),
                          label: Text('Start $moodTitle Radio'),
                          onPressed: () {
                            playerService.playSong(sampleSongs.first,
                                newQueue: sampleSongs);
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
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        final song = sampleSongs[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          color: colorScheme.surfaceContainer,
                          child: InkWell(
                            onTap: () => playerService.playSong(song,
                                newQueue: sampleSongs),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    color: stripeColor.withOpacity(0.3),
                                    child: const Center(
                                        child:
                                            Icon(Icons.music_note, size: 48)),
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
                      childCount: sampleSongs.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final song = sampleSongs[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: stripeColor.withOpacity(0.2),
                            child: Icon(Icons.music_note_rounded,
                                color: stripeColor),
                          ),
                          title: Text(song.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(song.artists.join(', ')),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow_rounded),
                            onPressed: () => playerService.playSong(song,
                                newQueue: sampleSongs),
                          ),
                          onTap: () => playerService.playSong(song,
                              newQueue: sampleSongs),
                        );
                      },
                      childCount: sampleSongs.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
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
  final AudioPlayerService _playerService = AudioPlayerService();

  late final List<SongItem> _topSongs;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _topSongs = List.generate(
      5,
      (index) => SongItem(
        id: 'artist_song_${widget.artistId}_$index',
        title: '${widget.name} - Hit Track #${index + 1}',
        artists: [widget.name],
        thumbnailUrl: widget.thumbnailUrl,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview & Songs'),
            Tab(text: 'Albums & EPs'),
            Tab(text: 'Similar Artists'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Artist Banner & Header
          Container(
            padding: const EdgeInsets.all(20),
            color: colorScheme.surfaceContainerHigh,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundImage: widget.thumbnailUrl != null
                      ? NetworkImage(widget.thumbnailUrl!)
                      : null,
                  child: widget.thumbnailUrl == null
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
                        widget.subscribers ?? '2.4M Monthly Listeners',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Radio'),
                            onPressed: () {
                              _playerService.playSong(_topSongs.first,
                                  newQueue: _topSongs);
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.favorite_border_rounded),
                            label: const Text('Subscribe'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Subscribed to ${widget.name}')),
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
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _topSongs.length,
                  itemBuilder: (context, index) {
                    final song = _topSongs[index];
                    return ListTile(
                      leading: SizedBox(
                        width: 24,
                        child: Text('#${index + 1}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary)),
                      ),
                      title: Text(song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artists.join(', ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () =>
                            _playerService.playSong(song, newQueue: _topSongs),
                      ),
                      onTap: () =>
                          _playerService.playSong(song, newQueue: _topSongs),
                    );
                  },
                ),

                // Tab 2: Albums & EPs Grid
                GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 4 : 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final titles = [
                      'Album Collection Vol. $index',
                      'Live Sessions 2026',
                      'Acoustic Edition',
                      'Remix Anthology'
                    ];
                    return Card(
                      color: colorScheme.surfaceContainer,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: colorScheme.primaryContainer,
                                child: const Center(
                                    child: Icon(Icons.album_rounded, size: 48)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(titles[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Tab 3: Similar Artists
                ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    final names = [
                      'Lofi Collective',
                      'Synthwave Express',
                      'The Metrolist Band',
                      'Unplugged Voices'
                    ];
                    return ListTile(
                      leading:
                          const CircleAvatar(child: Icon(Icons.person_rounded)),
                      title: Text(names[index],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Similar Musical Style'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

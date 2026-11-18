library;

import 'package:flutter/material.dart';
import '../../../services/innertube/models/explore_models.dart';
import '../../../services/innertube/models/yt_item.dart';
import '../../../services/innertube/youtube_service.dart';
import '../../../services/player/audio_player_service.dart';
import '../album_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();

  late Future<ExplorePageData> _exploreFuture;
  late Future<List<SongItem>> _chartsFuture;
  int _selectedFilterIndex = 0;

  final List<String> _filters = [
    'All',
    'New Releases',
    'Moods & Genres',
    'Top Charts'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _exploreFuture = _ytService.getExplorePage();
      _chartsFuture = _ytService.getChartsPage().then((chartsPage) {
        if (chartsPage.sections.isNotEmpty) {
          return chartsPage.sections.first.items.whereType<SongItem>().toList();
        }
        return <SongItem>[];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore & Discover',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Explore Data',
            onPressed: _loadData,
          ),
        ],
      ),
      body: FutureBuilder<ExplorePageData>(
        future: _exploreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              const ExplorePageData(
                newReleaseAlbums: [],
                moodsAndGenres: [],
              );

          final albums = data.newReleaseAlbums;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedFilterIndex;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(_filters[index]),
                        selectedColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // 1. New Releases Section
                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1) ...[
                  Text(
                    'New Releases & Fresh Albums',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 210,
                    child: albums.isNotEmpty
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: albums.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final album = albums[index];
                              return SizedBox(
                                width: 140,
                                child: Card(
                                  elevation: 1,
                                  clipBehavior: Clip.antiAlias,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AlbumScreen(
                                            albumId: album.browseId,
                                            title: album.title,
                                            artist: album.artist,
                                            thumbnailUrl: album.thumbnailUrl,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              album.thumbnailUrl != null &&
                                                      album.thumbnailUrl!
                                                          .isNotEmpty
                                                  ? Image.network(
                                                      album.thumbnailUrl!,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Container(
                                                      color: colorScheme
                                                          .primaryContainer,
                                                      child: const Icon(
                                                        Icons.album_rounded,
                                                        size: 54,
                                                      ),
                                                    ),
                                              Positioned(
                                                right: 6,
                                                bottom: 6,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: colorScheme.primary,
                                                  ),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.all(6.0),
                                                    child: Icon(
                                                      Icons.play_arrow_rounded,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                album.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                album.artist ?? 'Album',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Text('No new release albums found'),
                          ),
                  ),
                  const SizedBox(height: 28),
                ],

                // 2. Moods & Genres Grid Section
                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
                  Text(
                    'Moods & Genres',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2,
                      childAspectRatio: isDesktop ? 3.0 : 2.4,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: data.moodsAndGenres.length,
                    itemBuilder: (context, index) {
                      final mood = data.moodsAndGenres[index];
                      final color = Color(mood.stripeColor | 0xFF000000);

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Exploring ${mood.title} mood category',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.9),
                                  color.withOpacity(0.4),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    mood.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white54,
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                ],

                // 3. Regional Top Charts & Trending List Section
                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) ...[
                  Text(
                    'Top 100 Global Charts & Trending',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<SongItem>>(
                    future: _chartsFuture,
                    builder: (context, chartSnapshot) {
                      if (chartSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final chartSongs = chartSnapshot.data ?? [];
                      if (chartSongs.isEmpty) {
                        return const Text('No trending charts found.');
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chartSongs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final song = chartSongs[index];
                          return ListTile(
                            leading: SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 28,
                                    child: Text(
                                      '#${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: song.thumbnailUrl != null &&
                                            song.thumbnailUrl!.isNotEmpty
                                        ? Image.network(
                                            song.thumbnailUrl!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 48,
                                            height: 48,
                                            color: colorScheme
                                                .surfaceContainerHighest,
                                            child: const Icon(Icons.music_note),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              song.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              song.artists.map((a) => a.name).join(', '),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.play_arrow_rounded),
                              onPressed: () => _playerService.playSong(song),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

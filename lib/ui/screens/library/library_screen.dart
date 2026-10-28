library;

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/innertube/models/yt_item.dart';
import '../../../services/player/audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AudioPlayerService _playerService = AudioPlayerService();
  final List<SongItem> _localSongs = [];

  final List<Map<String, String>> _sampleAlbums = [
    {
      'title': 'Midnight Frequency',
      'subtitle': 'Album • 12 Tracks',
      'type': 'Album'
    },
    {
      'title': 'Chill Lofi Beats',
      'subtitle': 'Playlist • 45 Tracks',
      'type': 'Playlist'
    },
    {
      'title': 'Workout Euphoria',
      'subtitle': 'Playlist • 30 Tracks',
      'type': 'Playlist'
    },
    {
      'title': 'Velvet Horizon',
      'subtitle': 'Album • 9 Tracks',
      'type': 'Album'
    },
  ];

  final List<Map<String, String>> _sampleArtists = [
    {'name': 'The Metrolist Band', 'subscribers': '2.4M Listeners'},
    {'name': 'Lofi Collective', 'subscribers': '1.8M Listeners'},
    {'name': 'Synthwave Express', 'subscribers': '950K Listeners'},
    {'name': 'Unplugged Voices', 'subscribers': '520K Listeners'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _importLocalAudioFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        dialogTitle: 'Select Music Files to Import',
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              final song = SongItem(
                id: 'local:${file.path!}',
                title: file.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
                artists: const ['Local File'],
              );
              if (!_localSongs.any((s) => s.id == song.id)) {
                _localSongs.add(song);
              }
            }
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Imported ${result.files.length} song(s) into Library')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import local files')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 720;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your Library',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos_rounded),
            tooltip: 'Import Local Music Files',
            onPressed: _importLocalAudioFiles,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Favorites'),
            Tab(text: 'Local Music'),
            Tab(text: 'Albums & Playlists'),
            Tab(text: 'Artists'),
            Tab(text: 'Queue'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Persisted Favorites
          StreamBuilder<List<SongItem>>(
            stream: _playerService.favoriteSongsStream,
            builder: (context, snapshot) {
              final songs = snapshot.data ?? const <SongItem>[];
              if (songs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_rounded,
                          size: 64, color: Colors.redAccent),
                      SizedBox(height: 16),
                      Text('Your favorite songs will appear here'),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: songs.length,
                itemBuilder: (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: song.thumbnailUrl == null
                          ? const Icon(Icons.music_note_rounded)
                          : Image.network(
                              song.thumbnailUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.music_note_rounded),
                            ),
                    ),
                    title: Text(song.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artists.join(', '),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _playerService.playSong(song),
                    trailing: IconButton(
                      tooltip: 'Remove from favorites',
                      icon: const Icon(Icons.favorite_rounded,
                          color: Colors.redAccent),
                      onPressed: () => _playerService.toggleFavorite(song),
                    ),
                  );
                },
              );
            },
          ),

          // Tab 2: Local Imported Songs
          _localSongs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open_rounded,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text('No local music imported yet'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_open_rounded),
                        label: const Text('Import Local Music Files'),
                        onPressed: _importLocalAudioFiles,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _localSongs.length,
                  itemBuilder: (context, index) {
                    final song = _localSongs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: const Icon(Icons.audio_file_rounded),
                      ),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Local Storage File'),
                      onTap: () => _playerService.playSong(song),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () {
                          _playerService.playSong(song);
                        },
                      ),
                    );
                  },
                ),

          // Tab 3: Albums & Playlists Grid/List
          isDesktop
              ? GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _sampleAlbums.length,
                  itemBuilder: (context, index) {
                    final item = _sampleAlbums[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      color: colorScheme.surfaceContainerHigh,
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Opening ${item['title']}')),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Container(
                                color: colorScheme.primaryContainer,
                                child: Center(
                                  child: Icon(
                                    item['type'] == 'Album'
                                        ? Icons.album_rounded
                                        : Icons.queue_music_rounded,
                                    size: 48,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['subtitle']!,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _sampleAlbums.length,
                  itemBuilder: (context, index) {
                    final item = _sampleAlbums[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          item['type'] == 'Album'
                              ? Icons.album_rounded
                              : Icons.queue_music_rounded,
                        ),
                      ),
                      title: Text(item['title']!,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(item['subtitle']!),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${item['title']}')),
                        );
                      },
                    );
                  },
                ),

          // Tab 4: Artists List
          ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _sampleArtists.length,
            itemBuilder: (context, index) {
              final artist = _sampleArtists[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  child: const Icon(Icons.person_rounded),
                ),
                title: Text(artist['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(artist['subscribers']!),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening artist ${artist['name']}')),
                  );
                },
              );
            },
          ),

          // Tab 5: Current Playback Queue
          StreamBuilder<List<SongItem>>(
            stream: _playerService.queueStream,
            builder: (context, snapshot) {
              final queue = snapshot.data ?? [];
              if (queue.isEmpty) {
                return const Center(
                  child: Text('Playback queue is empty'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final song = queue[index];
                  final isCurrent = _playerService.currentSong?.id == song.id;
                  return ListTile(
                    selected: isCurrent,
                    leading: CircleAvatar(
                      backgroundColor: isCurrent
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      child: Icon(
                        isCurrent
                            ? Icons.graphic_eq_rounded
                            : Icons.music_note_rounded,
                        color: isCurrent ? colorScheme.onPrimary : null,
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      song.artists.isNotEmpty
                          ? song.artists.join(', ')
                          : 'Metrolist',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.play_arrow_rounded),
                      onPressed: () {
                        _playerService.playSong(song);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

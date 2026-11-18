library;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/innertube/models/yt_item.dart';
import '../../../services/player/audio_player_service.dart';
import '../../../services/storage/local_database.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AudioPlayerService _playerService = AudioPlayerService();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  final List<SongItem> _localSongs = [];
  late Future<List<SongItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _historyFuture = _dbService.getHistory();
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
                artists: const [Artist(name: 'Local File')],
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
                'Imported ${result.files.length} song(s) into Library',
              ),
            ),
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
            Tab(text: 'Listening History'),
            Tab(text: 'Local Music'),
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
                      child: song.thumbnailUrl == null ||
                              song.thumbnailUrl!.isEmpty
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
                    subtitle: Text(
                        song.artists.map((a) => a.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
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

          // Tab 2: Listening History
          FutureBuilder<List<SongItem>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(
                  child: Text('No played history songs yet.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final song = history[index];
                  return ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: Text(song.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(song.artists.map((a) => a.name).join(', ')),
                    onTap: () => _playerService.playSong(song),
                  );
                },
              );
            },
          ),

          // Tab 3: Local Imported Songs
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

          // Tab 4: Current Playback Queue
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
                          ? song.artists.map((a) => a.name).join(', ')
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

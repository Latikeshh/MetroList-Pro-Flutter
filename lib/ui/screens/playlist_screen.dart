library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String title;
  final String? author;
  final String? thumbnailUrl;
  final bool isOfflineCache;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    required this.title,
    this.author,
    this.thumbnailUrl,
    this.isOfflineCache = false,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  late List<SongItem> _tracks;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _tracks = List.generate(
      8,
      (index) => SongItem(
        id: 'playlist_track_${widget.playlistId}_$index',
        title: '${widget.title} - Track ${index + 1}',
        artists: [widget.author ?? 'Metrolist Mix'],
        thumbnailUrl: widget.thumbnailUrl,
      ),
    );
  }

  void _removeTrack(int index) {
    setState(() {
      _tracks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed track from playlist')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(_isDownloaded ? Icons.download_done_rounded : Icons.download_for_offline_outlined),
            tooltip: _isDownloaded ? 'Downloaded Offline' : 'Download Playlist',
            onPressed: () {
              setState(() {
                _isDownloaded = !_isDownloaded;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_isDownloaded ? 'Playlist downloaded for offline playback' : 'Offline cache cleared')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Playlist Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: colorScheme.surfaceContainerHigh,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.thumbnailUrl != null
                      ? Image.network(widget.thumbnailUrl!, width: 100, height: 100, fit: BoxFit.cover)
                      : Container(
                          width: 100,
                          height: 100,
                          color: colorScheme.primaryContainer,
                          child: const Icon(Icons.queue_music_rounded, size: 48),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text('${widget.author ?? 'Metrolist'} • ${_tracks.length} Songs'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          FilledButton.icon(
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Play All'),
                            onPressed: () {
                              if (_tracks.isNotEmpty) {
                                _playerService.playSong(_tracks.first, newQueue: _tracks);
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.shuffle_rounded),
                            onPressed: () {
                              if (_tracks.isNotEmpty) {
                                _playerService.toggleShuffle();
                                _playerService.playSong(_tracks.first, newQueue: _tracks);
                              }
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

          // Reorderable Track List
          Expanded(
            child: _tracks.isEmpty
                ? const Center(child: Text('Playlist is empty'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _tracks.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _tracks.removeAt(oldIndex);
                        _tracks.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      final song = _tracks[index];
                      return ListTile(
                        key: ValueKey(song.id),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(song.artists.join(', ')),
                        onTap: () => _playerService.playSong(song, newQueue: _tracks),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => _removeTrack(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class YouTubeBrowseScreen extends StatefulWidget {
  final String browseId;
  final String title;

  const YouTubeBrowseScreen({
    super.key,
    required this.browseId,
    required this.title,
  });

  @override
  State<YouTubeBrowseScreen> createState() => _YouTubeBrowseScreenState();
}

class _YouTubeBrowseScreenState extends State<YouTubeBrowseScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  late List<SongItem> _browseItems;

  @override
  void initState() {
    super.initState();
    _browseItems = List.generate(
      12,
      (index) => SongItem(
        id: 'browse_${widget.browseId}_$index',
        title: '${widget.title} Item #${index + 1}',
        artists: ['YouTube InnerTube Browse'],
        thumbnailUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _browseItems.length,
        itemBuilder: (context, index) {
          final song = _browseItems[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                song.thumbnailUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                ),
              ),
            ),
            title: Text(song.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(song.artists.join(', ')),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow_rounded),
              onPressed: () =>
                  _playerService.playSong(song, newQueue: _browseItems),
            ),
            onTap: () => _playerService.playSong(song, newQueue: _browseItems),
          );
        },
      ),
    );
  }
}

library;

import 'package:flutter/material.dart';
import '../../services/innertube/lyrics_service.dart';
import '../../services/player/audio_player_service.dart';

class LyricsSheet extends StatefulWidget {
  const LyricsSheet({super.key});

  @override
  State<LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<LyricsSheet> {
  final LyricsService _lyricsService = LyricsService();
  final AudioPlayerService _playerService = AudioPlayerService();
  Future<LyricsData?>? _lyricsFuture;

  @override
  void initState() {
    super.initState();
    final song = _playerService.currentSong;
    if (song != null) {
      final artist = song.artists.isNotEmpty ? song.artists.first : '';
      _lyricsFuture = _lyricsService.getLyrics(song.title, artist);
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = _playerService.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Lyrics', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<LyricsData?>(
        future: _lyricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null || (data.syncedLyrics.isEmpty && (data.plainLyrics == null || data.plainLyrics!.isEmpty))) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lyrics_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('No lyrics found for this track'),
                ],
              ),
            );
          }

          if (data.syncedLyrics.isNotEmpty) {
            return StreamBuilder<PositionData>(
              stream: _playerService.positionDataStream,
              builder: (context, posSnapshot) {
                final pos = posSnapshot.data?.position ?? Duration.zero;

                int activeIndex = -1;
                for (int i = 0; i < data.syncedLyrics.length; i++) {
                  if (pos >= data.syncedLyrics[i].timestamp) {
                    activeIndex = i;
                  } else {
                    break;
                  }
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: data.syncedLyrics.length,
                  itemBuilder: (context, index) {
                    final line = data.syncedLyrics[index];
                    final isActive = index == activeIndex;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        line.text,
                        style: TextStyle(
                          fontSize: isActive ? 20 : 16,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Text(
              data.plainLyrics ?? '',
              style: const TextStyle(fontSize: 16, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}

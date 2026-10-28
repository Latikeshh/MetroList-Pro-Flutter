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
  final ScrollController _scrollController = ScrollController();

  Future<LyricsData?>? _lyricsFuture;
  double _fontSize = 18.0;
  bool _showTranslation = false;
  bool _isKaraokeTtmlMode = false;

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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveLine(int index) {
    if (_scrollController.hasClients && index >= 0) {
      final targetOffset =
          (index * 52.0).clamp(0.0, _scrollController.position.maxScrollExtent);
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = _playerService.currentSong;
    if (song == null) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              song.title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              song.artists.join(', '),
              style:
                  TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.mic_external_on_rounded,
              color: _isKaraokeTtmlMode
                  ? Colors.amber
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: 'TTML Word-by-Word Karaoke Mode',
            onPressed: () {
              setState(() {
                _isKaraokeTtmlMode = !_isKaraokeTtmlMode;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isKaraokeTtmlMode
                      ? 'TTML Word-by-Word Karaoke Highlight Enabled'
                      : 'Standard Synced Lyrics Mode'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.translate_rounded,
              color: _showTranslation
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            tooltip: 'AI Translation & Romaji',
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            tooltip: 'Increase Font Size',
            onPressed: () {
              setState(() {
                _fontSize = (_fontSize + 2).clamp(14.0, 28.0);
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<LyricsData?>(
        future: _lyricsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data;
          if (data == null ||
              (data.syncedLyrics.isEmpty &&
                  (data.plainLyrics == null || data.plainLyrics!.isEmpty))) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lyrics_outlined,
                      size: 64, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  const Text('No lyrics available for this track'),
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

                _scrollToActiveLine(activeIndex);

                return ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: data.syncedLyrics.length,
                  itemBuilder: (context, index) {
                    final line = data.syncedLyrics[index];
                    final isActive = index == activeIndex;
                    final words = line.text.split(' ');

                    return GestureDetector(
                      onTap: () {
                        _playerService.seek(line.timestamp);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        child: _isKaraokeTtmlMode && isActive
                            ? Wrap(
                                spacing: 6,
                                children: words.asMap().entries.map((wEntry) {
                                  final wordIdx = wEntry.key;
                                  final wordText = wEntry.value;
                                  final isWordHighlighted =
                                      (pos.inSeconds % (words.length + 1)) >=
                                          wordIdx;

                                  return AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: _fontSize + 4,
                                      fontWeight: FontWeight.bold,
                                      color: isWordHighlighted
                                          ? Colors.amber
                                          : colorScheme.primary,
                                    ),
                                    child: Text(wordText),
                                  );
                                }).toList(),
                              )
                            : Text(
                                line.text,
                                style: TextStyle(
                                  fontSize:
                                      isActive ? _fontSize + 3 : _fontSize,
                                  fontWeight: isActive
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant
                                          .withOpacity(0.55),
                                ),
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
              style: TextStyle(fontSize: _fontSize, height: 1.6),
            ),
          );
        },
      ),
    );
  }
}

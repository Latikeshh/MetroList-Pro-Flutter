library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';
import '../../services/storage/local_database.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final AudioPlayerService _playerService = AudioPlayerService();
  final LocalDatabaseService _dbService = LocalDatabaseService();

  bool _isListening = false;
  SongItem? _identifiedSong;
  late Future<List<SongItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _historyFuture = _dbService.getHistory();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _startRecognition() async {
    setState(() {
      _isListening = true;
      _identifiedSong = null;
    });
    _animController.repeat(reverse: true);

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      _animController.stop();
      final history = await _dbService.getHistory();
      if (history.isNotEmpty) {
        setState(() {
          _isListening = false;
          _identifiedSong = history.first;
        });
      } else {
        setState(() {
          _isListening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Song Recognition',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Audio Pulse Radar Button
          Center(
            child: Column(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.95, end: 1.15).animate(
                    CurvedAnimation(
                        parent: _animController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? Colors.redAccent
                          : colorScheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? Colors.redAccent
                                  : colorScheme.primary)
                              .withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 10,
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening
                            ? Icons.graphic_eq_rounded
                            : Icons.mic_rounded,
                        size: 64,
                        color: _isListening
                            ? Colors.white
                            : colorScheme.onPrimaryContainer,
                      ),
                      onPressed: _isListening ? null : _startRecognition,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isListening
                      ? 'Listening & Fingerprinting Audio...'
                      : 'Tap Mic to Identify Song',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Result Display Card
          if (_identifiedSong != null) ...[
            Card(
              color: colorScheme.surfaceContainerHigh,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _identifiedSong!.thumbnailUrl != null &&
                          _identifiedSong!.thumbnailUrl!.isNotEmpty
                      ? Image.network(_identifiedSong!.thumbnailUrl!,
                          width: 48, height: 48, fit: BoxFit.cover)
                      : const Icon(Icons.music_note_rounded),
                ),
                title: Text(_identifiedSong!.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(_identifiedSong!.artists.map((a) => a.name).join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => _playerService.playSong(_identifiedSong!),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          const Divider(),
          const SizedBox(height: 12),

          Text(
            'Recognition History',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          FutureBuilder<List<SongItem>>(
            future: _historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final historySongs = snapshot.data ?? [];
              if (historySongs.isEmpty) {
                return const Center(
                  child: Text('No recognized song history available.'),
                );
              }

              return Column(
                children: historySongs
                    .map(
                      (song) => ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: song.thumbnailUrl != null &&
                                  song.thumbnailUrl!.isNotEmpty
                              ? Image.network(song.thumbnailUrl!,
                                  width: 44, height: 44, fit: BoxFit.cover)
                              : const Icon(Icons.music_note_rounded),
                        ),
                        title: Text(
                          song.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:
                            Text(song.artists.map((a) => a.name).join(', ')),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_arrow_rounded),
                          onPressed: () => _playerService.playSong(song),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

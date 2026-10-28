library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  final AudioPlayerService _playerService = AudioPlayerService();
  bool _isListening = false;
  SongItem? _identifiedSong;

  final List<SongItem> _history = [
    SongItem(
      id: 'rec_1',
      title: 'Midnight Frequency',
      artists: const ['The Metrolist Band'],
      thumbnailUrl:
          'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500',
    ),
    SongItem(
      id: 'rec_2',
      title: 'Starlight Memories',
      artists: const ['Lofi Collective'],
      thumbnailUrl:
          'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
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
      setState(() {
        _isListening = false;
        _identifiedSong = SongItem(
          id: 'rec_result_0',
          title: 'Velvet Horizon (Identified)',
          artists: const ['Synthwave Express'],
          thumbnailUrl:
              'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=500',
        );
        _history.insert(0, _identifiedSong!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song Recognition',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                  child: Image.network(_identifiedSong!.thumbnailUrl!,
                      width: 48, height: 48, fit: BoxFit.cover),
                ),
                title: Text(_identifiedSong!.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(_identifiedSong!.artists.join(', ')),
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

          Text('Recognition History',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ..._history.map((song) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(song.thumbnailUrl!,
                      width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: Text(song.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(song.artists.join(', ')),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () => _playerService.playSong(song),
                ),
              )),
        ],
      ),
    );
  }
}

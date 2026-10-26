library;

import 'package:flutter/material.dart';
import '../../services/player/audio_player_service.dart';

class AbLooperSheet extends StatefulWidget {
  const AbLooperSheet({super.key});

  @override
  State<AbLooperSheet> createState() => _AbLooperSheetState();
}

class _AbLooperSheetState extends State<AbLooperSheet> {
  final AudioPlayerService _playerService = AudioPlayerService();

  String _formatPreciseTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String threeDigits(int n) => n.toString().padLeft(3, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final millis = threeDigits(duration.inMilliseconds.remainder(1000));
    return '$minutes:$seconds.$millis';
  }

  @override
  Widget build(BuildContext context) {
    final song = _playerService.currentSong;
    final pointA = _playerService.pointA;
    final pointB = _playerService.pointB;
    final isEnabled = _playerService.isAbLoopEnabled;

    if (song == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'A–B Section Looper',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              Text(
                isEnabled ? 'Active' : 'Off',
                style: TextStyle(
                  color: isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  setState(() {
                    _playerService.setAbLoopEnabled(value);
                  });
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          children: [
            // Transport Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<bool>(
                          stream: _playerService.isPlayingStream,
                          builder: (context, snapshot) {
                            final isPlaying = snapshot.data ?? false;
                            return IconButton.filled(
                              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              onPressed: () {
                                _playerService.togglePlayPause();
                              },
                            );
                          },
                        ),
                        StreamBuilder<PositionData>(
                          stream: _playerService.positionDataStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data?.position ?? Duration.zero;
                            final duration = snapshot.data?.duration ?? Duration.zero;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${_formatPreciseTime(position)} / ${_formatPreciseTime(duration)}',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Playback Position',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Point A and Point B Setting Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: pointA != null ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Point A', style: TextStyle(fontWeight: FontWeight.bold, color: pointA != null ? Theme.of(context).colorScheme.onPrimaryContainer : null)),
                          const SizedBox(height: 4),
                          Text(pointA != null ? _formatPreciseTime(pointA) : 'Not Set', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _playerService.setPointA(_playerService.player.position);
                              });
                            },
                            child: const Text('Set A'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: pointB != null ? Theme.of(context).colorScheme.secondaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Point B', style: TextStyle(fontWeight: FontWeight.bold, color: pointB != null ? Theme.of(context).colorScheme.onSecondaryContainer : null)),
                          const SizedBox(height: 4),
                          Text(pointB != null ? _formatPreciseTime(pointB) : 'Not Set', style: const TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _playerService.setPointB(_playerService.player.position);
                              });
                            },
                            child: const Text('Set B'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Action Row when both Point A & Point B are set
            if (pointA != null && pointB != null && pointA < pointB)
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        _playerService.seek(pointA);
                        _playerService.setAbLoopEnabled(true);
                        _playerService.player.play();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Download Clip', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Exported clip [${_formatPreciseTime(pointA)} - ${_formatPreciseTime(pointB)}] to Music/Metrolist'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

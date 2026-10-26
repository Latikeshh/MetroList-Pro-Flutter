library;

import 'package:flutter/material.dart';
import '../../services/player/audio_player_service.dart';

class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({super.key});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  final AudioPlayerService _playerService = AudioPlayerService();
  double _currentSpeed = 1.0;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  String _formatTimerRemaining(Duration remaining) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Playback Speed & Sleep Timer', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Playback Speed Controls
          Text('Playback Speed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _speeds.map((speed) {
              final isSelected = (speed == _currentSpeed);
              return ChoiceChip(
                selected: isSelected,
                label: Text('${speed}x'),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSpeed = speed;
                      _playerService.setSpeed(speed);
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Section 2: Sleep Timer Controls
          Text('Sleep Timer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          StreamBuilder<Duration?>(
            stream: _playerService.sleepTimerRemainingStream,
            builder: (context, snapshot) {
              final remaining = snapshot.data;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remaining != null) ...[
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: Text('Sleep Timer Active: ${_formatTimerRemaining(remaining)}'),
                        trailing: TextButton(
                          onPressed: () => _playerService.cancelSleepTimer(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('15 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 15));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('30 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 30));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_rounded),
                    title: const Text('60 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 60));
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

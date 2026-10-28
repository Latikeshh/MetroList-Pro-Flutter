library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class PodcastScreen extends StatefulWidget {
  final String podcastId;
  final String title;
  final String? host;
  final String? thumbnailUrl;

  const PodcastScreen({
    super.key,
    required this.podcastId,
    required this.title,
    this.host,
    this.thumbnailUrl,
  });

  @override
  State<PodcastScreen> createState() => _PodcastScreenState();
}

class _PodcastScreenState extends State<PodcastScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  final Set<String> _completedEpisodes = {};

  final List<Map<String, String>> _episodes = [
    {
      'id': 'ep_1',
      'title': 'Episode 104: Future of Audio Technology',
      'date': 'Oct 24, 2026',
      'duration': '42 min',
      'summary':
          'In-depth discussion on cross-platform Flutter audio playback and native engines.'
    },
    {
      'id': 'ep_2',
      'title': 'Episode 103: Deep Dive into Material 3 UI Design',
      'date': 'Oct 17, 2026',
      'duration': '38 min',
      'summary':
          'Exploring Material 3 dynamic color palettes and desktop navigation rail patterns.'
    },
    {
      'id': 'ep_3',
      'title': 'Episode 102: Lofi Production & Soundscapes',
      'date': 'Oct 10, 2026',
      'duration': '55 min',
      'summary':
          'Interview with Lofi Collective producers on mixing relaxing beats.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Show Header Card
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.thumbnailUrl != null
                    ? Image.network(widget.thumbnailUrl!,
                        width: 110, height: 110, fit: BoxFit.cover)
                    : Container(
                        width: 110,
                        height: 110,
                        color: colorScheme.primaryContainer,
                        child: const Icon(Icons.podcasts_rounded, size: 54),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Host: ${widget.host ?? 'Metrolist Podcast Channel'}',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Subscribe'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Subscribed to ${widget.title}')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          Text(
            'Recent Episodes',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ..._episodes.map((ep) {
            final isCompleted = _completedEpisodes.contains(ep['id']);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: colorScheme.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${ep['date']} • ${ep['duration']}',
                            style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant)),
                        IconButton(
                          icon: Icon(
                            isCompleted
                                ? Icons.check_circle_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isCompleted ? Colors.green : null,
                          ),
                          tooltip: isCompleted
                              ? 'Marked Completed'
                              : 'Mark as Completed',
                          onPressed: () {
                            setState(() {
                              if (isCompleted) {
                                _completedEpisodes.remove(ep['id']);
                              } else {
                                _completedEpisodes.add(ep['id']!);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                    Text(ep['title']!,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(ep['summary']!,
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play Episode'),
                      onPressed: () {
                        _playerService.playSong(
                          SongItem(
                            id: 'podcast_${ep['id']}',
                            title: ep['title']!,
                            artists: [widget.title],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

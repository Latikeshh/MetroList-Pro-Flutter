library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/innertube/youtube_service.dart';
import '../../services/player/audio_player_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();
  String _selectedRegion = 'Global';
  late Future<List<SongItem>> _chartsFuture;

  final List<String> _regions = [
    'Global',
    'United States',
    'United Kingdom',
    'Japan',
    'India',
    'Germany'
  ];

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() {
    setState(() {
      _chartsFuture = _ytService.getChartsPage().then((chartsPage) {
        if (chartsPage.sections.isNotEmpty) {
          return chartsPage.sections.first.items.whereType<SongItem>().toList();
        }
        return <SongItem>[];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Top Charts & Trending',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Region Selector Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.public_rounded),
                const SizedBox(width: 12),
                const Text(
                  'Select Region:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _regions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _selectedRegion = val;
                        _loadChartData();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Chart Tracks List
          Expanded(
            child: FutureBuilder<List<SongItem>>(
              future: _chartsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final chartTracks = snapshot.data ?? [];
                if (chartTracks.isEmpty) {
                  return const Center(
                    child: Text('No trending charts available for this region.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: chartTracks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = chartTracks[index];
                    final isTop3 = index < 3;

                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '#${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isTop3
                                    ? Colors.amber
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: song.thumbnailUrl != null &&
                                    song.thumbnailUrl!.isNotEmpty
                                ? Image.network(
                                    song.thumbnailUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 48,
                                      height: 48,
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      child: const Icon(Icons.music_note),
                                    ),
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color:
                                        colorScheme.surfaceContainerHighest,
                                    child: const Icon(Icons.music_note),
                                  ),
                          ),
                        ],
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(song.artists.map((a) => a.name).join(', ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () => _playerService.playSong(song,
                            newQueue: chartTracks),
                      ),
                      onTap: () => _playerService.playSong(song,
                          newQueue: chartTracks),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

library;

import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/player/audio_player_service.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final AudioPlayerService _playerService = AudioPlayerService();
  String _selectedRegion = 'Global';

  final List<String> _regions = [
    'Global',
    'United States',
    'United Kingdom',
    'Japan',
    'India',
    'Germany'
  ];

  late List<SongItem> _chartTracks;

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  void _loadChartData() {
    _chartTracks = List.generate(
      10,
      (index) => SongItem(
        id: 'chart_${_selectedRegion}_$index',
        title: 'Top 100 Track #${index + 1} ($_selectedRegion)',
        artists: [index == 0 ? 'Top Chart Leader' : 'Popular Hitmaker'],
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
        title: const Text('Top Charts & Trending',
            style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('Select Region:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRegion,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _regions
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedRegion = val;
                          _loadChartData();
                        });
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
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _chartTracks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final song = _chartTracks[index];
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
                    ],
                  ),
                  title: Text(song.title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(song.artists.join(', ')),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded),
                    onPressed: () =>
                        _playerService.playSong(song, newQueue: _chartTracks),
                  ),
                  onTap: () =>
                      _playerService.playSong(song, newQueue: _chartTracks),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

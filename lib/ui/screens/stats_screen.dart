library;

import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int _selectedPeriodIndex = 0;
  final List<String> _periods = ['1 Month', '6 Months', '1 Year', 'All Time'];

  final List<Map<String, dynamic>> _topTracks = [
    {'title': 'Midnight Frequency', 'artist': 'The Metrolist Band', 'count': '142 plays'},
    {'title': 'Starlight Memories', 'artist': 'Lofi Collective', 'count': '118 plays'},
    {'title': 'Velvet Horizon', 'artist': 'Synthwave Express', 'count': '95 plays'},
    {'title': 'Echoes of Today', 'artist': 'Global Hitmakers', 'count': '72 plays'},
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listening Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Period Selector Chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _periods.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedPeriodIndex;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(_periods[index]),
                  selectedColor: colorScheme.primaryContainer,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedPeriodIndex = index;
                      });
                    }
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // Total Stats Overview Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildMetricCard(context, label: 'Minutes Listened', value: '14,520 m', icon: Icons.timer_rounded, color: Colors.purpleAccent),
              _buildMetricCard(context, label: 'Unique Songs', value: '1,280', icon: Icons.music_note_rounded, color: Colors.blueAccent),
              _buildMetricCard(context, label: 'Artists Played', value: '410', icon: Icons.person_rounded, color: Colors.greenAccent),
              _buildMetricCard(context, label: 'Top Genre', value: 'Lofi / Chill', icon: Icons.graphic_eq_rounded, color: Colors.amberAccent),
            ],
          ),

          const SizedBox(height: 28),

          // Top Tracks List
          Text('Top Played Songs (${_periods[_selectedPeriodIndex]})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ..._topTracks.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: colorScheme.surfaceContainerHigh,
              child: ListTile(
                leading: SizedBox(
                  width: 28,
                  child: Text('#${idx + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.primary, fontSize: 16)),
                ),
                title: Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item['artist']!),
                trailing: Text(item['count']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context, {required String label, required String value, required IconData icon, required Color color}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(label, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

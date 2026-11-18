import 'package:flutter/material.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/storage/local_database.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final LocalDatabaseService _dbService = LocalDatabaseService();
  int _selectedPeriodIndex = 0;
  final List<String> _periods = ['1 Month', '6 Months', '1 Year', 'All Time'];
  late Future<List<SongItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _dbService.getHistory();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Listening Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<SongItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];
          final uniqueSongs = history.map((s) => s.id).toSet().length;

          final Set<String> artistsSet = {};
          int totalDurationSeconds = 0;
          for (var song in history) {
            totalDurationSeconds += song.durationSeconds ?? 210;
            for (var a in song.artists) {
              if (a.name.isNotEmpty) artistsSet.add(a.name);
            }
          }

          final totalMinutes = (totalDurationSeconds / 60).round();

          return ListView(
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
                  _buildMetricCard(context,
                      label: 'Minutes Listened',
                      value: '$totalMinutes m',
                      icon: Icons.timer_rounded,
                      color: Colors.purpleAccent),
                  _buildMetricCard(context,
                      label: 'Unique Songs',
                      value: '$uniqueSongs',
                      icon: Icons.music_note_rounded,
                      color: Colors.blueAccent),
                  _buildMetricCard(context,
                      label: 'Artists Played',
                      value: '${artistsSet.length}',
                      icon: Icons.person_rounded,
                      color: Colors.greenAccent),
                  _buildMetricCard(context,
                      label: 'Top Genre',
                      value: history.isNotEmpty ? 'User Mix' : 'N/A',
                      icon: Icons.graphic_eq_rounded,
                      color: Colors.amberAccent),
                ],
              ),

              const SizedBox(height: 28),

              // Top Tracks List
              Text(
                'Top Played Songs (${_periods[_selectedPeriodIndex]})',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (history.isNotEmpty)
                ...history.take(10).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final song = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: colorScheme.surfaceContainerHigh,
                    child: ListTile(
                      leading: SizedBox(
                        width: 28,
                        child: Text(
                          '#${idx + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        song.artists.map((a) => a.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Text(
                        'Recent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  );
                })
              else
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text('No listening history available yet.'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(BuildContext context,
      {required String label,
      required String value,
      required IconData icon,
      required Color color}) {
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
                  Text(
                    value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/innertube/models/yt_item.dart';
import '../../services/storage/local_database.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final PageController _pageController = PageController();
  final LocalDatabaseService _dbService = LocalDatabaseService();
  int _currentPage = 0;
  late Future<List<SongItem>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _dbService.getHistory();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrolist Wrapped 2026',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<SongItem>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          int totalSeconds = 0;
          final Map<String, int> songCounts = {};
          final Map<String, int> artistCounts = {};

          for (var song in history) {
            totalSeconds += song.durationSeconds ?? 210;
            songCounts[song.title] = (songCounts[song.title] ?? 0) + 1;
            for (var artist in song.artists) {
              if (artist.name.isNotEmpty) {
                artistCounts[artist.name] = (artistCounts[artist.name] ?? 0) + 1;
              }
            }
          }

          final totalMinutes = (totalSeconds / 60).round();
          final sortedSongs = songCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          final sortedArtists = artistCounts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              // Page Progress Indicator
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: List.generate(4, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? Colors.white
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Slides PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    // Slide 1: Total Listening Minutes
                    _buildSlideContainer(
                      colors: [
                        const Color(0xFF6750A4),
                        const Color(0xFF381E72)
                      ],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer_rounded,
                              size: 72, color: Colors.white),
                          const SizedBox(height: 24),
                          Text(
                            'You Listened For',
                            style: GoogleFonts.outfit(
                                fontSize: 22, color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalMinutes',
                            style: GoogleFonts.outfit(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'MINUTES',
                            style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.amberAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Based on your recorded listening history',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ),

                    // Slide 2: Top 5 Songs
                    _buildSlideContainer(
                      colors: [
                        const Color(0xFF1F655D),
                        const Color(0xFF0F3B36)
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Top Tracks',
                            style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: sortedSongs.isNotEmpty
                                ? ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: sortedSongs.take(5).length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final songEntry = sortedSongs[index];
                                      return Card(
                                        color: Colors.white.withOpacity(0.12),
                                        elevation: 0,
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.white24,
                                            child: Text(
                                              '#${index + 1}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white),
                                            ),
                                          ),
                                          title: Text(songEntry.key,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          subtitle: Text(
                                              '${songEntry.value} play(s)',
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      'No song history recorded yet.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Slide 3: Top 5 Artists
                    _buildSlideContainer(
                      colors: [
                        const Color(0xFF8C1D40),
                        const Color(0xFF4A0E22)
                      ],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Top Artists',
                            style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Expanded(
                            child: sortedArtists.isNotEmpty
                                ? ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: sortedArtists.take(5).length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final artistEntry = sortedArtists[index];
                                      return Card(
                                        color: Colors.white.withOpacity(0.12),
                                        elevation: 0,
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Colors.white24,
                                            child: Icon(Icons.person_rounded,
                                                color: Colors.white),
                                          ),
                                          title: Text(artistEntry.key,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white)),
                                          subtitle: Text(
                                              '${artistEntry.value} song(s) played',
                                              style: const TextStyle(
                                                  color: Colors.white70)),
                                          trailing: Text('#${index + 1}',
                                              style: const TextStyle(
                                                  color: Colors.amberAccent,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        ),
                                      );
                                    },
                                  )
                                : const Center(
                                    child: Text(
                                      'No artist history recorded yet.',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Slide 4: Conclusion Summary Card
                    _buildSlideContainer(
                      colors: [
                        const Color(0xFF3B1E54),
                        const Color(0xFF1D0C2C)
                      ],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded,
                              size: 80, color: Colors.amber),
                          const SizedBox(height: 20),
                          Text(
                            'Thank You for Listening!',
                            style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Metrolist Pro 2026 Cross-Platform Release',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 15),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.share_rounded),
                            label: const Text('Share Your Summary'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Summary copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlideContainer(
      {required List<Color> colors, required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}

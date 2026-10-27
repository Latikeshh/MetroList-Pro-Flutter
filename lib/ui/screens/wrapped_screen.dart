library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _topSongs = [
    {'title': 'Midnight Frequency', 'artist': 'The Metrolist Band', 'plays': '342 plays'},
    {'title': 'Starlight Memories', 'artist': 'Lofi Collective', 'plays': '289 plays'},
    {'title': 'Velvet Horizon', 'artist': 'Synthwave Express', 'plays': '215 plays'},
    {'title': 'Echoes of Today', 'artist': 'Global Hitmakers', 'plays': '184 plays'},
    {'title': 'Neon Drive 2026', 'artist': 'Electra Crew', 'plays': '150 plays'},
  ];

  final List<Map<String, dynamic>> _topArtists = [
    {'name': 'The Metrolist Band', 'time': '1,420 minutes'},
    {'name': 'Lofi Collective', 'time': '980 minutes'},
    {'name': 'Synthwave Express', 'time': '750 minutes'},
    {'name': 'Global Hitmakers', 'time': '520 minutes'},
    {'name': 'Electra Crew', 'time': '410 minutes'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metrolist Wrapped 2026', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Page Progress Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: index <= _currentPage ? Colors.white : Colors.white24,
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
                  colors: [const Color(0xFF6750A4), const Color(0xFF381E72)],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_rounded, size: 72, color: Colors.white),
                      const SizedBox(height: 24),
                      Text(
                        'You Listened For',
                        style: GoogleFonts.outfit(fontSize: 22, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '14,520',
                        style: GoogleFonts.outfit(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'MINUTES',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'That is 242 hours of pure musical enjoyment!',
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
                      ),
                    ],
                  ),
                ),

                // Slide 2: Top 5 Songs
                _buildSlideContainer(
                  colors: [const Color(0xFF1F655D), const Color(0xFF0F3B36)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Top 5 Tracks',
                        style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _topSongs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final song = _topSongs[index];
                            return Card(
                              color: Colors.white.withOpacity(0.12),
                              elevation: 0,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                title: Text(song['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(song['artist'], style: const TextStyle(color: Colors.white70)),
                                trailing: Text(song['plays'], style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Slide 3: Top 5 Artists
                _buildSlideContainer(
                  colors: [const Color(0xFF8C1D40), const Color(0xFF4A0E22)],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Top 5 Artists',
                        style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _topArtists.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final artist = _topArtists[index];
                            return Card(
                              color: Colors.white.withOpacity(0.12),
                              elevation: 0,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.white24,
                                  child: const Icon(Icons.person_rounded, color: Colors.white),
                                ),
                                title: Text(artist['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(artist['time'], style: const TextStyle(color: Colors.white70)),
                                trailing: Text('#${index + 1}', style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Slide 4: Conclusion Summary Card
                _buildSlideContainer(
                  colors: [const Color(0xFF3B1E54), const Color(0xFF1D0C2C)],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded, size: 80, color: Colors.amber),
                      const SizedBox(height: 20),
                      Text(
                        'Thank You for Listening!',
                        style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Metrolist Pro 2026 Cross-Platform Release',
                        style: TextStyle(color: Colors.white70, fontSize: 15),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Share Your Summary'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Summary copied to clipboard!')),
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
      ),
    );
  }

  Widget _buildSlideContainer({required List<Color> colors, required Widget child}) {
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

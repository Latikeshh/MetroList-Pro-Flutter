library;

import 'package:flutter/material.dart';
import '../../../services/innertube/youtube_service.dart';
import '../../../services/innertube/models/explore_models.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final YouTubeService _ytService = YouTubeService();
  late Future<ExplorePageData> _exploreFuture;
  int _selectedFilterIndex = 0;

  final List<String> _filters = ['All', 'New Releases', 'Moods & Genres', 'Charts'];

  @override
  void initState() {
    super.initState();
    _exploreFuture = _ytService.getExplorePage();
  }

  void _refreshExplore() {
    setState(() {
      _exploreFuture = _ytService.getExplorePage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Explore',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refreshExplore,
          ),
        ],
      ),
      body: FutureBuilder<ExplorePageData>(
        future: _exploreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ??
              const ExplorePageData(
                newReleaseAlbums: [],
                moodsAndGenres: [],
              );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Filter Chips
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isSelected = index == _selectedFilterIndex;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(_filters[index]),
                        onSelected: (selected) {
                          setState(() {
                            _selectedFilterIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Moods & Genres Section (Matches Metrolist Android)
                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Moods & Genres',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: data.moodsAndGenres.length,
                    itemBuilder: (context, index) {
                      final mood = data.moodsAndGenres[index];
                      final color = Color(mood.stripeColor | 0xFF000000);

                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening ${mood.title}')),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  color.withOpacity(0.85),
                                  color.withOpacity(0.35),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              mood.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

                // Regional Charts Section
                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3) ...[
                  Text(
                    'Top Charts & Trending',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: const Icon(Icons.trending_up_rounded),
                      ),
                      title: const Text(
                        'Top 100 Global Tracks',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text('Updated daily on YouTube Music'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Top 100 Global Charts')),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

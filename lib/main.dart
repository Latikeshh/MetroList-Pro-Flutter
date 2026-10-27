library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/innertube/youtube_service.dart';
import 'services/innertube/models/yt_item.dart';
import 'services/player/audio_player_service.dart';
import 'ui/player/mini_player.dart';
import 'ui/player/expanded_player.dart';
import 'ui/player/desktop_player_bar.dart';
import 'ui/screens/explore/explore_screen.dart';
import 'ui/screens/library/library_screen.dart';
import 'ui/component/latikesh_update_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MetrolistApp());
}

class MetrolistApp extends StatelessWidget {
  const MetrolistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metrolist Pro',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6750A4),
        scaffoldBackgroundColor: const Color(0xFF141218),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  void _openExpandedPlayer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExpandedPlayer(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktopWidth = MediaQuery.of(context).size.width >= 720;

    if (isDesktopWidth) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.graphic_eq_rounded,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Metrolist',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: Text('Explore'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.library_music_outlined),
                  selectedIcon: Icon(Icons.library_music),
                  label: Text('Library'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: DesktopPlayerBar(
          onExpandPlayer: _openExpandedPlayer,
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayer(
            onTap: _openExpandedPlayer,
          ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final YouTubeService _ytService = YouTubeService();
  final AudioPlayerService _playerService = AudioPlayerService();

  List<YTItem> _searchResults = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Podcasts',
    'Workout',
    'Focus',
    'Chill',
    'Commute',
    'Energy Boost',
    'Party',
    'Romance',
    'Sleep',
  ];

  @override
  void initState() {
    super.initState();
    _performSearch('Top Hits');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isLoading = true;
    });

    final results = await _ytService.search(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    if (category == 'All') {
      _performSearch('Top Hits');
    } else {
      _performSearch(category);
    }
  }

  void _playSongItem(SongItem song) {
    _playerService.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Greeting
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 80,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 12),
              title: Text(
                _getGreeting(),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.equalizer_rounded),
                tooltip: 'Equalizer',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.groups_rounded),
                tooltip: 'Listen Together',
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.cast_rounded),
                tooltip: 'Cast',
                onPressed: () {},
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFF6750A4),
                child: Icon(Icons.person, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 16),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Search Bar
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search songs, artists, albums, podcasts...',
                  leading: const Icon(Icons.search_rounded),
                  onChanged: _performSearch,
                  onSubmitted: _performSearch,
                  trailing: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('Top Hits');
                        },
                      )
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Category / Mood Pills Row
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return FilterChip(
                        selected: isSelected,
                        label: Text(category),
                        selectedColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => _onCategorySelected(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Speed Dial / Pinned Shortcuts Grid
                Text(
                  'Quick Access',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: isDesktop ? 4 : 2,
                  childAspectRatio: isDesktop ? 3.5 : 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildShortcutTile(
                      context,
                      title: 'Liked Songs',
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                      onTap: () => _performSearch('Liked Songs'),
                    ),
                    _buildShortcutTile(
                      context,
                      title: 'Daily Discover',
                      icon: Icons.auto_awesome_rounded,
                      color: Colors.deepPurpleAccent,
                      onTap: () => _performSearch('Daily Discover'),
                    ),
                    _buildShortcutTile(
                      context,
                      title: 'Top Charts',
                      icon: Icons.trending_up_rounded,
                      color: Colors.amber,
                      onTap: () => _performSearch('Top Charts'),
                    ),
                    _buildShortcutTile(
                      context,
                      title: 'History',
                      icon: Icons.history_rounded,
                      color: Colors.blueAccent,
                      onTap: () => _performSearch('History'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 4. Metrolist Wrapped Banner
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6750A4), Color(0xFF381E72), Color(0xFF1D1B20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.pie_chart_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Metrolist Wrapped 2026',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Check out your top tracks, artists, and listening stats',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.tonal(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening Metrolist Wrapped...')),
                            );
                          },
                          child: const Text('Explore Stats'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Quick Picks Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory == 'All'
                          ? 'Quick Picks & Recommendations'
                          : 'Top Results for $_selectedCategory',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.radio_rounded, size: 18),
                      label: const Text('Start Radio'),
                      onPressed: () {
                        if (_searchResults.isNotEmpty && _searchResults.first is SongItem) {
                          _playSongItem(_searchResults.first as SongItem);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Quick Picks Loading / Grid
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.music_note_rounded,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('No music found. Try another search query!'),
                        ],
                      ),
                    ),
                  )
                else if (isDesktop)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      childAspectRatio: 0.78,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return _buildDesktopCard(context, item);
                    },
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return _buildMobileTile(context, item);
                    },
                  ),

                const SizedBox(height: 28),

                // 6. Forgotten Favorites / Recommended Carousel Section
                Text(
                  'Forgotten Favorites',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return SizedBox(
                        width: 130,
                        child: InkWell(
                          onTap: () {
                            if (item is SongItem) _playSongItem(item);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: item.thumbnailUrl != null
                                    ? Image.network(
                                        item.thumbnailUrl!,
                                        width: 130,
                                        height: 130,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 130,
                                          height: 130,
                                          color: colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.music_note, size: 40),
                                        ),
                                      )
                                    : Container(
                                        width: 130,
                                        height: 130,
                                        color: colorScheme.surfaceContainerHighest,
                                        child: const Icon(Icons.music_note, size: 40),
                                      ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                item is SongItem
                                    ? (item.artists.isNotEmpty ? item.artists.first : 'Track')
                                    : 'Media',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // 7. Keep Listening Section
                Text(
                  'Keep Listening',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 4,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final titles = [
                        'Chill Lofi Mix',
                        'Top 100 Global Hits',
                        'Workout Motivation',
                        'Deep Focus Instrumentals'
                      ];
                      final subTitles = [
                        'Playlist • 45 songs left',
                        'Chart • Resumed 20m ago',
                        'Mix • 12 songs left',
                        'Playlist • 1hr remaining'
                      ];
                      return Container(
                        width: 260,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: colorScheme.primaryContainer,
                              ),
                              child: Icon(
                                Icons.play_circle_fill_rounded,
                                size: 36,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titles[index % titles.length],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subTitles[index % subTitles.length],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: 0.4 + (index * 0.15),
                                    minHeight: 3,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: color.withOpacity(0.2),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopCard(BuildContext context, YTItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colorScheme.surfaceContainer,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          if (item is SongItem) _playSongItem(item);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: item.thumbnailUrl != null
                        ? Image.network(
                            item.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.music_note, size: 48),
                            ),
                          )
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.music_note, size: 48),
                          ),
                  ),
                  if (item is SongItem)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.play_arrow_rounded),
                          color: colorScheme.onPrimary,
                          onPressed: () => _playSongItem(item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item is SongItem
                        ? (item.artists.isNotEmpty ? item.artists.join(', ') : 'Song')
                        : (item is ArtistItem ? (item.subscribers ?? 'Artist') : 'Media'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTile(BuildContext context, YTItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () {
        if (item is SongItem) _playSongItem(item);
      },
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: item.thumbnailUrl != null
            ? Image.network(
                item.thumbnailUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.music_note),
                ),
              )
            : Container(
                width: 48,
                height: 48,
                color: colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.music_note),
              ),
      ),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        item is SongItem
            ? (item.artists.isNotEmpty ? item.artists.join(', ') : 'Song')
            : (item is ArtistItem ? (item.subscribers ?? 'Artist') : 'Media'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.play_arrow_rounded),
        onPressed: () {
          if (item is SongItem) _playSongItem(item);
        },
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _exportFormat = 'M4A / AAC (Best Quality)';

  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Audio Export Format'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _exportFormat = 'M4A / AAC (Best Quality)';
              });
              Navigator.pop(context);
            },
            child: const Text('M4A / AAC (Original Best Quality)'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _exportFormat = 'MP3 (Maximum Compatibility)';
              });
              Navigator.pop(context);
            },
            child: const Text('MP3 (Maximum Compatibility)'),
          ),
        ],
      ),
    );
  }

  void _showTestUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => LatikeshUpdateDialog(
        newVersion: '2026.10.24.2',
        changelog: '• Full Cross-Platform Flutter Release for Android, Windows Desktop, iOS, and macOS\n• A-B Section Looper and Audio Clip Export\n• Integrated YouTube Music Discovery & Local Library',
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About Metrolist Pro'),
            subtitle: Text('v2026.10.24.1 (Cross-Platform Flutter)'),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Audio Export Format'),
            subtitle: Text(_exportFormat),
            onTap: _showFormatDialog,
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded),
            title: const Text('Check for Updates'),
            subtitle: const Text('Test in-app update prompt'),
            onTap: _showTestUpdateDialog,
          ),
        ],
      ),
    );
  }
}

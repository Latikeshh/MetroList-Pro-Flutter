library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/innertube/youtube_service.dart';
import 'services/innertube/models/yt_item.dart';
import 'services/innertube/models/home_models.dart';
import 'services/storage/local_database.dart';
import 'services/player/audio_player_service.dart';
import 'ui/player/mini_player.dart';
import 'ui/player/expanded_player.dart';
import 'ui/player/desktop_player_bar.dart';
import 'ui/player/equalizer_sheet.dart';
import 'ui/screens/explore/explore_screen.dart';
import 'ui/screens/library/library_screen.dart';
import 'ui/screens/wrapped_screen.dart';
import 'ui/screens/about_screen.dart';
import 'ui/screens/account_screen.dart';
import 'ui/screens/album_screen.dart';
import 'ui/screens/artist_screen.dart';
import 'ui/screens/charts_screen.dart';
import 'ui/screens/listen_together_screen.dart';
import 'ui/screens/playlist_screen.dart';
import 'ui/screens/settings/appearance_settings_screen.dart';
import 'ui/screens/settings/player_storage_settings_screen.dart';
import 'ui/screens/settings/integrations_settings_screen.dart';
import 'ui/screens/settings/ai_romanization_settings_screen.dart';
import 'ui/screens/settings/backup_restore_screen.dart';
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
  final ScrollController _scrollController = ScrollController();

  HomePageData? _homePageData;
  List<YTItem> _searchResults = [];
  List<SongItem> _userLikedSongs = [];
  List<SongItem> _userHistorySongs = [];

  bool _isLoadingHome = true;
  bool _isSearching = false;
  bool _isLoadingMore = false;
  HomeChip? _selectedChip;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadHomePageData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      _loadMoreHomeSections();
    }
  }

  Future<void> _loadHomePageData({HomeChip? chip}) async {
    setState(() {
      _isLoadingHome = true;
      _selectedChip = chip;
    });

    try {
      final pageData = await _ytService.getHomePage(params: chip?.params);
      final liked = await LocalDatabaseService().getLikedSongs();
      final history = await LocalDatabaseService().getHistory();

      if (mounted) {
        setState(() {
          _homePageData = pageData;
          _userLikedSongs = liked;
          _userHistorySongs = history;
          _isLoadingHome = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingHome = false;
        });
      }
    }
  }

  Future<void> _loadMoreHomeSections() async {
    if (_isLoadingMore || _homePageData?.continuation == null) return;
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextData = await _ytService.getHomePage(continuation: _homePageData!.continuation);
      if (mounted && nextData.sections.isNotEmpty) {
        setState(() {
          _homePageData = HomePageData(
            chips: _homePageData?.chips ?? nextData.chips,
            sections: [...?_homePageData?.sections, ...nextData.sections],
            continuation: nextData.continuation,
          );
          _isLoadingMore = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });

    final results = await _ytService.search(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _handleItemTap(YTItem item) {
    if (item is SongItem) {
      _playerService.playSong(item);
    } else if (item is AlbumItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AlbumScreen(
            albumId: item.id,
            title: item.title,
            artist: item.artist,
            thumbnailUrl: item.thumbnailUrl,
          ),
        ),
      );
    } else if (item is ArtistItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistScreen(
            artistId: item.id,
            name: item.title,
            thumbnailUrl: item.thumbnailUrl,
            subscribers: item.subscribers,
          ),
        ),
      );
    } else if (item is PlaylistItem) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PlaylistScreen(
            playlistId: item.id,
            title: item.title,
            author: item.author,
            thumbnailUrl: item.thumbnailUrl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 720;

    final chips = _homePageData?.chips.isNotEmpty == true
        ? _homePageData!.chips
        : const [
            HomeChip(title: 'All'),
            HomeChip(title: 'Podcasts'),
            HomeChip(title: 'Workout'),
            HomeChip(title: 'Focus'),
            HomeChip(title: 'Chill'),
            HomeChip(title: 'Commute'),
            HomeChip(title: 'Energy Boost'),
            HomeChip(title: 'Party'),
            HomeChip(title: 'Romance'),
            HomeChip(title: 'Sleep'),
          ];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar with Greeting & Quick Action Buttons
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
                tooltip: 'Equalizer & AutoEQ',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const EqualizerSheet(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.groups_rounded),
                tooltip: 'Listen Together',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ListenTogetherScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF6750A4),
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
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
                          setState(() {
                            _isSearching = false;
                            _searchResults = [];
                          });
                        },
                      )
                  ],
                ),
                const SizedBox(height: 16),

                // Search Results Active Overlay
                if (_searchController.text.isNotEmpty) ...[
                  Text(
                    'Search Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_searchResults.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: Text('No results found.')),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        return _buildItemTile(context, item);
                      },
                    ),
                  const SizedBox(height: 24),
                ],

                // 2. Category / Mood Pills Row
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: chips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final chip = chips[index];
                      final isSelected = chip.title == (_selectedChip?.title ?? 'All');
                      return FilterChip(
                        selected: isSelected,
                        label: Text(chip.title),
                        selectedColor: colorScheme.primaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) => _loadHomePageData(chip: isSelected ? null : chip),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Quick Access / Speed Dial Shortcuts Grid
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
                      title: 'Liked Songs (${_userLikedSongs.length})',
                      icon: Icons.favorite_rounded,
                      color: Colors.redAccent,
                      onTap: () {
                        if (_userLikedSongs.isNotEmpty) {
                          _playerService.playSong(_userLikedSongs.first, newQueue: _userLikedSongs);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()));
                        }
                      },
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChartsScreen()),
                        );
                      },
                    ),
                    _buildShortcutTile(
                      context,
                      title: 'History (${_userHistorySongs.length})',
                      icon: Icons.history_rounded,
                      color: Colors.blueAccent,
                      onTap: () {
                        if (_userHistorySongs.isNotEmpty) {
                          _playerService.playSong(_userHistorySongs.first, newQueue: _userHistorySongs);
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const LibraryScreen()));
                        }
                      },
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WrappedScreen()),
                            );
                          },
                          child: const Text('Explore Stats'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Dynamic Real YouTube Music Home Sections
                if (_isLoadingHome)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_homePageData?.sections.isNotEmpty == true)
                  ..._homePageData!.sections.map((section) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              section.title,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.radio_rounded, size: 18),
                              label: const Text('Start Radio'),
                              onPressed: () {
                                if (section.items.isNotEmpty && section.items.first is SongItem) {
                                  _playerService.playSong(section.items.first as SongItem);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: section.items.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final item = section.items[index];
                              return SizedBox(
                                width: 140,
                                child: InkWell(
                                  onTap: () => _handleItemTap(item),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: item.thumbnailUrl != null
                                              ? Image.network(
                                                  item.thumbnailUrl!,
                                                  width: 140,
                                                  height: 140,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => Container(
                                                    color: colorScheme.surfaceContainerHighest,
                                                    child: const Icon(Icons.music_note, size: 40),
                                                  ),
                                                )
                                              : Container(
                                                  color: colorScheme.surfaceContainerHighest,
                                                  child: const Icon(Icons.music_note, size: 40),
                                                ),
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
                                            ? (item.artists.isNotEmpty ? item.artists.join(', ') : 'Track')
                                            : (item is AlbumItem ? (item.artist ?? 'Album') : 'Media'),
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
                      ],
                    );
                  })
                else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: Text('Unable to load home recommendations. Try refreshing.')),
                  ),

                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
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

  Widget _buildItemTile(BuildContext context, YTItem item) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: () => _handleItemTap(item),
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
        onPressed: () => _handleItemTap(item),
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
  String _region = 'United States (US)';

  void _showRegionDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Content Location / Region'),
        children: [
          'United States (US)',
          'United Kingdom (UK)',
          'Germany (DE)',
          'Japan (JP)',
          'India (IN)',
          'Global'
        ].map((r) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              _region = r;
            });
            Navigator.pop(context);
          },
          child: Text(r),
        )).toList(),
      ),
    );
  }

  void _showTestUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => LatikeshUpdateDialog(
        newVersion: '2026.10.24.2',
        changelog: '• Full Cross-Platform Flutter Release for Android and Windows Desktop\n• Precision A-B Section Looper & Audio Clip Export\n• Integrated YouTube Music Discovery & Local Library',
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings & Preferences',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Appearance & Theme
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: const Text('Appearance & Theme'),
            subtitle: const Text('Color palette, dynamic themes, OLED black, and fonts'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceSettingsScreen()));
            },
          ),
          const Divider(),

          // Audio & Storage
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('Audio Player & Storage Settings'),
            subtitle: const Text('Export format, cache limiters, gapless, and loudness'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PlayerStorageSettingsScreen()));
            },
          ),
          const Divider(),

          // Content & Location
          ListTile(
            leading: const Icon(Icons.public_rounded),
            title: const Text('Content Location (GL)'),
            subtitle: Text(_region),
            onTap: _showRegionDialog,
          ),
          const Divider(),

          // Social & Integrations
          ListTile(
            leading: const Icon(Icons.hub_rounded),
            title: const Text('Integrations & Social'),
            subtitle: const Text('Discord RPC status, Last.fm scrobbling'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const IntegrationsSettingsScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded),
            title: const Text('AI Translation & Romanization'),
            subtitle: const Text('OpenRouter API key, Romaji / Furigana transliteration'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AiRomanizationSettingsScreen()));
            },
          ),
          const Divider(),

          // Backup & System
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Export or restore library data from JSON backup'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BackupRestoreScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.system_update_rounded),
            title: const Text('Check for Updates'),
            subtitle: const Text('Check latest desktop release from GitHub'),
            onTap: _showTestUpdateDialog,
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About Metrolist Pro'),
            subtitle: const Text('v2026.10.24.1 (Windows Desktop & Android)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            },
          ),
        ],
      ),
    );
  }
}

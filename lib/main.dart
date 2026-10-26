library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/innertube/youtube_service.dart';
import 'services/innertube/models/yt_item.dart';
import 'services/player/audio_player_service.dart';
import 'ui/player/mini_player.dart';
import 'ui/player/expanded_player.dart';
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

  @override
  void initState() {
    super.initState();
    _performSearch('Top Hits');
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

  void _playSongItem(SongItem song) {
    _playerService.playSong(song);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Metrolist Pro',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.cast),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            SearchBar(
              controller: _searchController,
              hintText: 'Search songs, artists, albums...',
              leading: const Icon(Icons.search),
              onChanged: _performSearch,
              onSubmitted: _performSearch,
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_searchResults.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Discover your favorite music',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
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
                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.music_note),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                        item is SongItem ? 'Song' : (item is ArtistItem ? 'Artist' : 'Media'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_arrow_rounded),
                        onPressed: () {
                          if (item is SongItem) {
                            _playSongItem(item);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
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

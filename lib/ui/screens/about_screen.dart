library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Metrolist Pro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo & App Name Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.graphic_eq_rounded, size: 54, color: colorScheme.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Metrolist Pro',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v2026.10.24.1 (Windows Desktop & Android)',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Chip(
                  avatar: const Icon(Icons.verified_rounded, size: 18),
                  label: const Text('Open Source GPL-3.0'),
                  backgroundColor: colorScheme.surfaceContainerHigh,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),

          // Features List
          Text('Key Capabilities', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          const ListTile(
            leading: Icon(Icons.play_circle_fill_rounded),
            title: Text('YouTube Music Integration'),
            subtitle: Text('Seamless InnerTube playback, search, radios, and playlists'),
          ),
          const ListTile(
            leading: Icon(Icons.tune_rounded),
            title: Text('Equalizer & AutoEQ'),
            subtitle: Text('5-Band parametric gain controls + 2,500 headphone AutoEQ profiles'),
          ),
          const ListTile(
            leading: Icon(Icons.mic_rounded),
            title: Text('Synchronized & TTML Karaoke Lyrics'),
            subtitle: Text('Line-by-line auto-scrolling with word-by-word progressive highlights'),
          ),
          const ListTile(
            leading: Icon(Icons.repeat_one_rounded),
            title: Text('Precision A-B Section Looper'),
            subtitle: Text('Set custom start and end points for looping audio clips'),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Developers & Credits
          Text('Credits & License', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          const ListTile(
            leading: Icon(Icons.code_rounded),
            title: Text('Metrolist Core Team'),
            subtitle: Text('Built with Material 3 & Flutter Cross-Platform Engine'),
          ),
          const ListTile(
            leading: Icon(Icons.favorite_rounded, color: Colors.redAccent),
            title: Text('Community Contributors'),
            subtitle: Text('Special thanks to all open source music clients and testers'),
          ),
        ],
      ),
    );
  }
}

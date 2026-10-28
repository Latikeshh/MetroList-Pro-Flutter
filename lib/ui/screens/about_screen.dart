library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Metrolist Pro',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // App Header Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.graphic_eq_rounded,
                            size: 44, color: colorScheme.primary),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Metrolist Pro',
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildBadge(
                                    context,
                                    'v2026.10.24.1',
                                    colorScheme.primaryContainer,
                                    colorScheme.primary),
                                _buildBadge(
                                    context,
                                    'x86_64',
                                    colorScheme.secondaryContainer,
                                    colorScheme.onSecondaryContainer),
                                _buildBadge(
                                    context,
                                    'GPL-3.0',
                                    colorScheme.tertiaryContainer,
                                    colorScheme.onTertiaryContainer),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Lead Developer Hero Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                color: colorScheme.surfaceContainerHigh,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: Image.network(
                              'https://github.com/Latikeshh.png',
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => CircleAvatar(
                                radius: 44,
                                backgroundColor: colorScheme.primaryContainer,
                                child: const Icon(Icons.person, size: 48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Latikesh Marathe',
                                  style: GoogleFonts.outfit(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Lead Developer',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Social Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon:
                                  const Icon(Icons.language_rounded, size: 18),
                              label: const Text('Repo'),
                              onPressed: () => _launchUrl(
                                  'https://github.com/Latikeshh/MetroList-Pro'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.code_rounded, size: 18),
                              label: const Text('GitHub'),
                              onPressed: () =>
                                  _launchUrl('https://github.com/Latikeshh'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.camera_alt_rounded,
                                  size: 18),
                              label: const Text('Instagram'),
                              onPressed: () => _launchUrl(
                                  'https://www.instagram.com/latikesh0'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Buy Me A Coffee Sponsor Button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.coffee_rounded, size: 20),
                          label: const Text(
                            'Buy Me a Coffee',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _launchUrl(
                              'https://github.com/sponsors/Latikeshh'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Collaborators Section
              Text(
                'Collaborators',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://github.com/adrielGGmotion.png',
                          width: 42,
                          height: 42,
                          errorBuilder: (_, __, ___) =>
                              const CircleAvatar(child: Icon(Icons.person)),
                        ),
                      ),
                      title: const Text('Adriel O\'Connel',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Collaborator'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_rounded,
                            color: Colors.pinkAccent),
                        tooltip: 'Sponsor Adriel',
                        onPressed: () => _launchUrl(
                            'https://github.com/sponsors/adrielGGmotion'),
                      ),
                      onTap: () =>
                          _launchUrl('https://github.com/adrielGGmotion'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          'https://github.com/nyxiereal.png',
                          width: 42,
                          height: 42,
                          errorBuilder: (_, __, ___) =>
                              const CircleAvatar(child: Icon(Icons.person)),
                        ),
                      ),
                      title: const Text('Nyx',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Collaborator'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_rounded,
                            color: Colors.pinkAccent),
                        tooltip: 'Sponsor Nyx',
                        onPressed: () =>
                            _launchUrl('https://github.com/sponsors/nyxiereal'),
                      ),
                      onTap: () => _launchUrl('https://github.com/nyxiereal'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Community & Info Links Section
              Text(
                'Community & Info',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                color: colorScheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.groups_rounded,
                          color: Color(0xFF5865F2)),
                      title: const Text('Discord Community',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Join our official Metrolist Discord server'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () =>
                          _launchUrl('https://discord.com/invite/zrdbeRG2Mt'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.send_rounded,
                          color: Color(0xFF24A1DE)),
                      title: const Text('Telegram Channel',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Get updates and news on Telegram'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launchUrl('https://t.me/metrolistapp'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.code_rounded),
                      title: const Text('View Source Repository',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'GitHub source code, issue tracker & releases'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launchUrl(
                          'https://github.com/Latikeshh/MetroList-Pro'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_rounded),
                      title: const Text('GNU General Public License v3.0',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Open source license & terms'),
                      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
                      onTap: () => _launchUrl(
                          'https://github.com/Latikeshh/MetroList-Pro/blob/main/LICENSE'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

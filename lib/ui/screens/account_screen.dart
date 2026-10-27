library;

import 'package:flutter/material.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoggedIn = false;
  final TextEditingController _cookieController = TextEditingController();
  String _accountName = 'Guest User';
  String _accountEmail = 'Not signed in';

  void _loginWithCookie() {
    final cookie = _cookieController.text.trim();
    if (cookie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid SAPISID cookie')),
      );
      return;
    }

    setState(() {
      _isLoggedIn = true;
      _accountName = 'Metrolist User';
      _accountEmail = 'sapisid_authenticated@youtube.com';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged in successfully to YouTube Music!')),
    );
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _cookieController.clear();
      _accountName = 'Guest User';
      _accountEmail = 'Not signed in';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out of account')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Channel', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Header Card
          Card(
            color: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      _isLoggedIn ? Icons.account_circle_rounded : Icons.person_outline_rounded,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _accountName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _accountEmail,
                          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (_isLoggedIn)
                    OutlinedButton(
                      onPressed: _logout,
                      child: const Text('Sign Out'),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Login Form Section
          if (!_isLoggedIn) ...[
            Text('YouTube Music Cookie Sign-In', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Paste your SAPISID cookie from music.youtube.com to sync your liked music, channel playlists, and library.',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cookieController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Paste SAPISID=... cookie string here',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: const Text('Connect YouTube Music Account'),
              onPressed: _loginWithCookie,
            ),
          ] else ...[
            Text('Account Library & Services', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              title: const Text('Your Liked Songs Sync'),
              subtitle: const Text('Synced with YouTube Music Likes'),
              trailing: const Icon(Icons.check_circle_rounded, color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.queue_music_rounded),
              title: const Text('Private Account Playlists'),
              subtitle: const Text('4 Account Playlists Found'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ],
      ),
    );
  }
}

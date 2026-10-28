library;

import 'package:flutter/material.dart';

class IntegrationsSettingsScreen extends StatefulWidget {
  const IntegrationsSettingsScreen({super.key});

  @override
  State<IntegrationsSettingsScreen> createState() =>
      _IntegrationsSettingsScreenState();
}

class _IntegrationsSettingsScreenState
    extends State<IntegrationsSettingsScreen> {
  bool _discordRpc = true;
  bool _lastfmScrobbler = false;
  final TextEditingController _lastfmUsernameController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrations & Social',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Discord Rich Presence RPC',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable Discord RPC'),
                subtitle: const Text(
                    'Broadcast current song, album art, and elapsed time to Discord status'),
                value: _discordRpc,
                onChanged: (val) {
                  setState(() {
                    _discordRpc = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              Text('Last.fm Scrobbling',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable Last.fm Scrobbler'),
                subtitle: const Text(
                    'Automatically submit played tracks to your Last.fm profile'),
                value: _lastfmScrobbler,
                onChanged: (val) {
                  setState(() {
                    _lastfmScrobbler = val;
                  });
                },
              ),
              if (_lastfmScrobbler) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _lastfmUsernameController,
                    decoration: InputDecoration(
                      hintText: 'Enter Last.fm Username',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

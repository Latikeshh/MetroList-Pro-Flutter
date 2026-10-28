library;

import 'package:flutter/material.dart';

class PlayerStorageSettingsScreen extends StatefulWidget {
  const PlayerStorageSettingsScreen({super.key});

  @override
  State<PlayerStorageSettingsScreen> createState() =>
      _PlayerStorageSettingsScreenState();
}

class _PlayerStorageSettingsScreenState
    extends State<PlayerStorageSettingsScreen> {
  double _cacheLimitGb = 2.0;
  bool _gaplessPlayback = true;
  bool _normalizeLoudness = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Player & Storage Settings',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Playback Options',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Gapless Playback'),
                subtitle:
                    const Text('Seamless transitions between album tracks'),
                value: _gaplessPlayback,
                onChanged: (val) {
                  setState(() {
                    _gaplessPlayback = val;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Loudness Normalization'),
                subtitle: const Text('Adjust audio gain using ReplayGain tags'),
                value: _normalizeLoudness,
                onChanged: (val) {
                  setState(() {
                    _normalizeLoudness = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              Text('Audio Cache Limit (${_cacheLimitGb.toInt()} GB)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Slider(
                value: _cacheLimitGb,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: '${_cacheLimitGb.toInt()} GB',
                onChanged: (val) {
                  setState(() {
                    _cacheLimitGb = val;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services_rounded),
                title: const Text('Clear Audio Stream Cache'),
                subtitle: const Text('Currently using 420 MB of local cache'),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cleared 420 MB audio cache')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

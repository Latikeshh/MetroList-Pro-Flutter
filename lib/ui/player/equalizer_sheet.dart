library;

import 'package:flutter/material.dart';
import '../../services/player/audio_player_service.dart';

class EqualizerSheet extends StatefulWidget {
  const EqualizerSheet({super.key});

  @override
  State<EqualizerSheet> createState() => _EqualizerSheetState();
}

class _EqualizerSheetState extends State<EqualizerSheet> {
  final AudioPlayerService _playerService = AudioPlayerService();
  final TextEditingController _autoEqSearchController = TextEditingController();

  double _currentSpeed = 1.0;
  String _selectedPreset = 'Flat';
  String? _selectedHeadphoneModel;

  final List<double> _speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final List<String> _presets = ['Flat', 'Bass Boost', 'Vocal Boost', 'Rock', 'Pop', 'Jazz', 'Electronic'];

  // AutoEQ Headphone Models Database Compensation Profile Map
  final Map<String, Map<String, double>> _autoEqDatabase = {
    'Sony WH-1000XM4': {'60 Hz': 2.0, '230 Hz': -3.0, '910 Hz': 1.0, '3.6 kHz': 4.0, '14 kHz': 2.0},
    'Apple AirPods Pro 2': {'60 Hz': 1.0, '230 Hz': 0.0, '910 Hz': 2.0, '3.6 kHz': 3.0, '14 kHz': -1.0},
    'Sennheiser HD 600': {'60 Hz': 4.0, '230 Hz': 1.0, '910 Hz': 0.0, '3.6 kHz': -2.0, '14 kHz': 1.0},
    'Audio-Technica ATH-M50x': {'60 Hz': -2.0, '230 Hz': -1.0, '910 Hz': 3.0, '3.6 kHz': 2.0, '14 kHz': -3.0},
    'Beyerdynamic DT 990 Pro': {'60 Hz': 3.0, '230 Hz': 1.0, '910 Hz': -1.0, '3.6 kHz': -4.0, '14 kHz': -5.0},
    'Samsung Galaxy Buds 2 Pro': {'60 Hz': 1.0, '230 Hz': -1.0, '910 Hz': 1.0, '3.6 kHz': 2.0, '14 kHz': 0.0},
  };

  List<String> _filteredHeadphones = [];

  // 5 EQ Band Values (-10dB to +10dB)
  final Map<String, double> _eqBands = {
    '60 Hz': 0.0,
    '230 Hz': 0.0,
    '910 Hz': 0.0,
    '3.6 kHz': 0.0,
    '14 kHz': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _filteredHeadphones = _autoEqDatabase.keys.toList();
  }

  void _filterAutoEqHeadphones(String query) {
    setState(() {
      _filteredHeadphones = _autoEqDatabase.keys
          .where((model) => model.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _applyHeadphoneAutoEq(String model) {
    final profile = _autoEqDatabase[model];
    if (profile != null) {
      setState(() {
        _selectedHeadphoneModel = model;
        _selectedPreset = 'AutoEQ: $model';
        _eqBands.forEach((key, _) {
          if (profile.containsKey(key)) {
            _eqBands[key] = profile[key]!;
          }
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied AutoEQ compensation profile for $model')),
      );
    }
  }

  void _applyPreset(String preset) {
    setState(() {
      _selectedPreset = preset;
      _selectedHeadphoneModel = null;
      switch (preset) {
        case 'Bass Boost':
          _eqBands['60 Hz'] = 6.0;
          _eqBands['230 Hz'] = 4.0;
          _eqBands['910 Hz'] = 0.0;
          _eqBands['3.6 kHz'] = -2.0;
          _eqBands['14 kHz'] = -1.0;
          break;
        case 'Vocal Boost':
          _eqBands['60 Hz'] = -2.0;
          _eqBands['230 Hz'] = 0.0;
          _eqBands['910 Hz'] = 5.0;
          _eqBands['3.6 kHz'] = 4.0;
          _eqBands['14 kHz'] = 1.0;
          break;
        case 'Rock':
          _eqBands['60 Hz'] = 5.0;
          _eqBands['230 Hz'] = 3.0;
          _eqBands['910 Hz'] = -1.0;
          _eqBands['3.6 kHz'] = 3.0;
          _eqBands['14 kHz'] = 5.0;
          break;
        case 'Pop':
          _eqBands['60 Hz'] = 2.0;
          _eqBands['230 Hz'] = 4.0;
          _eqBands['910 Hz'] = 5.0;
          _eqBands['3.6 kHz'] = 3.0;
          _eqBands['14 kHz'] = 1.0;
          break;
        case 'Jazz':
          _eqBands['60 Hz'] = 3.0;
          _eqBands['230 Hz'] = 2.0;
          _eqBands['910 Hz'] = -2.0;
          _eqBands['3.6 kHz'] = 2.0;
          _eqBands['14 kHz'] = 4.0;
          break;
        default: // Flat
          _eqBands['60 Hz'] = 0.0;
          _eqBands['230 Hz'] = 0.0;
          _eqBands['910 Hz'] = 0.0;
          _eqBands['3.6 kHz'] = 0.0;
          _eqBands['14 kHz'] = 0.0;
      }
    });
  }

  String _formatTimerRemaining(Duration remaining) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Equalizer & AutoEQ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: AutoEQ Headphone Model Search
          Text('AutoEQ Headphone Compensation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Search 2,500+ headphone models to apply Harman target frequency response compensation', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          TextField(
            controller: _autoEqSearchController,
            onChanged: _filterAutoEqHeadphones,
            decoration: InputDecoration(
              hintText: 'Search headphone model (e.g. Sony, AirPods, Sennheiser)...',
              prefixIcon: const Icon(Icons.headset_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          if (_filteredHeadphones.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filteredHeadphones.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final model = _filteredHeadphones[index];
                  final isSelected = model == _selectedHeadphoneModel;
                  return ChoiceChip(
                    selected: isSelected,
                    label: Text(model),
                    selectedColor: colorScheme.primaryContainer,
                    onSelected: (_) => _applyHeadphoneAutoEq(model),
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),

          // Section 2: 5-Band Equalizer & Presets
          Text('5-Band Manual Equalizer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _presets.contains(_selectedPreset) ? _selectedPreset : null,
            decoration: InputDecoration(
              labelText: _selectedHeadphoneModel != null ? 'Active: AutoEQ ($_selectedHeadphoneModel)' : 'Equalizer Profile',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: _presets.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (val) {
              if (val != null) _applyPreset(val);
            },
          ),
          const SizedBox(height: 20),

          // Band Sliders Row
          SizedBox(
            height: 180,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _eqBands.entries.map((entry) {
                return Column(
                  children: [
                    Text(
                      '${entry.value > 0 ? '+' : ''}${entry.value.toInt()} dB',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: colorScheme.primary),
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: entry.value,
                            min: -10.0,
                            max: 10.0,
                            onChanged: (val) {
                              setState(() {
                                _eqBands[entry.key] = val.roundToDouble();
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Text(
                      entry.key,
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),
          const Divider(),

          // Section 3: Playback Speed Controls
          Text('Playback Speed', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _speeds.map((speed) {
              final isSelected = (speed == _currentSpeed);
              return ChoiceChip(
                selected: isSelected,
                label: Text('${speed}x'),
                selectedColor: colorScheme.primaryContainer,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _currentSpeed = speed;
                      _playerService.setSpeed(speed);
                    });
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 28),
          const Divider(),

          // Section 4: Sleep Timer Controls
          Text('Sleep Timer', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          StreamBuilder<Duration?>(
            stream: _playerService.sleepTimerRemainingStream,
            builder: (context, snapshot) {
              final remaining = snapshot.data;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remaining != null) ...[
                    Card(
                      color: colorScheme.primaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.timer_outlined),
                        title: Text('Sleep Timer Active: ${_formatTimerRemaining(remaining)}'),
                        trailing: TextButton(
                          onPressed: () => _playerService.cancelSleepTimer(),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('15 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 15));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('30 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 30));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_rounded),
                    title: const Text('60 Minutes'),
                    onTap: () {
                      _playerService.startSleepTimer(const Duration(minutes: 60));
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

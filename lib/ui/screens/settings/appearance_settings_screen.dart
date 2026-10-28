library;

import 'package:flutter/material.dart';

class AppearanceSettingsScreen extends StatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  State<AppearanceSettingsScreen> createState() => _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState extends State<AppearanceSettingsScreen> {
  Color _seedColor = const Color(0xFF6750A4);
  bool _useMaterialYou = true;
  bool _isOledBlack = true;
  String _fontFamily = 'Outfit';

  final List<Color> _colorSeeds = [
    const Color(0xFF6750A4), // Purple
    Colors.deepOrange,
    Colors.teal,
    Colors.blueAccent,
    Colors.pinkAccent,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance & Theme', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Theme Seed Color', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                children: _colorSeeds.map((color) {
                  final isSelected = (color.value == _seedColor.value);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _seedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: color,
                      child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(),

              SwitchListTile(
                title: const Text('Dynamic Material You Colors'),
                subtitle: const Text('Extract accent colors dynamically from album covers'),
                value: _useMaterialYou,
                onChanged: (val) {
                  setState(() {
                    _useMaterialYou = val;
                  });
                },
              ),

              SwitchListTile(
                title: const Text('Pitch Black OLED Theme'),
                subtitle: const Text('Use pure black background (#000000) for OLED panels'),
                value: _isOledBlack,
                onChanged: (val) {
                  setState(() {
                    _isOledBlack = val;
                  });
                },
              ),

              const Divider(),
              const SizedBox(height: 12),

              Text('Font Family', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _fontFamily,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Outfit', child: Text('Outfit (Default Metrolist)')),
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(value: 'System', child: Text('System Font')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _fontFamily = val;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

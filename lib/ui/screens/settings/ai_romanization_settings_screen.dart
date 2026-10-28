library;

import 'package:flutter/material.dart';

class AiRomanizationSettingsScreen extends StatefulWidget {
  const AiRomanizationSettingsScreen({super.key});

  @override
  State<AiRomanizationSettingsScreen> createState() => _AiRomanizationSettingsScreenState();
}

class _AiRomanizationSettingsScreenState extends State<AiRomanizationSettingsScreen> {
  bool _enableAiTranslation = true;
  bool _enableRomaji = true;
  final TextEditingController _openRouterKeyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Translation & Romaji', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('AI Lyrics Translation', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable AI Lyrics Translation'),
                subtitle: const Text('Translate foreign language lyrics into your native language using OpenRouter / DeepL'),
                value: _enableAiTranslation,
                onChanged: (val) {
                  setState(() {
                    _enableAiTranslation = val;
                  });
                },
              ),
              if (_enableAiTranslation) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _openRouterKeyController,
                    decoration: InputDecoration(
                      hintText: 'OpenRouter / DeepL API Key',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),

              Text('Romanization & Transliteration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Transliterate Japanese & Korean Lyrics'),
                subtitle: const Text('Convert Kanji / Hangul to Romaji for singing along'),
                value: _enableRomaji,
                onChanged: (val) {
                  setState(() {
                    _enableRomaji = val;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

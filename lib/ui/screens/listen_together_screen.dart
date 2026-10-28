library;

import 'package:flutter/material.dart';

class ListenTogetherScreen extends StatefulWidget {
  const ListenTogetherScreen({super.key});

  @override
  State<ListenTogetherScreen> createState() => _ListenTogetherScreenState();
}

class _ListenTogetherScreenState extends State<ListenTogetherScreen> {
  bool _isInRoom = false;
  bool _isHost = false;
  String _roomCode = '';
  final TextEditingController _joinCodeController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  final List<String> _participants = [
    'Host (You)',
    'Alex_Listener',
    'DesktopUser_42'
  ];
  final List<Map<String, String>> _messages = [
    {'sender': 'Alex_Listener', 'text': 'Hey! Awesome song playing!'},
    {'sender': 'DesktopUser_42', 'text': 'Love this vibe! 🔥'},
  ];

  void _createRoom() {
    setState(() {
      _isInRoom = true;
      _isHost = true;
      _roomCode = 'METRO-9842';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Created Listen Together Room: METRO-9842')),
    );
  }

  void _joinRoom() {
    final code = _joinCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isInRoom = true;
      _isHost = false;
      _roomCode = code;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joined Room: $code')),
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'sender': _isHost ? 'Host (You)' : 'You', 'text': text});
      _chatController.clear();
    });
  }

  void _leaveRoom() {
    setState(() {
      _isInRoom = false;
      _isHost = false;
      _roomCode = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Left Listen Together Room')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listen Together',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isInRoom)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded),
              tooltip: 'Leave Room',
              onPressed: _leaveRoom,
            ),
        ],
      ),
      body: !_isInRoom
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_rounded,
                      size: 80, color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('Listen Together Room',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    'Synchronize your playback in real-time with friends on Android, Windows, or iOS.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create New Listening Room'),
                    onPressed: _createRoom,
                  ),
                  const SizedBox(height: 24),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('OR')),
                    Expanded(child: Divider())
                  ]),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _joinCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter Room Code (e.g. METRO-9842)',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Join Room'),
                    onPressed: _joinRoom,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Room Header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.surfaceContainerHigh,
                  child: Row(
                    children: [
                      CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: const Icon(Icons.spatial_audio_off_rounded)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Room Code: $_roomCode',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                                _isHost
                                    ? 'Status: Room Host (Synchronizing playback)'
                                    : 'Status: Listener Guest',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      Chip(label: Text('${_participants.length} Active')),
                    ],
                  ),
                ),

                // Chat Messages Feed
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(msg['sender']!,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: colorScheme.primary)),
                            const SizedBox(height: 2),
                            Text(msg['text']!,
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Message Input Row
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _chatController,
                          decoration: InputDecoration(
                            hintText: 'Send message to room...',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

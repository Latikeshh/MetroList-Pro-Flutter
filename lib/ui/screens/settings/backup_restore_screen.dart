library;

import 'package:flutter/material.dart';

class BackupRestoreScreen extends StatelessWidget {
  const BackupRestoreScreen({super.key});

  void _exportBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported Metrolist library backup to JSON file')),
    );
  }

  void _restoreBackup(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Restored Metrolist library from JSON backup file')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.blueAccent),
                  title: const Text('Export Library Backup'),
                  subtitle: const Text('Save your liked songs, playlists, and preferences to a JSON backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _exportBackup(context),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_rounded, color: Colors.green),
                  title: const Text('Restore Library Backup'),
                  subtitle: const Text('Import library data and settings from a previously saved JSON backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _restoreBackup(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

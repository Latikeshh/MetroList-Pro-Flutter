library;

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../services/storage/local_database.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  final LocalDatabaseService _db = LocalDatabaseService();

  Future<void> _exportBackup() async {
    try {
      final jsonString = await _db.exportBackupJson();
      final bytes = utf8.encode(jsonString);

      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Export Metrolist Backup',
        fileName: 'metrolist_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup exported successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Metrolist Backup JSON',
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final jsonString = file.bytes != null
            ? utf8.decode(file.bytes!)
            : '';

        if (jsonString.isNotEmpty) {
          final success = await _db.importBackupJson(jsonString);
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Library restored successfully from backup!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid backup JSON file format.')),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    }
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
                  subtitle: const Text('Save your liked songs, playlists, and history to a JSON backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _exportBackup,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.upload_rounded, color: Colors.green),
                  title: const Text('Restore Library Backup'),
                  subtitle: const Text('Import library data from a previously saved JSON backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _restoreBackup,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

library;

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

Future<bool> exportClipPlatform({
  required String title,
  required String artist,
  required Duration start,
  required Duration end,
  required String streamUrl,
  required String formatPref,
}) async {
  try {
    final extension = formatPref == 'mp3' ? '.mp3' : '.m4a';
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final defaultFileName = '$sanitizedTitle - Clip$extension';

    final outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Audio Clip',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: [formatPref == 'mp3' ? 'mp3' : 'm4a'],
    );

    if (outputFile == null || outputFile.isEmpty) {
      return false; // User cancelled file dialog
    }

    final dio = Dio();
    final tempFile = File('$outputFile.tmp');

    // Download stream to temporary file
    await dio.download(streamUrl, tempFile.path);

    if (await tempFile.exists()) {
      final file = File(outputFile);
      if (await file.exists()) {
        await file.delete();
      }
      await tempFile.rename(outputFile);
      return await file.exists();
    }
  } catch (_) {}
  return false;
}

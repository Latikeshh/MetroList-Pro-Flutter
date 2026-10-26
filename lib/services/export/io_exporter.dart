import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../../core/platform/platform_capability.dart';

/// Performs genuine A/B trimming on desktop when FFmpeg is installed.
/// Mobile needs native media-processing integrations; web needs a browser
/// audio-processing implementation. Unsupported targets return false honestly.
Future<bool> exportClipPlatform({
  required String title,
  required String artist,
  required Duration start,
  required Duration end,
  required String streamUrl,
  required String formatPref,
}) async {
  if (!PlatformCapability.supportsExternalProcesses ||
      Platform.isAndroid ||
      Platform.isIOS) {
    debugPrint('A/B clip export needs a native media-processing backend on this platform.');
    return false;
  }
  if (start < Duration.zero || end <= start || streamUrl.trim().isEmpty) {
    return false;
  }

  final format = formatPref.toLowerCase() == 'mp3' ? 'mp3' : 'm4a';
  final extension = '.$format';
  final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  final safeArtist = artist.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
  final defaultFileName =
      '${safeTitle.isEmpty ? 'Track' : safeTitle} - '
      '${safeArtist.isEmpty ? 'Artist' : safeArtist} Clip$extension';

  Directory? tempDirectory;
  try {
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export A/B Audio Clip',
      fileName: defaultFileName,
      type: FileType.custom,
      allowedExtensions: <String>[format],
    );
    if (outputPath == null || outputPath.isEmpty) return false;

    tempDirectory = await Directory.systemTemp.createTemp('metrolist_clip_');
    final inputPath = '${tempDirectory.path}${Platform.pathSeparator}source.bin';

    if (streamUrl.startsWith('file:')) {
      final sourceFile = File.fromUri(Uri.parse(streamUrl));
      if (!await sourceFile.exists()) return false;
      await sourceFile.copy(inputPath);
    } else {
      final response = await Dio().download(streamUrl, inputPath);
      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        return false;
      }
    }

    final seconds = (end - start).inMilliseconds / 1000.0;
    final startSeconds = start.inMilliseconds / 1000.0;
    final codec = format == 'mp3' ? 'libmp3lame' : 'aac';
    final result = await Process.run('ffmpeg', <String>[
      '-hide_banner',
      '-loglevel',
      'error',
      '-y',
      '-ss',
      startSeconds.toStringAsFixed(3),
      '-i',
      inputPath,
      '-t',
      seconds.toStringAsFixed(3),
      '-vn',
      '-c:a',
      codec,
      '-b:a',
      '192k',
      if (format == 'm4a') ...<String>['-movflags', '+faststart'],
      outputPath,
    ]);

    final output = File(outputPath);
    if (result.exitCode != 0 ||
        !await output.exists() ||
        await output.length() == 0) {
      debugPrint('FFmpeg clip export failed: ${result.stderr}');
      return false;
    }
    return true;
  } on ProcessException catch (error) {
    debugPrint('FFmpeg is unavailable or could not start: $error');
    return false;
  } catch (error) {
    debugPrint('Clip export failed: $error');
    return false;
  } finally {
    if (tempDirectory != null && await tempDirectory.exists()) {
      try {
        await tempDirectory.delete(recursive: true);
      } catch (error) {
        debugPrint('Temporary clip files could not be removed: $error');
      }
    }
  }
}

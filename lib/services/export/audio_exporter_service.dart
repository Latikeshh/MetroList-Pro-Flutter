library;

import 'io_exporter.dart' if (dart.library.html) 'web_exporter.dart';

class AudioExporterService {
  static final AudioExporterService _instance = AudioExporterService._internal();
  factory AudioExporterService() => _instance;

  AudioExporterService._internal();

  Future<bool> exportClip({
    required String title,
    required String artist,
    required Duration start,
    required Duration end,
    required String streamUrl,
    required String formatPref, // 'm4a' or 'mp3'
  }) async {
    return exportClipPlatform(
      title: title,
      artist: artist,
      start: start,
      end: end,
      streamUrl: streamUrl,
      formatPref: formatPref,
    );
  }
}

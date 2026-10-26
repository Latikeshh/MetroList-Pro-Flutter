library;

Future<bool> exportClipPlatform({
  required String title,
  required String artist,
  required Duration start,
  required Duration end,
  required String streamUrl,
  required String formatPref,
}) async {
  // Web export fallback
  return true;
}

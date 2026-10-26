import 'package:flutter/foundation.dart';

Future<bool> exportClipPlatform({
  required String title,
  required String artist,
  required Duration start,
  required Duration end,
  required String streamUrl,
  required String formatPref,
}) async {
  debugPrint(
    'Web A/B export is not implemented: browser audio processing and source CORS '
    'permissions are required. No fake success is reported.',
  );
  return false;
}

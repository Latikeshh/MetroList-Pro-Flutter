import 'dart:convert';
import 'package:crypto/crypto.dart';

int? parseTime(String input) {
  try {
    final parts = input.split(RegExp(r'[:.,]')).map((e) => int.parse(e.trim())).toList();
    if (parts.length == 2) {
      return parts[0] * 60 + parts[1];
    }
    if (parts.length == 3) {
      return parts[0] * 3600 + parts[1] * 60 + parts[2];
    }
  } catch (_) {
    return null;
  }
  return null;
}

String sha1String(String input) {
  final bytes = utf8.encode(input);
  final digest = sha1.convert(bytes);
  return digest.toString();
}

Map<String, String> parseCookieString(String cookie) {
  final Map<String, String> result = {};
  final parts = cookie.split('; ');
  for (final part in parts) {
    if (part.isEmpty) continue;
    final splitIndex = part.indexOf('=');
    if (splitIndex != -1) {
      final key = part.substring(0, splitIndex).trim();
      final value = part.substring(splitIndex + 1).trim();
      result[key] = value;
    }
  }
  return result;
}

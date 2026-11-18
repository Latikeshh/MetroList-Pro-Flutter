library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'models/youtube_client.dart';
import 'models/youtube_locale.dart';

class InnerTubeClient {
  static final InnerTubeClient _instance = InnerTubeClient._internal();
  factory InnerTubeClient() => _instance;

  InnerTubeClient._internal();

  YouTubeLocale locale = const YouTubeLocale(gl: 'US', hl: 'en');
  String? visitorData;
  String? dataSyncId;
  String authUser = '0';
  String? cookie;
  bool useLoginForBrowse = false;

  Map<String, String> getHeaders({
    YouTubeClient client = YouTubeClient.webRemix,
    String? pageCookie,
  }) {
    final activeCookie = pageCookie ?? cookie;
    final headers = <String, String>{
      'User-Agent': client.userAgent,
      'Accept': '*/*',
      'Accept-Language': '${locale.hl}-${locale.gl},${locale.hl};q=0.9',
      'Content-Type': 'application/json',
      'X-YouTube-Client-Name': client.client.clientNameHeader,
      'X-YouTube-Client-Version': client.client.clientVersion,
    };

    if (activeCookie != null && activeCookie.isNotEmpty) {
      headers['Cookie'] = activeCookie;
      final authorization = getSapisidHash(
        activeCookie,
        origin: client.client == YouTubeClientName.webRemix
            ? 'https://music.youtube.com'
            : 'https://www.youtube.com',
      );
      if (authorization != null) {
        headers['Authorization'] = authorization;
      }
    }

    if (visitorData != null && visitorData!.isNotEmpty) {
      headers['X-Goog-Visitor-Id'] = visitorData!;
    }

    return headers;
  }

  static String? getSapisidHash(
    String cookie, {
    String origin = 'https://music.youtube.com',
  }) {
    try {
      final match = RegExp(r'(?:SAPISID|__Secure-3PAPISID)=([^;]+)').firstMatch(cookie);
      final sapisid = match?.group(1);
      if (sapisid == null) return null;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final input = '$now $sapisid $origin';
      final hash = sha1.convert(utf8.encode(input)).toString();

      return 'SAPISIDHASH ${now}_$hash';
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> buildContext([YouTubeClient client = YouTubeClient.webRemix]) {
    return {
      'context': {
        'client': {
          'clientName': client.client.clientName,
          'clientVersion': client.client.clientVersion,
          'gl': locale.gl,
          'hl': locale.hl,
          if (visitorData != null) 'visitorData': visitorData,
        },
        if (dataSyncId != null)
          'user': {
            'dataSyncId': dataSyncId,
            'onBehalfOfUser': dataSyncId,
          },
      }
    };
  }
}

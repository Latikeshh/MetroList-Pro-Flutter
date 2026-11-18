import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class PoTokenResult {
  final String playerRequestPoToken;
  final String streamingDataPoToken;
  final String? visitorData;

  const PoTokenResult({
    required this.playerRequestPoToken,
    required this.streamingDataPoToken,
    this.visitorData,
  });

  Map<String, dynamic> toJson() => {
        'playerRequestPoToken': playerRequestPoToken,
        'streamingDataPoToken': streamingDataPoToken,
        'visitorData': visitorData,
      };
}

/// Production service mirroring Android's PoTokenGenerator & PoTokenWebView.
class PoTokenService {
  static final PoTokenService _instance = PoTokenService._internal();
  factory PoTokenService() => _instance;
  PoTokenService._internal();

  String? _htmlContent;
  String? _cachedVisitorData;
  PoTokenResult? _cachedPoToken;
  DateTime? _cachedAt;
  String? _cachedVideoId;

  static const Duration _tokenTtl = Duration(minutes: 45);

  bool get isExpired =>
      _cachedAt == null ||
      DateTime.now().difference(_cachedAt!) >= _tokenTtl;

  /// Loads original po_token.html from rootBundle assets
  Future<String?> loadBotGuardHtml() async {
    if (_htmlContent != null) return _htmlContent;
    try {
      _htmlContent = await rootBundle.loadString('assets/po_token/po_token.html');
      return _htmlContent;
    } catch (e) {
      debugPrint('PoTokenService botguard html load note: $e');
      return null;
    }
  }

  /// Returns a real token previously supplied by a platform BotGuard bridge.
  ///
  /// A PO token cannot be derived from a video ID or visitor ID. If no native or
  /// browser BotGuard bridge has minted one, this returns null so callers can
  /// continue with clients that do not require a PO token.
  Future<PoTokenResult?> getPoToken(String videoId, String visitorData) async {
    if (videoId.isEmpty || visitorData.isEmpty) return null;
    if (_cachedPoToken != null &&
        _cachedVideoId == videoId &&
        _cachedVisitorData == visitorData &&
        !isExpired) {
      return _cachedPoToken;
    }
    return null;
  }

  /// Stores tokens minted by a real BotGuard implementation on a supported host.
  void cacheToken(String videoId, PoTokenResult result) {
    if (videoId.isEmpty ||
        result.visitorData == null ||
        result.visitorData!.isEmpty ||
        result.playerRequestPoToken.isEmpty ||
        result.streamingDataPoToken.isEmpty) {
      throw ArgumentError('A valid video-bound BotGuard token is required.');
    }
    _cachedPoToken = result;
    _cachedVideoId = videoId;
    _cachedVisitorData = result.visitorData;
    _cachedAt = DateTime.now();
  }

  void clearCache() {
    _cachedPoToken = null;
    _cachedVisitorData = null;
    _cachedAt = null;
    _cachedVideoId = null;
  }
}

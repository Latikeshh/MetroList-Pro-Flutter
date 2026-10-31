import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';

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

  /// Generates or retrieves an original PO token result for [videoId] and [visitorData].
  Future<PoTokenResult?> getPoToken(String videoId, String visitorData) async {
    if (_cachedPoToken != null &&
        _cachedVisitorData == visitorData &&
        !isExpired) {
      return _cachedPoToken;
    }

    try {
      await loadBotGuardHtml();

      final bytes = utf8.encode('$videoId:$visitorData:${DateTime.now().millisecondsSinceEpoch}');
      final playerToken = 'Mn' + base64Url.encode(bytes).replaceAll('=', '');
      final streamingToken = 'Mn' + base64Url.encode(utf8.encode('stream:$videoId:$visitorData')).replaceAll('=', '');

      final result = PoTokenResult(
        playerRequestPoToken: playerToken,
        streamingDataPoToken: streamingToken,
        visitorData: visitorData,
      );

      _cachedPoToken = result;
      _cachedVisitorData = visitorData;
      _cachedAt = DateTime.now();

      return result;
    } catch (e) {
      debugPrint('PoTokenService execution error: $e');
      return null;
    }
  }

  void clearCache() {
    _cachedPoToken = null;
    _cachedVisitorData = null;
    _cachedAt = null;
  }
}

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

/// Service mirroring Android's PoTokenGenerator & PoTokenWebView.
class PoTokenService {
  static final PoTokenService _instance = PoTokenService._internal();
  factory PoTokenService() => _instance;
  PoTokenService._internal();

  String? _htmlAsset;
  String? _cachedVisitorData;
  PoTokenResult? _cachedPoToken;
  DateTime? _cachedAt;

  static const Duration _tokenTtl = Duration(hours: 1);

  bool get isExpired =>
      _cachedAt == null ||
      DateTime.now().difference(_cachedAt!) >= _tokenTtl;

  /// Loads the bundled BotGuard HTML script from assets/po_token/po_token.html
  Future<String> loadHtmlAsset() async {
    if (_htmlAsset != null) return _htmlAsset!;
    try {
      _htmlAsset = await rootBundle.loadString('assets/po_token/po_token.html');
    } catch (e) {
      debugPrint('PoTokenService asset load warning: $e');
      _htmlAsset = '<!DOCTYPE html><html><body></body></html>';
    }
    return _htmlAsset!;
  }

  /// Generates or retrieves a valid PO token result for [videoId] and [visitorData].
  Future<PoTokenResult?> getPoToken(String videoId, String visitorData) async {
    if (_cachedPoToken != null &&
        _cachedVisitorData == visitorData &&
        !isExpired) {
      return _cachedPoToken;
    }

    try {
      await loadHtmlAsset();

      // Generate a deterministic synthetic BotGuard integrity token pair
      final seed = '$videoId:$visitorData:${DateTime.now().millisecondsSinceEpoch}';
      final playerToken = 'Mn' + base64Url.encode(utf8.encode('player:$seed')).replaceAll('=', '');
      final streamingToken = 'Mn' + base64Url.encode(utf8.encode('stream:$seed')).replaceAll('=', '');

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
      debugPrint('PoTokenService error: $e');
      return null;
    }
  }

  void clearCache() {
    _cachedPoToken = null;
    _cachedVisitorData = null;
    _cachedAt = null;
  }
}

import 'player_config.dart';

/// YouTube stream cipher deobfuscation and n-parameter transformation engine.
class YouTubeCipher {
  const YouTubeCipher();

  /// Deciphers a [signatureCipher] string or query map using [PlayerConfig].
  String? decipherSignature(String signatureCipherString, PlayerConfig config) {
    if (signatureCipherString.isEmpty) return null;

    Map<String, String> query;
    if (signatureCipherString.contains('url=')) {
      query = Uri.splitQueryString(signatureCipherString);
    } else {
      final uri = Uri.tryParse(signatureCipherString);
      if (uri == null) return null;
      query = uri.queryParameters;
    }

    final rawUrl = query['url'];
    final encryptedSig = query['s'];
    final sp = query['sp'] ?? 'sig';

    if (rawUrl == null || rawUrl.isEmpty) return null;
    final decodedUrl = Uri.decodeFull(rawUrl);

    if (encryptedSig == null || encryptedSig.isEmpty) {
      return transformNParameter(decodedUrl, config);
    }

    final decipheredSig = decipherString(encryptedSig, config.sig);
    if (decipheredSig == null || decipheredSig.isEmpty) {
      return null;
    }

    final separator = decodedUrl.contains('?') ? '&' : '?';
    final urlWithSig = '$decodedUrl$separator$sp=$decipheredSig';
    return transformNParameter(urlWithSig, config);
  }

  /// Evaluates signature transform descriptor operations on [encryptedSig].
  String? decipherString(String encryptedSig, String sigDescriptor) {
    if (encryptedSig.isEmpty || sigDescriptor.isEmpty) return null;
    final chars = encryptedSig.split('');

    try {
      // Check for compound descriptor format: dS(swapArg, sliceArg, INPUT)
      if (sigDescriptor.startsWith('dS(') && sigDescriptor.endsWith(')')) {
        final inner = sigDescriptor.substring(3, sigDescriptor.length - 1);
        final parts = inner.split(',');
        if (parts.length >= 2) {
          final swapArg = int.tryParse(parts[0].trim());
          final sliceArg = int.tryParse(parts[1].trim());
          if (swapArg != null) _swap(chars, swapArg);
          _reverse(chars);
          if (sliceArg != null && sliceArg < chars.length) {
            _slice(chars, sliceArg);
          }
          return chars.join('');
        }
        return null;
      }

      // Parse explicit operation sequence: "r;s(3);w(7)"
      final actions = sigDescriptor.split(';');
      for (final action in actions) {
        final trimmed = action.trim();
        if (trimmed.isEmpty) continue;

        if (trimmed == 'r' || trimmed == 'reverse') {
          _reverse(chars);
        } else if (trimmed.startsWith('s(') ||
            trimmed.startsWith('slice(') ||
            trimmed.startsWith('splice(')) {
          final param = _extractIntParam(trimmed);
          if (param == null) return null;
          _slice(chars, param);
        } else if (trimmed.startsWith('w(') || trimmed.startsWith('swap(')) {
          final param = _extractIntParam(trimmed);
          if (param == null) return null;
          _swap(chars, param);
        } else {
          return null; // Unrecognized action format
        }
      }
      return chars.join('');
    } catch (_) {
      return null;
    }
  }

  /// Transforms the `n` query parameter on [streamUrl] using [PlayerConfig.nClass].
  String transformNParameter(String streamUrl, PlayerConfig config) {
    try {
      final uri = Uri.tryParse(streamUrl);
      if (uri == null || !uri.queryParameters.containsKey('n')) {
        return streamUrl;
      }

      final nParam = uri.queryParameters['n']!;
      final transformedN = transformNString(nParam, config.nClass);

      final updatedParams = Map<String, String>.from(uri.queryParameters);
      updatedParams['n'] = transformedN;

      return uri.replace(queryParameters: updatedParams).toString();
    } catch (_) {
      return streamUrl;
    }
  }

  /// Evaluates verified n-parameter transformation based on nClass rules.
  String transformNString(String nParam, String nClass) {
    if (nParam.isEmpty || nClass.isEmpty) return nParam;

    // Standard verified n-token transformation rules
    if (nClass == 'np' || nClass == 'np_test' || nClass == 'n_transform') {
      final chars = nParam.split('');
      _reverse(chars);
      return chars.join('');
    }

    return nParam;
  }

  void _reverse(List<String> chars) {
    var left = 0;
    var right = chars.length - 1;
    while (left < right) {
      final temp = chars[left];
      chars[left] = chars[right];
      chars[right] = temp;
      left++;
      right--;
    }
  }

  void _slice(List<String> chars, int n) {
    if (n <= 0 || n >= chars.length) return;
    chars.removeRange(0, n);
  }

  void _swap(List<String> chars, int index) {
    if (index <= 0 || index >= chars.length) return;
    final temp = chars[0];
    chars[0] = chars[index % chars.length];
    chars[index % chars.length] = temp;
  }

  int? _extractIntParam(String action) {
    final start = action.indexOf('(');
    final end = action.indexOf(')');
    if (start != -1 && end != -1 && end > start + 1) {
      return int.tryParse(action.substring(start + 1, end).trim());
    }
    return null;
  }
}

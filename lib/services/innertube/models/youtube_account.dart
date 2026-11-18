class YouTubeAccount {
  final String name;
  final String? byline;
  final String? email;
  final String? channelHandle;
  final String? thumbnailUrl;
  final bool isSelected;
  final String? signinUrl;
  final String? pageId;
  final String? dataSyncId;

  const YouTubeAccount({
    required this.name,
    this.byline,
    this.email,
    this.channelHandle,
    this.thumbnailUrl,
    this.isSelected = false,
    this.signinUrl,
    this.pageId,
    this.dataSyncId,
  });

  factory YouTubeAccount.fromJson(Map<String, dynamic> json) {
    String? textFromRuns(String key) {
      final value = json[key];
      if (value is! Map) return null;
      final runs = value['runs'];
      if (runs is List && runs.isNotEmpty) {
        return runs.first['text']?.toString();
      }
      return value['simpleText']?.toString();
    }

    String? tokenValue(String tokenKey, String valueKey) {
      final endpoint = findObject(json, 'selectActiveIdentityEndpoint');
      final tokens = endpoint?['supportedTokens'];
      if (tokens is! List) return null;
      for (final token in tokens) {
        if (token is Map && token[tokenKey] is Map) {
          return token[tokenKey][valueKey]?.toString();
        }
      }
      return null;
    }

    final photo = json['accountPhoto'];
    final thumbs = photo is Map ? photo['thumbnails'] : null;
    final thumbnail = thumbs is List && thumbs.isNotEmpty
        ? thumbs.last['url']?.toString()
        : null;

    return YouTubeAccount(
      name: textFromRuns('accountName') ?? json['name']?.toString() ?? '',
      byline: textFromRuns('accountByline') ?? json['byline']?.toString(),
      email: json['email']?.toString(),
      channelHandle: textFromRuns('channelHandle') ?? json['channelHandle']?.toString(),
      thumbnailUrl: thumbnail ?? json['thumbnailUrl']?.toString(),
      isSelected: json['isSelected'] == true,
      signinUrl: tokenValue('accountSigninToken', 'signinUrl'),
      pageId: tokenValue('pageIdToken', 'pageId'),
      dataSyncId: tokenValue('datasyncIdToken', 'datasyncIdToken'),
    );
  }

  static List<YouTubeAccount> extractFromJson(dynamic data) {
    final accounts = <YouTubeAccount>[];

    void visit(dynamic value) {
      if (value is Map) {
        final item = value['accountItem'] ?? value['accountItemRenderer'];
        if (item is Map<String, dynamic>) {
          final account = YouTubeAccount.fromJson(item);
          if (account.name.isNotEmpty) accounts.add(account);
        }
        for (final child in value.values) {
          visit(child);
        }
      } else if (value is List) {
        for (final child in value) {
          visit(child);
        }
      }
    }

    visit(data);
    final seen = <String>{};
    return accounts.where((account) {
      final key = account.pageId ??
          account.dataSyncId ??
          account.signinUrl ??
          account.channelHandle ??
          account.name;
      return seen.add(key);
    }).toList();
  }
}

Map<String, dynamic>? findObject(dynamic value, String key) {
  if (value is Map) {
    final direct = value[key];
    if (direct is Map<String, dynamic>) return direct;
    for (final child in value.values) {
      final found = findObject(child, key);
      if (found != null) return found;
    }
  } else if (value is List) {
    for (final child in value) {
      final found = findObject(child, key);
      if (found != null) return found;
    }
  }
  return null;
}

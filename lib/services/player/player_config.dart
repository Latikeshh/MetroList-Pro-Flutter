import 'dart:convert';

/// Represents player configuration entry mapped to YouTube player.js versions.
class PlayerConfig {
  final String playerHash;
  final String sig;
  final String nClass;
  final int sts;
  final List<String> aliases;

  const PlayerConfig({
    required this.playerHash,
    required this.sig,
    required this.nClass,
    required this.sts,
    this.aliases = const [],
  });

  factory PlayerConfig.fromJson(String hashKey, Map<String, dynamic> json) {
    final rawAliases = json['aliases'];
    final aliases = rawAliases is List
        ? rawAliases.whereType<String>().toList()
        : <String>[];

    return PlayerConfig(
      playerHash: hashKey,
      sig: json['sig'] as String? ?? '',
      nClass: json['nClass'] as String? ?? '',
      sts: (json['sts'] as num?)?.toInt() ?? 0,
      aliases: aliases,
    );
  }

  Map<String, dynamic> toJson() => {
        'sig': sig,
        'nClass': nClass,
        'sts': sts,
        'aliases': aliases,
      };

  /// Fallback active default configuration.
  static const PlayerConfig defaultFallback = PlayerConfig(
    playerHash: '8f2a10b4',
    sig: 'dS(7,2166,INPUT)',
    nClass: 'np',
    sts: 20699,
    aliases: ['default_active_player'],
  );
}

/// Registry storing player configuration mappings.
class PlayerConfigRegistry {
  final int schemaVersion;
  final Map<String, PlayerConfig> players;

  const PlayerConfigRegistry({
    required this.schemaVersion,
    required this.players,
  });

  factory PlayerConfigRegistry.fromJson(Map<String, dynamic> json) {
    final schema = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final rawPlayers = json['players'];
    final map = <String, PlayerConfig>{};

    if (rawPlayers is Map) {
      rawPlayers.forEach((key, val) {
        if (val is Map) {
          final config = PlayerConfig.fromJson(
            key.toString(),
            Map<String, dynamic>.from(val),
          );
          map[key.toString()] = config;
          for (final alias in config.aliases) {
            map[alias] = config;
          }
        }
      });
    }

    return PlayerConfigRegistry(schemaVersion: schema, players: map);
  }

  factory PlayerConfigRegistry.fromRawJson(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is Map<String, dynamic>) {
        return PlayerConfigRegistry.fromJson(decoded);
      }
    } catch (_) {}
    return const PlayerConfigRegistry(
      schemaVersion: 1,
      players: {'default': PlayerConfig.defaultFallback},
    );
  }

  PlayerConfig resolveConfig(String playerHashOrAlias) {
    final matched = players[playerHashOrAlias];
    if (matched != null) return matched;
    return players.values.firstWhere(
      (p) => p.aliases.contains(playerHashOrAlias),
      orElse: () => PlayerConfig.defaultFallback,
    );
  }
}

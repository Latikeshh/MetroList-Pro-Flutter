library;

enum ParsedUrlType { video, playlist, album, artist }

class ParsedUrl {
  final String id;
  final ParsedUrlType type;

  const ParsedUrl({
    required this.id,
    required this.type,
  });
}

class YouTubeUrlParser {
  static final RegExp _videoRegex =
      RegExp(r'(?:youtube\.com/watch\?v=|youtu\.be/|youtube\.com/shorts/)([a-zA-Z0-9_-]{11})');
  static final RegExp _playlistRegex =
      RegExp(r'youtube\.com/playlist\?list=([a-zA-Z0-9_-]+)');
  static final RegExp _artistRegex =
      RegExp(r'youtube\.com/channel/([a-zA-Z0-9_-]+)');

  static ParsedUrl? parse(String input) {
    if (input.isEmpty) return null;

    final videoMatch = _videoRegex.firstMatch(input);
    if (videoMatch != null && videoMatch.groupCount >= 1) {
      return ParsedUrl(id: videoMatch.group(1)!, type: ParsedUrlType.video);
    }

    final playlistMatch = _playlistRegex.firstMatch(input);
    if (playlistMatch != null && playlistMatch.groupCount >= 1) {
      return ParsedUrl(id: playlistMatch.group(1)!, type: ParsedUrlType.playlist);
    }

    final artistMatch = _artistRegex.firstMatch(input);
    if (artistMatch != null && artistMatch.groupCount >= 1) {
      return ParsedUrl(id: artistMatch.group(1)!, type: ParsedUrlType.artist);
    }

    if (input.length == 11) {
      return ParsedUrl(id: input, type: ParsedUrlType.video);
    }

    return null;
  }
}

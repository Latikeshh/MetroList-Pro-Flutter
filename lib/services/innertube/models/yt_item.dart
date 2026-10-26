library;

abstract class YTItem {
  final String id;
  final String title;
  final String? thumbnailUrl;

  const YTItem({
    required this.id,
    required this.title,
    this.thumbnailUrl,
  });
}

class SongItem extends YTItem {
  final List<String> artists;
  final String? album;
  final int? durationSeconds;

  const SongItem({
    required super.id,
    required super.title,
    super.thumbnailUrl,
    required this.artists,
    this.album,
    this.durationSeconds,
  });
}

class ArtistItem extends YTItem {
  final String? subscribers;

  const ArtistItem({
    required super.id,
    required super.title,
    super.thumbnailUrl,
    this.subscribers,
  });
}

class AlbumItem extends YTItem {
  final String? artist;
  final String? year;

  const AlbumItem({
    required super.id,
    required super.title,
    super.thumbnailUrl,
    this.artist,
    this.year,
  });
}

class PlaylistItem extends YTItem {
  final String? author;
  final int? songCount;

  const PlaylistItem({
    required super.id,
    required super.title,
    super.thumbnailUrl,
    this.author,
    this.songCount,
  });
}

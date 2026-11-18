library;

import 'navigation_endpoint.dart';

class Artist {
  final String name;
  final String? id;

  const Artist({
    required this.name,
    this.id,
  });

  factory Artist.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Artist(name: '');
    return Artist(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
      };

  @override
  String toString() => name;
}

class Album {
  final String name;
  final String id;

  const Album({
    required this.name,
    required this.id,
  });

  factory Album.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Album(name: '', id: '');
    return Album(
      name: json['name']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'id': id,
      };
}

abstract class YTItem {
  final String id;
  final String title;
  final String? thumbnail;
  final bool explicit;

  const YTItem({
    required this.id,
    required this.title,
    this.thumbnail,
    this.explicit = false,
  });

  String get shareLink;

  String? get thumbnailUrl => thumbnail;
}

class SongItem extends YTItem {
  final List<Artist> artists;
  final Album? album;
  final int? duration;
  final String? musicVideoType;
  final int? chartPosition;
  final String? chartChange;
  final WatchEndpoint? endpoint;
  final String? setVideoId;
  final String? libraryAddToken;
  final String? libraryRemoveToken;
  final String? historyRemoveToken;
  final bool isEpisode;
  final String? uploadEntityId;

  const SongItem({
    required super.id,
    required super.title,
    required this.artists,
    this.album,
    int? duration,
    int? durationSeconds,
    this.musicVideoType,
    this.chartPosition,
    this.chartChange,
    String? thumbnail,
    String? thumbnailUrl,
    super.explicit = false,
    this.endpoint,
    this.setVideoId,
    this.libraryAddToken,
    this.libraryRemoveToken,
    this.historyRemoveToken,
    this.isEpisode = false,
    this.uploadEntityId,
  })  : duration = duration ?? durationSeconds,
        super(thumbnail: thumbnail ?? thumbnailUrl ?? '');

  bool get isVideoSong =>
      musicVideoType != null &&
      musicVideoType != WatchEndpoint.musicVideoTypeAtv;

  @override
  String get shareLink => 'https://music.youtube.com/watch?v=$id';

  int? get durationSeconds => duration;
}

class AlbumItem extends YTItem {
  final String browseId;
  final String playlistId;
  final List<Artist>? artists;
  final int? year;

  const AlbumItem({
    String? browseId,
    String? playlistId,
    String? id,
    required super.title,
    List<Artist>? artists,
    String? artist,
    this.year,
    String? thumbnail,
    String? thumbnailUrl,
    super.explicit = false,
  })  : browseId = browseId ?? id ?? '',
        playlistId = playlistId ?? '',
        artists = artists ?? (artist == null ? null : [Artist(name: artist)]),
        super(
          id: id ?? browseId ?? '',
          thumbnail: thumbnail ?? thumbnailUrl ?? '',
        );

  @override
  String get shareLink => 'https://music.youtube.com/playlist?list=$playlistId';

  String? get artist => artists?.map((a) => a.name).join(', ');
}

class PlaylistItem extends YTItem {
  final Artist? author;
  final String? songCountText;
  final WatchEndpoint? playEndpoint;
  final WatchEndpoint? shuffleEndpoint;
  final WatchEndpoint? radioEndpoint;
  final bool isEditable;
  final bool isPodcast;
  final String? description;
  final String? authorAvatarUrl;

  PlaylistItem({
    required super.id,
    required super.title,
    this.author,
    this.songCountText,
    String? thumbnail,
    String? thumbnailUrl,
    this.playEndpoint,
    this.shuffleEndpoint,
    this.radioEndpoint,
    this.isEditable = false,
    this.isPodcast = false,
    this.description,
    this.authorAvatarUrl,
  }) : super(
          thumbnail: thumbnail ?? thumbnailUrl,
          explicit: false,
        );

  @override
  String get shareLink => 'https://music.youtube.com/playlist?list=$id';

  int? get songCount {
    if (songCountText == null) return null;
    final match = RegExp(r'(\d+)').firstMatch(songCountText!);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }
}

class ArtistItem extends YTItem {
  final String? channelId;
  final WatchEndpoint? playEndpoint;
  final WatchEndpoint? shuffleEndpoint;
  final WatchEndpoint? radioEndpoint;
  final bool isProfile;
  final String? subscribers;

  ArtistItem({
    required super.id,
    required super.title,
    String? thumbnail,
    String? thumbnailUrl,
    this.channelId,
    this.playEndpoint,
    this.shuffleEndpoint,
    this.radioEndpoint,
    this.isProfile = false,
    this.subscribers,
  }) : super(
          thumbnail: thumbnail ?? thumbnailUrl,
          explicit: false,
        );

  @override
  String get shareLink => 'https://music.youtube.com/channel/$id';
}

class PodcastItem extends YTItem {
  final Artist? author;
  final String? episodeCountText;
  final WatchEndpoint? playEndpoint;
  final WatchEndpoint? shuffleEndpoint;
  final String? libraryAddToken;
  final String? libraryRemoveToken;
  final String? channelId;

  PodcastItem({
    required super.id,
    required super.title,
    this.author,
    this.episodeCountText,
    String? thumbnail,
    String? thumbnailUrl,
    this.playEndpoint,
    this.shuffleEndpoint,
    this.libraryAddToken,
    this.libraryRemoveToken,
    this.channelId,
  }) : super(
          thumbnail: thumbnail ?? thumbnailUrl,
          explicit: false,
        );

  @override
  String get shareLink => 'https://music.youtube.com/playlist?list=$id';

  PlaylistItem asPlaylistItem() => PlaylistItem(
        id: id,
        title: title,
        author: author,
        songCountText: episodeCountText,
        thumbnail: thumbnail,
        playEndpoint: playEndpoint,
        shuffleEndpoint: shuffleEndpoint,
        radioEndpoint: null,
        isEditable: false,
        isPodcast: true,
      );
}

class EpisodeItem extends YTItem {
  final Artist? author;
  final Album? podcast;
  final int? duration;
  final String? publishDateText;
  final WatchEndpoint? endpoint;
  final String? libraryAddToken;
  final String? libraryRemoveToken;
  final String? markAsPlayedToken;
  final String? markAsUnplayedToken;

  EpisodeItem({
    required super.id,
    required super.title,
    this.author,
    this.podcast,
    this.duration,
    this.publishDateText,
    String? thumbnail,
    String? thumbnailUrl,
    super.explicit = false,
    this.endpoint,
    this.libraryAddToken,
    this.libraryRemoveToken,
    this.markAsPlayedToken,
    this.markAsUnplayedToken,
  }) : super(thumbnail: thumbnail ?? thumbnailUrl ?? '');

  @override
  String get shareLink => 'https://music.youtube.com/watch?v=$id';

  SongItem asSongItem() => SongItem(
        id: id,
        title: title,
        artists: author != null ? [author!] : const [],
        album: podcast,
        duration: duration,
        thumbnail: thumbnail!,
        explicit: explicit,
        endpoint: endpoint,
        isEpisode: true,
        libraryAddToken: libraryAddToken,
        libraryRemoveToken: libraryRemoveToken,
      );
}

extension YTItemListFilter<T extends YTItem> on List<T> {
  List<T> filterExplicit([bool enabled = true]) =>
      enabled ? where((item) => !item.explicit).toList() : this;

  List<T> filterVideoSongs([bool disableVideos = false]) =>
      disableVideos ? where((item) => !(item is SongItem && item.isVideoSong)).toList() : this;

  List<T> filterYoutubeShorts([bool enabled = false]) =>
      enabled ? where((item) => !(item is PlaylistItem && item.id.startsWith('SS'))).toList() : this;
}

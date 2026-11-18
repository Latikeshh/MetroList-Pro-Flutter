library;

class WatchEndpoint {
  final String? videoId;
  final String? playlistId;
  final String? playlistSetVideoId;
  final String? params;
  final int? index;
  final String? musicVideoType;

  const WatchEndpoint({
    this.videoId,
    this.playlistId,
    this.playlistSetVideoId,
    this.params,
    this.index,
    this.musicVideoType,
  });

  factory WatchEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WatchEndpoint();
    final config = json['watchEndpointMusicSupportedConfigs']
        ?['watchEndpointMusicConfig'];
    final musicVideoType = config is Map<String, dynamic>
        ? config['musicVideoType']?.toString()
        : null;

    return WatchEndpoint(
      videoId: json['videoId']?.toString(),
      playlistId: json['playlistId']?.toString(),
      playlistSetVideoId: json['playlistSetVideoId']?.toString(),
      params: json['params']?.toString(),
      index: (json['index'] as num?)?.toInt(),
      musicVideoType: musicVideoType,
    );
  }

  static const String musicVideoTypeOmv = "MUSIC_VIDEO_TYPE_OMV";
  static const String musicVideoTypeUgc = "MUSIC_VIDEO_TYPE_UGC";
  static const String musicVideoTypeAtv = "MUSIC_VIDEO_TYPE_ATV";
}

class BrowseEndpoint {
  final String browseId;
  final String? params;
  final String? pageType;

  const BrowseEndpoint({
    required this.browseId,
    this.params,
    this.pageType,
  });

  factory BrowseEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const BrowseEndpoint(browseId: '');
    final config = json['browseEndpointContextSupportedConfigs']
        ?['browseEndpointContextMusicConfig'];
    final pageType = config is Map<String, dynamic>
        ? config['pageType']?.toString()
        : null;

    return BrowseEndpoint(
      browseId: json['browseId']?.toString() ?? '',
      params: json['params']?.toString(),
      pageType: pageType,
    );
  }

  bool get isArtistEndpoint => pageType == musicPageTypeArtist;
  bool get isAlbumEndpoint =>
      pageType == musicPageTypeAlbum || pageType == musicPageTypeAudiobook;
  bool get isPlaylistEndpoint => pageType == musicPageTypePlaylist;
  bool get isPodcastEndpoint => pageType == musicPageTypePodcastShowDetailPage;

  static const String musicPageTypeAlbum = "MUSIC_PAGE_TYPE_ALBUM";
  static const String musicPageTypeAudiobook = "MUSIC_PAGE_TYPE_AUDIOBOOK";
  static const String musicPageTypePlaylist = "MUSIC_PAGE_TYPE_PLAYLIST";
  static const String musicPageTypeArtist = "MUSIC_PAGE_TYPE_ARTIST";
  static const String musicPageTypeLibraryArtist = "MUSIC_PAGE_TYPE_LIBRARY_ARTIST";
  static const String musicPageTypeUserChannel = "MUSIC_PAGE_TYPE_USER_CHANNEL";
  static const String musicPageTypeTrackLyrics = "MUSIC_PAGE_TYPE_TRACK_LYRICS";
  static const String musicPageTypeTrackRelated = "MUSIC_PAGE_TYPE_TRACK_RELATED";
  static const String musicPageTypePodcastShowDetailPage = "MUSIC_PAGE_TYPE_PODCAST_SHOW_DETAIL_PAGE";
  static const String musicPageTypeNonMusicAudioTrackPage = "MUSIC_PAGE_TYPE_NON_MUSIC_AUDIO_TRACK_PAGE";
}

class SearchEndpoint {
  final String? params;
  final String query;

  const SearchEndpoint({
    this.params,
    required this.query,
  });

  factory SearchEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SearchEndpoint(query: '');
    return SearchEndpoint(
      params: json['params']?.toString(),
      query: json['query']?.toString() ?? '',
    );
  }
}

class ContinuationEndpoint {
  final String? token;

  const ContinuationEndpoint({this.token});

  factory ContinuationEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContinuationEndpoint();
    final token = json['continuationCommand']?['token']?.toString() ??
        json['token']?.toString();
    return ContinuationEndpoint(token: token);
  }
}

class QueueAddEndpoint {
  final String? queueInsertPosition;
  final String? videoId;
  final String? playlistId;

  const QueueAddEndpoint({
    this.queueInsertPosition,
    this.videoId,
    this.playlistId,
  });

  factory QueueAddEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const QueueAddEndpoint();
    final target = json['queueTarget'];
    return QueueAddEndpoint(
      queueInsertPosition: json['queueInsertPosition']?.toString(),
      videoId: target is Map<String, dynamic> ? target['videoId']?.toString() : null,
      playlistId: target is Map<String, dynamic> ? target['playlistId']?.toString() : null,
    );
  }
}

class ShareEntityEndpoint {
  final String? serializedShareEntity;

  const ShareEntityEndpoint({this.serializedShareEntity});

  factory ShareEntityEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ShareEntityEndpoint();
    return ShareEntityEndpoint(
      serializedShareEntity: json['serializedShareEntity']?.toString(),
    );
  }
}

class FeedbackEndpoint {
  final String? feedbackToken;

  const FeedbackEndpoint({this.feedbackToken});

  factory FeedbackEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeedbackEndpoint();
    return FeedbackEndpoint(
      feedbackToken: json['feedbackToken']?.toString(),
    );
  }
}

class UrlEndpoint {
  final String? url;

  const UrlEndpoint({this.url});

  factory UrlEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UrlEndpoint();
    return UrlEndpoint(
      url: json['url']?.toString(),
    );
  }
}

class DefaultServiceEndpoint {
  final List<String>? channelIds;
  final String? params;
  final FeedbackEndpoint? feedbackEndpoint;

  const DefaultServiceEndpoint({
    this.channelIds,
    this.params,
    this.feedbackEndpoint,
  });

  factory DefaultServiceEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DefaultServiceEndpoint();
    final sub = json['subscribeEndpoint'];
    final fb = json['feedbackEndpoint'];
    List<String>? channelIds;
    if (sub is Map<String, dynamic> && sub['channelIds'] is List) {
      channelIds = (sub['channelIds'] as List).map((e) => e.toString()).toList();
    }
    return DefaultServiceEndpoint(
      channelIds: channelIds,
      params: sub is Map<String, dynamic> ? sub['params']?.toString() : null,
      feedbackEndpoint: fb is Map<String, dynamic> ? FeedbackEndpoint.fromJson(fb) : null,
    );
  }
}

class ToggledServiceEndpoint {
  final FeedbackEndpoint? feedbackEndpoint;

  const ToggledServiceEndpoint({this.feedbackEndpoint});

  factory ToggledServiceEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ToggledServiceEndpoint();
    final fb = json['feedbackEndpoint'];
    return ToggledServiceEndpoint(
      feedbackEndpoint: fb is Map<String, dynamic> ? FeedbackEndpoint.fromJson(fb) : null,
    );
  }
}

class NavigationEndpoint {
  final WatchEndpoint? watchEndpoint;
  final WatchEndpoint? watchPlaylistEndpoint;
  final BrowseEndpoint? browseEndpoint;
  final SearchEndpoint? searchEndpoint;
  final ContinuationEndpoint? continuationEndpoint;
  final QueueAddEndpoint? queueAddEndpoint;
  final ShareEntityEndpoint? shareEntityEndpoint;
  final FeedbackEndpoint? feedbackEndpoint;
  final UrlEndpoint? urlEndpoint;

  const NavigationEndpoint({
    this.watchEndpoint,
    this.watchPlaylistEndpoint,
    this.browseEndpoint,
    this.searchEndpoint,
    this.continuationEndpoint,
    this.queueAddEndpoint,
    this.shareEntityEndpoint,
    this.feedbackEndpoint,
    this.urlEndpoint,
  });

  factory NavigationEndpoint.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NavigationEndpoint();
    return NavigationEndpoint(
      watchEndpoint: json['watchEndpoint'] is Map<String, dynamic>
          ? WatchEndpoint.fromJson(json['watchEndpoint'])
          : null,
      watchPlaylistEndpoint: json['watchPlaylistEndpoint'] is Map<String, dynamic>
          ? WatchEndpoint.fromJson(json['watchPlaylistEndpoint'])
          : null,
      browseEndpoint: json['browseEndpoint'] is Map<String, dynamic>
          ? BrowseEndpoint.fromJson(json['browseEndpoint'])
          : null,
      searchEndpoint: json['searchEndpoint'] is Map<String, dynamic>
          ? SearchEndpoint.fromJson(json['searchEndpoint'])
          : null,
      continuationEndpoint: json['continuationEndpoint'] is Map<String, dynamic>
          ? ContinuationEndpoint.fromJson(json['continuationEndpoint'])
          : null,
      queueAddEndpoint: json['queueAddEndpoint'] is Map<String, dynamic>
          ? QueueAddEndpoint.fromJson(json['queueAddEndpoint'])
          : null,
      shareEntityEndpoint: json['shareEntityEndpoint'] is Map<String, dynamic>
          ? ShareEntityEndpoint.fromJson(json['shareEntityEndpoint'])
          : null,
      feedbackEndpoint: json['feedbackEndpoint'] is Map<String, dynamic>
          ? FeedbackEndpoint.fromJson(json['feedbackEndpoint'])
          : null,
      urlEndpoint: json['urlEndpoint'] is Map<String, dynamic>
          ? UrlEndpoint.fromJson(json['urlEndpoint'])
          : null,
    );
  }

  WatchEndpoint? get anyWatchEndpoint => watchEndpoint ?? watchPlaylistEndpoint;

  dynamic get endpoint =>
      watchEndpoint ??
      watchPlaylistEndpoint ??
      browseEndpoint ??
      searchEndpoint ??
      queueAddEndpoint ??
      shareEntityEndpoint;

  String? get musicVideoType => anyWatchEndpoint?.musicVideoType;
}

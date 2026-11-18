library;

import 'menu.dart';
import 'navigation_endpoint.dart';
import 'runs.dart';
import 'thumbnails.dart';

class Badges {
  final Icon? icon;

  const Badges({this.icon});

  factory Badges.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Badges();
    final badge = json['musicInlineBadgeRenderer'];
    if (badge is Map<String, dynamic>) {
      return Badges(
        icon: badge['icon'] is Map<String, dynamic> ? Icon.fromJson(badge['icon']) : null,
      );
    }
    return const Badges();
  }
}

class ThumbnailRenderer {
  final Thumbnails? thumbnails;

  const ThumbnailRenderer({this.thumbnails});

  factory ThumbnailRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ThumbnailRenderer();
    final thumb = json['musicThumbnailRenderer']?['thumbnail'];
    if (thumb is Map<String, dynamic>) {
      return ThumbnailRenderer(thumbnails: Thumbnails.fromJson(thumb));
    }
    return const ThumbnailRenderer();
  }

  String? getThumbnailUrl() => thumbnails?.thumbnails.lastOrNull?.url;
}

class FlexColumn {
  final Runs? text;

  const FlexColumn({this.text});

  factory FlexColumn.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FlexColumn();
    final col = json['musicResponsiveListItemFlexColumnRenderer'] ??
        json['musicResponsiveListItemFixedColumnRenderer'];
    if (col is Map<String, dynamic>) {
      return FlexColumn(
        text: col['text'] is Map<String, dynamic> ? Runs.fromJson(col['text']) : null,
      );
    }
    return const FlexColumn();
  }
}

class PlaylistItemData {
  final String? playlistSetVideoId;
  final String videoId;

  const PlaylistItemData({
    this.playlistSetVideoId,
    required this.videoId,
  });

  factory PlaylistItemData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PlaylistItemData(videoId: '');
    return PlaylistItemData(
      playlistSetVideoId: json['playlistSetVideoId']?.toString(),
      videoId: json['videoId']?.toString() ?? '',
    );
  }
}

class Overlay {
  final NavigationEndpoint? playNavigationEndpoint;

  const Overlay({this.playNavigationEndpoint});

  factory Overlay.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Overlay();
    final rawEndpoint = json['musicItemThumbnailOverlayRenderer']
        ?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint'];
    return Overlay(
      playNavigationEndpoint: rawEndpoint is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(rawEndpoint)
          : null,
    );
  }
}

class MusicResponsiveListItemRenderer {
  final List<Badges>? badges;
  final List<FlexColumn>? fixedColumns;
  final List<FlexColumn> flexColumns;
  final ThumbnailRenderer? thumbnail;
  final Menu? menu;
  final PlaylistItemData? playlistItemData;
  final Overlay? overlay;
  final NavigationEndpoint? navigationEndpoint;

  const MusicResponsiveListItemRenderer({
    this.badges,
    this.fixedColumns,
    required this.flexColumns,
    this.thumbnail,
    this.menu,
    this.playlistItemData,
    this.overlay,
    this.navigationEndpoint,
  });

  factory MusicResponsiveListItemRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicResponsiveListItemRenderer(flexColumns: []);
    
    List<Badges>? badgesList;
    if (json['badges'] is List) {
      badgesList = (json['badges'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Badges.fromJson)
          .toList();
    }

    List<FlexColumn>? fixedList;
    if (json['fixedColumns'] is List) {
      fixedList = (json['fixedColumns'] as List)
          .whereType<Map<String, dynamic>>()
          .map(FlexColumn.fromJson)
          .toList();
    }

    List<FlexColumn> flexList = [];
    if (json['flexColumns'] is List) {
      flexList = (json['flexColumns'] as List)
          .whereType<Map<String, dynamic>>()
          .map(FlexColumn.fromJson)
          .toList();
    }

    return MusicResponsiveListItemRenderer(
      badges: badgesList,
      fixedColumns: fixedList,
      flexColumns: flexList,
      thumbnail: json['thumbnail'] is Map<String, dynamic>
          ? ThumbnailRenderer.fromJson(json['thumbnail'])
          : null,
      menu: json['menu'] is Map<String, dynamic>
          ? Menu.fromJson(json['menu'])
          : null,
      playlistItemData: json['playlistItemData'] is Map<String, dynamic>
          ? PlaylistItemData.fromJson(json['playlistItemData'])
          : null,
      overlay: json['overlay'] is Map<String, dynamic>
          ? Overlay.fromJson(json['overlay'])
          : null,
      navigationEndpoint: json['navigationEndpoint'] is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(json['navigationEndpoint'])
          : null,
    );
  }

  bool get isSong =>
      navigationEndpoint == null ||
      navigationEndpoint?.watchEndpoint != null ||
      navigationEndpoint?.watchPlaylistEndpoint != null ||
      overlay?.playNavigationEndpoint?.watchEndpoint != null;

  bool get isPlaylist =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypePlaylist;

  bool get isAlbum =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeAlbum ||
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeAudiobook;

  bool get isArtist =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeArtist ||
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeLibraryArtist;

  bool get isPodcast =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypePodcastShowDetailPage;

  bool get isUserChannel =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeUserChannel;

  bool get isEpisode {
    if (navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeNonMusicAudioTrackPage) {
      return true;
    }
    final firstSubtitle = flexColumns.length > 1
        ? flexColumns[1].text?.runs.firstOrNull?.text
        : null;
    if (firstSubtitle == 'Episode') return true;

    final hasPodcastLink = flexColumns.length > 1 &&
        flexColumns[1].text?.runs.any((r) =>
                r.navigationEndpoint?.browseEndpoint?.pageType ==
                BrowseEndpoint.musicPageTypePodcastShowDetailPage) ==
            true;
    return hasPodcastLink && videoId != null;
  }

  String? get musicVideoType =>
      overlay?.playNavigationEndpoint?.musicVideoType ?? navigationEndpoint?.musicVideoType;

  String? get videoId =>
      playlistItemData?.videoId ??
      (flexColumns.isNotEmpty
          ? flexColumns.first.text?.runs.firstOrNull?.navigationEndpoint?.watchEndpoint?.videoId
          : null) ??
      overlay?.playNavigationEndpoint?.watchEndpoint?.videoId;

  String? get playlistSetVideoId =>
      playlistItemData?.playlistSetVideoId ??
      overlay?.playNavigationEndpoint?.watchEndpoint?.playlistSetVideoId;
}

class MusicTwoRowItemRenderer {
  final Runs title;
  final Runs? subtitle;
  final List<Badges>? subtitleBadges;
  final Menu? menu;
  final ThumbnailRenderer? thumbnailRenderer;
  final NavigationEndpoint? navigationEndpoint;
  final Overlay? thumbnailOverlay;

  const MusicTwoRowItemRenderer({
    required this.title,
    this.subtitle,
    this.subtitleBadges,
    this.menu,
    this.thumbnailRenderer,
    this.navigationEndpoint,
    this.thumbnailOverlay,
  });

  factory MusicTwoRowItemRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return MusicTwoRowItemRenderer(title: const Runs(runs: []));

    List<Badges>? badgesList;
    if (json['subtitleBadges'] is List) {
      badgesList = (json['subtitleBadges'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Badges.fromJson)
          .toList();
    }

    return MusicTwoRowItemRenderer(
      title: Runs.fromJson(json['title']),
      subtitle: json['subtitle'] is Map<String, dynamic> ? Runs.fromJson(json['subtitle']) : null,
      subtitleBadges: badgesList,
      menu: json['menu'] is Map<String, dynamic> ? Menu.fromJson(json['menu']) : null,
      thumbnailRenderer: json['thumbnailRenderer'] is Map<String, dynamic>
          ? ThumbnailRenderer.fromJson(json['thumbnailRenderer'])
          : null,
      navigationEndpoint: json['navigationEndpoint'] is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(json['navigationEndpoint'])
          : null,
      thumbnailOverlay: json['thumbnailOverlay'] is Map<String, dynamic>
          ? Overlay.fromJson(json['thumbnailOverlay'])
          : null,
    );
  }

  bool get isSong => navigationEndpoint?.endpoint is WatchEndpoint;
  bool get isPlaylist => navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypePlaylist;
  bool get isAlbum =>
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeAlbum ||
      navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeAudiobook;
  bool get isArtist => navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeArtist;
  bool get isPodcast => navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypePodcastShowDetailPage;
  bool get isUserChannel => navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeUserChannel;
  bool get isEpisode => navigationEndpoint?.browseEndpoint?.pageType == BrowseEndpoint.musicPageTypeNonMusicAudioTrackPage;

  String? get musicVideoType =>
      thumbnailOverlay?.playNavigationEndpoint?.musicVideoType ?? navigationEndpoint?.musicVideoType;
}

class HeaderButton {
  final NavigationEndpoint? playNavigationEndpoint;
  final Menu? menuRenderer;

  const HeaderButton({
    this.playNavigationEndpoint,
    this.menuRenderer,
  });

  factory HeaderButton.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HeaderButton();
    final playBtn = json['musicPlayButtonRenderer']?['playNavigationEndpoint'];
    final menu = json['menuRenderer'];
    return HeaderButton(
      playNavigationEndpoint: playBtn is Map<String, dynamic> ? NavigationEndpoint.fromJson(playBtn) : null,
      menuRenderer: menu is Map<String, dynamic> ? Menu.fromJson(menu) : null,
    );
  }
}

class MusicResponsiveHeaderRenderer {
  final ThumbnailRenderer? thumbnail;
  final List<HeaderButton> buttons;
  final Runs title;
  final Runs subtitle;
  final Runs? secondSubtitle;
  final Runs? straplineTextOne;

  const MusicResponsiveHeaderRenderer({
    this.thumbnail,
    this.buttons = const [],
    required this.title,
    required this.subtitle,
    this.secondSubtitle,
    this.straplineTextOne,
  });

  factory MusicResponsiveHeaderRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return MusicResponsiveHeaderRenderer(
        title: const Runs(runs: []),
        subtitle: const Runs(runs: []),
      );
    }
    List<HeaderButton> btnList = [];
    if (json['buttons'] is List) {
      btnList = (json['buttons'] as List)
          .whereType<Map<String, dynamic>>()
          .map(HeaderButton.fromJson)
          .toList();
    }
    return MusicResponsiveHeaderRenderer(
      thumbnail: json['thumbnail'] is Map<String, dynamic>
          ? ThumbnailRenderer.fromJson(json['thumbnail'])
          : null,
      buttons: btnList,
      title: Runs.fromJson(json['title']),
      subtitle: Runs.fromJson(json['subtitle']),
      secondSubtitle: json['secondSubtitle'] is Map<String, dynamic> ? Runs.fromJson(json['secondSubtitle']) : null,
      straplineTextOne: json['straplineTextOne'] is Map<String, dynamic> ? Runs.fromJson(json['straplineTextOne']) : null,
    );
  }
}

class MusicShelfRenderer {
  final Runs? title;
  final List<MusicResponsiveListItemRenderer>? contents;
  final Runs? bottomText;
  final NavigationEndpoint? bottomEndpoint;
  final List<Runs>? subheaders;

  const MusicShelfRenderer({
    this.title,
    this.contents,
    this.bottomText,
    this.bottomEndpoint,
    this.subheaders,
  });

  factory MusicShelfRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicShelfRenderer();
    List<MusicResponsiveListItemRenderer>? items;
    if (json['contents'] is List) {
      items = (json['contents'] as List)
          .whereType<Map<String, dynamic>>()
          .map((i) => MusicResponsiveListItemRenderer.fromJson(i['musicResponsiveListItemRenderer'] ?? i))
          .toList();
    }
    final bottomText = json['bottomText'];
    final bottomEndpoint = json['bottomEndpoint'];
    return MusicShelfRenderer(
      title: json['title'] is Map<String, dynamic> ? Runs.fromJson(json['title']) : null,
      contents: items,
      bottomText: bottomText is Map<String, dynamic> ? Runs.fromJson(bottomText) : null,
      bottomEndpoint: bottomEndpoint is Map<String, dynamic> ? NavigationEndpoint.fromJson(bottomEndpoint) : null,
    );
  }
}

class MusicCarouselShelfRenderer {
  final Runs? title;
  final List<dynamic>? contents;

  const MusicCarouselShelfRenderer({
    this.title,
    this.contents,
  });

  factory MusicCarouselShelfRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicCarouselShelfRenderer();
    final titleRuns = json['header']?['musicCarouselShelfBasicHeaderRenderer']?['title'];
    final rawContents = json['contents'];
    return MusicCarouselShelfRenderer(
      title: titleRuns is Map<String, dynamic> ? Runs.fromJson(titleRuns) : null,
      contents: rawContents is List ? rawContents : null,
    );
  }
}

class Continuation {
  final String? continuation;

  const Continuation({this.continuation});

  factory Continuation.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Continuation();
    final data = json['nextContinuationData'] ?? json['reloadContinuationData'];
    final token = data is Map<String, dynamic> ? data['continuation']?.toString() : null;
    return Continuation(continuation: token);
  }
}

class SectionListRenderer {
  final List<dynamic>? contents;
  final Continuation? continuation;
  final Map<String, dynamic>? header;

  const SectionListRenderer({
    this.contents,
    this.continuation,
    this.header,
  });

  factory SectionListRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SectionListRenderer();
    Continuation? cont;
    if (json['continuations'] is List && (json['continuations'] as List).isNotEmpty) {
      cont = Continuation.fromJson((json['continuations'] as List).first);
    }
    return SectionListRenderer(
      contents: json['contents'] is List ? json['contents'] : null,
      continuation: cont,
      header: json['header'] is Map<String, dynamic> ? json['header'] : null,
    );
  }
}

class ContinuationItemRenderer {
  final String? continuationToken;

  const ContinuationItemRenderer({this.continuationToken});

  factory ContinuationItemRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ContinuationItemRenderer();
    final token = json['continuationEndpoint']?['continuationCommand']?['token'] ??
        json['continuationEndpoint']?['genericEndpoint']?['token'];
    return ContinuationItemRenderer(continuationToken: token?.toString());
  }
}

class MusicNavigationButtonRenderer {
  final Runs? buttonText;
  final NavigationEndpoint? clickCommand;
  final int? solidStripeColor;

  const MusicNavigationButtonRenderer({
    this.buttonText,
    this.clickCommand,
    this.solidStripeColor,
  });

  factory MusicNavigationButtonRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicNavigationButtonRenderer();
    return MusicNavigationButtonRenderer(
      buttonText: json['buttonText'] is Map<String, dynamic> ? Runs.fromJson(json['buttonText']) : null,
      clickCommand: json['clickCommand'] is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(json['clickCommand'])
          : null,
      solidStripeColor: json['solid']?['leftStripeColor'] is int
          ? json['solid']['leftStripeColor']
          : null,
    );
  }
}

class MusicDescriptionShelfRenderer {
  final Runs? description;
  final Runs? subheader;

  const MusicDescriptionShelfRenderer({
    this.description,
    this.subheader,
  });

  factory MusicDescriptionShelfRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MusicDescriptionShelfRenderer();
    return MusicDescriptionShelfRenderer(
      description: json['description'] is Map<String, dynamic> ? Runs.fromJson(json['description']) : null,
      subheader: json['subheader'] is Map<String, dynamic> ? Runs.fromJson(json['subheader']) : null,
    );
  }
}

class AutomixPreviewVideoRenderer {
  final NavigationEndpoint? navigationEndpoint;

  const AutomixPreviewVideoRenderer({this.navigationEndpoint});

  factory AutomixPreviewVideoRenderer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AutomixPreviewVideoRenderer();
    final rawEndpoint = json['content']?['automixPlaylistVideoRenderer']?['navigationEndpoint'];
    return AutomixPreviewVideoRenderer(
      navigationEndpoint: rawEndpoint is Map<String, dynamic>
          ? NavigationEndpoint.fromJson(rawEndpoint)
          : null,
    );
  }
}


library;

import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class AlbumPageData {
  final AlbumItem album;
  final List<SongItem> songs;
  final List<AlbumItem> otherVersions;

  const AlbumPageData({
    required this.album,
    required this.songs,
    this.otherVersions = const [],
  });
}

class AlbumPageParser {
  static SongItem? getSong(MusicResponsiveListItemRenderer renderer, {AlbumItem? album}) {
    final libraryTokens = PageHelper.extractLibraryTokensFromMenuItems(renderer.menu?.items);

    final subtitleRuns = renderer.flexColumns.length > 1
        ? renderer.flexColumns[1].text?.runs
        : null;

    List<Artist> artists = PageHelper.extractArtists(subtitleRuns);
    if (artists.isEmpty) {
      if (album?.playlistId.startsWith('OLAK') == true ||
          album?.browseId.startsWith('FEmusic_library_privately_owned_release_detail') == true) {
        if (subtitleRuns != null) {
          final groups = Runs.splitBySeparator(subtitleRuns);
          if (groups.isNotEmpty) {
            final oddRuns = Runs.oddElements(groups.first);
            artists = oddRuns.map((r) {
              final t = r.text.trim();
              return Artist(name: t, id: r.navigationEndpoint?.browseEndpoint?.browseId);
            }).where((a) => a.name.isNotEmpty).toList();
          }
        }
      }
    }
    if (artists.isEmpty && album?.artists != null) {
      artists = album!.artists!;
    }

    final videoId = renderer.videoId;
    if (videoId == null) return null;

    final title = renderer.flexColumns.isNotEmpty
        ? renderer.flexColumns.first.text?.runs.firstOrNull?.text
        : null;
    if (title == null) return null;

    Album? songAlbum;
    if (album != null) {
      songAlbum = Album(name: album.title, id: album.browseId);
    } else if (renderer.flexColumns.length > 2) {
      final col2Run = renderer.flexColumns[2].text?.runs.firstOrNull;
      if (col2Run != null && col2Run.navigationEndpoint?.browseEndpoint?.browseId != null) {
        songAlbum = Album(name: col2Run.text, id: col2Run.navigationEndpoint!.browseEndpoint!.browseId);
      }
    }

    final durationText = renderer.fixedColumns?.firstOrNull?.text?.runs.firstOrNull?.text;
    final duration = durationText != null ? parseTime(durationText) : null;

    final isExplicit = renderer.badges?.any(
          (b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE',
        ) ??
        false;

    final thumbUrl = renderer.thumbnail?.getThumbnailUrl() ?? album?.thumbnailUrl ?? '';

    return SongItem(
      id: videoId,
      title: title,
      artists: artists,
      album: songAlbum,
      duration: duration,
      musicVideoType: renderer.musicVideoType,
      thumbnail: thumbUrl,
      explicit: isExplicit,
      setVideoId: renderer.playlistItemData?.playlistSetVideoId,
      libraryAddToken: libraryTokens.addToken,
      libraryRemoveToken: libraryTokens.removeToken,
    );
  }

  static List<SongItem> parseTracks(dynamic data) {
    if (data is! Map<String, dynamic>) return const [];
    final items = <SongItem>[];

    void parseSection(dynamic section) {
      if (section is Map<String, dynamic>) {
        final contents = section['musicShelfRenderer']?['contents'] ??
            section['musicPlaylistShelfRenderer']?['contents'];
        if (contents is List) {
          for (final item in contents) {
            if (item is Map<String, dynamic>) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer is Map<String, dynamic>) {
                final song = getSong(MusicResponsiveListItemRenderer.fromJson(renderer));
                if (song != null) items.add(song);
              }
            }
          }
        }
      }
    }

    final sectionList = data['contents']?['singleColumnBrowseResultsRenderer']?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
    if (sectionList is List) {
      for (final s in sectionList) {
        parseSection(s);
      }
    }

    final continuationItems = data['continuationContents']?['musicPlaylistShelfContinuation']?['contents'] ??
        data['continuationContents']?['musicShelfContinuation']?['contents'];
    if (continuationItems is List) {
      for (final item in continuationItems) {
        if (item is Map<String, dynamic>) {
          final renderer = item['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final song = getSong(MusicResponsiveListItemRenderer.fromJson(renderer));
            if (song != null) items.add(song);
          }
        }
      }
    }

    return items;
  }

  static AlbumPageData parseAlbumPage(dynamic data, String browseId) {
    if (data is! Map<String, dynamic>) {
      return AlbumPageData(
        album: AlbumItem(browseId: browseId, playlistId: '', title: 'Album'),
        songs: const [],
      );
    }

    String title = 'Album';
    String? thumb;
    String? artistName;
    int? year;

    final header = data['header']?['musicDetailHeaderRenderer'] ??
        data['header']?['musicResponsiveHeaderRenderer'] ??
        data['header']?['musicEditablePlaylistDetailHeaderRenderer']?['header']?['musicDetailHeaderRenderer'];

    if (header is Map<String, dynamic>) {
      final titleRuns = header['title']?['runs'];
      if (titleRuns is List && titleRuns.isNotEmpty) {
        title = titleRuns[0]['text'] ?? 'Album';
      }

      final thumbs = header['thumbnail']?['croppedSquareThumbnailRenderer']?['thumbnail']?['thumbnails'] ??
          header['thumbnail']?['musicThumbnailRenderer']?['thumbnail']?['thumbnails'];
      if (thumbs is List && thumbs.isNotEmpty) {
        thumb = thumbs.last['url'];
      }

      final subtitleRuns = header['subtitle']?['runs'];
      if (subtitleRuns is List) {
        for (final run in subtitleRuns) {
          final text = run['text']?.toString() ?? '';
          final parsedYear = int.tryParse(text);
          if (parsedYear != null && parsedYear > 1900 && parsedYear < 2100) {
            year = parsedYear;
          } else if (text.isNotEmpty && text != '•' && text != 'Album' && text != 'EP' && text != 'Single') {
            artistName ??= text;
          }
        }
      }
    }

    final albumItem = AlbumItem(
      browseId: browseId,
      playlistId: '',
      title: title,
      thumbnail: thumb ?? '',
      year: year,
      artists: artistName != null ? [Artist(name: artistName)] : null,
    );

    final songs = parseTracks(data);

    return AlbumPageData(
      album: albumItem,
      songs: songs,
    );
  }
}

library;

import '../models/menu.dart';
import '../models/navigation_endpoint.dart';
import '../models/renderers.dart';
import '../models/runs.dart';
import '../models/yt_item.dart';

class LibraryFeedbackTokens {
  final String? addToken;
  final String? removeToken;

  const LibraryFeedbackTokens(this.addToken, this.removeToken);
}

class PageHelper {
  static const _libraryAddIcons = {'LIBRARY_ADD', 'BOOKMARK_BORDER'};
  static const _librarySavedIcons = {'LIBRARY_SAVED', 'BOOKMARK', 'LIBRARY_REMOVE'};
  static final _allLibraryIcons = {..._libraryAddIcons, ..._librarySavedIcons};

  static bool isLibraryIcon(String? iconType) {
    if (iconType == null) return false;
    if (iconType == 'KEEP' || iconType == 'KEEP_OFF') return false;
    return _allLibraryIcons.contains(iconType) || iconType.startsWith('LIBRARY_');
  }

  static bool isAddLibraryIcon(String? iconType) => _libraryAddIcons.contains(iconType);

  static bool isSavedLibraryIcon(String? iconType) => _librarySavedIcons.contains(iconType);

  static List<Run> extractRuns(List<FlexColumn> columns, String typeLike) {
    final List<Run> filteredRuns = [];
    for (final column in columns) {
      final runs = column.text?.runs;
      if (runs == null) continue;

      for (final run in runs) {
        final typeStr = run.navigationEndpoint?.watchEndpoint?.musicVideoType ??
            run.navigationEndpoint?.browseEndpoint?.pageType;
        if (typeStr != null && typeStr.contains(typeLike)) {
          filteredRuns.add(run);
        }
      }
    }
    return filteredRuns;
  }

  static LibraryFeedbackTokens extractLibraryTokensFromMenuItems(List<MenuItem>? menuItems) {
    if (menuItems == null) return const LibraryFeedbackTokens(null, null);

    String? addToken;
    String? removeToken;

    for (final item in menuItems) {
      final toggleRenderer = item.toggleMenuServiceItemRenderer;
      if (toggleRenderer == null) continue;

      final iconType = toggleRenderer.defaultIcon?.iconType;
      if (iconType == 'KEEP' || iconType == 'KEEP_OFF') continue;
      if (!isLibraryIcon(iconType)) continue;

      final defaultToken = toggleRenderer.defaultServiceEndpoint?.feedbackEndpoint?.feedbackToken;
      final toggledToken = toggleRenderer.toggledServiceEndpoint?.feedbackEndpoint?.feedbackToken;

      if (isAddLibraryIcon(iconType)) {
        addToken ??= defaultToken;
        removeToken ??= toggledToken;
      } else if (isSavedLibraryIcon(iconType)) {
        removeToken ??= defaultToken;
        addToken ??= toggledToken;
      }
    }

    return LibraryFeedbackTokens(addToken, removeToken);
  }

  static List<Artist> extractArtists(List<Run>? runs) {
    if (runs == null) return const [];
    final List<Artist> artists = [];
    for (final run in runs) {
      final endpoint = run.navigationEndpoint?.browseEndpoint;
      if (endpoint == null) continue;
      final pageType = endpoint.pageType;
      final text = run.text.trim();
      if (text.isEmpty) continue;

      final isArtistType = pageType == BrowseEndpoint.musicPageTypeArtist ||
          pageType == BrowseEndpoint.musicPageTypeLibraryArtist ||
          pageType == BrowseEndpoint.musicPageTypeUserChannel ||
          (pageType == null && endpoint.browseId.startsWith('UC'));

      if (isArtistType) {
        artists.add(Artist(name: text, id: endpoint.browseId));
      }
    }
    return artists;
  }

  static int? extractDuration(List<Run>? runs) {
    if (runs == null) return null;
    for (final run in runs) {
      final text = run.text.trim();
      if (_isDurationText(text)) {
        return parseTime(text);
      }
    }
    return null;
  }

  static bool _isDurationText(String text) =>
      RegExp(r'^\d{1,2}[:.,]\d{2}(?:[:.,]\d{2})?$').hasMatch(text);
}

int? parseTime(String? text) {
  if (text == null || text.isEmpty) return null;
  final parts = text.split(':');
  if (parts.length == 2) {
    final m = int.tryParse(parts[0]);
    final s = int.tryParse(parts[1]);
    if (m != null && s != null) return m * 60 + s;
  } else if (parts.length == 3) {
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = int.tryParse(parts[2]);
    if (h != null && m != null && s != null) return h * 3600 + m * 60 + s;
  }
  return null;
}

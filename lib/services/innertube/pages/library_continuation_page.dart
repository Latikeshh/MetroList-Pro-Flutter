import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'library_page.dart';

class LibraryContinuationPage {
  final List<YTItem> items;
  final String? continuation;

  const LibraryContinuationPage({
    required this.items,
    this.continuation,
  });
}

class LibraryContinuationPageParser {
  static LibraryContinuationPage parse(
    dynamic data, {
    bool isUploaded = false,
  }) {
    if (data is! Map) return const LibraryContinuationPage(items: []);
    final contents = data['continuationContents'];
    final grid = contents?['gridContinuation'];
    final shelf = contents?['musicShelfContinuation'];
    final items = <YTItem>[];
    dynamic continuations;

    if (grid is Map) {
      final rawItems = grid['items'];
      continuations = grid['continuations'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicTwoRowItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = LibraryPageParser.fromMusicTwoRowItemRenderer(
              MusicTwoRowItemRenderer.fromJson(renderer),
            );
            if (item != null) items.add(item);
          }
        }
      }
    } else if (shelf is Map) {
      continuations = shelf['continuations'];
      final rawItems = shelf['contents'];
      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final renderer = raw['musicResponsiveListItemRenderer'];
          if (renderer is Map<String, dynamic>) {
            final item = LibraryPageParser.fromMusicResponsiveListItemRenderer(
              MusicResponsiveListItemRenderer.fromJson(renderer),
              isUploaded: isUploaded,
            );
            if (item != null) items.add(item);
          }
        }
      }
    }

    String? token;
    if (continuations is List) {
      for (final entry in continuations) {
        final value = entry?['nextContinuationData']?['continuation']?.toString();
        if (value != null && value.isNotEmpty) {
          token = value;
          break;
        }
      }
    }
    return LibraryContinuationPage(
      items: items,
      continuation: items.isEmpty ? null : token,
    );
  }
}

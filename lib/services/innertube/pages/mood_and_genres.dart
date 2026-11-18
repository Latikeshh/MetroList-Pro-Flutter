import '../models/navigation_endpoint.dart';

class MoodAndGenresItem {
  final String title;
  final int stripeColor;
  final NavigationEndpoint endpoint;

  MoodAndGenresItem({
    required this.title,
    required this.stripeColor,
    required this.endpoint,
  });
}

class MoodAndGenres {
  final String title;
  final List<MoodAndGenresItem> items;

  MoodAndGenres({
    required this.title,
    required this.items,
  });

  static MoodAndGenres? fromSectionListRendererContent(Map<String, dynamic> content) {
    try {
      final grid = content['gridRenderer'];
      if (grid == null) return null;

      final titleRuns = grid['header']?['gridHeaderRenderer']?['title']?['runs'] as List?;
      final title = (titleRuns != null && titleRuns.isNotEmpty)
          ? titleRuns.first['text'] as String?
          : null;
      if (title == null) return null;

      final rawItems = grid['items'] as List?;
      final List<MoodAndGenresItem> items = [];
      if (rawItems != null) {
        for (final item in rawItems) {
          final btn = item['musicNavigationButtonRenderer'];
          if (btn != null) {
            final parsed = _fromMusicNavigationButtonRenderer(btn);
            if (parsed != null) items.add(parsed);
          }
        }
      }

      return MoodAndGenres(title: title, items: items);
    } catch (_) {
      return null;
    }
  }

  static MoodAndGenresItem? _fromMusicNavigationButtonRenderer(Map<String, dynamic> renderer) {
    try {
      final textRuns = renderer['buttonText']?['runs'] as List?;
      final title = (textRuns != null && textRuns.isNotEmpty)
          ? textRuns.first['text'] as String?
          : null;
      if (title == null) return null;

      final color = renderer['solid']?['leftStripeColor'] as int? ?? 0xFF000000;
      final endpointMap = renderer['clickCommand'] as Map<String, dynamic>?;
      if (endpointMap == null) return null;

      return MoodAndGenresItem(
        title: title,
        stripeColor: color,
        endpoint: NavigationEndpoint.fromJson(endpointMap),
      );
    } catch (_) {
      return null;
    }
  }
}

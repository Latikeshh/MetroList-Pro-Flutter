library;

import '../models/yt_item.dart';

class BrowseResult {
  final List<YTItem> items;
  final String? continuation;

  const BrowseResult({
    required this.items,
    this.continuation,
  });
}

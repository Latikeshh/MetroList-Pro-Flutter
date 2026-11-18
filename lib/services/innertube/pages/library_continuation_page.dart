import '../models/yt_item.dart';

class LibraryContinuationPage {
  final List<YTItem> items;
  final String? continuation;

  const LibraryContinuationPage({
    required this.items,
    this.continuation,
  });
}

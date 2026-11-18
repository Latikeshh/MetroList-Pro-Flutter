import '../models/yt_item.dart';

class LibraryContinuationPage {
  final List<YtItem> items;
  final String? continuation;

  LibraryContinuationPage({
    required this.items,
    this.continuation,
  });
}

import '../models/yt_item.dart';

class ArtistItemsContinuationPage {
  final List<YtItem> items;
  final String? continuation;

  ArtistItemsContinuationPage({
    required this.items,
    this.continuation,
  });
}

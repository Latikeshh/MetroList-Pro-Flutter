import '../models/yt_item.dart';

class ArtistItemsContinuationPage {
  final List<YTItem> items;
  final String? continuation;

  const ArtistItemsContinuationPage({
    required this.items,
    this.continuation,
  });
}

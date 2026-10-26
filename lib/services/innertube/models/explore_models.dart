library;

import 'yt_item.dart';

class MoodAndGenreItem {
  final String title;
  final int stripeColor;
  final String browseId;
  final String? params;

  const MoodAndGenreItem({
    required this.title,
    required this.stripeColor,
    required this.browseId,
    this.params,
  });
}

class ExplorePageData {
  final List<AlbumItem> newReleaseAlbums;
  final List<MoodAndGenreItem> moodsAndGenres;

  const ExplorePageData({
    required this.newReleaseAlbums,
    required this.moodsAndGenres,
  });
}

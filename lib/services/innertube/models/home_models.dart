library;

import 'yt_item.dart';

class HomeChip {
  final String title;
  final String? params;

  const HomeChip({
    required this.title,
    this.params,
  });
}

class HomeSection {
  final String title;
  final List<YTItem> items;

  const HomeSection({
    required this.title,
    required this.items,
  });
}

class HomePageData {
  final List<HomeChip> chips;
  final List<HomeSection> sections;
  final String? continuation;

  const HomePageData({
    this.chips = const [],
    this.sections = const [],
    this.continuation,
  });
}

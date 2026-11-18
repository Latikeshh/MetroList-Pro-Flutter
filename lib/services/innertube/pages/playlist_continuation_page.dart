import '../models/yt_item.dart';

class PlaylistContinuationPage {
  final List<PlaylistItem> songs;
  final String? continuation;

  PlaylistContinuationPage({
    required this.songs,
    this.continuation,
  });
}

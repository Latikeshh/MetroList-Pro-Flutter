import '../models/yt_item.dart';

class PlaylistContinuationPage {
  final List<SongItem> songs;
  final String? continuation;

  const PlaylistContinuationPage({
    required this.songs,
    this.continuation,
  });
}

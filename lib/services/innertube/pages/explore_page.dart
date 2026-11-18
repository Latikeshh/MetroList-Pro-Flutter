library;

import '../models/explore_models.dart';
import '../models/renderers.dart';
import '../models/yt_item.dart';
import 'page_helper.dart';

class ExplorePageParser {
  static ExplorePageData parse(dynamic data) {
    final List<AlbumItem> newReleaseAlbums = [];
    final List<MoodAndGenreItem> moodsAndGenres = [];

    if (data is Map<String, dynamic>) {
      try {
        final contents = data['contents']?['singleColumnBrowseResultsRenderer']
                ?['tabs']?[0]?['tabRenderer']?['content']?['sectionListRenderer']
            ?['contents'];

        if (contents is List) {
          for (final section in contents) {
            if (section is! Map<String, dynamic>) continue;
            final carousel = section['musicCarouselShelfRenderer'];
            if (carousel is! Map<String, dynamic>) continue;

            final browseId = carousel['header']
                ?['musicCarouselShelfBasicHeaderRenderer']
                ?['moreContentButton']
                ?['buttonRenderer']
                ?['navigationEndpoint']
                ?['browseEndpoint']
                ?['browseId']
                ?.toString();

            final carouselContents = carousel['contents'];
            if (carouselContents is! List) continue;

            if (browseId == 'FEmusic_new_releases_albums') {
              for (final item in carouselContents) {
                if (item is Map<String, dynamic> && item['musicTwoRowItemRenderer'] != null) {
                  final twoRow = MusicTwoRowItemRenderer.fromJson(item['musicTwoRowItemRenderer']);
                  final album = _parseNewReleaseAlbum(twoRow);
                  if (album != null) newReleaseAlbums.add(album);
                }
              }
            } else if (browseId == 'FEmusic_moods_and_genres') {
              for (final item in carouselContents) {
                if (item is Map<String, dynamic> && item['musicNavigationButtonRenderer'] != null) {
                  final navBtn = item['musicNavigationButtonRenderer'];
                  final mood = _parseMoodAndGenreItem(navBtn);
                  if (mood != null) moodsAndGenres.add(mood);
                }
              }
            }
          }
        }
      } catch (_) {}
    }

    return ExplorePageData(
      newReleaseAlbums: newReleaseAlbums,
      moodsAndGenres: moodsAndGenres.isNotEmpty
          ? moodsAndGenres
          : const [
              MoodAndGenreItem(
                  title: 'Chill',
                  stripeColor: 0xFF4E65FF,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Commute',
                  stripeColor: 0xFFFF5722,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Energy Boost',
                  stripeColor: 0xFFFFC107,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Focus',
                  stripeColor: 0xFF00BCD4,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Party',
                  stripeColor: 0xFFE91E63,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Romance',
                  stripeColor: 0xFF9C27B0,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Sleep',
                  stripeColor: 0xFF3F51B5,
                  browseId: 'FEmusic_moods_and_genres_category'),
              MoodAndGenreItem(
                  title: 'Workout',
                  stripeColor: 0xFF4CAF50,
                  browseId: 'FEmusic_moods_and_genres_category'),
            ],
    );
  }

  static AlbumItem? _parseNewReleaseAlbum(MusicTwoRowItemRenderer renderer) {
    final browseId = renderer.navigationEndpoint?.browseEndpoint?.browseId;
    final title = renderer.title.runs.firstOrNull?.text;
    final thumb = renderer.thumbnailRenderer?.getThumbnailUrl();
    if (browseId == null || title == null || thumb == null) return null;

    final playlistId = renderer.thumbnailOverlay?.playNavigationEndpoint?.anyWatchEndpoint?.playlistId ?? '';
    final yearText = renderer.subtitle?.runs.lastOrNull?.text;

    return AlbumItem(
      browseId: browseId,
      playlistId: playlistId,
      title: title,
      artists: PageHelper.extractArtists(renderer.subtitle?.runs),
      year: yearText != null ? int.tryParse(yearText) : null,
      thumbnail: thumb,
      explicit: renderer.subtitleBadges?.any((b) => b.icon?.iconType == 'MUSIC_EXPLICIT_BADGE') ?? false,
    );
  }

  static MoodAndGenreItem? _parseMoodAndGenreItem(Map<String, dynamic> renderer) {
    final title = renderer['buttonText']?['runs']?[0]?['text']?.toString();
    final color = renderer['solid']?['leftStripeColor'];
    final browseId = renderer['clickCommand']?['browseEndpoint']?['browseId']?.toString();
    if (title == null || browseId == null) return null;

    return MoodAndGenreItem(
      title: title,
      stripeColor: color is int ? color : 0xFF6750A4,
      browseId: browseId,
    );
  }
}

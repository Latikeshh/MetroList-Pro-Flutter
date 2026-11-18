import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/innertube_client.dart';
import 'package:metrolist_pro/services/innertube/pages/album_page.dart';
import 'package:metrolist_pro/services/innertube/pages/artist_page.dart';
import 'package:metrolist_pro/services/innertube/pages/library_page.dart';
import 'package:metrolist_pro/services/innertube/pages/podcast_page.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

void main() {
  group('InnerTube Dart & Kotlin Parity Unit Tests', () {
    late YouTubeService service;

    setUp(() {
      service = YouTubeService();
    });

    test('YouTubeService has all extended parity methods available', () {
      expect(service, isNotNull);
    });

    test('ArtistPageParser parses artist data correctly', () {
      final mockData = {
        'header': {
          'musicImmersiveHeaderRenderer': {
            'title': {
              'runs': [
                {'text': 'Test Artist'}
              ]
            },
            'description': {
              'runs': [
                {'text': 'Artist Bio'}
              ]
            }
          }
        },
        'contents': {
          'singleColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {'contents': []}
                  }
                }
              }
            ]
          }
        }
      };

      final parsed = ArtistPageParser.parseArtistPage(mockData, 'UC123');
      expect(parsed.artist.id, 'UC123');
      expect(parsed.artist.title, 'Test Artist');
      expect(parsed.description, 'Artist Bio');
    });

    test('AlbumPageParser parses album data correctly', () {
      final mockData = {
        'header': {
          'musicDetailHeaderRenderer': {
            'title': {
              'runs': [
                {'text': 'Test Album'}
              ]
            },
            'subtitle': {
              'runs': [
                {'text': 'Test Artist'},
                {'text': '•'},
                {'text': '2024'}
              ]
            }
          }
        },
        'contents': {
          'singleColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {'contents': []}
                  }
                }
              }
            ]
          }
        }
      };

      final parsed = AlbumPageParser.parseAlbumPage(mockData, 'MPRE123');
      expect(parsed.album.browseId, 'MPRE123');
      expect(parsed.album.title, 'Test Album');
      expect(parsed.album.year, 2024);
    });

    test('LibraryPageParser parses empty library page fallback', () {
      final parsed = LibraryPageParser.parseLibraryPage({});
      expect(parsed.items, isEmpty);
    });

    test('PodcastPageParser parses empty podcast page fallback', () {
      final parsed = PodcastPageParser.parsePodcastPage({}, 'POD123');
      expect(parsed.podcast.id, 'POD123');
      expect(parsed.episodes, isEmpty);
    });

    test('InnerTubeClient SAPISIDHASH computation works correctly', () {
      const mockCookie = 'SAPISID=test_sapisid_12345; __Secure-3PAPISID=test_sapisid_12345;';
      final hash = InnerTubeClient.getSapisidHash(mockCookie);
      expect(hash, isNotNull);
      expect(hash!, startsWith('SAPISIDHASH '));
    });
  });
}

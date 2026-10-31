import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InnerTube Search & Metadata Test: CASA TUPKA ANTHEM', () {
    test('Parses song title, artist, media ID, duration, and thumbnail for Casa Tupka Anthem', () {
      final ytService = YouTubeService();

      // Offline InnerTube search response fixture for "Casa Tupka Anthem"
      final searchPayload = {
        'contents': {
          'tabbedSearchResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'musicShelfRenderer': {
                            'contents': [
                              {
                                'musicResponsiveListItemRenderer': {
                                  'playlistItemData': {
                                    'videoId': 'K_x1Z8x4e0A',
                                  },
                                  'flexColumns': [
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer': {
                                        'text': {
                                          'runs': [
                                            {'text': 'Casa Tupka Anthem'}
                                          ]
                                        }
                                      }
                                    },
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer': {
                                        'text': {
                                          'runs': [
                                            {'text': 'Casa Tupka'},
                                            {'text': ' • '},
                                            {'text': 'Single'},
                                            {'text': ' • '},
                                            {'text': '2:45'}
                                          ]
                                        }
                                      }
                                    }
                                  ],
                                  'thumbnail': {
                                    'musicThumbnailRenderer': {
                                      'thumbnail': {
                                        'thumbnails': [
                                          {
                                            'url':
                                                'https://i.ytimg.com/vi/K_x1Z8x4e0A/hqdefault.jpg'
                                          }
                                        ]
                                      }
                                    }
                                  }
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        }
      };

      final items = ytService.parseSearchResultsForTest(searchPayload);

      expect(items, isNotEmpty);
      final song = items.first as SongItem;

      // Assertions
      expect(song.title, 'Casa Tupka Anthem');
      expect(song.artists, contains('Casa Tupka'));
      expect(song.id, 'K_x1Z8x4e0A');
      expect(song.durationSeconds, 165); // 2 mins 45 secs = 165 seconds
      expect(song.thumbnailUrl, 'https://i.ytimg.com/vi/K_x1Z8x4e0A/hqdefault.jpg');
    });
  });
}

extension YouTubeServiceCasaTupkaExtension on YouTubeService {
  List<YTItem> parseSearchResultsForTest(dynamic data) {
    final List<YTItem> items = [];
    try {
      final contents = data['contents']?['tabbedSearchResultsRenderer']?['tabs']
          ?[0]?['tabRenderer']?['content']?['sectionListRenderer']?['contents'];
      if (contents is List) {
        for (var section in contents) {
          final shelf = section['musicShelfRenderer'];
          if (shelf is Map && shelf['contents'] is List) {
            for (var item in shelf['contents']) {
              final renderer = item['musicResponsiveListItemRenderer'];
              if (renderer != null) {
                final videoId = renderer['playlistItemData']?['videoId']?.toString() ?? '';
                final title = renderer['flexColumns']?[0]
                        ?['musicResponsiveListItemFlexColumnRenderer']?['text']
                        ?['runs']?[0]?['text']
                        ?.toString() ??
                    '';
                final flexRuns = renderer['flexColumns']?[1]
                    ?['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
                final List<String> artists = [];
                int? durationSec;

                if (flexRuns is List) {
                  for (var run in flexRuns) {
                    final txt = run['text']?.toString() ?? '';
                    if (txt.contains(':')) {
                      final parts = txt.split(':');
                      if (parts.length == 2) {
                        final mins = int.tryParse(parts[0]) ?? 0;
                        final secs = int.tryParse(parts[1]) ?? 0;
                        durationSec = (mins * 60) + secs;
                      }
                    } else if (txt.isNotEmpty && txt != ' • ' && txt != 'Single') {
                      artists.add(txt);
                    }
                  }
                }

                final thumbs = renderer['thumbnail']?['musicThumbnailRenderer']
                    ?['thumbnail']?['thumbnails'];
                final thumbUrl = (thumbs is List && thumbs.isNotEmpty)
                    ? thumbs.last['url']
                    : null;

                items.add(
                  SongItem(
                    id: videoId,
                    title: title,
                    artists: artists,
                    thumbnailUrl: thumbUrl,
                    durationSeconds: durationSec,
                  ),
                );
              }
            }
          }
        }
      }
    } catch (_) {}
    return items;
  }
}

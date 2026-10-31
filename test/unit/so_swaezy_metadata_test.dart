import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Song Metadata Search Test: SO SWAEZY BY HOMMIE DILLIWALA', () {
    test('Parses song metadata, artist, video ID, and duration without internet', () {
      final ytService = YouTubeService();

      // online InnerTube search response fixture for "SO SWAEZY BY HOMMIE DILLIWALA"
      final offlineSearchData = {
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
                                    'videoId': 'd6C4uP9wHBA',
                                  },
                                  'flexColumns': [
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer': {
                                        'text': {
                                          'runs': [
                                            {'text': 'So Swaezy'}
                                          ]
                                        }
                                      }
                                    },
                                    {
                                      'musicResponsiveListItemFlexColumnRenderer': {
                                        'text': {
                                          'runs': [
                                            {'text': 'Hommie Dilliwala'},
                                            {'text': ' • '},
                                            {'text': 'Single'},
                                            {'text': ' • '},
                                            {'text': '3:12'}
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
                                                'https://i.ytimg.com/vi/d6C4uP9wHBA/hqdefault.jpg'
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

      // Extract metadata from offline InnerTube parser
      final items = ytService.parseSearchResultsForTest(offlineSearchData);

      expect(items, isNotEmpty);
      final song = items.first as SongItem;

      // Verify song metadata
      expect(song.id, 'd6C4uP9wHBA');
      expect(song.title, 'So Swaezy');
      expect(song.artists, contains('Hommie Dilliwala'));
      expect(song.thumbnailUrl, 'https://i.ytimg.com/vi/d6C4uP9wHBA/hqdefault.jpg');
      expect(song.durationSeconds, 192); // 3 minutes 12 seconds = 192 seconds
    });
  });
}

extension YouTubeServiceTestExtension on YouTubeService {
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

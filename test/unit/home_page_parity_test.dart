import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/models/home_models.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

void main() {
  group('Home Page Data Models & Structure Tests', () {
    test('HomePageData holds chips, sections, and continuation correctly', () {
      const pageData = HomePageData(
        chips: [
          HomeChip(title: 'All', params: null),
          HomeChip(title: 'Podcasts', params: 'g_podcast'),
        ],
        sections: [
          HomeSection(
            title: 'Quick Picks',
            items: [
              SongItem(id: 'song_1', title: 'Song 1', artists: ['Artist 1']),
              AlbumItem(id: 'album_1', title: 'Album 1', artist: 'Artist 1'),
            ],
          ),
        ],
        continuation: 'continuation_token_123',
      );

      expect(pageData.chips.length, 2);
      expect(pageData.chips.first.title, 'All');
      expect(pageData.chips.last.params, 'g_podcast');

      expect(pageData.sections.length, 1);
      expect(pageData.sections.first.title, 'Quick Picks');
      expect(pageData.sections.first.items.length, 2);

      expect(pageData.continuation, 'continuation_token_123');
    });
  });

  group('Deterministic Home Feed JSON Parser Tests', () {
    late YouTubeService service;

    setUp(() {
      service = YouTubeService();
    });

    test('Parses musicCarouselShelfBasicHeaderRenderer section titles and two-row items', () {
      final jsonFixture = {
        'contents': {
          'singleColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'header': {
                        'chipCloudRenderer': {
                          'chips': [
                            {
                              'chipCloudChipRenderer': {
                                'text': {'runs': [{'text': 'Podcasts'}]},
                                'navigationEndpoint': {
                                  'browseEndpoint': {'params': 'g_podcast'}
                                }
                              }
                            }
                          ]
                        }
                      },
                      'contents': [
                        {
                          'musicCarouselShelfRenderer': {
                            'header': {
                              'musicCarouselShelfBasicHeaderRenderer': {
                                'title': {
                                  'runs': [{'text': 'Forgotten Favorites'}]
                                }
                              }
                            },
                            'contents': [
                              {
                                'musicTwoRowItemRenderer': {
                                  'title': {
                                    'runs': [{'text': 'Blinding Lights'}]
                                  },
                                  'subtitle': {
                                    'runs': [{'text': 'The Weeknd'}]
                                  },
                                  'navigationEndpoint': {
                                    'watchEndpoint': {'videoId': '4NRXx6U8ABQ'}
                                  },
                                  'thumbnailRenderer': {
                                    'musicThumbnailRenderer': {
                                      'thumbnail': {
                                        'thumbnails': [
                                          {'url': 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg'}
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

      final parsed = service.parseHomePageData(jsonFixture);

      expect(parsed.chips.length, 1);
      expect(parsed.chips.first.title, 'Podcasts');
      expect(parsed.chips.first.params, 'g_podcast');

      expect(parsed.sections.length, 1);
      expect(parsed.sections.first.title, 'Forgotten Favorites');
      expect(parsed.sections.first.items.length, 1);

      final item = parsed.sections.first.items.first;
      expect(item, isA<SongItem>());
      expect((item as SongItem).id, '4NRXx6U8ABQ');
      expect(item.title, 'Blinding Lights');
      expect(item.artists.first, 'The Weeknd');
    });

    test('Parses musicMultiRowListItemRenderer podcast and episode items', () {
      final jsonFixture = {
        'contents': {
          'singleColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [
                        {
                          'musicCarouselShelfRenderer': {
                            'header': {
                              'musicCarouselShelfBasicHeaderRenderer': {
                                'title': {
                                  'runs': [{'text': 'Episodes for you'}]
                                }
                              }
                            },
                            'contents': [
                              {
                                'musicMultiRowListItemRenderer': {
                                  'title': {
                                    'runs': [{'text': 'Tech News Episode 101'}]
                                  },
                                  'onTap': {
                                    'watchEndpoint': {'videoId': 'pod_ep_999'}
                                  },
                                  'thumbnail': {
                                    'musicThumbnailRenderer': {
                                      'thumbnail': {
                                        'thumbnails': [
                                          {'url': 'https://i.ytimg.com/vi/pod_ep_999/hqdefault.jpg'}
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

      final parsed = service.parseHomePageData(jsonFixture);

      expect(parsed.sections.length, 1);
      expect(parsed.sections.first.title, 'Episodes for you');
      expect(parsed.sections.first.items.length, 1);

      final item = parsed.sections.first.items.first;
      expect(item, isA<SongItem>());
      expect((item as SongItem).id, 'pod_ep_999');
      expect(item.title, 'Tech News Episode 101');
      expect(item.artists.first, 'Podcast Episode');
    });

    test('Extracts sectionList continuation tokens correctly', () {
      final jsonFixture = {
        'contents': {
          'singleColumnBrowseResultsRenderer': {
            'tabs': [
              {
                'tabRenderer': {
                  'content': {
                    'sectionListRenderer': {
                      'contents': [],
                      'continuations': [
                        {
                          'nextContinuationData': {
                            'continuation': 'continuation_token_abc_xyz_789'
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

      final parsed = service.parseHomePageData(jsonFixture);

      expect(parsed.continuation, 'continuation_token_abc_xyz_789');
    });

    test('Parses continuation response payload (sectionListContinuation)', () {
      final jsonFixture = {
        'continuationContents': {
          'sectionListContinuation': {
            'contents': [
              {
                'musicCarouselShelfRenderer': {
                  'header': {
                    'musicCarouselShelfBasicHeaderRenderer': {
                      'title': {
                        'runs': [{'text': 'More Recommendations'}]
                      }
                    }
                  },
                  'contents': [
                    {
                      'musicTwoRowItemRenderer': {
                        'title': {
                          'runs': [{'text': 'Continuation Song'}]
                        },
                        'navigationEndpoint': {
                          'watchEndpoint': {'videoId': 'cont_123'}
                        }
                      }
                    }
                  ]
                }
              }
            ],
            'continuations': [
              {
                'nextContinuationData': {
                  'continuation': 'next_page_token_456'
                }
              }
            ]
          }
        }
      };

      final parsed = service.parseHomePageData(jsonFixture);

      expect(parsed.sections.length, 1);
      expect(parsed.sections.first.title, 'More Recommendations');
      expect((parsed.sections.first.items.first as SongItem).id, 'cont_123');
      expect(parsed.continuation, 'next_page_token_456');
    });

    test('Handles empty, malformed, or null JSON gracefully without throwing', () {
      final nullParsed = service.parseHomePageData(null);
      expect(nullParsed.chips, isEmpty);
      expect(nullParsed.sections, isEmpty);
      expect(nullParsed.continuation, isNull);

      final emptyParsed = service.parseHomePageData({});
      expect(emptyParsed.chips, isEmpty);
      expect(emptyParsed.sections, isEmpty);
      expect(emptyParsed.continuation, isNull);

      final malformedParsed = service.parseHomePageData({
        'contents': {'unexpectedKey': 12345}
      });
      expect(malformedParsed.chips, isEmpty);
      expect(malformedParsed.sections, isEmpty);
      expect(malformedParsed.continuation, isNull);
    });
  });

  group('Home Page Pagination & Deduplication Tests', () {
    test('mergeHomePages appends new unique sections and updates token', () {
      const current = HomePageData(
        chips: [HomeChip(title: 'All')],
        sections: [
          HomeSection(title: 'Quick Picks', items: [SongItem(id: 's1', title: 'S1', artists: [])])
        ],
        continuation: 'token_1',
      );

      const next = HomePageData(
        chips: [],
        sections: [
          HomeSection(title: 'Recommended', items: [SongItem(id: 's2', title: 'S2', artists: [])])
        ],
        continuation: 'token_2',
      );

      final merged = YouTubeService.mergeHomePages(current, next);

      expect(merged.sections.length, 2);
      expect(merged.sections[0].title, 'Quick Picks');
      expect(merged.sections[1].title, 'Recommended');
      expect(merged.continuation, 'token_2');
      expect(merged.chips.length, 1);
    });

    test('mergeHomePages filters out exact duplicate sections with matching title and items', () {
      const current = HomePageData(
        chips: [],
        sections: [
          HomeSection(title: 'Quick Picks', items: [SongItem(id: 's1', title: 'S1', artists: [])])
        ],
        continuation: 'token_1',
      );

      const next = HomePageData(
        chips: [],
        sections: [
          HomeSection(title: 'Quick Picks', items: [SongItem(id: 's1', title: 'S1', artists: [])]),
          HomeSection(title: 'Forgotten Favorites', items: [SongItem(id: 's3', title: 'S3', artists: [])])
        ],
        continuation: 'token_2',
      );

      final merged = YouTubeService.mergeHomePages(current, next);

      expect(merged.sections.length, 2);
      expect(merged.sections[0].title, 'Quick Picks');
      expect(merged.sections[1].title, 'Forgotten Favorites');
    });

    test('mergeHomePages preserves sections with same title if items are different', () {
      const current = HomePageData(
        chips: [],
        sections: [
          HomeSection(title: 'Recommended', items: [SongItem(id: 's1', title: 'S1', artists: [])])
        ],
        continuation: 'token_1',
      );

      const next = HomePageData(
        chips: [],
        sections: [
          HomeSection(title: 'Recommended', items: [SongItem(id: 's99', title: 'S99', artists: [])]),
        ],
        continuation: 'token_2',
      );

      final merged = YouTubeService.mergeHomePages(current, next);

      expect(merged.sections.length, 2);
      expect(merged.sections[0].items.first.id, 's1');
      expect(merged.sections[1].items.first.id, 's99');
    });

    test('mergeHomePages sets continuation to null if next token is identical or null', () {
      const current = HomePageData(
        chips: [],
        sections: [HomeSection(title: 'S1', items: [])],
        continuation: 'token_same',
      );

      const next = HomePageData(
        chips: [],
        sections: [HomeSection(title: 'S2', items: [])],
        continuation: 'token_same',
      );

      final merged = YouTubeService.mergeHomePages(current, next);

      expect(merged.sections.length, 2);
      expect(merged.continuation, isNull);
    });
  });
}

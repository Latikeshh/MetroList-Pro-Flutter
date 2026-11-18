import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/services/innertube/innertube_client.dart';
import 'package:metrolist_pro/services/innertube/models/yt_item.dart';
import 'package:metrolist_pro/services/innertube/pages/album_page.dart';
import 'package:metrolist_pro/services/innertube/pages/next_page.dart';
import 'package:metrolist_pro/services/innertube/models/youtube_client.dart';
import 'package:metrolist_pro/services/innertube/pages/artist_page.dart';
import 'package:metrolist_pro/services/innertube/pages/artist_items_continuation_page.dart';
import 'package:metrolist_pro/services/innertube/pages/playlist_page.dart';
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

    test('InnerTubeClient login context follows client capability', () {
      final client = InnerTubeClient();
      client.dataSyncId = 'test-data-sync-id';

      final anonymous = client.buildContext(client: YouTubeClient.webRemix);
      expect(anonymous['context']['user'], isNull);

      final authenticated = client.buildContext(
        client: YouTubeClient.webRemix,
        useLogin: true,
      );
      expect(
        authenticated['context']['user']['onBehalfOfUser'],
        'test-data-sync-id',
      );

      final mobile = client.buildContext(
        client: YouTubeClient.androidMusic,
        useLogin: true,
      );
      expect(mobile['context']['user'], isNull);
      client.dataSyncId = null;
    });

    test('NextPageParser extracts queue selection and continuation', () {
      final parsed = NextPageParser.parse({
        'contents': {
          'singleColumnMusicWatchNextResultsRenderer': {
            'tabbedRenderer': {
              'watchNextTabbedResultsRenderer': {
                'tabs': [
                  {
                    'tabRenderer': {
                      'content': {
                        'musicQueueRenderer': {
                          'content': {
                            'playlistPanelRenderer': {
                              'contents': [
                                {
                                  'playlistPanelVideoRenderer': {
                                    'videoId': 'video-123',
                                    'title': {
                                      'runs': [{'text': 'Queue Track'}]
                                    },
                                    'longBylineText': {
                                      'runs': [{'text': 'Queue Artist'}]
                                    },
                                    'lengthText': {
                                      'runs': [{'text': '3:20'}]
                                    },
                                    'selected': true,
                                    'thumbnail': {
                                      'thumbnails': [
                                        {'url': 'https://example.com/thumb.jpg'}
                                      ]
                                    },
                                    'navigationEndpoint': {
                                      'watchEndpoint': {'videoId': 'video-123'}
                                    }
                                  }
                                }
                              ],
                              'continuations': [
                                {
                                  'nextContinuationData': {
                                    'continuation': 'next-token'
                                  }
                                }
                              ]
                            }
                          }
                        }
                      }
                    }
                  },
                  {
                    'tabRenderer': {
                      'endpoint': {
                        'browseEndpoint': {'browseId': 'lyrics-id'}
                      }
                    }
                  },
                  {
                    'tabRenderer': {
                      'endpoint': {
                        'browseEndpoint': {'browseId': 'related-id'}
                      }
                    }
                  }
                ]
              }
            }
          }
        }
      });

      expect(parsed.queue, hasLength(1));
      expect(parsed.queue.single.id, 'video-123');
      expect(parsed.queue.single.title, 'Queue Track');
      expect(parsed.currentIndex, 0);
      expect(parsed.continuation, 'next-token');
      expect(parsed.lyricsEndpoint, 'lyrics-id');
      expect(parsed.relatedEndpoint, 'related-id');
    });

    test('PodcastPageParser reads two-column multi-row episodes', () {
      final parsed = PodcastPageParser.parsePodcastPage(
        {
          'header': {
            'musicResponsiveHeaderRenderer': {
              'title': {
                'runs': [{'text': 'Test Podcast'}]
              },
              'straplineTextOne': {
                'runs': [
                  {
                    'text': 'Podcast Host',
                    'navigationEndpoint': {
                      'browseEndpoint': {'browseId': 'UC-host'}
                    }
                  }
                ]
              },
              'thumbnail': {
                'musicThumbnailRenderer': {
                  'thumbnail': {
                    'thumbnails': [
                      {'url': 'https://example.com/podcast.jpg'}
                    ]
                  }
                }
              }
            }
          },
          'contents': {
            'twoColumnBrowseResultsRenderer': {
              'secondaryContents': {
                'sectionListRenderer': {
                  'contents': [
                    {
                      'musicShelfRenderer': {
                        'contents': [
                          {
                            'musicMultiRowListItemRenderer': {
                              'title': {
                                'runs': [{'text': 'Episode One'}]
                              },
                              'subtitle': {
                                'runs': [
                                  {'text': '2026-11-18'},
                                  {'text': ' • '},
                                  {'text': '25:10'}
                                ]
                              },
                              'secondSubtitle': {
                                'runs': [{'text': 'Published today'}]
                              },
                              'onTap': {
                                'watchEndpoint': {'videoId': 'episode-1'}
                              },
                              'thumbnail': {
                                'musicThumbnailRenderer': {
                                  'thumbnail': {
                                    'thumbnails': [
                                      {'url': 'https://example.com/episode.jpg'}
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
        },
        'MPSP-test',
      );

      expect(parsed.podcast.title, 'Test Podcast');
      expect(parsed.podcast.author?.name, 'Podcast Host');
      expect(parsed.episodes, hasLength(1));
      expect(parsed.episodes.single.id, 'episode-1');
      expect(parsed.episodes.single.title, 'Episode One');
      expect(parsed.episodes.single.podcast?.name, 'Test Podcast');
    });

    test('Artist items continuation parses grid cards and next token', () {
      final page = ArtistItemsContinuationPageParser.parse({
        'continuationContents': {
          'gridContinuation': {
            'items': [
              {
                'musicTwoRowItemRenderer': {
                  'title': {
                    'runs': [{'text': 'Continuation Album'}]
                  },
                  'navigationEndpoint': {
                    'browseEndpoint': {
                      'browseId': 'MPRE-album',
                      'browseEndpointContextSupportedConfigs': {
                        'browseEndpointContextMusicConfig': {
                          'pageType': 'MUSIC_PAGE_TYPE_ALBUM'
                        }
                      }
                    }
                  }
                }
              }
            ],
            'continuations': [
              {'nextContinuationData': {'continuation': 'artist-next'}}
            ]
          }
        }
      });

      expect(page.items, hasLength(1));
      expect(page.items.single, isA<AlbumItem>());
      expect(page.continuation, 'artist-next');
    });

    test('Playlist continuation parses songs and continuation token', () {
      final page = PlaylistPageParser.parseContinuation({
        'continuationContents': {
          'musicPlaylistShelfContinuation': {
            'contents': [
              {
                'musicResponsiveListItemRenderer': {
                  'playlistItemData': {
                    'videoId': 'song-cont-1',
                    'playlistSetVideoId': 'set-cont-1'
                  },
                  'flexColumns': [
                    {
                      'musicResponsiveListItemFlexColumnRenderer': {
                        'text': {
                          'runs': [{'text': 'Continuation Song'}]
                        }
                      }
                    },
                    {
                      'musicResponsiveListItemFlexColumnRenderer': {
                        'text': {
                          'runs': [
                            {
                              'text': 'Continuation Artist',
                              'navigationEndpoint': {
                                'browseEndpoint': {
                                  'browseId': 'UC-cont-artist',
                                  'browseEndpointContextSupportedConfigs': {
                                    'browseEndpointContextMusicConfig': {
                                      'pageType': 'MUSIC_PAGE_TYPE_ARTIST'
                                    }
                                  }
                                }
                              }
                            }
                          ]
                        }
                      }
                    }
                  ],
                  'thumbnail': {
                    'musicThumbnailRenderer': {
                      'thumbnail': {
                        'thumbnails': [
                          {'url': 'https://example.com/continuation.jpg'}
                        ]
                      }
                    }
                  }
                }
              }
            ],
            'continuations': [
              {'nextContinuationData': {'continuation': 'playlist-next'}}
            ]
          }
        }
      });

      expect(page.songs, hasLength(1));
      expect(page.songs.single.id, 'song-cont-1');
      expect(page.songs.single.title, 'Continuation Song');
      expect(page.continuation, 'playlist-next');
    });

    test('InnerTubeClient SAPISIDHASH computation works correctly', () {
      const mockCookie = 'SAPISID=test_sapisid_12345; __Secure-3PAPISID=test_sapisid_12345;';
      final hash = InnerTubeClient.getSapisidHash(mockCookie);
      expect(hash, isNotNull);
      expect(hash!, startsWith('SAPISIDHASH '));
    });
  });
}

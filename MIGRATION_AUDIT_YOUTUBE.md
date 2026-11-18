# YouTube.kt → Dart migration audit

## Source snapshot
- Kotlin source: `innertube/src/main/kotlin/com/metrolist/innertube/YouTube.kt`
- Kotlin blob: `3ec82c5ee36812b1d328e17f2185dd2b186dcd55`
- Kotlin source size: 152,016 characters / 3,402 lines
- Existing Dart target: `lib/services/innertube/youtube_service.dart`
- Dart blob: `e59ac01bd9a67f10cb5d995b4d9a500c0d9fcee3`
- Existing Dart size: 26,199 characters / 762 lines

## Declaration coverage check
A name-based declaration scan found:
- Kotlin function declarations: 72 unique names
- Dart method declarations detected: 39
- Kotlin names not detected in the Dart file: 55

The missing names are:
- `extractionTransport`
- `searchSuggestions`
- `searchSummary`
- `groupItemsByType`
- `search`
- `searchContinuation`
- `album`
- `albumSongs`
- `artist`
- `mapRuns`
- `artistItems`
- `artistItemsContinuation`
- `playlist`
- `playlistContinuation`
- `podcast`
- `podcastWithDebug`
- `home`
- `homeContinuation`
- `explore`
- `newReleaseAlbums`
- `moodAndGenres`
- `browse`
- `library`
- `libraryContinuation`
- `determineChartType`
- `convertToChartItem`
- `convertMusicTwoRowItem`
- `musicHistory`
- `libraryPodcastChannels`
- `libraryPodcastEpisodes`
- `savedPodcastShows`
- `newEpisodes`
- `processShelf`
- `newEpisodesPlaylistInfo`
- `episodesForLater`
- `getChannelId`
- `moveSongPlaylist`
- `uploadCustomThumbnailLink`
- `removeThumbnailPlaylist`
- `player`
- `next`
- `related`
- `queue`
- `transcript`
- `visitorData`
- `accountInfo`
- `accountsList`
- `feedback`
- `toggleSongLibrary`
- `getMediaInfo`
- `uploadSong`
- `deleteUploadedSong`
- `resolveArtistIds`
- `resolveArtistIdMap`
- `reportBytesRead`

This is a regex/name-based comparison, not proof of semantic absence: names may differ between Kotlin and Dart, and some methods may be implemented under another name. Conversely, matching names do not prove equivalent behavior.

## Major dependency groups in Kotlin
The source imports types and helpers from:
- `com.metrolist.innertube.models.*`
- `com.metrolist.innertube.models.response.*`
- `com.metrolist.innertube.pages.*`
- `com.metrolist.innertube.utils.parseTime`
- `com.metrolist.innertubex.models.YouTubeClient`
- Ktor HTTP client/response APIs
- Kotlin coroutines
- Kotlin serialization
- Timber logging
- Java InputStream / FilterInputStream / Proxy
- Kotlin Random

The existing Dart service imports Dio, `innertube_client.dart`, selected models, response types and page parsers. The Kotlin dependency surface is broader than the imports visible in the existing Dart service.

## Migration acceptance criteria
1. Port each public operation and preserve behavior, parameters, defaults, return semantics and errors.
2. Port all referenced model, response, page and utility types or map them to existing Dart equivalents.
3. Replace Ktor/coroutines/Java stream/proxy behavior with tested Dart equivalents.
4. Preserve authentication, visitor data, cookies, locale, continuation tokens, upload and playback behavior.
5. Run `dart format`, `flutter analyze`, unit tests and targeted integration tests.
6. Verify search, suggestions, albums, artists, playlists, podcasts, library, history, playback, queue, lyrics/transcript, account and upload paths.

## Current verified status
- Repository and source files inspected.
- Migration branch exists: `kotlin-to-dart-migration`.
- No full semantic conversion or build verification has been completed.
- Do not treat this audit as a completed migration.

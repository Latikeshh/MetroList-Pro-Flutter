# YouTube.kt → Dart migration audit

- Source: `innertube/src/main/kotlin/com/metrolist/innertube/YouTube.kt`
- Source revision: 3ec82c5ee36812b1d328e17f2185dd2b186dcd55
- Existing Dart target: `lib/services/innertube/youtube_service.dart`
- Target revision before migration: e59ac01bd9a67f10cb5d995b4d9a500c0d9fcee3
- Kotlin source size: 152,016 characters / 3402 lines
- Existing Dart service size: 26,199 characters / 762 lines
- Kotlin function declarations found (unique names): 66
- Existing Dart method declarations detected: 152
- Kotlin function names not detected in current Dart service: 48

## Missing method names (initial regex-based audit)

- `extractionTransport`
- `searchSuggestions`
- `searchSummary`
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
- `explore`
- `newReleaseAlbums`
- `moodAndGenres`
- `browse`
- `library`
- `libraryContinuation`
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

## Important conversion constraints

This is not a complete semantic comparison. A method can exist in Dart and still have different behavior. The Kotlin service imports many types from separate `models`, `response`, `pages`, and `utils` packages, plus the `InnerTube` transport. A faithful port requires translating those dependencies and preserving the typed parsing logic, coroutine behavior, proxy/cookie/auth state, and error semantics.

## Migration policy

- Preserve original Kotlin files.
- Work only on branch `kotlin-to-dart-migration`.
- Do not replace real implementations with TODOs, stubs, empty lists, or generic raw JSON responses.
- Treat each operation as complete only after its dependencies and behavior have been ported and verified.
- Run Dart formatting, static analysis, and targeted tests after each group of changes.

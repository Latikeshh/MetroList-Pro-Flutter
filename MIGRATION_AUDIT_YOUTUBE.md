# YouTube.kt → Dart migration audit

## Scope and branch
- Repository: `Latikeshh/MetroList-Pro-Flutter`
- Working branch: `kotlin-to-dart-migration`
- Kotlin facade: `innertube/src/main/kotlin/com/metrolist/innertube/YouTube.kt`
- Kotlin facade snapshot: `3ec82c5ee36812b1d328e17f2185dd2b186dcd55`
- Dart service: `lib/services/innertube/youtube_service.dart`
- Dart service at this audit: 2,457 lines
- Kotlin facade at this audit: 3,402 lines

## Work implemented

| Area | Current implementation | Status |
|---|---|---|
| YouTube service facade | Search/suggestions/summary, browse/home/explore, album/artist/playlist/podcast, library/history, player/next/related/queue, transcript, feedback and account operations | Implemented in Dart |
| Models and responses | Existing models consolidated across `renderers.dart`, `yt_item.dart`, typed response files and client/account models | Ported; exhaustive field parity still needs test coverage |
| Page parsers | Album, artist, artist continuation, playlist and playlist continuation, podcast, history, related, search, home, library, charts and explore parsers | Implemented; representative parser tests added |
| HTTP client | Dio transport, client-specific endpoints, request context, query-parameter continuation encoding, timeouts and injectable adapter | Implemented; runtime parity not yet verified |
| Authentication | Cookie headers, SAPISIDHASH, account origin, dataSyncId context, account menu/list and visitor-data retrieval | Implemented; live authenticated session not verified |
| Playback | Player response, stream URL extraction, cipher handling, extractor adapter, range-aware local proxy and playback tracking | Partial; see limitations |
| Playlists and podcasts | Create/edit/delete, add/remove/move, library feedback, saved episodes, podcast shelves and custom thumbnail upload | Implemented; live mutation/upload not verified |
| Windows | Windows build job added to platform workflow; stream proxy uses Dart IO | Build result pending |
| Tests | Added InnerTube parity, queue/continuation, podcast, client-login and PO-token cache tests; workflow now runs `flutter analyze` and `flutter test` | CI pending |

## Important limitations

1. A valid YouTube PO token must be minted by BotGuard. The previous placeholder token generation was removed; the service now accepts only real tokens supplied by a platform bridge and otherwise returns null. No working BotGuard bridge is currently wired for Windows.
2. The Kotlin extraction transport does not have a direct, verified Dart equivalent. Audio playback currently uses the Dart player resolver, cipher support, `youtube_explode_dart` adapter and a local range proxy as fallbacks.
3. No live YouTube authenticated mutation, upload, or playback integration test has been completed.
4. GitHub Actions runs for this branch were queued at the time of this audit; no successful build/test result is claimed.

## Remaining acceptance checks

- [ ] Complete a real BotGuard PO-token bridge for supported targets, or explicitly keep token-required playback as a documented limitation
- [ ] Verify every renderer/response field against Kotlin fixtures, including unknown and nullable fields
- [ ] Verify account switching, visitor data refresh, cookies and SAPISIDHASH with a real test account
- [ ] Verify search, album, artist, playlist, podcast, history and continuation results against captured Kotlin fixtures
- [ ] Verify player, queue, transcript, media info, playback tracking and stream seeking
- [ ] Verify playlist mutations, feedback tokens and uploads against live responses
- [ ] Obtain successful `flutter analyze`, unit tests, Windows build and platform builds
- [ ] Run a Windows playback smoke test

This branch contains substantial Dart migration work, but the migration must not be described as fully complete until the remaining checks above pass.

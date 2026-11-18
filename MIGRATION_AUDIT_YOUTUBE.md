# YouTube.kt → Dart migration audit

## Scope
- Repository: `Latikeshh/MetroList-Pro-Flutter`
- Branch: `kotlin-to-dart-migration`
- Kotlin facade: `innertube/src/main/kotlin/com/metrolist/innertube/YouTube.kt`
- Kotlin source snapshot: `3ec82c5ee36812b1d328e17f2185dd2b186dcd55`
- Dart service: `lib/services/innertube/youtube_service.dart`
- Dart service at this audit: approximately 2,500 lines

## Implemented migration areas

| Area | Dart work now present | Verification |
|---|---|---|
| Service facade | Search/search pages, suggestions, browse/home/explore, albums, artists and artist shelves, playlists and continuations, podcasts, library/history, player/next/related/queue, transcript, feedback, account and upload operations | Implemented; live endpoint parity pending |
| Models/responses | Consolidated renderer, YT item, account, client, locale, media and typed response models | Ported into Dart files; exhaustive field-by-field fixtures pending |
| Page parsers | Search, search summary/suggestions, album, artist, artist continuation, playlist, playlist continuation, library, library continuation, podcast, history, related, charts, home and explore | Implemented; representative unit tests added |
| HTTP transport | Dio, client-specific endpoint URLs, context construction, continuation query encoding, timeouts and injectable adapter | Implemented; live request parity pending |
| Authentication | Cookie handling, origin-aware SAPISIDHASH, dataSyncId login context, account menu/list and visitor-data refresh | Implemented; live authenticated session not verified |
| Playback | Player request builder, media info, playback tracking, cipher resolver, extractor adapter, range-aware desktop proxy | Partial; see PO-token limitation |
| Mutations/uploads | Playlist create/edit/delete/move, feedback/library tokens, subscription, saved episodes, upload and custom thumbnails | Implemented; live mutations/uploads not verified |
| Windows | Windows build job in platform workflow; Dart IO stream proxy for desktop seeking | Workflow queued; no passing build claimed |
| Tests | Added client-login, queue, artist/playlist/library/search continuation, podcast and playlist-header parser tests; CI runs analyzer and tests | CI queued; results pending |

## Remaining limitations

1. **BotGuard PO tokens:** a valid token must be minted by YouTube's BotGuard VM. Fabricated ID-derived token strings were removed. `PoTokenService` now accepts only real tokens supplied by a host bridge and returns null when none exists. No real cross-platform BotGuard bridge is wired, so token-required playback is not guaranteed.
2. **Extraction transport:** the Kotlin extraction transport has no direct verified Dart equivalent. The Flutter player uses its own InnerTube client rotation, cipher handling, `youtube_explode_dart` adapter and range-aware local proxy.
3. **Live verification:** no authenticated account, playlist mutation, upload, transcript or playback integration test has been completed.
4. **CI:** GitHub Actions runs for this branch were queued at the time of the audit. No successful analyzer, test or platform build result is claimed.

## Acceptance checks still required

- [ ] Real BotGuard bridge for supported targets, or explicit acceptance of fallback-only behavior
- [ ] Field-by-field renderer/response parity fixtures, including nullable and unknown fields
- [ ] Live cookie, SAPISIDHASH, visitor-data refresh and account-switch verification
- [ ] Live search, browse, continuation, history and podcast checks
- [ ] Player, queue, transcript, media info, playback tracking and range-seeking checks
- [ ] Live playlist mutation and upload checks
- [ ] Successful `flutter analyze`, unit tests and Windows build
- [ ] Windows playback smoke test

The branch contains substantial service, model, parser, authentication and playback migration work. It is not yet safe to call the entire migration complete until the outstanding checks above pass.

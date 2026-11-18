# YouTube.kt dependency migration matrix

## Current status on `kotlin-to-dart-migration`

| Kotlin dependency / behavior | Dart implementation | Status |
|---|---|---|
| Models and enums | `models/yt_item.dart`, `models/renderers.dart`, client, locale, account and endpoint models | Ported across consolidated files; exhaustive field parity pending |
| Response envelopes | Typed response models under `models/response/` | Ported; live fixture parity pending |
| Page parsing | Parsers under `pages/` for search, browse, album, artist, playlist, podcast, history, charts, home, explore, related and continuations | Implemented; integration coverage pending |
| Ktor HTTP | Dio in `youtube_service.dart` and `innertube_client.dart` | Implemented; live request parity pending |
| Client identity | WEB_REMIX, WEB, Android Music, iOS, TV HTML5 and Android VR profiles | Implemented; version drift must be monitored |
| Locale / visitor data | Locale state and visitor-data refresh | Implemented; live refresh not verified |
| Cookies / SAPISIDHASH | Cookie headers and origin-aware SAPISIDHASH | Implemented; authenticated account test pending |
| Login context | Optional dataSyncId context and per-request login policy | Implemented; session-switch test pending |
| Kotlin coroutines / Flow | Futures and streams; RxDart in player services | Ported where needed; cancellation semantics need tests |
| Upload progress streams | Dio stream upload and progress callback | Implemented; live upload pending |
| Java InputStream wrapper | Dart Stream and Dio progress callbacks | Equivalent behavior used; exact back-pressure parity not verified |
| Java Proxy | No direct one-to-one mapping; Dio adapter injection and local loopback stream proxy | Platform-dependent |
| Kotlin extraction transport | Dart audio source resolver, cipher engine and extractor adapter | Partial; no verified direct equivalent |
| BotGuard / PO tokens | Token cache accepts real tokens only | Incomplete: no real cross-platform minting bridge |

## Playback notes

- `AudioSourceResolver` tries InnerTube player clients, parses adaptive audio formats and cipher parameters, then falls back to the extractor adapter and public Piped instances.
- The previous PO-token implementation generated fabricated strings from IDs. That was removed because such strings are not valid BotGuard tokens.
- Without a real PO token, the resolver may still succeed through clients/adapters that do not require one; token-required playback is not guaranteed.
- The local HTTP proxy forwards range requests and selected response headers for desktop seeking.

## Validation workflow

The GitHub workflow includes analyzer, tests and platform build jobs, including Windows. At the time of this update, branch runs were queued; no passing result is claimed.

Required before completion:
- [ ] `flutter analyze` passes
- [ ] InnerTube unit and fixture tests pass
- [ ] Windows build passes
- [ ] Windows audio playback, range seeking and proxy smoke tests pass
- [ ] Authenticated browse, account switching and mutations are verified
- [ ] Real BotGuard token bridge or documented fallback limitation is accepted

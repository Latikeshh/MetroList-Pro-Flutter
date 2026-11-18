# YouTube.kt dependency migration matrix

## Current implementation on `kotlin-to-dart-migration`

| Kotlin dependency / behavior | Dart equivalent | Status |
|---|---|---|
| Models and enums | `models/yt_item.dart`, `models/renderers.dart`, account/client/locale/endpoint models | Ported across consolidated files; exhaustive field parity pending |
| Response envelopes | Typed response models under `models/response/` | Ported; live fixture parity pending |
| Page parsing | Typed parsers under `pages/`, including artist, playlist, library and search continuations | Implemented; broader fixture coverage pending |
| Ktor HTTP | Dio in `youtube_service.dart` and `innertube_client.dart` | Implemented; live request parity pending |
| Client identity | WEB_REMIX, WEB, Android Music, iOS, TV HTML5 and Android VR profiles | Implemented; client version drift must be monitored |
| Locale and visitor data | Locale state and visitor-data refresh | Implemented; live refresh not verified |
| Cookies and SAPISIDHASH | Cookie headers and origin-aware SAPISIDHASH | Implemented; authenticated account test pending |
| Login context | Optional dataSyncId context and per-request login policy | Implemented; session-switch test pending |
| Coroutines and Flow | Futures/async-await, Dart streams and RxDart where needed | Ported where used; cancellation semantics need tests |
| Upload progress | Dio stream upload with progress callbacks | Implemented; live upload pending |
| InputStream wrapper | Dart byte streams and Dio progress callbacks | Equivalent approach used; back-pressure parity unverified |
| Java Proxy | Dio adapter injection and local range-aware HTTP proxy | Platform-dependent |
| Extraction transport | InnerTube client rotation, cipher resolver, extractor adapter and local proxy | Partial; no direct verified equivalent |
| BotGuard PO tokens | Video-bound token cache accepts real host-minted tokens only | Incomplete: no real BotGuard bridge |

## Playback notes

- `AudioSourceResolver` rotates InnerTube player clients, parses adaptive audio formats and cipher parameters, then falls back to the extractor adapter and public Piped instances.
- The previous PO-token implementation generated fabricated strings; this has been removed because those are not valid BotGuard tokens.
- Without a real PO token, playback may still work through clients/adapters that do not require one, but token-required playback is not guaranteed.
- The desktop proxy forwards range requests and selected response headers to support seeking.

## Validation status

The GitHub platform workflow now includes `flutter analyze`, `flutter test` and platform build jobs, including Windows. At the time of this update, branch runs were queued and no passing result is claimed.

Required before declaring the migration complete:
- [ ] Analyzer and unit tests pass
- [ ] Windows build and audio playback/range-seeking smoke tests pass
- [ ] Authenticated browse, account switching and mutations are verified
- [ ] Real BotGuard token bridge or accepted fallback limitation is documented

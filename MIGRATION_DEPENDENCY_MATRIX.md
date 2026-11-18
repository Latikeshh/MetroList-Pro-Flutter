# YouTube.kt dependency migration matrix

This document records the dependency work required before the Kotlin YouTube service can be considered ported.

## Existing Flutter dependencies (from pubspec.yaml)

| Existing package | Potential migration role | Verification still required |
|---|---|---|
| `dio` | HTTP transport replacing Ktor client calls | Match request bodies, headers, cookies, proxy behavior, timeouts and error handling |
| `rxdart` | Reactive streams where Kotlin Flow is used | Verify stream lifecycle, cancellation, replay and error semantics |
| `just_audio` | Audio playback integration | Keep player implementation outside the API service unless source requires it |
| `shared_preferences` | Persist simple settings/session preferences | Do not store sensitive credentials without an appropriate secure-storage design |
| `youtube_explode_dart` | Existing YouTube extraction capability | Determine whether each Kotlin InnerTube path should be ported or delegated; avoid silently changing API behavior |

## Kotlin dependency groups and required Dart work

| Kotlin import group / types | Dart migration approach | Status |
|---|---|---|
| `com.metrolist.innertube.models.*` | Port all referenced model classes, enums, helpers and JSON mappings; reuse existing Dart models only after field/behavior comparison | Not verified complete |
| `com.metrolist.innertube.models.response.*` | Port response envelopes and nested payload models; preserve nullable fields and unknown-key handling | Not verified complete |
| `com.metrolist.innertube.pages.*` | Port page parsers and continuation parsing; compare renderer traversal and item ordering | Not verified complete |
| `com.metrolist.innertube.utils.parseTime` | Implement and test equivalent duration/time parsing | Not verified complete |
| `io.ktor.client.*` | Use Dio with equivalent request methods, query parameters, headers, body decoding and exceptions | Partial existing Dio client; parity unverified |
| `kotlinx.coroutines.*` | Use Future/async/await and Stream/RxDart as appropriate; preserve concurrency and cancellation | Not verified complete |
| `kotlinx.serialization.json.Json` | Use typed Dart JSON factories or a serializer; preserve encoding/decoding rules | Not verified complete |
| `timber.log.Timber` | Use the project's logging approach; avoid leaking cookies, tokens or account data | Not verified complete |
| `java.io.InputStream`, `FilterInputStream` | Use Dart Stream<List<int>> / byte streams; preserve byte-count reporting and cancellation | Not verified complete |
| `java.net.Proxy` | Map only if the Flutter target and chosen HTTP adapter support the required proxy configuration | Platform-dependent |
| `kotlin.random.Random` | Use Dart Random with equivalent bounds and security properties | Not verified complete |

## Existing service coverage caveat

The existing `lib/services/innertube/youtube_service.dart` is a partial implementation. A method-name scan is only a rough inventory: differing method names can implement the same behavior, and matching names do not establish parity.

The Kotlin service references broad model, response, parser and transport surfaces. Porting the main service file without those dependencies would leave unresolved types or behavior gaps.

## Required validation before declaring completion

- [ ] Every public Kotlin operation mapped to a Dart operation or explicitly documented as platform-specific/not applicable
- [ ] Request context, client identity, locale, visitor data, cookies and authentication parity checked
- [ ] Search, suggestions, album, artist, playlist, podcast, browse/home, library and continuation parsing tested
- [ ] Player, next, related, queue, transcript and media-info flows tested
- [ ] Account/session, feedback, library mutation and upload flows tested where supported
- [ ] Stream/proxy/byte-count behavior tested on each supported Flutter platform
- [ ] `dart format` completed
- [ ] `flutter analyze` has no migration-introduced errors
- [ ] Unit and integration tests pass
- [ ] Windows build and runtime smoke test pass

## Current status

This is a dependency planning update, not a completed port. No Kotlin service implementation has been replaced by generated placeholder code. The repository must not be described as fully migrated until the validation checklist is satisfied.

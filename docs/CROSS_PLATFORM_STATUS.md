# Cross-platform implementation status

This document records current implementation intent. A feature is not runtime-verified
until it has been built and exercised on the target platform.

## Shared Flutter core

- Search/discovery continue to use the existing YouTube Music request/parser.
- Player state, queue, A/B points, repeat/shuffle, and favorite metadata are managed
  in Dart.
- Favorites and recent history are persisted through shared_preferences, which has
  implementations for Android, iOS, Windows, macOS, Linux, and web.
- Local playback uses a local: source identifier and a file URI on supported targets.
- Failed remote source resolution is an error; unrelated sample audio is never used
  as a fallback.

## Platform constraints and current gaps

| Capability | Android | Windows | iOS | macOS | Linux | Web |
|---|---|---|---|---|---|---|
| Shared UI and metadata logic | Shared | Shared | Shared | Shared | Shared | Shared |
| Favorites/history metadata | Shared prefs | Shared prefs | Shared prefs | Shared prefs | Shared prefs | Browser storage |
| Remote audio playback | Plugin/source dependent | Plugin/source dependent | Plugin/source dependent | Plugin/source dependent | Plugin/source dependent | Browser/CORS limits |
| Local file import | URI/permissions | File picker | File picker/security-scoped URLs | File picker/security-scoped URLs | File picker | Browser file selection |
| A/B clip export | Native backend still required | FFmpeg must be on PATH | Native backend still required | FFmpeg must be on PATH | FFmpeg must be on PATH | Not implemented |
| Background/system media controls | Native integration required | Native integration required | Native integration and OS policy required | Native integration required | Native integration required | Browser-dependent |

Desktop clip export uses FFmpeg and does not bundle it. Android/iOS clip export still
needs native media-processing implementations. Web clip export returns false rather
than claiming success without creating a file.

Full parity with the original Android app is not complete. Native background playback,
system media controls, advanced audio processing, lyrics providers, account sync,
Listen Together, and other platform-specific integrations remain work items. Third-party
source availability may also change independently of this repository.

## Verification commands

Run with each platform toolchain installed:

    flutter pub get
    dart format lib test
    flutter analyze
    flutter test
    flutter build apk
    flutter build windows
    flutter build ios --no-codesign
    flutter build macos
    flutter build linux
    flutter build web

iOS builds require macOS and Xcode. Each build must be run and inspected; successful
compilation alone does not prove every runtime feature works.

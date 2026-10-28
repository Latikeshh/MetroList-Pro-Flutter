import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrolist_pro/main.dart';
import 'package:metrolist_pro/services/innertube/youtube_service.dart';

final List<int> _transparentPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];

class _ImageHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _ImageHttpClient();
  }
}

class _ImageHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _ImageHttpClientRequest();
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _ImageHttpClientRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => _ImageHttpClientRequest();
}

class _ImageHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = _ImageHttpHeaders();

  @override
  Future<HttpClientResponse> close() async => _ImageHttpClientResponse();
  @override
  Future<HttpClientResponse> get done async => _ImageHttpClientResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _ImageHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode = 200;
  @override
  final int contentLength = _transparentPng.length;
  @override
  final HttpHeaders headers = _ImageHttpHeaders();
  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _TestDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _ImageHttpOverrides();
    YouTubeService().setDioAdapter(_TestDioAdapter());
  });

  testWidgets('Metrolist App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MetrolistApp());
    expect(find.byType(MetrolistApp), findsOneWidget);
    expect(find.byType(MainNavigationScreen), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
  });
}

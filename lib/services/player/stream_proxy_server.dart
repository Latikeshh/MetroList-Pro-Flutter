import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Local HTTP loopback proxy server enabling seamless audio streaming on Windows Desktop.
/// Forwards local just_audio requests to remote YouTube CDN stream URLs with custom headers.
class StreamProxyServer {
  static final StreamProxyServer _instance = StreamProxyServer._internal();
  factory StreamProxyServer() => _instance;
  StreamProxyServer._internal();

  HttpServer? _server;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    followRedirects: true,
    maxRedirects: 5,
  ));

  int? get port => _server?.port;

  /// Starts the local loopback HTTP server if not already running.
  Future<int> ensureStarted() async {
    if (_server != null) return _server!.port;

    try {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server!.listen(_handleRequest, onError: (e) {
        debugPrint('StreamProxyServer error: $e');
      });
      debugPrint('StreamProxyServer started on http://127.0.0.1:${_server!.port}');
      return _server!.port;
    } catch (e) {
      debugPrint('Failed to start StreamProxyServer: $e');
      rethrow;
    }
  }

  /// Converts a remote YouTube stream URL into a local proxy URL (http://127.0.0.1:port/stream?url=...)
  Future<String> getProxyUrl(String remoteUrl) async {
    final port = await ensureStarted();
    final encoded = Uri.encodeComponent(remoteUrl);
    return 'http://127.0.0.1:$port/stream?url=$encoded';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    if (path != '/stream') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
      return;
    }

    final rawUrl = request.uri.queryParameters['url'];
    if (rawUrl == null || rawUrl.isEmpty) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..close();
      return;
    }

    final targetUrl = Uri.decodeComponent(rawUrl);

    try {
      final reqHeaders = <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': 'https://music.youtube.com/',
        'Origin': 'https://music.youtube.com',
      };

      // Forward Range header for seeking and streaming chunks
      final rangeHeader = request.headers.value('range');
      if (rangeHeader != null && rangeHeader.isNotEmpty) {
        reqHeaders['Range'] = rangeHeader;
      }

      final response = await _dio.get<ResponseBody>(
        targetUrl,
        options: Options(
          headers: reqHeaders,
          responseType: ResponseType.stream,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      final clientResponse = request.response;
      clientResponse.statusCode = response.statusCode ?? HttpStatus.ok;

      // Forward essential streaming response headers
      response.headers.forEach((name, values) {
        final lowerName = name.toLowerCase();
        if (lowerName == 'content-type' ||
            lowerName == 'content-length' ||
            lowerName == 'accept-ranges' ||
            lowerName == 'content-range') {
          for (final val in values) {
            clientResponse.headers.add(name, val);
          }
        }
      });

      final stream = response.data?.stream;
      if (stream != null) {
        await clientResponse.addStream(stream);
      }
      await clientResponse.close();
    } catch (e) {
      debugPrint('StreamProxyServer proxy error: $e');
      try {
        request.response
          ..statusCode = HttpStatus.internalServerError
          ..close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

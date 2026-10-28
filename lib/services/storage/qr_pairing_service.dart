import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'account_service.dart';

enum QrPairingState {
  idle,
  serverListening,
  receivedPayload,
  validating,
  success,
  expired,
  error,
}

class QrPairingSessionInfo {
  final String pairingId;
  final String secretKey;
  final String localIp;
  final int port;
  final String qrData;

  const QrPairingSessionInfo({
    required this.pairingId,
    required this.secretKey,
    required this.localIp,
    required this.port,
    required this.qrData,
  });
}

/// Manages short-lived ephemeral local network QR pairing bridge between Android & Windows.
class QrPairingService {
  QrPairingService._internal();
  static final QrPairingService _instance = QrPairingService._internal();
  factory QrPairingService() => _instance;

  HttpServer? _server;
  Timer? _expirationTimer;

  final BehaviorSubject<QrPairingState> _stateSubject =
      BehaviorSubject<QrPairingState>.seeded(QrPairingState.idle);
  final BehaviorSubject<QrPairingSessionInfo?> _sessionInfoSubject =
      BehaviorSubject<QrPairingSessionInfo?>.seeded(null);
  final BehaviorSubject<String?> _errorSubject =
      BehaviorSubject<String?>.seeded(null);

  Stream<QrPairingState> get stateStream => _stateSubject.stream;
  Stream<QrPairingSessionInfo?> get sessionInfoStream => _sessionInfoSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;

  QrPairingState get currentState => _stateSubject.value;

  Future<String> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        final name = interface.name.toLowerCase();
        // Skip virtual network adapters (WSL, Hyper-V, VirtualBox, vEthernet)
        if (name.contains('wsl') ||
            name.contains('vethernet') ||
            name.contains('hyper-v') ||
            name.contains('virtualbox') ||
            name.contains('vmware') ||
            name.contains('virtual')) {
          continue;
        }
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            return addr.address;
          }
        }
      }
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && !addr.isLinkLocal) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  String _generateRandomHex(int length) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (_) => rand.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  Future<QrPairingSessionInfo?> startPairingServer() async {
    await stopPairingServer();

    try {
      _stateSubject.add(QrPairingState.idle);
      _errorSubject.add(null);

      final localIp = await _getLocalIpAddress();
      final pairingId = _generateRandomHex(8);
      final secretKey = _generateRandomHex(16);

      _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
      final port = _server!.port;

      final qrData =
          'metrolist://pair?ip=$localIp&port=$port&id=$pairingId&key=$secretKey';

      final info = QrPairingSessionInfo(
        pairingId: pairingId,
        secretKey: secretKey,
        localIp: localIp,
        port: port,
        qrData: qrData,
      );

      _sessionInfoSubject.add(info);
      _stateSubject.add(QrPairingState.serverListening);

      // Listen for pairing payload
      _server!.listen(
        (HttpRequest request) => _handlePairingRequest(request, info),
        onError: (Object err) {
          debugPrint('QR Pairing Server error: $err');
          _stateSubject.add(QrPairingState.error);
          _errorSubject.add(err.toString());
        },
      );

      // Auto-expire after 3 minutes
      _expirationTimer = Timer(const Duration(minutes: 3), () {
        if (_stateSubject.value == QrPairingState.serverListening) {
          _stateSubject.add(QrPairingState.expired);
          _errorSubject.add('Pairing request timed out after 3 minutes.');
          unawaited(stopPairingServer());
        }
      });

      return info;
    } catch (e) {
      _stateSubject.add(QrPairingState.error);
      _errorSubject.add('Failed to start local pairing server: $e');
      debugPrint('Pairing server start failed: $e');
      return null;
    }
  }

  Future<void> _handlePairingRequest(HttpRequest request, QrPairingSessionInfo info) async {
    // Enable CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    if (request.method != 'POST' || request.uri.path != '/pair') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    try {
      _stateSubject.add(QrPairingState.receivedPayload);

      final content = await utf8.decoder.bind(request).join();
      final body = jsonDecode(content);

      if (body is! Map || body['id'] != info.pairingId || (body['key'] != info.secretKey && body['key'] != null)) {
        request.response.statusCode = HttpStatus.unauthorized;
        request.response.write(jsonEncode({'status': 'ERROR', 'message': 'Invalid pairing credentials'}));
        await request.response.close();
        _stateSubject.add(QrPairingState.error);
        _errorSubject.add('Invalid pairing credentials received.');
        unawaited(stopPairingServer()); // Enforce one-time use
        return;
      }

      final cookie = body['cookie']?.toString() ?? '';
      final visitorData = body['visitorData']?.toString() ?? '';
      final accountName = body['accountName']?.toString() ?? 'YouTube Music User';
      final accountEmail = body['accountEmail']?.toString() ?? '';

      _stateSubject.add(QrPairingState.validating);

      // Validate received session
      final accountService = AccountService();
      final success = await accountService.authenticateWithCookie(
        cookie,
        visitorData: visitorData,
        name: accountName,
        email: accountEmail,
      );

      if (success) {
        request.response.statusCode = HttpStatus.ok;
        request.response.write(jsonEncode({'status': 'SUCCESS'}));
        await request.response.close();

        _stateSubject.add(QrPairingState.success);
        debugPrint('QR Pairing successful for $accountName! Session saved.');
        unawaited(stopPairingServer());
      } else {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write(jsonEncode({'status': 'ERROR', 'message': 'Session validation failed'}));
        await request.response.close();

        _stateSubject.add(QrPairingState.error);
        _errorSubject.add('Received session failed authentication validation.');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write(jsonEncode({'status': 'ERROR', 'message': e.toString()}));
      await request.response.close();

      _stateSubject.add(QrPairingState.error);
      _errorSubject.add('Pairing processing error: $e');
    }
  }

  Future<void> stopPairingServer() async {
    _expirationTimer?.cancel();
    _expirationTimer = null;

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
    }

    _sessionInfoSubject.add(null);
    if (_stateSubject.value != QrPairingState.success) {
      _stateSubject.add(QrPairingState.idle);
    }
  }
}

void unawaited(Future<void> future) {}

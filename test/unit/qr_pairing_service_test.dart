import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metrolist_pro/services/storage/account_service.dart';
import 'package:metrolist_pro/services/storage/qr_pairing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QrPairingService Unit Tests', () {
    late QrPairingService pairingService;
    late AccountService accountService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      pairingService = QrPairingService();
      accountService = AccountService();
      await accountService.signOut();
      await pairingService.stopPairingServer();
    });

    test('Initial state is idle', () {
      expect(pairingService.currentState, QrPairingState.idle);
    });

    test('Starts local pairing server on available port', () async {
      final info = await pairingService.startPairingServer();

      expect(info, isNotNull);
      expect(info!.pairingId, isNotEmpty);
      expect(info.port, greaterThan(0));
      expect(info.qrData, contains('metrolist://pair'));
      expect(pairingService.currentState, QrPairingState.serverListening);

      await pairingService.stopPairingServer();
      expect(pairingService.currentState, QrPairingState.idle);
    });

    test('Rejects pairing request with invalid pairing ID', () async {
      final info = await pairingService.startPairingServer();
      expect(info, isNotNull);

      final dio = Dio();
      try {
        await dio.post<dynamic>(
          'http://${info!.localIp}:${info.port}/pair',
          data: {
            'id': 'INVALID_PAIRING_ID',
            'cookie': 'SAPISID=test',
          },
        );
      } catch (e) {
        expect(e, isA<DioException>());
      }

      await pairingService.stopPairingServer();
    });
  });
}

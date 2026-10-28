import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metrolist_pro/services/storage/account_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccountService Unit Tests', () {
    late AccountService accountService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      accountService = AccountService();
      accountService.disconnect();
    });

    test('Initial state is disconnected', () {
      expect(accountService.currentAuthState, AccountAuthState.disconnected);
      expect(accountService.isVerifiedSignedIn, isFalse);
      expect(accountService.currentSession, isNull);
    });

    test('Rejects invalid cookie missing SAPISID token', () {
      accountService.attachUnverifiedSession('INVALID_COOKIE_STRING');

      expect(accountService.currentAuthState, AccountAuthState.disconnected);
      expect(accountService.isVerifiedSignedIn, isFalse);
      expect(accountService.currentSession, isNull);
    });

    test(
        'Attaching session string marks state as unverified, NOT verified signed in',
        () {
      const sampleCookie =
          'VISITOR_INFO1_LIVE=xyz; SAPISID=sapisid_token_12345; SSID=abc';

      accountService.attachUnverifiedSession(sampleCookie);

      expect(
          accountService.currentAuthState, AccountAuthState.unverifiedSession);
      expect(accountService.isVerifiedSignedIn, isFalse);
      expect(accountService.currentSession, isNotNull);
      expect(accountService.currentSession!.isVerified, isFalse);
    });

    test('Disconnect clears session and restores disconnected state', () {
      const sampleCookie = 'SAPISID=sapisid_token_12345';
      accountService.attachUnverifiedSession(sampleCookie);
      expect(accountService.currentSession, isNotNull);

      accountService.disconnect();

      expect(accountService.currentAuthState, AccountAuthState.disconnected);
      expect(accountService.isVerifiedSignedIn, isFalse);
      expect(accountService.currentSession, isNull);
    });
  });
}

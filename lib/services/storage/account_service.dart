import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../innertube/youtube_service.dart';

enum AccountAuthState {
  disconnected,
  unverifiedSession,
  verifiedSession,
}

class UserAccountSession {
  final String cookie;
  final String visitorData;
  final String dataSyncId;
  final String authUser;
  final String accountName;
  final String accountEmail;
  final bool isVerified;

  const UserAccountSession({
    required this.cookie,
    this.visitorData = '',
    this.dataSyncId = '',
    this.authUser = '0',
    this.accountName = 'Unverified Session',
    this.accountEmail = '',
    this.isVerified = false,
  });
}

/// Dedicated account session service with clear verification state management.
class AccountService {
  AccountService._internal();

  static final AccountService _instance = AccountService._internal();
  factory AccountService() => _instance;

  final BehaviorSubject<AccountAuthState> _authStateSubject =
      BehaviorSubject<AccountAuthState>.seeded(AccountAuthState.disconnected);
  final BehaviorSubject<UserAccountSession?> _sessionSubject =
      BehaviorSubject<UserAccountSession?>.seeded(null);
  final BehaviorSubject<String?> _errorSubject =
      BehaviorSubject<String?>.seeded(null);

  Stream<AccountAuthState> get authStateStream => _authStateSubject.stream;
  Stream<UserAccountSession?> get sessionStream => _sessionSubject.stream;
  Stream<String?> get errorStream => _errorSubject.stream;

  AccountAuthState get currentAuthState => _authStateSubject.value;
  UserAccountSession? get currentSession => _sessionSubject.value;
  bool get isVerifiedSignedIn =>
      _authStateSubject.value == AccountAuthState.verifiedSession &&
      _sessionSubject.value?.isVerified == true;

  static Map<String, String> parseCookieString(String cookieHeader) {
    final map = <String, String>{};
    for (final pair in cookieHeader.split(';')) {
      final trimmed = pair.trim();
      if (trimmed.isEmpty) continue;
      final eqIdx = trimmed.indexOf('=');
      if (eqIdx > 0) {
        final k = trimmed.substring(0, eqIdx).trim();
        final v = trimmed.substring(eqIdx + 1).trim();
        map[k] = v;
      }
    }
    return map;
  }

  void attachUnverifiedSession(String rawCookieInput) {
    final trimmed = rawCookieInput.trim();
    if (trimmed.isEmpty) {
      _authStateSubject.add(AccountAuthState.disconnected);
      _sessionSubject.add(null);
      _errorSubject.add('Session input is empty.');
      return;
    }

    final cookieMap = parseCookieString(trimmed);
    if (!cookieMap.containsKey('SAPISID')) {
      _authStateSubject.add(AccountAuthState.disconnected);
      _sessionSubject.add(null);
      _errorSubject.add('Unverified session: Missing SAPISID token format.');
      debugPrint('Unverified session input rejected: Missing SAPISID token.');
      return;
    }

    final session = UserAccountSession(
      cookie: trimmed,
      accountName: 'Unverified Session Input',
      accountEmail: 'Unverified (Not authenticated by Google)',
      isVerified: false,
    );

    _sessionSubject.add(session);
    _authStateSubject.add(AccountAuthState.unverifiedSession);
    _errorSubject.add(null);
    debugPrint('Unverified session string attached. (Cookie REDACTED)');
  }

  Future<bool> authenticateWithCookie(
    String cookieInput, {
    String? visitorData,
    String? name,
    String? email,
  }) async {
    final trimmed = cookieInput.trim();
    if (trimmed.isEmpty) return false;

    final cookieMap = parseCookieString(trimmed);
    if (!cookieMap.containsKey('SAPISID')) {
      _authStateSubject.add(AccountAuthState.disconnected);
      _sessionSubject.add(null);
      _errorSubject.add('Invalid session cookie: Missing SAPISID token.');
      return false;
    }

    // Verify session with real InnerTube request
    final verifiedInfo = await YouTubeService().verifySession(trimmed);
    if (verifiedInfo == null) {
      _authStateSubject.add(AccountAuthState.disconnected);
      _sessionSubject.add(null);
      _errorSubject.add('Session verification failed: YouTube Music server rejected the session.');
      debugPrint('Authentication failed: InnerTube server verification returned null.');
      return false;
    }

    final accountName = verifiedInfo['accountName'] ?? name ?? 'YouTube Music Account';
    final accountEmail = verifiedInfo['accountEmail'] ?? email ?? '';

    final session = UserAccountSession(
      cookie: trimmed,
      visitorData: visitorData ?? '',
      accountName: accountName,
      accountEmail: accountEmail,
      isVerified: true,
    );

    _sessionSubject.add(session);
    _authStateSubject.add(AccountAuthState.verifiedSession);
    _errorSubject.add(null);
    debugPrint('Account session authenticated and verified via pairing. (Cookie REDACTED)');
    return true;
  }

  Future<void> signOut() async {
    disconnect();
  }

  void disconnect() {
    _sessionSubject.add(null);
    _authStateSubject.add(AccountAuthState.disconnected);
    _errorSubject.add(null);
    debugPrint('Account session disconnected.');
  }
}

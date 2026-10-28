library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/storage/account_service.dart';
import '../../services/storage/qr_pairing_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AccountService _accountService = AccountService();
  final QrPairingService _pairingService = QrPairingService();

  void _showQrPairingDialog() {
    _pairingService.startPairingServer();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: StreamBuilder<QrPairingSessionInfo?>(
              stream: _pairingService.sessionInfoStream,
              builder: (context, sessionSnapshot) {
                final sessionInfo = sessionSnapshot.data;

                return StreamBuilder<QrPairingState>(
                  stream: _pairingService.stateStream,
                  builder: (context, stateSnapshot) {
                    final state = stateSnapshot.data ?? QrPairingState.idle;

                    if (state == QrPairingState.success) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'Login Successful!',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your YouTube Music session has been authorized and connected via Android.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      );
                    }

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Sign in with Android',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _pairingService.stopPairingServer();
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Open MetroList Pro on Android, navigate to Settings > QR Login, and scan this QR code to authorize Windows.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),

                        // QR Code Image
                        if (sessionInfo != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: QrImageView(
                              data: sessionInfo.qrData,
                              version: QrVersions.auto,
                              size: 220.0,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (state == QrPairingState.serverListening) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Listening on ${sessionInfo.localIp}:${sessionInfo.port}...',
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ] else if (state == QrPairingState.receivedPayload || state == QrPairingState.validating) ...[
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Verifying session with YouTube...',
                                  style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ] else if (state == QrPairingState.expired) ...[
                                const Text(
                                  'Pairing request expired.',
                                  style: TextStyle(fontSize: 12, color: Colors.redAccent),
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Channel', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<UserAccountSession?>(
            stream: _accountService.sessionStream,
            builder: (context, sessionSnapshot) {
              final session = sessionSnapshot.data;
              final authState = _accountService.currentAuthState;
              final isVerified = authState == AccountAuthState.verifiedSession && session != null;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Status Header Card
                  Card(
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: isVerified
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest,
                            child: Icon(
                              isVerified
                                  ? Icons.account_circle_rounded
                                  : Icons.person_outline_rounded,
                              size: 40,
                              color: isVerified
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isVerified ? session.accountName : 'Guest User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isVerified ? session.accountEmail : 'Account Not Connected',
                                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (isVerified)
                            OutlinedButton(
                              onPressed: _accountService.signOut,
                              child: const Text('Sign Out'),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.qr_code_scanner_rounded, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Cross-Platform Android Sign-In',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Seamlessly authorize MetroList Pro Windows using your signed-in MetroList Pro Android app over local network QR code pairing.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                          const SizedBox(height: 16),
                          if (!isVerified)
                            FilledButton.icon(
                              icon: const Icon(Icons.qr_code_2_rounded),
                              label: const Text('Sign in with Android (Scan QR)'),
                              onPressed: _showQrPairingDialog,
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.green),
                                  SizedBox(width: 12),
                                  Text(
                                    'Account verified and active via Android QR Pairing.',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

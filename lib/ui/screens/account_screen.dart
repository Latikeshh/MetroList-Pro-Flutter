library;

import 'package:flutter/material.dart';
import '../../services/storage/account_service.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accountService = AccountService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account & Channel',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: StreamBuilder<UserAccountSession?>(
            stream: accountService.sessionStream,
            builder: (context, sessionSnapshot) {
              final session = sessionSnapshot.data;
              final authState = accountService.currentAuthState;
              final isVerified =
                  authState == AccountAuthState.verifiedSession &&
                      session != null;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile Status Header Card
                  Card(
                    color: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
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
                                  isVerified
                                      ? session.accountName
                                      : 'Guest User',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isVerified
                                      ? session.accountEmail
                                      : 'Account Not Connected',
                                  style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Account Authentication Notice',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Google Accounts sign-in is not connected in the Windows desktop application. Online metadata browsing, search, playlists, and local music file playback remain fully operational.',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13),
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';

class CustomerBlockedScreen extends StatelessWidget {
  const CustomerBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    final email = account?.email.trim().isNotEmpty == true
        ? account!.email.trim()
        : '';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            // Warning Icon
            Center(
              child: Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppConstants.pendingBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 30,
                  color: AppConstants.pending,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Staff & Admin Access Only',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.ink,
              ),
            ),
            const SizedBox(height: 10),

            // Message
            const Text(
              'This app is for staff & admins only. \n Open the Car Clean Plus customer app to book a wash.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppConstants.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 14),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppConstants.line),
                  ),
                  child: Text(
                    'Signed in: $email',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.muted,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Log out Button
            FilledButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffWaitingScreen extends StatelessWidget {
  const StaffWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Clean Plus Staff'),
        titleTextStyle: const TextStyle(
          color: AppConstants.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppConstants.iconWell,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.badge_outlined,
                  size: 22,
                  color: AppConstants.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Staff jobs are not ready',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppConstants.ink,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

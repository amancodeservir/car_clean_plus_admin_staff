import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';

class CustomerBlockedScreen extends StatelessWidget {
  const CustomerBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _NoticeScreen(
      title: 'Customer account',
      icon: Icons.person_outlined,
      message:
          'This app is for staff. Open the Car Clean Plus customer app to book a wash.',
    );
  }
}

class StaffWaitingScreen extends StatelessWidget {
  const StaffWaitingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().account?.role ?? 'staff';
    return _NoticeScreen(
      title: 'Staff jobs are not ready',
      icon: Icons.badge_outlined,
      message:
          'You are signed in as $role. Assigned jobs, accept, and on-the-way updates need a staff role on the server. That work is still pending.',
    );
  }
}

class _NoticeScreen extends StatelessWidget {
  const _NoticeScreen({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

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
            Center(child: _Well(icon: icon)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: AppConstants.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppConstants.muted,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.logout_outlined, size: 22),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Well extends StatelessWidget {
  const _Well({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppConstants.accent),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../theme/desk_theme.dart';

class CustomerBlockedScreen extends StatelessWidget {
  const CustomerBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _NoticeScreen(
      title: 'Customer account',
      icon: Icons.person_outlined,
      message:
          'This app is for admin and staff. Open the Car Clean Plus customer app to book a wash.',
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
      appBar: AppBar(title: const Text('Car Clean Admin')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Image.asset(AppConstants.logo, height: 56, fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          const Center(child: BrandMark()),
          const SizedBox(height: 16),
          const DeskPhoto(asset: AppConstants.coverPhoto, height: 140),
          const SizedBox(height: 16),
          DeskCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconWell(icon: icon),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(message, style: const TextStyle(color: AppConstants.muted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout_outlined, size: 20),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

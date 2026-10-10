import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import 'account_screens.dart';
import 'staff_jobs_screen.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _count();
  }

  Future<void> _count() async {
    final token = context.read<AuthProvider>().token;
    final result = await runGuarded(
      context,
      context.read<AdminService>().notifications(token),
    );
    if (!mounted || result == null) return;
    setState(() => _unread = result.unread);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          const StaffJobsScreen(),
          AlertsScreen(
            active: _index == 1,
            onRead: () {
              if (_unread != 0) setState(() => _unread = 0);
            },
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppConstants.line)),
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _tab(0, Icons.assignment_outlined, 'Jobs'),
              _tab(1, Icons.notifications_outlined, 'Alerts', badge: _unread),
              _tab(2, Icons.person_outlined, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label, {int badge = 0}) {
    final selected = _index == index;
    final color = selected ? AppConstants.accent : AppConstants.muted;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _index = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

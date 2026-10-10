import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class DeskAlertButton extends StatefulWidget {
  const DeskAlertButton({super.key});

  @override
  State<DeskAlertButton> createState() => _DeskAlertButtonState();
}

class _DeskAlertButtonState extends State<DeskAlertButton> {
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
    return IconButton(
      tooltip: 'Alerts',
      onPressed: () async {
        await context.push('/desk/alerts');
        if (mounted) _count();
      },
      icon: Badge(
        isLabelVisible: _unread > 0,
        label: Text('$_unread'),
        child: const Icon(Icons.notifications_outlined, size: 22),
      ),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, this.active = true, this.onRead});

  final bool active;
  final VoidCallback? onRead;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<DeskAlert> _items = [];
  bool _loading = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) _load();
  }

  @override
  void didUpdateWidget(AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final service = context.read<AdminService>();
    final result = await runGuarded(context, service.notifications(token));
    if (!mounted) return;
    if (result != null && result.unread > 0) {
      await runOk(context, service.markNotificationsRead(token));
      if (!mounted) return;
      widget.onRead?.call();
    }
    if (!mounted) return;
    setState(() {
      if (result != null) _items = result.items;
      _loading = false;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: _loading && !_loaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        DeskEmpty(message: 'No alerts yet.'),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return DeskCard(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const IconWell(icon: Icons.notifications_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppConstants.ink,
                                      ),
                                    ),
                                    if (item.body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        item.body,
                                        style: const TextStyle(color: AppConstants.ink),
                                      ),
                                    ],
                                    if (item.createdAt.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _when(item.createdAt),
                                        style: const TextStyle(
                                          color: AppConstants.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _currentPassword = TextEditingController();
  final _password = TextEditingController();
  StaffDaySummary? _summary;
  DashboardStats? _desk;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final account = context.read<AuthProvider>().account;
    _name.text = account?.name ?? '';
    _phone.text = account?.phone ?? '';
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _currentPassword.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final service = context.read<AdminService>();
    if (auth.account?.isStaff == true) {
      final summary = await runGuarded(context, service.staffSummary(auth.token));
      if (mounted) setState(() => _summary = summary);
    } else if (auth.account?.isAdmin == true) {
      final desk = await runGuarded(context, service.dashboard(auth.token));
      if (mounted) setState(() => _desk = desk);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }
    if (_phone.text.trim().isNotEmpty && digits.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone needs 10 digits')));
      return;
    }
    if (_password.text.isNotEmpty && _password.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }
    if (_password.text.isNotEmpty && _currentPassword.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the current password')));
      return;
    }
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
    };
    if (_password.text.isNotEmpty) {
      body['password'] = _password.text;
      body['currentPassword'] = _currentPassword.text;
    }
    final error = await context.read<AuthProvider>().saveProfile(body);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Profile saved')),
    );
    if (error == null) {
      _currentPassword.clear();
      _password.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            DeskCard(
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      AppConstants.logo,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account?.name ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: AppConstants.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          account?.email ?? '',
                          style: const TextStyle(color: AppConstants.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _roleLabel(account?.role ?? ''),
                          style: const TextStyle(
                            color: AppConstants.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (account?.isStaff == true && _summary != null)
              _StaffNumbers(summary: _summary!)
            else if (account?.isAdmin == true && _desk != null)
              _DeskNumbers(desk: _desk!),
            const SizedBox(height: 12),
            DeskCard(
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: Icon(Icons.lock_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.key_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: Text(_saving ? 'Saving' : 'Save profile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              icon: const Icon(Icons.logout_outlined, size: 20),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffNumbers extends StatelessWidget {
  const _StaffNumbers({required this.summary});

  final StaffDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return DeskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today · ${summary.date}',
            style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Stat(icon: Icons.assignment_outlined, label: 'Jobs', value: '${summary.jobs}'),
              _Stat(icon: Icons.hourglass_bottom_outlined, label: 'Pending', value: '${summary.pending}'),
              _Stat(icon: Icons.sync_outlined, label: 'Active', value: '${summary.active}'),
              _Stat(icon: Icons.task_alt_outlined, label: 'Done', value: '${summary.completed}'),
              _Stat(icon: Icons.payments_outlined, label: 'Cash', value: '₹${_money(summary.collectedCash)}'),
              _Stat(icon: Icons.account_balance_wallet_outlined, label: 'UPI', value: '₹${_money(summary.collectedUpi)}'),
              _Stat(icon: Icons.currency_rupee_outlined, label: 'Booked', value: '₹${_money(summary.expected)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeskNumbers extends StatelessWidget {
  const _DeskNumbers({required this.desk});

  final DashboardStats desk;

  @override
  Widget build(BuildContext context) {
    return DeskCard(
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Stat(icon: Icons.calendar_month_outlined, label: 'Bookings', value: '${desk.totalBookings}'),
          _Stat(icon: Icons.hourglass_bottom_outlined, label: 'Pending', value: '${desk.pendingBookings}'),
          _Stat(icon: Icons.currency_rupee_outlined, label: 'Revenue', value: '₹${_money(desk.totalRevenue)}'),
          _Stat(icon: Icons.mail_outlined, label: 'Enquiries', value: '${desk.totalInquiries}'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppConstants.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppConstants.accent),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink)),
          Text(label, style: const TextStyle(color: AppConstants.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

String _roleLabel(String role) {
  switch (role) {
    case 'superadmin':
      return 'Admin';
    case 'admin':
      return 'Admin';
    case 'staff':
      return 'Washer';
    default:
      return role;
  }
}

String _money(num amount) {
  if (amount == amount.roundToDouble()) return amount.toInt().toString();
  return amount.toStringAsFixed(0);
}

String _when(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month ${local.year} · $hour:$minute';
}

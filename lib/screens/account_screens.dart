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
        label: Text('$_unread', style: const TextStyle(fontSize: 12)),
        child: const Icon(Icons.notifications_outlined, size: 22, color: AppConstants.accent),
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

  /// The desk opens the booking; a washer opens the chat on a message.
  Future<void> _open(DeskAlert item) async {
    final account = context.read<AuthProvider>().account;
    if (account?.isAdmin == true) {
      await openBooking(context, item.bookingId);
    } else if (item.title.toLowerCase().contains('message')) {
      await context.push('/staff/chat/${item.bookingId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        titleTextStyle: _Type.bar,
      ),
      body: _loading && !_loaded
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        _Explain(
                          icon: Icons.notifications_outlined,
                          title: 'No alerts yet',
                          body: 'Booking updates will show up here.',
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: _items.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: item.bookingId.isEmpty ? null : () => _open(item),
                          child: _Surface(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Well(icon: Icons.notifications_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title, style: _Type.section),
                                    if (item.body.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(item.body, style: _Type.body),
                                    ],
                                    if (item.createdAt.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(_when(item.createdAt), style: _Type.caption),
                                    ],
                                  ],
                                ),
                              ),
                              if (item.bookingId.isNotEmpty)
                                const Icon(Icons.chevron_right_outlined, color: AppConstants.muted),
                            ],
                          ),
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
      _say('Name is required');
      return;
    }
    if (_phone.text.trim().isNotEmpty && digits.length < 10) {
      _say('Phone needs 10 digits');
      return;
    }
    if (_password.text.isNotEmpty && _password.text.length < 6) {
      _say('Password must be at least 6 characters');
      return;
    }
    if (_password.text.isNotEmpty && _currentPassword.text.isEmpty) {
      _say('Enter the current password');
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
    _say(error ?? 'Profile saved');
    if (error == null) {
      _currentPassword.clear();
      _password.clear();
    }
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleTextStyle: _Type.bar,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _Surface(
              child: Row(
                children: [
                  const _Well(icon: Icons.person_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account?.name ?? '', style: _Type.section),
                        const SizedBox(height: 2),
                        Text(account?.email ?? '', style: _Type.muted),
                        const SizedBox(height: 6),
                        Text(
                          roleLabel(account?.role ?? ''),
                          style: const TextStyle(
                            color: AppConstants.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (account?.isStaff == true && _summary != null) ...[
              const Text('Today', style: _Type.section),
              const SizedBox(height: 8),
              _StaffNumbers(summary: _summary!),
              const SizedBox(height: 16),
            ] else if (account?.isAdmin == true && _desk != null) ...[
              const Text('Desk', style: _Type.section),
              const SizedBox(height: 8),
              _DeskNumbers(desk: _desk!),
              const SizedBox(height: 16),
            ],
            const Text('Account', style: _Type.section),
            const SizedBox(height: 8),
            _Surface(
              child: Column(
                children: [
                  TextField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outlined, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      prefixIcon: Icon(Icons.phone_outlined, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _currentPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current password',
                      prefixIcon: Icon(Icons.lock_outlined, size: 22),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      prefixIcon: Icon(Icons.key_outlined, size: 22),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.save_outlined, size: 22),
                      label: Text(_saving ? 'Saving' : 'Save profile'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthProvider>().logout(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
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

class _StaffNumbers extends StatelessWidget {
  const _StaffNumbers({required this.summary});

  final StaffDaySummary summary;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(summary.date, style: _Type.caption),
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
    return _Surface(
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
      constraints: const BoxConstraints(minWidth: 104),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppConstants.accent),
          const SizedBox(height: 8),
          Text(value, style: _Type.section),
          Text(label, style: _Type.caption),
        ],
      ),
    );
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

class _Type {
  static const bar = TextStyle(
    color: AppConstants.ink,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  static const section = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppConstants.ink,
  );
  static const body = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppConstants.ink,
  );
  static const muted = TextStyle(
    fontSize: 14,
    height: 1.4,
    color: AppConstants.muted,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    color: AppConstants.muted,
  );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: child,
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

class _Explain extends StatelessWidget {
  const _Explain({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          _Well(icon: icon),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: _Type.section),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center, style: _Type.muted),
        ],
      ),
    );
  }
}

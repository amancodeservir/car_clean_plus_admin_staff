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
    final now = DateTime.now();
    bool isToday(DeskAlert item) {
      final at = DateTime.tryParse(item.createdAt)?.toLocal();
      return at != null && at.year == now.year && at.month == now.month && at.day == now.day;
    }

    final today = _items.where(isToday).toList();
    final earlier = _items.where((item) => !isToday(item)).toList();
    final unread = _items.where((item) => !item.read).length;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    if (canPop)
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 4),
                    const Expanded(child: Text('Alerts', style: _Type.hero)),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: AppConstants.accent, borderRadius: BorderRadius.circular(999)),
                        child: Text(
                          '$unread new',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
              ),
              if (_loading && !_loaded)
                const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
              else if (_items.isEmpty)
                const _Explain(
                  icon: Icons.notifications_none_rounded,
                  title: 'You are all caught up',
                  body: 'New jobs, messages and payment updates will show up here.',
                )
              else ...[
                if (today.isNotEmpty) ...[
                  const _Label('Today'),
                  _AlertGroup(items: today, onOpen: _open),
                  const SizedBox(height: 20),
                ],
                if (earlier.isNotEmpty) ...[
                  const _Label('Earlier'),
                  _AlertGroup(items: earlier, onOpen: _open),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// One white card holding a run of alerts, divided by thin lines.
class _AlertGroup extends StatelessWidget {
  const _AlertGroup({required this.items, required this.onOpen});

  final List<DeskAlert> items;
  final ValueChanged<DeskAlert> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 68),
            _AlertTile(item: items[index], onTap: items[index].bookingId.isEmpty ? null : () => onOpen(items[index])),
          ],
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.item, required this.onTap});

  final DeskAlert item;
  final VoidCallback? onTap;

  /// Icon and colour by what the alert is about.
  (IconData, Color, Color) get _look {
    final title = item.title.toLowerCase();
    if (title.contains('message')) return (Icons.chat_bubble_outline, AppConstants.accent, AppConstants.iconWell);
    if (title.contains('payment') || title.contains('refund') || title.contains('paid')) {
      return (Icons.payments_outlined, AppConstants.completed, AppConstants.completedBg);
    }
    if (title.contains('cancel')) return (Icons.event_busy_outlined, AppConstants.danger, AppConstants.dangerBg);
    if (title.contains('new job') || title.contains('new customer') || title.contains('booking')) {
      return (Icons.local_car_wash_outlined, AppConstants.pending, AppConstants.pendingBg);
    }
    if (title.contains('moved')) return (Icons.update_rounded, AppConstants.accent, AppConstants.iconWell);
    return (Icons.notifications_none_rounded, AppConstants.accent, AppConstants.iconWell);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = _look;
    return Material(
      color: item.read ? Colors.white : const Color(0xFFF5F8FF),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
                              color: AppConstants.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_ago(item.createdAt), style: _Type.caption),
                      ],
                    ),
                    if (item.body.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, height: 1.4, color: AppConstants.muted),
                      ),
                    ],
                  ],
                ),
              ),
              if (!item.read)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppConstants.accent, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Now", "12m", "3h", "Yesterday", "14 Oct".
String _ago(String raw) {
  final at = DateTime.tryParse(raw)?.toLocal();
  if (at == null) return '';
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays == 1) return 'Yesterday';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${at.day} ${months[at.month - 1]}';
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  StaffDaySummary? _summary;
  DashboardStats? _desk;
  bool _loading = true;
  bool _saving = false;
  bool _editing = false;

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
    setState(() => _saving = true);
    final error = await context.read<AuthProvider>().saveProfile({
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (error == null) _editing = false;
    });
    _say(error ?? 'Profile saved');
  }

  void _startEdit(StaffAccount? account) {
    _name.text = account?.name ?? '';
    _phone.text = account?.phone ?? '';
    setState(() => _editing = true);
  }

  void _cancelEdit(StaffAccount? account) {
    _name.text = account?.name ?? '';
    _phone.text = account?.phone ?? '';
    FocusScope.of(context).unfocus();
    setState(() => _editing = false);
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 14))),
    );
  }

  Future<void> _logout() async {
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will stop getting job alerts on this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (go == true && mounted) await context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    final name = (account?.name ?? '').trim();
    final initials = name.isEmpty
        ? '?'
        : name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).take(2).map((part) => part[0].toUpperCase()).join();
    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 4, 16),
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back),
                      )
                    else
                      const SizedBox(width: 4),
                    const Text('Profile', style: _Type.hero),
                  ],
                ),
              ),
              _Card(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: AppConstants.accent, shape: BoxShape.circle),
                      child: Text(
                        initials,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'Your account' : name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _Type.section),
                          const SizedBox(height: 2),
                          Text(account?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: _Type.muted),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _Badge(label: roleLabel(account?.role ?? ''), color: AppConstants.accent, background: AppConstants.iconWell),
                              if (account?.isStaff == true)
                                account!.onShift
                                    ? const _Badge(label: 'On shift', color: AppConstants.completed, background: AppConstants.completedBg)
                                    : const _Badge(label: 'Off shift', color: AppConstants.muted, background: Color(0xFFF1F3F6)),
                              if ((account?.branch ?? '').isNotEmpty)
                                _Badge(label: account!.branch, color: AppConstants.ink, background: const Color(0xFFF1F3F6)),
                            ],
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
              else if (account?.isStaff == true && _summary != null)
                _StaffNumbers(summary: _summary!)
              else if (account?.isAdmin == true && _desk != null)
                _DeskNumbers(desk: _desk!),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'YOUR DETAILS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppConstants.muted),
                      ),
                    ),
                    if (!_editing)
                      TextButton.icon(
                        onPressed: () => _startEdit(account),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      ),
                  ],
                ),
              ),
              _Card(
                padding: _editing ? const EdgeInsets.all(16) : EdgeInsets.zero,
                child: _editing
                    ? Column(
                        children: [
                          TextField(
                            controller: _name,
                            autofocus: true,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline, size: 22)),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone',
                              helperText: 'Customers see this number when you are on a job.',
                              prefixIcon: Icon(Icons.phone_outlined, size: 22),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 50,
                                  child: OutlinedButton(
                                    onPressed: _saving ? null : () => _cancelEdit(account),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      side: const BorderSide(color: AppConstants.line),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: SizedBox(
                                  height: 50,
                                  child: FilledButton(
                                    onPressed: _saving ? null : _save,
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                    ),
                                    child: Text(_saving ? 'Saving…' : 'Save changes'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          _InfoRow(icon: Icons.person_outline, label: 'Name', value: account?.name ?? ''),
                          const Divider(height: 1, indent: 52),
                          _InfoRow(icon: Icons.phone_outlined, label: 'Phone', value: account?.phone ?? ''),
                          const Divider(height: 1, indent: 52),
                          _InfoRow(icon: Icons.mail_outline, label: 'Email', value: account?.email ?? ''),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              const _Label('Account'),
              _Card(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _Row(
                      icon: Icons.lock_outline,
                      label: 'Change password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const ChangePasswordScreen()),
                      ),
                    ),
                    const Divider(height: 1, indent: 52),
                    _Row(
                      icon: Icons.support_agent_outlined,
                      label: 'Call the desk',
                      onTap: () => dialNumber(AppConstants.supportPhone, context),
                    ),
                    const Divider(height: 1, indent: 52),
                    _Row(
                      icon: Icons.logout_rounded,
                      label: 'Log out',
                      color: AppConstants.danger,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
    final cash = summary.collectedCash + summary.collectedUpi;
    final progress = summary.jobs == 0 ? 0.0 : summary.completed / summary.jobs;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppConstants.accent, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Today', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                '${summary.completed} of ${summary.jobs} done',
                style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              color: AppConstants.signal,
              backgroundColor: const Color(0x33FFFFFF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _WhiteStat(value: '${summary.pending + summary.active}', label: 'Still to do'),
              _WhiteStat(value: rupees(summary.collectedCash), label: 'Cash'),
              _WhiteStat(value: rupees(summary.collectedUpi), label: 'UPI'),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: const Color(0x1FFFFFFF), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Collected ${rupees(cash)} of ${rupees(summary.expected)} booked',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppConstants.accent, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          _WhiteStat(value: '${desk.todayBookings}', label: 'Today'),
          _WhiteStat(value: '${desk.unassigned}', label: 'Need a washer'),
          _WhiteStat(value: rupees(desk.collectedRevenue), label: 'Paid'),
        ],
      ),
    );
  }
}

class _WhiteStat extends StatelessWidget {
  const _WhiteStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppConstants.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: _Type.caption),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? 'Not added' : value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: value.trim().isEmpty ? AppConstants.muted : AppConstants.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Its own page so the profile stays a plain read-out.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _saving = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String? problem;
    if (_current.text.isEmpty) {
      problem = 'Enter your current password';
    } else if (_next.text.length < 6) {
      problem = 'The new password needs at least 6 characters';
    } else if (_next.text != _again.text) {
      problem = 'The new passwords do not match';
    } else if (_next.text == _current.text) {
      problem = 'Choose a password different from the current one';
    }
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final account = auth.account;
    // The server needs the name with every profile update.
    final error = await auth.saveProfile({
      'name': account?.name ?? '',
      'phone': account?.phone ?? '',
      'password': _next.text,
      'currentPassword': _current.text,
    });
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password changed')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration field(String label, IconData icon, {String? helper}) => InputDecoration(
          labelText: label,
          helperText: helper,
          prefixIcon: Icon(icon, size: 22),
        );
    return Scaffold(
      backgroundColor: AppConstants.paper,
      appBar: AppBar(title: const Text('Change password')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: Text(
              'Use a password only you know. You stay signed in on this phone.',
              style: TextStyle(fontSize: 14, height: 1.4, color: AppConstants.muted),
            ),
          ),
          _Card(
            child: Column(
              children: [
                TextField(
                  controller: _current,
                  obscureText: !_show,
                  autofocus: true,
                  decoration: field('Current password', Icons.lock_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _next,
                  obscureText: !_show,
                  decoration: field('New password', Icons.key_outlined, helper: 'At least 6 characters.'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _again,
                  obscureText: !_show,
                  onSubmitted: (_) => _save(),
                  decoration: field('New password again', Icons.key_outlined),
                ),
                const SizedBox(height: 4),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _show,
                  onChanged: (value) => setState(() => _show = value ?? false),
                  title: const Text('Show passwords', style: TextStyle(fontSize: 14)),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 18, color: AppConstants.danger),
                        const SizedBox(width: 6),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppConstants.danger, fontSize: 13))),
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: Text(_saving ? 'Saving…' : 'Change password'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.line),
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppConstants.muted),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.background});

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.color = AppConstants.ink});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color == AppConstants.ink ? AppConstants.accent : color),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color))),
            const Icon(Icons.chevron_right, color: AppConstants.muted),
          ],
        ),
      ),
    );
  }
}



class _Type {
  static const hero = TextStyle(
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppConstants.ink,
  );
  static const section = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
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

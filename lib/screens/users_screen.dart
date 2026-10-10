import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<StaffAccount> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final users = await runGuarded(
      context,
      context.read<AdminService>().users(token),
    );
    if (!mounted) return;
    setState(() {
      if (users != null) _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        itemCount: (_users.isEmpty ? 1 : _users.length) + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'People',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppConstants.ink),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final changed = await context.push<bool>('/desk/tools', extra: 'staff');
                      if (changed == true) _load();
                    },
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: const Text('Add staff'),
                  ),
                ],
              ),
            );
          }
          if (_users.isEmpty) {
            return const DeskEmpty(message: 'No people yet. Add staff to create a washer login.');
          }
          final user = _users[index - 1];
          final title = user.name.isEmpty ? user.email : user.name;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DeskCard(
              onTap: () async {
                final changed = await context.push<bool>('/desk/user', extra: user);
                if (changed == true) _load();
              },
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w500, color: AppConstants.ink),
                        ),
                        Text(user.email, style: const TextStyle(color: AppConstants.muted, fontSize: 12, fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _RolePill(role: user.role),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: AppConstants.accent,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.user});

  final StaffAccount user;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  late String _role;
  bool _busy = false;
  bool _historyLoading = true;
  List<BookingRecord> _washes = [];

  @override
  void initState() {
    super.initState();
    _role = widget.user.role;
    _loadWashes();
  }

  Future<void> _loadWashes() async {
    final token = context.read<AuthProvider>().token;
    final data = await runGuarded(
      context,
      context.read<AdminService>().getMap(
            token,
            AppConstants.userBookings(widget.user.id),
          ),
    );
    if (!mounted) return;
    setState(() {
      _historyLoading = false;
      if (data != null) {
        _washes = mapList(data['data'], BookingRecord.fromJson);
      }
    });
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().updateRole(token, widget.user.id, _role),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().account;
    final canEdit = me?.isSuperadmin == true;
    final title = widget.user.name.isEmpty ? widget.user.email : widget.user.name;
    return Scaffold(
      appBar: AppBar(title: const Text('User')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DeskCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconWell(icon: Icons.person_outlined),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                MetaRow(icon: Icons.email_outlined, text: widget.user.email),
                MetaRow(
                  icon: Icons.phone_outlined,
                  text: widget.user.phone.isEmpty ? 'No phone' : widget.user.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (!canEdit)
            DeskCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconWell(icon: Icons.admin_panel_settings_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Role: $_role\nOnly a superadmin can change roles.',
                      style: const TextStyle(color: AppConstants.ink, height: 1.4),
                    ),
                  ),
                ],
              ),
            )
          else
            DeskCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    decoration: const InputDecoration(
                      labelText: 'Role',
                      prefixIcon: Icon(Icons.admin_panel_settings_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'customer', child: Text('customer')),
                      DropdownMenuItem(value: 'staff', child: Text('staff')),
                      DropdownMenuItem(value: 'admin', child: Text('admin')),
                      DropdownMenuItem(value: 'superadmin', child: Text('superadmin')),
                    ],
                    onChanged: (value) => setState(() => _role = value ?? _role),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'An admin account cannot promote people. This control is only shown for superadmin.',
                    style: TextStyle(color: AppConstants.muted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: Icon(_busy ? Icons.hourglass_bottom_outlined : Icons.save_outlined, size: 20),
                    label: Text(_busy ? 'Saving…' : 'Save role'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Row(
            children: [
              Icon(Icons.history_outlined, size: 20, color: AppConstants.accent),
              SizedBox(width: 8),
              Text('Wash history', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink)),
            ],
          ),
          const SizedBox(height: 8),
          if (_historyLoading)
            const LinearProgressIndicator()
          else if (_washes.isEmpty)
            const DeskEmpty(message: 'No washes yet.')
          else
            for (final wash in _washes)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: DeskCard(
                  child: Row(
                    children: [
                      DeskPhoto(asset: washAssetFor(wash.service), height: 52, width: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wash.service.isEmpty ? 'Wash' : wash.service,
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${wash.date} · ${wash.timeSlot}',
                              style: const TextStyle(color: AppConstants.muted, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.currency_rupee_outlined, size: 20, color: AppConstants.accent),
                                const SizedBox(width: 4),
                                Text('₹${wash.price}', style: const TextStyle(fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      StatusPill(status: wash.status),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

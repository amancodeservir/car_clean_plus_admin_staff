import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.booking});

  final BookingRecord booking;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late String _status;
  bool _busy = false;
  List<StaffAccount> _staff = [];
  String? _staffId;

  @override
  void initState() {
    super.initState();
    _status = widget.booking.status;
    _staffId = widget.booking.assignedStaffId.isEmpty
        ? null
        : widget.booking.assignedStaffId;
    _loadStaff();
  }

  Future<void> _loadStaff() async {
    final token = context.read<AuthProvider>().token;
    final users = await runGuarded(
      context,
      context.read<AdminService>().users(token),
    );
    if (!mounted || users == null) return;
    setState(() {
      _staff = users.where((user) => user.isStaff).toList();
    });
  }

  Future<void> _assign() async {
    final staffId = _staffId;
    if (staffId == null || staffId.isEmpty) return;
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final message = await runGuarded(
      context,
      context.read<AdminService>().assignStaff(token, widget.booking.id, staffId),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _setStatus(String status) async {
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().updateStatus(token, widget.booking.id, status),
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (ok) _status = status;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this booking?'),
        content: Text(
          _status == 'blocked'
              ? 'This opens the slot again for customers.'
              : 'This removes the booking from the server.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().deleteBooking(token, widget.booking.id),
    );
    if (!mounted) return;
    if (ok) Navigator.pop(context, true);
    setState(() => _busy = false);
  }

  Future<void> _openWhatsApp() async {
    final digits = widget.booking.mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final local = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final text = Uri.encodeComponent('Wash status: ${_status.replaceAll('_', ' ')}');
    final uri = Uri.parse('https://wa.me/91$local?text=$text');
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open WhatsApp')),
      );
    }
  }

  Future<void> _refund() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund this booking?'),
        content: Text('Amount ₹${widget.booking.price}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Refund')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final token = context.read<AuthProvider>().token;
    final ok = await runOk(
      context,
      context.read<AdminService>().put(
        token,
        AppConstants.refundBooking(widget.booking.id),
        {'amount': widget.booking.price},
      ),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund recorded')),
      );
    }
  }

  List<StaffAccount> get _assignableStaff {
    if (!_staff.any((user) => user.onShift)) return _staff;
    return [
      ..._staff.where((user) => user.onShift),
      ..._staff.where((user) => !user.onShift),
    ];
  }

  String _staffLabel(StaffAccount user) {
    final name = user.name.isEmpty ? user.email : user.name;
    if (_staff.any((item) => item.onShift) && !user.onShift) {
      return '$name · off shift';
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking'),
        actions: [
          IconButton(
            tooltip: 'Delete',
            onPressed: _busy ? null : _delete,
            icon: const Icon(Icons.delete_outlined, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DeskCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DeskPhoto(asset: washAssetFor(booking.service), height: 72, width: 72),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StatusPill(status: _status),
                          const SizedBox(height: 8),
                          Text(
                            booking.customerName.isEmpty ? 'Booking' : booking.customerName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (booking.mobile.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DeskAction(
                          icon: Icons.phone_outlined,
                          label: booking.mobile,
                          onPressed: () => dialNumber(booking.mobile),
                        ),
                        DeskAction(
                          icon: Icons.chat_outlined,
                          label: 'WhatsApp',
                          onPressed: _openWhatsApp,
                        ),
                      ],
                    ),
                  ),
                MetaRow(icon: Icons.local_car_wash_outlined, text: booking.service),
                MetaRow(
                  icon: Icons.directions_car_outlined,
                  text: '${booking.carName} (${booking.carCategory})',
                ),
                MetaRow(
                  icon: Icons.calendar_today_outlined,
                  text: '${booking.date} · ${booking.timeSlot}',
                ),
                MetaRow(
                  icon: Icons.location_on_outlined,
                  text: '${booking.address}, ${booking.city}',
                ),
                MetaRow(
                  icon: Icons.currency_rupee_outlined,
                  text: '₹${booking.price} · ${booking.paymentMethod}',
                ),
                MetaRow(icon: Icons.source_outlined, text: booking.source),
                if (booking.instructions.isNotEmpty)
                  MetaRow(icon: Icons.notes_outlined, text: booking.instructions),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy ? null : _refund,
            icon: const Icon(Icons.currency_rupee_outlined, size: 20),
            label: Text('Refund ₹${booking.price}'),
          ),
          const SizedBox(height: 16),
          DeskCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const IconWell(icon: Icons.badge_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.booking.assignedStaffName.isEmpty
                            ? 'No one assigned'
                            : 'Assigned: ${widget.booking.assignedStaffName}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppConstants.ink),
                      ),
                    ),
                  ],
                ),
                if (_staff.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('Make a staff account before assigning a job.'),
                  )
                else ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_staffId ?? ''),
                    initialValue: _assignableStaff.any((user) => user.id == _staffId) ? _staffId : null,
                    decoration: const InputDecoration(
                      labelText: 'Assign staff',
                      prefixIcon: Icon(Icons.person_outlined, size: 20),
                    ),
                    items: [
                      for (final user in _assignableStaff)
                        DropdownMenuItem(value: user.id, child: Text(_staffLabel(user))),
                    ],
                    onChanged: (value) => setState(() => _staffId = value),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy || _staffId == null ? null : _assign,
                    icon: const Icon(Icons.person_add_outlined, size: 20),
                    label: const Text('Give this job to staff'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.flag_outlined, size: 20, color: AppConstants.accent),
              SizedBox(width: 8),
              Text('Status', style: TextStyle(fontWeight: FontWeight.w800, color: AppConstants.ink)),
            ],
          ),
          const SizedBox(height: 8),
          StatusTree(
            status: _status,
            onNext: _busy || nextStatusAfter(_status) == null ? null : () => _setStatus(nextStatusAfter(_status)!),
          ),
          if (!_busy && !const {'completed', 'cancelled', 'blocked'}.contains(_status))
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _setStatus('cancelled'),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel this wash'),
                style: TextButton.styleFrom(foregroundColor: AppConstants.danger),
              ),
            ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

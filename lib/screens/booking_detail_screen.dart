import 'dart:convert';

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
        title: const Text('Delete this booking?', style: _titleStyle),
        content: Text(
          _status == 'blocked'
              ? 'This opens the slot again for customers.'
              : 'This removes the booking from the server.',
          style: _bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: _actionStyle),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              textStyle: _actionStyle,
              shape: const StadiumBorder(),
            ),
            child: const Text('Delete'),
          ),
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
        title: const Text('Refund this booking?', style: _titleStyle),
        content: Text('Amount ₹${widget.booking.price}', style: _bodyStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: _actionStyle),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              textStyle: _actionStyle,
              shape: const StadiumBorder(),
            ),
            child: const Text('Refund'),
          ),
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

  Widget? _memoryImage(String value) {
    if (!value.startsWith('data:image')) return null;
    final comma = value.indexOf(',');
    if (comma < 0 || comma + 1 >= value.length) return null;
    try {
      final bytes = base64Decode(value.substring(comma + 1));
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          bytes,
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const SizedBox(
              height: 180,
              child: Center(
                child: Icon(Icons.broken_image_outlined, size: 22, color: AppConstants.muted),
              ),
            );
          },
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Widget _labeledPhoto(String value, String label) {
    final image = _memoryImage(value);
    if (image == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _bodyStyle.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        image,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final name = booking.customerName.trim();
    final identity = name.isEmpty ? 'Booking' : name;
    final service = booking.service.trim();
    final notes = booking.instructions.trim();
    final vehicleIcon = booking.carCategory == 'Bike'
        ? Icons.two_wheeler_outlined
        : Icons.directions_car_outlined;
    final facts = <Widget>[
      _FactRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _textOrDash(shortDate(booking.date))),
      _FactRow(icon: Icons.schedule_outlined, label: 'Slot', value: _textOrDash(booking.timeSlot)),
      _FactRow(icon: vehicleIcon, label: 'Vehicle', value: _vehicleValue(booking)),
      _FactRow(icon: Icons.location_on_outlined, label: 'Address', value: _addressValue(booking)),
      _FactRow(icon: Icons.phone_outlined, label: 'Phone', value: _textOrDash(booking.mobile)),
      _FactRow(icon: Icons.payments_outlined, label: 'Payment', value: _paymentValue(booking)),
      _FactRow(icon: Icons.person_outline, label: 'Staff', value: _staffValue(booking)),
    ];
    if (booking.source.trim().isNotEmpty) {
      facts.add(
        _FactRow(icon: Icons.source_outlined, label: 'Source', value: booking.source.trim()),
      );
    }
    final barTheme = Theme.of(context).appBarTheme;
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: barTheme.copyWith(
          backgroundColor: AppConstants.paper,
          foregroundColor: AppConstants.ink,
          titleTextStyle: _titleStyle,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppConstants.paper,
        appBar: AppBar(
          title: Text(identity),
          actions: [
            IconButton(
              tooltip: 'Delete',
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outlined, size: 22),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _Sheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(identity, style: _titleStyle)),
                      const SizedBox(width: 8),
                      _TonePill(status: _status),
                    ],
                  ),
                  if (service.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(service, style: _bodyStyle),
                  ],
                  const SizedBox(height: 8),
                  Text('₹${booking.price}', style: _titleStyle),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Sheet(
              child: Column(
                children: [
                  for (var index = 0; index < facts.length; index++) ...[
                    if (index > 0) const SizedBox(height: 14),
                    facts[index],
                  ],
                ],
              ),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Notes', style: _titleStyle),
                    const SizedBox(height: 8),
                    Text(notes, style: _bodyStyle),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (booking.mobile.isNotEmpty) ...[
                  _ActionButton(
                    icon: Icons.phone_outlined,
                    label: 'Call',
                    onPressed: () => dialNumber(booking.mobile),
                  ),
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    onPressed: _openWhatsApp,
                  ),
                  const SizedBox(height: 8),
                ],
                _ActionButton(
                  icon: Icons.currency_rupee_outlined,
                  label: 'Refund ₹${booking.price}',
                  onPressed: _busy ? null : _refund,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Sheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const _IconWell(icon: Icons.badge_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.booking.assignedStaffName.isEmpty
                              ? 'Assign this client'
                              : 'Assigned: ${widget.booking.assignedStaffName}',
                          style: _titleStyle,
                        ),
                      ),
                    ],
                  ),
                  if (_staff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Make a staff account before assigning a job.',
                        style: _bodyStyle,
                      ),
                    )
                  else ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_staffId ?? ''),
                      initialValue: _assignableStaff.any((user) => user.id == _staffId) ? _staffId : null,
                      isExpanded: true,
                      style: _bodyStyle,
                      decoration: const InputDecoration(
                        labelText: 'Assign staff',
                        labelStyle: _labelStyle,
                        prefixIcon: Icon(Icons.person_outline, size: 22, color: AppConstants.accent),
                      ),
                      items: [
                        for (final user in _assignableStaff)
                          DropdownMenuItem(
                            value: user.id,
                            child: Text(_staffLabel(user), style: _bodyStyle),
                          ),
                      ],
                      onChanged: (value) => setState(() => _staffId = value),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Assign this wash to a washer. They will see the job.',
                        style: _mutedBodyStyle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _busy || _staffId == null ? null : _assign,
                        icon: const Icon(Icons.person_add_outlined, size: 22),
                        label: const Text('Assign to washer'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          shape: const StadiumBorder(),
                          textStyle: _primaryActionStyle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (booking.beforePhoto.startsWith('data:image') ||
                booking.afterPhoto.startsWith('data:image')) ...[
              const SizedBox(height: 12),
              _Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Photos', style: _titleStyle),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (booking.beforePhoto.startsWith('data:image'))
                          Expanded(child: _labeledPhoto(booking.beforePhoto, 'Before')),
                        if (booking.beforePhoto.startsWith('data:image') &&
                            booking.afterPhoto.startsWith('data:image'))
                          const SizedBox(width: 12),
                        if (booking.afterPhoto.startsWith('data:image'))
                          Expanded(child: _labeledPhoto(booking.afterPhoto, 'After')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            if (booking.reports.isNotEmpty) ...[
              const SizedBox(height: 12),
              _Sheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Customer reports', style: _titleStyle),
                    for (final report in booking.reports) ...[
                      const SizedBox(height: 12),
                      if (report.byName.isNotEmpty)
                        Text(report.byName, style: _bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                      if (report.note.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(report.note, style: _bodyStyle),
                        ),
                      if (report.image.startsWith('data:image'))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: _memoryImage(report.image) ?? const SizedBox.shrink(),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const Text('Status', style: _titleStyle),
            const SizedBox(height: 12),
            StatusTree(
              status: _status,
              onNext: _busy || nextStatusAfter(_status) == null
                  ? null
                  : () => _setStatus(nextStatusAfter(_status)!),
            ),
            if (!_busy && !const {'completed', 'cancelled', 'blocked'}.contains(_status)) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: _ActionButton(
                  icon: Icons.cancel_outlined,
                  label: 'Cancel this wash',
                  foreground: AppConstants.danger,
                  onPressed: () => _setStatus('cancelled'),
                ),
              ),
            ],
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

const _titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: AppConstants.ink,
  height: 1.2,
);

const _bodyStyle = TextStyle(
  fontSize: 14,
  color: AppConstants.ink,
  height: 1.35,
);

const _mutedBodyStyle = TextStyle(
  fontSize: 14,
  color: AppConstants.muted,
  height: 1.35,
);

const _labelStyle = TextStyle(
  fontSize: 12,
  color: AppConstants.muted,
  height: 1.25,
);

const _actionStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
);

const _primaryActionStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
);

String _textOrDash(String value) {
  final text = value.trim();
  return text.isEmpty ? '—' : text;
}

String _vehicleValue(BookingRecord booking) {
  final name = booking.carName.trim();
  final category = booking.carCategory.trim();
  if (name.isEmpty && category.isEmpty) return '—';
  if (name.isEmpty) return category;
  if (category.isEmpty) return name;
  return '$name ($category)';
}

String _addressValue(BookingRecord booking) {
  final street = booking.address.trim();
  final city = booking.city.trim();
  if (street.isEmpty && city.isEmpty) return '—';
  if (street.isEmpty) return city;
  if (city.isEmpty) return street;
  return '$street, $city';
}

String _paymentValue(BookingRecord booking) {
  final method = booking.paymentMethod.trim();
  final status = booking.paymentStatus.trim();
  if (method.isEmpty && status.isEmpty) return '—';
  if (method.isEmpty) return status;
  if (status.isEmpty) return method;
  return '$method · $status';
}

String _staffValue(BookingRecord booking) {
  final name = booking.washerName.trim().isNotEmpty
      ? booking.washerName.trim()
      : booking.assignedStaffName.trim();
  if (name.isEmpty) return 'Not assigned';
  final phone = booking.washerPhone.trim();
  if (phone.isEmpty) return name;
  return '$name · $phone';
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: child,
    );
  }
}

class _IconWell extends StatelessWidget {
  const _IconWell({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppConstants.iconWell,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 22, color: AppConstants.accent),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _IconWell(icon: icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _labelStyle),
              const SizedBox(height: 2),
              Text(value, style: _bodyStyle),
            ],
          ),
        ),
      ],
    );
  }
}

class _TonePill extends StatelessWidget {
  const _TonePill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final tone = statusTone(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        prettyStatus(status),
        style: TextStyle(
          color: tone.foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.foreground = AppConstants.accent,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 22),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
        side: BorderSide(color: foreground == AppConstants.accent ? AppConstants.line : foreground),
        textStyle: _actionStyle,
      ),
    );
  }
}

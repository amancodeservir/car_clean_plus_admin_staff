import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

/// One booking on the desk. Always reads the latest copy from the server,
/// and pops `true` when anything changed so the list behind it reloads.
class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId, this.initial});

  final String bookingId;
  final BookingRecord? initial;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  BookingRecord? _booking;
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  String? _error;
  List<StaffAccount> _staff = [];
  String? _staffId;

  String get _token => context.read<AuthProvider>().token;
  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _booking = widget.initial;
    _staffId = _booking?.assignedStaffId.isEmpty == false ? _booking!.assignedStaffId : null;
    _load();
    _loadStaff();
  }

  Future<void> _load() async {
    try {
      final fresh = await _service.booking(_token, widget.bookingId);
      if (!mounted) return;
      setState(() {
        _booking = fresh;
        _staffId = fresh.assignedStaffId.isEmpty ? null : fresh.assignedStaffId;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _loadStaff() async {
    final staff = await runGuarded(context, _service.staff(_token));
    if (!mounted || staff == null) return;
    setState(() {
      _staff = [...staff.where((user) => user.onShift), ...staff.where((user) => !user.onShift)];
    });
  }

  /// Runs one desk action, then shows [done] and reloads the booking.
  Future<void> _act(Future<Object?> action, String done) async {
    setState(() => _busy = true);
    final ok = await runOk(context, action);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    _changed = true;
    _say(done);
    await _load();
  }

  void _say(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _assign() async {
    final staffId = _staffId;
    if (staffId == null) return;
    await _act(_service.assignStaff(_token, widget.bookingId, staffId), 'Washer assigned');
  }

  Future<void> _advance(String status) async {
    final booking = _booking!;
    if (status == 'completed' && booking.due > 0 && !booking.isPaid) {
      final go = await _confirm(
        'Finish without payment?',
        '${rupees(booking.due)} is still due on this wash. Mark it finished anyway?',
        'Mark done',
      );
      if (go != true) return;
    }
    await _act(_service.setStatus(_token, widget.bookingId, status), 'Now ${prettyStatus(status).toLowerCase()}');
  }

  Future<void> _cancel() async {
    final reason = TextEditingController();
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this wash?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The customer and the washer are told.'),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Reason (optional)', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppConstants.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel wash'),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (go != true || !mounted) return;
    await _act(_service.setStatus(_token, widget.bookingId, 'cancelled', reason: text), 'Wash cancelled');
  }

  Future<bool?> _confirm(String title, String body, String action, {bool danger = false}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          FilledButton(
            style: danger ? FilledButton.styleFrom(backgroundColor: AppConstants.danger) : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _delete() async {
    final booking = _booking!;
    final go = await _confirm(
      booking.isBlocked ? 'Open this slot again?' : 'Delete this booking?',
      booking.isBlocked
          ? 'Customers can book ${booking.timeSlot} on ${booking.date} again.'
          : 'This removes the booking for good. Cancel it instead to keep a record.',
      booking.isBlocked ? 'Unblock' : 'Delete',
      danger: true,
    );
    if (go != true || !mounted) return;
    setState(() => _busy = true);
    final ok = await runOk(context, _service.deleteBooking(_token, widget.bookingId));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) context.pop(true);
  }

  Future<void> _refund() async {
    final booking = _booking!;
    final most = booking.refundable;
    final amount = TextEditingController(text: '${most.round()}');
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Up to ${rupees(most)} can be returned.'),
            const SizedBox(height: 12),
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Refund')),
        ],
      ),
    );
    final value = num.tryParse(amount.text.trim());
    amount.dispose();
    if (go != true || !mounted) return;
    if (value == null || value <= 0 || value > most) {
      _say('Enter an amount from ₹1 to ${rupees(most)}');
      return;
    }
    setState(() => _busy = true);
    final message = await runGuarded(context, _service.refund(_token, widget.bookingId, value));
    if (!mounted) return;
    setState(() => _busy = false);
    if (message == null) return;
    _changed = true;
    _say(message);
    await _load();
  }

  Future<void> _markPaid() async {
    final booking = _booking!;
    var method = AppConstants.paymentMethods.contains(booking.paymentMethod) ? booking.paymentMethod : 'Cash';
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Mark ${rupees(booking.price)} paid'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How did the customer pay?'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final option in AppConstants.paymentMethods)
                    ChoiceChip(
                      label: Text(option),
                      selected: method == option,
                      onSelected: (_) => setLocal(() => method = option),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Mark paid')),
          ],
        ),
      ),
    );
    if (go != true || !mounted) return;
    await _act(
      _service.editBooking(_token, widget.bookingId, {'markPaid': true, 'paymentMethod': method}),
      'Marked paid',
    );
  }

  Future<void> _edit() async {
    final booking = _booking!;
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _EditSheet(booking: booking),
    );
    if (result == null || result.isEmpty || !mounted) return;
    await _act(_service.editBooking(_token, widget.bookingId, result), 'Booking updated');
  }

  Future<void> _whatsApp() async {
    final booking = _booking!;
    final digits = booking.mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return;
    final local = digits.substring(digits.length - 10);
    final text = Uri.encodeComponent(
      'Hi ${booking.customerName}, this is Car Clean Plus about your ${booking.service} on ${booking.date} (${booking.timeSlot}).',
    );
    final opened = await launchUrl(Uri.parse('https://wa.me/91$local?text=$text'), mode: LaunchMode.externalApplication);
    if (!opened && mounted) _say('Could not open WhatsApp');
  }

  void _openChat() {
    final booking = _booking!;
    context.push(Uri(
      path: '/desk/chat/${booking.id}',
      queryParameters: {'title': '${booking.customerName} · ${booking.service}'},
    ).toString());
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(booking == null ? 'Booking' : (booking.isBlocked ? 'Blocked slot' : _name(booking))),
          actions: [
            if (booking != null && (booking.isBlocked || (!booking.isPaid && !booking.isRefunded)))
              IconButton(
                tooltip: booking.isBlocked ? 'Unblock slot' : 'Delete',
                onPressed: _busy ? null : _delete,
                icon: Icon(booking.isBlocked ? Icons.lock_open_outlined : Icons.delete_outlined, size: 22),
              ),
          ],
        ),
        body: booking == null
            ? Center(
                child: _loading
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DeskEmpty(message: _error ?? 'Booking not found'),
                            TextButton(onPressed: _load, child: const Text('Retry')),
                          ],
                        ),
                      ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: booking.isBlocked ? _blockedBody(booking) : _body(booking),
                ),
              ),
      ),
    );
  }

  List<Widget> _blockedBody(BookingRecord booking) {
    return [
      _Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${booking.date} · ${booking.timeSlot}', style: deskTitle),
            const SizedBox(height: 6),
            Text(booking.city, style: deskBody),
            if (booking.instructions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(booking.instructions, style: deskCaption),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      _Button(icon: Icons.lock_open_outlined, label: 'Unblock this slot', onPressed: _busy ? null : _delete),
    ];
  }

  List<Widget> _body(BookingRecord booking) {
    final next = nextStatusAfter(booking.status);
    final canPay = !booking.isPaid && !booking.isRefunded && booking.status != 'cancelled' && booking.price > 0;
    return [
      _Sheet(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(_name(booking), style: deskTitle)),
                const SizedBox(width: 8),
                StatusPill(status: booking.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${booking.service} · ${sourceLabel(booking.source)}', style: deskBody),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(rupees(booking.price), style: deskHeadline.copyWith(fontSize: 22)),
                const SizedBox(width: 10),
                _PayTag(booking: booking),
              ],
            ),
            if (booking.collected > 0 && !booking.isPaid)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${rupees(booking.collected)} collected · ${rupees(booking.due)} due', style: deskCaption),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          if (booking.mobile.isNotEmpty) ...[
            Expanded(child: _Button(icon: Icons.phone_outlined, label: 'Call', onPressed: () => dialNumber(booking.mobile))),
            const SizedBox(width: 8),
            Expanded(child: _Button(icon: Icons.chat_outlined, label: 'WhatsApp', onPressed: _whatsApp)),
            const SizedBox(width: 8),
          ],
          Expanded(child: _Button(icon: Icons.forum_outlined, label: 'Chat', onPressed: _openChat)),
        ],
      ),
      const SizedBox(height: 12),
      _Sheet(
        child: Column(
          children: [
            _Fact(icon: Icons.calendar_today_outlined, label: 'When', value: '${shortDate(booking.date)} · ${_dash(booking.timeSlot)}'),
            _Fact(
              icon: booking.carCategory == 'Bike' ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
              label: 'Vehicle',
              value: [booking.carName, booking.carCategory].where((part) => part.trim().isNotEmpty).join(' · '),
            ),
            _Fact(
              icon: Icons.location_on_outlined,
              label: 'Address',
              value: [booking.address, booking.city].where((part) => part.trim().isNotEmpty).join(', '),
            ),
            _Fact(icon: Icons.phone_outlined, label: 'Phone', value: booking.mobile),
            _Fact(
              icon: Icons.payments_outlined,
              label: 'Payment',
              value: [booking.paymentMethod, booking.paymentStatus].where((part) => part.isNotEmpty).join(' · '),
            ),
            if (booking.instructions.isNotEmpty)
              _Fact(icon: Icons.notes_outlined, label: 'Notes', value: booking.instructions),
            if (booking.rating != null)
              _Fact(
                icon: Icons.star_outline,
                label: 'Rating',
                value: '${booking.rating}/5${booking.review.isEmpty ? '' : ' · ${booking.review}'}',
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (!booking.isClosed)
            _Button(icon: Icons.edit_calendar_outlined, label: 'Reschedule / edit', onPressed: _busy ? null : _edit),
          if (canPay) _Button(icon: Icons.check_circle_outline, label: 'Mark paid', onPressed: _busy ? null : _markPaid),
          if (booking.refundable > 0)
            _Button(icon: Icons.undo_outlined, label: 'Refund', onPressed: _busy ? null : _refund),
        ],
      ),
      if (!booking.isClosed) ...[
        const SizedBox(height: 16),
        _assignCard(booking),
      ],
      if (booking.beforePhoto.startsWith('data:image') || booking.afterPhoto.startsWith('data:image')) ...[
        const SizedBox(height: 12),
        _Sheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Photos', style: deskTitle),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Photo(value: booking.beforePhoto, label: 'Before')),
                  const SizedBox(width: 12),
                  Expanded(child: _Photo(value: booking.afterPhoto, label: 'After')),
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
              Text('Customer reports', style: deskTitle),
              for (final report in booking.reports) ...[
                const SizedBox(height: 12),
                if (report.byName.isNotEmpty) Text(report.byName, style: deskRow),
                if (report.note.isNotEmpty) Text(report.note, style: deskBody),
                if (report.image.startsWith('data:image'))
                  Padding(padding: const EdgeInsets.only(top: 8), child: _Photo(value: report.image, label: '')),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 16),
      Text('Status', style: deskTitle),
      const SizedBox(height: 12),
      StatusTree(
        status: booking.status,
        onNext: _busy || next == null ? null : () => _advance(next),
      ),
      if (!booking.isClosed) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: _Button(
            icon: Icons.cancel_outlined,
            label: 'Cancel this wash',
            color: AppConstants.danger,
            onPressed: _busy ? null : _cancel,
          ),
        ),
      ],
      if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
      if (booking.timeline.isNotEmpty) ...[
        const SizedBox(height: 20),
        Text('History', style: deskTitle),
        const SizedBox(height: 8),
        _Sheet(
          child: Column(
            children: [
              for (final step in booking.timeline.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(statusIcon(step.status), size: 20, color: statusTone(step.status).foreground),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(step.note.isNotEmpty ? step.note : prettyStatus(step.status), style: deskRow),
                            Text(
                              [whenText(step.at), if (step.byName.isNotEmpty) step.byName].join(' · '),
                              style: deskCaption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  Widget _assignCard(BookingRecord booking) {
    final current = booking.washerName.isNotEmpty ? booking.washerName : booking.assignedStaffName;
    return _Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconWell(icon: Icons.badge_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(current.isEmpty ? 'No washer yet' : current, style: deskTitle),
                    if (booking.washerPhone.isNotEmpty) Text(booking.washerPhone, style: deskCaption),
                  ],
                ),
              ),
              if (booking.washerPhone.isNotEmpty)
                IconButton(
                  tooltip: 'Call washer',
                  onPressed: () => dialNumber(booking.washerPhone),
                  icon: const Icon(Icons.phone_outlined),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_staff.isEmpty)
            Text('Add a washer under People before assigning a job.', style: deskBody)
          else ...[
            DropdownButtonFormField<String>(
              key: ValueKey('staff-${booking.assignedStaffId}-${_staff.length}'),
              initialValue: _staff.any((user) => user.id == _staffId) ? _staffId : null,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Washer', prefixIcon: Icon(Icons.person_outline, size: 22)),
              items: [
                for (final user in _staff)
                  DropdownMenuItem(
                    value: user.id,
                    child: Text(
                      '${user.name.isEmpty ? user.email : user.name}${user.onShift ? ' · on shift' : ' · off shift'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _staffId = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || _staffId == null || _staffId == booking.assignedStaffId ? null : _assign,
                icon: const Icon(Icons.person_add_outlined, size: 22),
                label: Text(booking.isAssigned ? 'Move to this washer' : 'Assign washer'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _name(BookingRecord booking) => booking.customerName.trim().isEmpty ? 'Booking' : booking.customerName.trim();

String _dash(String value) => value.trim().isEmpty ? '—' : value.trim();

/// Date, slot, price and notes. Returns only the fields that changed.
class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.booking});

  final BookingRecord booking;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late DateTime _date;
  late String _slot;
  late final TextEditingController _price;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final booking = widget.booking;
    _date = DateTime.tryParse(booking.date) ?? DateTime.now();
    _slot = AppConstants.timeSlots.contains(booking.timeSlot) ? booking.timeSlot : AppConstants.timeSlots.first;
    _price = TextEditingController(text: '${booking.price.round()}');
    _notes = TextEditingController(text: booking.instructions);
  }

  @override
  void dispose() {
    _price.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      initialDate: _date.isBefore(today) ? today : _date,
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final booking = widget.booking;
    final body = <String, dynamic>{};
    final date = formatYmd(_date);
    if (date != booking.date || _slot != booking.timeSlot) {
      body['date'] = date;
      body['timeSlot'] = _slot;
    }
    final price = num.tryParse(_price.text.trim());
    if (price != null && price != booking.price) body['finalPrice'] = price;
    if (_notes.text.trim() != booking.instructions.trim()) body['instructions'] = _notes.text.trim();
    Navigator.pop(context, body);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit booking', style: deskTitle),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined, size: 20),
              label: Text(formatYmd(_date)),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), alignment: Alignment.centerLeft),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _slot,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Slot', prefixIcon: Icon(Icons.schedule_outlined, size: 22)),
              items: [for (final slot in AppConstants.timeSlots) DropdownMenuItem(value: slot, child: Text(slot))],
              onChanged: (value) => setState(() => _slot = value ?? _slot),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: 'Price', prefixText: '₹ ', prefixIcon: Icon(Icons.currency_rupee_outlined, size: 22)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(labelText: 'Notes for the washer', prefixIcon: Icon(Icons.notes_outlined, size: 22)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: const StadiumBorder()),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayTag extends StatelessWidget {
  const _PayTag({required this.booking});

  final BookingRecord booking;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = booking.isRefunded
        ? ('Refunded ${rupees(booking.refundAmount)}', const StatusTone(AppConstants.danger, AppConstants.dangerBg))
        : booking.isPaid
            ? ('Paid', const StatusTone(AppConstants.completed, AppConstants.completedBg))
            : ('Unpaid', const StatusTone(AppConstants.pending, AppConstants.pendingBg));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: deskCaption.copyWith(color: tone.foreground, fontWeight: FontWeight.w700)),
    );
  }
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

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconWell(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: deskCaption),
                const SizedBox(height: 2),
                Text(_dash(value), style: deskBody),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.icon, required this.label, required this.onPressed, this.color = AppConstants.accent});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        minimumSize: const Size(0, 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: const StadiumBorder(),
        side: BorderSide(color: color == AppConstants.accent ? AppConstants.line : color),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final comma = value.indexOf(',');
    if (!value.startsWith('data:image') || comma < 0) {
      return label.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: deskRow),
                const SizedBox(height: 8),
                Text('Not taken yet', style: deskCaption),
              ],
            );
    }
    Widget image;
    try {
      image = Image.memory(
        base64Decode(value.substring(comma + 1)),
        height: 160,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 160, child: Icon(Icons.broken_image_outlined)),
      );
    } catch (_) {
      image = const SizedBox(height: 160, child: Icon(Icons.broken_image_outlined));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[Text(label, style: deskRow), const SizedBox(height: 8)],
        ClipRRect(borderRadius: BorderRadius.circular(12), child: image),
      ],
    );
  }
}

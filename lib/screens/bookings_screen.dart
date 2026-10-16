import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

/// The desk's booking list: search, one row of filter chips, compact cards.
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  List<BookingRecord> _bookings = [];
  bool _loading = true;
  String _query = '';
  String _status = '';
  String _payment = '';
  String _date = '';
  bool _unassigned = false;
  String? _routeKey;

  static const _statusChips = <(String, String)>[
    ('', 'All'),
    ('pending', 'Pending'),
    ('confirmed', 'Confirmed'),
    ('accepted', 'Accepted'),
    ('on_the_way', 'On the way'),
    ('in_progress', 'Washing'),
    ('completed', 'Done'),
    ('cancelled', 'Cancelled'),
    ('blocked', 'Blocked'),
    ('lead', 'Unfinished'),
  ];

  static const _payments = ['Cash', 'UPI', 'Online'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final key = '${params['status'] ?? ''}|${params['date'] ?? ''}|${params['unassigned'] ?? ''}';
    if (key == _routeKey) return;
    _routeKey = key;
    _status = params['status'] ?? '';
    _date = params['date'] ?? '';
    _unassigned = params['unassigned'] == '1';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final query = <String, String>{
      if (_status.isNotEmpty) 'status': _status,
      if (_payment.isNotEmpty) 'payment': _payment,
      if (_date.isNotEmpty) 'date': _date,
      if (_unassigned) 'unassigned': '1',
    };
    final list = await runGuarded(
      context,
      context.read<AdminService>().bookings(
            token,
            query: query.isEmpty ? '' : '?${Uri(queryParameters: query).query}',
          ),
    );
    if (!mounted) return;
    setState(() {
      if (list != null) _bookings = list;
      _loading = false;
    });
  }

  List<BookingRecord> get _visible {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _bookings;
    return _bookings.where((booking) {
      final haystack = [
        booking.customerName,
        booking.mobile,
        booking.service,
        booking.date,
        booking.timeSlot,
        booking.status,
        booking.city,
        booking.washerName,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  void _setStatus(String value) {
    if (value == _status) return;
    setState(() => _status = value);
    _load();
  }

  Future<void> _pickPayment() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final option in ['', ..._payments])
              ListTile(
                leading: Icon(
                  option == _payment ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: AppConstants.accent,
                ),
                title: Text(option.isEmpty ? 'Any payment' : option),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == _payment || !mounted) return;
    setState(() => _payment = picked);
    _load();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? now,
      firstDate: DateTime(2024),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = formatYmd(picked));
    _load();
  }

  Future<void> _openPath(String path) async {
    final saved = await context.push<bool>(path);
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final filtered = _status.isNotEmpty || _payment.isNotEmpty || _date.isNotEmpty || _unassigned || _query.isNotEmpty;
    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              style: deskBody,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search name, phone or washer',
                prefixIcon: const Icon(Icons.search, size: 22, color: AppConstants.muted),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppConstants.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppConstants.line),
                ),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              children: [
                _Chip(
                  icon: Icons.person_off_outlined,
                  label: 'No washer',
                  selected: _unassigned,
                  warn: true,
                  onTap: () {
                    setState(() => _unassigned = !_unassigned);
                    _load();
                  },
                ),
                _Chip(
                  icon: Icons.calendar_today_outlined,
                  label: _date.isEmpty ? 'Any date' : _shortDay(_date),
                  selected: _date.isNotEmpty,
                  onTap: _pickDate,
                  onClear: _date.isEmpty
                      ? null
                      : () {
                          setState(() => _date = '');
                          _load();
                        },
                ),
                _Chip(
                  icon: Icons.payments_outlined,
                  label: _payment.isEmpty ? 'Payment' : _payment,
                  selected: _payment.isNotEmpty,
                  onTap: _pickPayment,
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  color: AppConstants.line,
                ),
                for (final chip in _statusChips)
                  _Chip(label: chip.$2, selected: _status == chip.$1, onTap: () => _setStatus(chip.$1)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loading ? 'Loading…' : '${visible.length} ${visible.length == 1 ? 'booking' : 'bookings'}',
                    style: deskCaption.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (filtered)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _status = '';
                        _payment = '';
                        _date = '';
                        _unassigned = false;
                      });
                      _load();
                    },
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading && _bookings.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: visible.isEmpty ? 1 : visible.length,
                      itemBuilder: (context, index) {
                        if (visible.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: DeskEmpty(message: 'No bookings match these filters.'),
                          );
                        }
                        final booking = visible[index];
                        Future<void> open() async {
                          if (await openBooking(context, booking.id, initial: booking)) _load();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: booking.isBlocked
                              ? _BlockedRow(booking: booking, onTap: open)
                              : _BookingCard(booking: booking, onTap: open),
                        );
                      },
                    ),
            ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppConstants.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openPath('/desk/block'),
                      icon: const Icon(Icons.event_busy_outlined, size: 20),
                      label: const Text('Block slot'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: const StadiumBorder(),
                        side: const BorderSide(color: AppConstants.line),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openPath('/desk/phone'),
                      icon: const Icon(Icons.add_ic_call_outlined, size: 20),
                      label: const Text('Phone booking'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Slot 2 – 10:00 AM" → "10:00 AM".
String _slotTime(String slot) {
  final parts = slot.split(RegExp(r'\s[–-]\s'));
  return parts.length > 1 ? parts.last.trim() : slot.trim();
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

DateTime? _parseDay(String raw) {
  final iso = DateTime.tryParse(raw);
  if (iso != null) return iso;
  final dmy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$').firstMatch(raw.trim());
  if (dmy == null) return null;
  return DateTime(int.parse(dmy[3]!), int.parse(dmy[2]!), int.parse(dmy[1]!));
}

/// "Today", "Tomorrow", or "12 Oct".
String _shortDay(String raw) {
  final day = _parseDay(raw);
  if (day == null) return raw;
  final today = DateUtils.dateOnly(DateTime.now());
  final diff = DateUtils.dateOnly(day).difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  return '${day.day} ${_months[day.month - 1]}';
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.onClear,
    this.warn = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final VoidCallback? onClear;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    final active = warn ? AppConstants.pending : AppConstants.accent;
    final fg = selected ? Colors.white : AppConstants.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? active : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? active : AppConstants.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(icon == null ? 14 : 10, 0, onClear == null ? 14 : 4, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: selected ? Colors.white : AppConstants.muted),
                  const SizedBox(width: 6),
                ],
                Text(label, style: deskCaption.copyWith(color: fg, fontWeight: FontWeight.w700, fontSize: 13)),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    icon: Icon(Icons.close, size: 16, color: fg),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final BookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = booking.customerName.trim().isEmpty ? 'Customer' : booking.customerName.trim();
    final vehicle = [booking.service, booking.carName].where((part) => part.trim().isNotEmpty).join(' · ');
    final needsWasher = booking.washerName.isEmpty && !booking.isClosed;
    final tone = statusTone(booking.status);
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: tone.foreground),
              Container(
                width: 72,
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: tone.background.withValues(alpha: 0.45),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortDay(booking.date),
                      textAlign: TextAlign.center,
                      style: deskRow.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _slotTime(booking.timeSlot),
                      textAlign: TextAlign.center,
                      style: deskCaption.copyWith(color: AppConstants.ink),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: deskRow.copyWith(fontSize: 15)),
                          ),
                          const SizedBox(width: 8),
                          Text(rupees(booking.price), style: deskRow.copyWith(fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        vehicle.isEmpty ? '—' : vehicle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: deskCaption.copyWith(fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Tag(label: prettyStatus(booking.status), tone: tone),
                          const SizedBox(width: 6),
                          _Tag(
                            label: booking.isRefunded ? 'Refunded' : (booking.isPaid ? 'Paid' : 'Unpaid'),
                            tone: booking.isPaid
                                ? const StatusTone(AppConstants.completed, AppConstants.completedBg)
                                : const StatusTone(AppConstants.muted, Color(0xFFF1F3F6)),
                          ),
                          const Spacer(),
                          Text(sourceLabel(booking.source), style: deskCaption),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            needsWasher ? Icons.person_off_outlined : Icons.badge_outlined,
                            size: 16,
                            color: needsWasher ? AppConstants.pending : AppConstants.muted,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              needsWasher
                                  ? 'Needs a washer'
                                  : (booking.washerName.isEmpty ? 'No washer' : booking.washerName),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: deskCaption.copyWith(
                                fontSize: 13,
                                color: needsWasher ? AppConstants.pending : AppConstants.ink,
                                fontWeight: needsWasher ? FontWeight.w700 : FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A closed slot: one quiet line, not a full booking card.
class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.booking, required this.onTap});

  final BookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reason = booking.customerName.replaceFirst('[BLOCKED]', '').trim();
    return Material(
      color: const Color(0xFFF1F3F6),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppConstants.muted),
              const SizedBox(width: 10),
              Text(
                '${_shortDay(booking.date)} · ${_slotTime(booking.timeSlot)}',
                style: deskRow.copyWith(fontSize: 13),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason.isEmpty ? 'Slot blocked' : reason,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deskCaption.copyWith(fontSize: 13),
                ),
              ),
              const Icon(Icons.chevron_right, size: 20, color: AppConstants.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: deskCaption.copyWith(color: tone.foreground, fontWeight: FontWeight.w700, fontSize: 11),
      ),
    );
  }
}

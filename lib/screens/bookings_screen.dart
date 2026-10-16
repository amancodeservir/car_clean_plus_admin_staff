import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

const _ink14 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w700,
  color: AppConstants.ink,
);

const _body14 = TextStyle(fontSize: 14, color: AppConstants.ink);

const _muted14 = TextStyle(
  fontSize: 14,
  color: AppConstants.muted,
  height: 1.25,
);

const _label12 = TextStyle(fontSize: 12, color: AppConstants.muted);

const _source12 = TextStyle(
  fontSize: 12,
  fontWeight: FontWeight.w700,
  color: AppConstants.accent,
);

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

  static const _payments = ['Cash', 'UPI', 'Online', 'Pending', 'N/A'];

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
    final list = await runGuarded(
      context,
      context.read<AdminService>().bookings(
        token,
        query:
            '?status=${Uri.encodeQueryComponent(_status)}&payment=${Uri.encodeQueryComponent(_payment)}&date=${Uri.encodeQueryComponent(_date)}${_unassigned ? '&unassigned=1' : ''}',
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
        booking.source,
        booking.city,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  Future<void> _openPath(String path) async {
    final saved = await context.push<bool>(path);
    if (saved == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _FilterBlock(
              status: _status,
              payment: _payment,
              payments: _payments,
              onQuery: (value) => setState(() => _query = value),
              onStatus: (value) {
                _status = value ?? '';
                _load();
              },
              onPayment: (value) {
                _payment = value ?? '';
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                FilterChip(
                  label: const Text('No washer yet'),
                  selected: _unassigned,
                  onSelected: (value) {
                    setState(() => _unassigned = value);
                    _load();
                  },
                ),
                if (_date.isNotEmpty)
                  InputChip(
                    label: Text('Wash date $_date'),
                    onDeleted: () {
                      setState(() => _date = '');
                      _load();
                    },
                  ),
                if (!_loading)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('${visible.length} shown', style: deskCaption),
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
                          return const DeskEmpty(message: 'No bookings match.');
                        }
                        final booking = visible[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(
                            booking: booking,
                            onTap: () async {
                              if (await openBooking(context, booking.id, initial: booking)) _load();
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1, color: AppConstants.line),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: _BarButton(
                    icon: Icons.event_busy_outlined,
                    label: 'Block slot',
                    onPressed: () => _openPath('/desk/block'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BarButton(
                    icon: Icons.add_ic_call_outlined,
                    label: 'Phone booking',
                    onPressed: () => _openPath('/desk/phone'),
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

class _FilterBlock extends StatelessWidget {
  const _FilterBlock({
    required this.status,
    required this.payment,
    required this.payments,
    required this.onQuery,
    required this.onStatus,
    required this.onPayment,
  });

  final String status;
  final String payment;
  final List<String> payments;
  final ValueChanged<String> onQuery;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onPayment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              style: _body14,
              decoration: _plainField(
                icon: Icons.search_outlined,
                hint: 'Search name, phone, date, status',
              ),
              onChanged: onQuery,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('status-$status'),
                    initialValue: status,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: 22,
                      color: AppConstants.muted,
                    ),
                    style: _ink14,
                    decoration: _plainField(
                      icon: Icons.flag_outlined,
                      label: 'Status',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(
                          'All statuses',
                          overflow: TextOverflow.ellipsis,
                          style: _ink14,
                        ),
                      ),
                      for (final item in AppConstants.statuses)
                        DropdownMenuItem(
                          value: item,
                          child: Text(
                            prettyStatus(item),
                            overflow: TextOverflow.ellipsis,
                            style: _ink14,
                          ),
                        ),
                    ],
                    onChanged: onStatus,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('payment-$payment'),
                    initialValue: payment,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_outlined,
                      size: 22,
                      color: AppConstants.muted,
                    ),
                    style: _ink14,
                    decoration: _plainField(
                      icon: Icons.payments_outlined,
                      label: 'Payment',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text(
                          'All payments',
                          overflow: TextOverflow.ellipsis,
                          style: _ink14,
                        ),
                      ),
                      for (final item in payments)
                        DropdownMenuItem(
                          value: item,
                          child: Text(
                            item,
                            overflow: TextOverflow.ellipsis,
                            style: _ink14,
                          ),
                        ),
                    ],
                    onChanged: onPayment,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const _controlRadius = BorderRadius.all(Radius.circular(16));

InputDecoration _plainField({
  required IconData icon,
  String? label,
  String? hint,
}) {
  const border = OutlineInputBorder(
    borderRadius: _controlRadius,
    borderSide: BorderSide(color: AppConstants.line),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: _label12,
    floatingLabelStyle: _label12,
    hintStyle: _muted14,
    prefixIcon: Icon(icon, size: 22, color: AppConstants.accent),
    filled: true,
    fillColor: AppConstants.paper,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border,
    enabledBorder: border,
    focusedBorder: const OutlineInputBorder(
      borderRadius: _controlRadius,
      borderSide: BorderSide(color: AppConstants.accent, width: 1.5),
    ),
  );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.onTap});

  final BookingRecord booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = booking.customerName.isEmpty
        ? booking.service
        : booking.customerName;
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppConstants.line),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeskPhoto(
                asset: washAssetFor(booking.service),
                height: 64,
                width: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? 'Booking' : title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ink14,
                    ),
                    const SizedBox(height: 2),
                    Text(sourceLabel(booking.source), style: _source12),
                    const SizedBox(height: 6),
                    _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      text: '${booking.date} · ${booking.timeSlot}',
                    ),
                    const SizedBox(height: 4),
                    _MetaLine(
                      icon: Icons.directions_car_outlined,
                      text: booking.service,
                    ),
                    if (!booking.isBlocked) ...[
                      const SizedBox(height: 4),
                      _MetaLine(
                        icon: Icons.badge_outlined,
                        text: booking.washerName.isNotEmpty
                            ? booking.washerName
                            : (booking.isClosed ? '—' : 'No washer yet'),
                        warn: booking.washerName.isEmpty && !booking.isClosed,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusPill(status: booking.status),
                  if (!booking.isBlocked) ...[
                    const SizedBox(height: 8),
                    Text(rupees(booking.price), style: _ink14),
                    Text(
                      booking.isRefunded ? 'Refunded' : (booking.isPaid ? 'Paid' : 'Unpaid'),
                      style: _label12.copyWith(
                        color: booking.isPaid ? AppConstants.completed : AppConstants.pending,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text, this.warn = false});

  final IconData icon;
  final String text;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: warn ? AppConstants.pending : AppConstants.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: warn ? _muted14.copyWith(color: AppConstants.pending, fontWeight: FontWeight.w700) : _muted14,
          ),
        ),
      ],
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppConstants.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 22, color: Colors.white),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

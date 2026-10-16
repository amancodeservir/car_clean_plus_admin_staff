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
  String? _routeKey;

  static const _payments = ['Cash', 'UPI', 'Online', 'Pending', 'N/A'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final params = GoRouterState.of(context).uri.queryParameters;
    final key = '${params['status'] ?? ''}|${params['date'] ?? ''}';
    if (key == _routeKey) return;
    _routeKey = key;
    _status = params['status'] ?? '';
    _date = params['date'] ?? '';
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
            '?status=${Uri.encodeQueryComponent(_status)}&payment=${Uri.encodeQueryComponent(_payment)}&date=${Uri.encodeQueryComponent(_date)}',
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
          if (_date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Wash date $_date', style: deskCaption.copyWith(color: AppConstants.accent, fontWeight: FontWeight.w700)),
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
                              final changed = await context.push<bool>(
                                '/desk/booking',
                                extra: booking,
                              );
                              if (changed == true) _load();
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(status: booking.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppConstants.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _muted14,
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

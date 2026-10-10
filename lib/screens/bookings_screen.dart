import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

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

  static const _payments = ['Cash', 'UPI', 'Online', 'Pending', 'N/A'];

  @override
  void initState() {
    super.initState();
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
                '?status=${Uri.encodeQueryComponent(_status)}&payment=${Uri.encodeQueryComponent(_payment)}',
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_outlined, size: 20),
                hintText: 'Search name, phone, date, status',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('status-$_status'),
                    initialValue: _status,
                    isExpanded: true,
                    decoration: _filterField('Status', Icons.flag_outlined),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All statuses')),
                      for (final status in AppConstants.statuses)
                        DropdownMenuItem(
                          value: status,
                          child: Text(prettyStatus(status), overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      _status = value ?? '';
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('payment-$_payment'),
                    initialValue: _payment,
                    isExpanded: true,
                    decoration: _filterField('Payment', Icons.payments_outlined),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('All payments')),
                      for (final payment in _payments)
                        DropdownMenuItem(value: payment, child: Text(payment)),
                    ],
                    onChanged: (value) {
                      _payment = value ?? '';
                      _load();
                    },
                  ),
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
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: visible.isEmpty ? 1 : visible.length,
                      itemBuilder: (context, index) {
                        if (visible.isEmpty) {
                          return const DeskEmpty(message: 'No bookings match.');
                        }
                        final booking = visible[index];
                        final title = booking.customerName.isEmpty
                            ? booking.service
                            : booking.customerName;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeskCard(
                            onTap: () async {
                              final changed = await context.push<bool>(
                                '/desk/booking',
                                extra: booking,
                              );
                              if (changed == true) _load();
                            },
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
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: AppConstants.ink,
                                        ),
                                      ),
                                      Text(
                                        sourceLabel(booking.source),
                                        style: const TextStyle(
                                          color: AppConstants.accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today_outlined,
                                            size: 20,
                                            color: AppConstants.accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              '${booking.date} · ${booking.timeSlot}',
                                              style: const TextStyle(
                                                color: AppConstants.muted,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.directions_car_outlined,
                                            size: 20,
                                            color: AppConstants.accent,
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              booking.service,
                                              style: const TextStyle(
                                                color: AppConstants.ink,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusPill(status: booking.status),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'block',
            onPressed: () => _openPath('/desk/block'),
            icon: const Icon(Icons.event_busy_outlined, size: 20),
            label: const Text('Block slot'),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'phone',
            onPressed: () => _openPath('/desk/phone'),
            icon: const Icon(Icons.add_ic_call_outlined, size: 20),
            label: const Text('Phone booking'),
          ),
        ],
      ),
    );
  }
}

InputDecoration _filterField(String label, IconData icon) {
  return InputDecoration(
    labelText: label,
    isDense: true,
    prefixIcon: Icon(icon, size: 20),
  );
}

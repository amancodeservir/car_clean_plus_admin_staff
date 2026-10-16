import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<LedgerEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final items = await runGuarded(
      context,
      context.read<AdminService>().transactions(token),
    );
    if (!mounted) return;
    setState(() {
      if (items != null) _items = items;
      _loading = false;
    });
  }

  Future<void> _open(LedgerEntry entry) async {
    if (entry.bookingId.isEmpty) return;
    if (await openBooking(context, entry.bookingId) && mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    // The ledger holds a payment row for every priced booking; only rows
    // that were actually paid count as money taken.
    final payments = _items.where((item) => !item.isRefund && _received(item));
    final owed = _items.where(
      (item) => !item.isRefund && !_received(item) && item.bookingStatus != 'cancelled',
    );
    final refunds = _items.where((item) => item.isRefund);
    final taken = payments.fold<num>(0, (sum, item) => sum + item.amount);
    final due = owed.fold<num>(0, (sum, item) => sum + item.amount);
    final returned = refunds.fold<num>(0, (sum, item) => sum + item.amount);
    return Scaffold(
      appBar: AppBar(title: Text('Transactions', style: deskTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  _NetCard(taken: taken, returned: returned, due: due),
                  const SizedBox(height: 14),
                  Text('All transactions', style: deskTitle),
                  const SizedBox(height: 10),
                  if (_items.isEmpty)
                    const DeskEmpty(message: 'No transactions yet.')
                  else
                    for (final item in _items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TransactionRow(
                          entry: item,
                          busy: false,
                          onTap: () => _open(item),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _NetCard extends StatelessWidget {
  const _NetCard({required this.taken, required this.returned, required this.due});

  final num taken;
  final num returned;
  final num due;

  @override
  Widget build(BuildContext context) {
    final net = taken - returned;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConstants.accent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Net recorded', style: deskCaption.copyWith(color: Colors.white70)),
          const SizedBox(height: 4),
          Text('₹${_money(net)}', style: deskHeadline.copyWith(color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Paid ₹${_money(taken)} · Refunds ₹${_money(returned)} · Still due ₹${_money(due)}',
            style: deskCaption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.entry, required this.onTap, required this.busy});

  final LedgerEntry entry;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final title = entry.customerName.isEmpty ? entry.service : entry.customerName;
    final detail = [
      if (entry.service.isNotEmpty) entry.service,
      if (entry.date.isNotEmpty) entry.date,
      if (entry.method.isNotEmpty) entry.method,
    ].join(' · ');
    final amountColor = entry.isRefund ? AppConstants.danger : AppConstants.accent;
    final sign = entry.isRefund ? '−' : '';
    return DeskCard(
      onTap: onTap,
      child: Row(
        children: [
          IconWell(icon: entry.isRefund ? Icons.undo_outlined : Icons.currency_rupee),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Transaction' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deskRow,
                ),
                const SizedBox(height: 2),
                Text(
                  detail.isEmpty ? (entry.isRefund ? 'Refund' : 'Payment') : detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deskCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign₹${_money(entry.amount)}',
                  style: deskRow.copyWith(color: amountColor),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.isRefund ? 'Refund' : _payLabel(entry.paymentStatus),
                  style: deskCaption,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

String _payLabel(String status) {
  final value = status.trim();
  if (value.isEmpty) return 'Pending';
  return value[0].toUpperCase() + value.substring(1);
}

String _money(num value) {
  final whole = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    if (index > 0 && remaining % 3 == 0) buffer.write(',');
    buffer.write(whole[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

bool _received(LedgerEntry entry) {
  final status = entry.paymentStatus.toLowerCase();
  return status == 'paid' || status == 'refunded';
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final stats = await runGuarded(
      context,
      context.read<AdminService>().dashboard(token),
    );
    if (!mounted) return;
    setState(() {
      _stats = stats ?? _stats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          Text('Dashboard', style: deskTitle),
          const SizedBox(height: 10),
          if (_loading && stats == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stats == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Text(
                'Dashboard could not be loaded.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConstants.muted, fontSize: 14),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.event_note_outlined,
                    label: 'Bookings',
                    value: '${stats.totalBookings}',
                    background: AppConstants.accent,
                    foreground: Colors.white,
                    well: const Color(0x33FFFFFF),
                    iconColor: Colors.white,
                    onTap: () => _openBookings(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.hourglass_bottom_outlined,
                    label: 'Pending',
                    value: '${stats.pendingBookings}',
                    background: const Color(0xFFDBEAFE),
                    foreground: const Color(0xFF1E3A8A),
                    well: Colors.white,
                    iconColor: AppConstants.accent,
                    onTap: () => _openBookings(context, status: 'pending'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.currency_rupee_outlined,
                    label: 'Revenue',
                    value: '₹${_grouped(stats.totalRevenue)}',
                    background: const Color(0xFF1E40AF),
                    foreground: Colors.white,
                    well: const Color(0x33FFFFFF),
                    iconColor: Colors.white,
                    onTap: () => context.push('/desk/transactions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    icon: Icons.mail_outlined,
                    label: 'Enquiries',
                    value: '${stats.totalInquiries}',
                    background: const Color(0xFFEFF6FF),
                    foreground: AppConstants.ink,
                    well: Colors.white,
                    iconColor: AppConstants.accent,
                    onTap: () => context.push('/desk/contacts'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _WeekChart(
              points: _weekPoints(stats),
              onDay: (date) => _openBookings(context, date: date),
            ),
            const SizedBox(height: 12),
            _StatusChart(
              counts: _statusCounts(stats),
              onStatus: (status) => _openBookings(context, status: status),
            ),
            const SizedBox(height: 16),
            Text('Recent bookings', style: deskTitle),
            const SizedBox(height: 10),
            if (stats.recentBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text(
                  'No bookings yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConstants.muted, fontSize: 14),
                ),
              )
            else
              ...stats.recentBookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BookingRow(
                    booking: booking,
                    onTap: booking.id.isEmpty
                        ? null
                        : () {
                            context.push('/desk/booking', extra: booking);
                          },
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

void _openBookings(BuildContext context, {String status = '', String date = ''}) {
  context.go(Uri(path: '/bookings', queryParameters: {
    if (status.isNotEmpty) 'status': status,
    if (date.isNotEmpty) 'date': date,
  }).toString());
}

String _grouped(num value) {
  final whole = value.round().abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < whole.length; index++) {
    final remaining = whole.length - index;
    if (index > 0 && remaining % 3 == 0) buffer.write(',');
    buffer.write(whole[index]);
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}

List<WeekPoint> _weekPoints(DashboardStats stats) {
  final week = stats.week;
  if (week != null && week.isNotEmpty) return week;
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
  final points = List.generate(7, (index) {
    final day = start.add(Duration(days: index));
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return WeekPoint(date: key, count: 0, revenue: 0);
  });
  for (final booking in stats.recentBookings) {
    final index = points.indexWhere((point) => point.date == booking.date);
    if (index < 0) continue;
    final current = points[index];
    points[index] = WeekPoint(date: current.date, count: current.count + 1, revenue: current.revenue);
  }
  return points;
}

Map<String, int> _statusCounts(DashboardStats stats) {
  final incoming = stats.statusCounts;
  if (incoming != null && incoming.isNotEmpty) return incoming;
  final counts = <String, int>{};
  for (final booking in stats.recentBookings) {
    final status = booking.status.isEmpty ? 'pending' : booking.status;
    counts[status] = (counts[status] ?? 0) + 1;
  }
  return counts;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
    required this.well,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final Color well;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: well, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: deskIconSize, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: deskHeadline.copyWith(color: foreground),
          ),
          const SizedBox(height: 2),
          Text(label, style: deskCaption.copyWith(color: foreground.withValues(alpha: 0.8))),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.points, required this.onDay});

  final List<WeekPoint> points;
  final ValueChanged<String> onDay;

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold<int>(0, (max, point) => point.count > max ? point.count : max);
    final peak = maxCount == 0 ? 1 : maxCount;
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days', style: deskTitle),
          const SizedBox(height: 2),
          Text('Bookings by wash date', style: deskCaption),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final point in points)
                  Expanded(
                    child: InkWell(
                      onTap: point.date.isEmpty ? null : () => onDay(point.date),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            point.count == 0 ? '' : '${point.count}',
                            style: deskCaption.copyWith(color: AppConstants.accent, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: point.count == 0 ? 0.08 : point.count / peak,
                                widthFactor: 1,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: point.count == 0 ? const Color(0xFFDBEAFE) : AppConstants.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_dayLabel(point.date), style: deskCaption),
                        ],
                      ),
                    ),
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

String _dayLabel(String date) {
  final parsed = DateTime.tryParse(date);
  if (parsed == null) return '';
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return names[parsed.weekday - 1];
}

class _StatusChart extends StatelessWidget {
  const _StatusChart({required this.counts, required this.onStatus});

  final Map<String, int> counts;
  final ValueChanged<String> onStatus;

  static const _order = [
    'pending',
    'confirmed',
    'accepted',
    'on_the_way',
    'in_progress',
    'completed',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (final status in _order)
        if ((counts[status] ?? 0) > 0) (status, counts[status]!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    final peak = rows.fold<int>(0, (max, row) => row.$2 > max ? row.$2 : max);
    return _WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('By status', style: deskTitle),
          const SizedBox(height: 12),
          for (final row in rows) ...[
            InkWell(
              onTap: () => onStatus(row.$1),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
              children: [
                SizedBox(width: 92, child: Text(prettyStatus(row.$1), style: deskCaption.copyWith(color: AppConstants.ink))),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: row.$2 / peak,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFEFF6FF),
                      color: statusTone(row.$1).foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 28,
                  child: Text(
                    '${row.$2}',
                    textAlign: TextAlign.end,
                    style: deskCaption.copyWith(color: AppConstants.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onTap});

  final BookingRecord booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final title = booking.customerName.isEmpty ? booking.service : booking.customerName;
    return _WhiteCard(
      onTap: onTap,
      child: Row(
        children: [
          const IconWell(icon: Icons.event_note_outlined),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Booking' : title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deskRow,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sourceLabel(booking.source)} · ${booking.date} · ${booking.timeSlot}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: deskCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _StatusPill(status: booking.status),
        ],
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  const _WhiteCard({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.line),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

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
        style: deskCaption.copyWith(color: tone.foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}

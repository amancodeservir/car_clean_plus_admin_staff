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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
        children: [
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppConstants.ink,
            ),
          ),
          const SizedBox(height: 10),
          if (_loading && stats == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (stats == null)
            const Text('Dashboard could not be loaded.')
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      width: width,
                      icon: Icons.event_note_outlined,
                      label: 'Bookings',
                      value: '${stats.totalBookings}',
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.hourglass_bottom_outlined,
                      label: 'Pending',
                      value: '${stats.pendingBookings}',
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.currency_rupee_outlined,
                      label: 'Revenue',
                      value: '₹${stats.totalRevenue}',
                    ),
                    _StatCard(
                      width: width,
                      icon: Icons.mail_outlined,
                      label: 'Enquiries',
                      value: '${stats.totalInquiries}',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Recent bookings',
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppConstants.ink),
            ),
            const SizedBox(height: 8),
            if (stats.recentBookings.isEmpty)
              const DeskEmpty(message: 'No bookings yet.')
            else
              ...stats.recentBookings.map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: DeskCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppConstants.accent),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: AppConstants.muted, fontSize: 12, fontWeight: FontWeight.w400)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppConstants.ink,
              ),
            ),
          ],
        ),
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
    return DeskCard(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.isEmpty ? 'Booking' : title,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppConstants.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  '${sourceLabel(booking.source)} · ${booking.date} · ${booking.timeSlot}',
                  style: const TextStyle(color: AppConstants.muted, fontSize: 12, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(status: booking.status),
        ],
      ),
    );
  }
}

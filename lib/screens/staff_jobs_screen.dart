import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/screen_guard.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';
import '../theme/desk_theme.dart';

class StaffJobsScreen extends StatefulWidget {
  const StaffJobsScreen({super.key});

  @override
  State<StaffJobsScreen> createState() => _StaffJobsScreenState();
}

class _StaffJobsScreenState extends State<StaffJobsScreen> {
  List<BookingRecord> _jobs = [];
  bool _loading = true;
  bool _busy = false;
  int _dayOffset = 0;
  bool _onShift = false;

  static const _next = {
    'pending': 'accepted',
    'confirmed': 'accepted',
    'accepted': 'on_the_way',
    'on_the_way': 'in_progress',
    'in_progress': 'completed',
  };

  @override
  void initState() {
    super.initState();
    _onShift = context.read<AuthProvider>().account?.onShift ?? false;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final token = context.read<AuthProvider>().token;
    final jobs = await runGuarded(
      context,
      context.read<AdminService>().staffJobs(
            token,
            date: _dayOffset == 2 ? null : indiaYmd(dayOffset: _dayOffset),
            upcoming: _dayOffset == 2,
          ),
    );
    if (!mounted) return;
    setState(() {
      if (jobs != null) _jobs = jobs;
      _loading = false;
    });
  }

  Future<void> _advance(BookingRecord job) async {
    final next = _next[job.status];
    if (next == null || _busy) return;
    if (next == 'accepted' && !_onShift) {
      _note('Turn on shift before accepting a job');
      return;
    }
    if (next == 'completed' && job.due > 0 && job.paymentStatus.toLowerCase() != 'paid') {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment still due'),
          content: Text('₹${_whole(job.due)} is not collected yet. Tap Collected first if the customer paid you.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Go back')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Finish anyway')),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    final token = context.read<AuthProvider>().token;
    setState(() => _busy = true);
    final ok = await runOk(
      context,
      context.read<AdminService>().updateStaffJob(token, job.id, next),
    );
    if (mounted) setState(() => _busy = false);
    if (ok) _load();
  }

  void _note(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 14))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AuthProvider>().account;
    final first = (account?.name ?? '').trim().split(' ').first;
    final done = _jobs.where((job) => job.status == 'completed').length;
    final collected = _jobs.fold<num>(0, (sum, job) => sum + job.collected);
    final open = _jobs.length - done;
    return Scaffold(
      backgroundColor: AppConstants.paper,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_todayLine(), style: _Type.caption.copyWith(letterSpacing: 0.2)),
                            const SizedBox(height: 2),
                            Text(
                              first.isEmpty ? 'Your jobs' : 'Hi, $first',
                              style: _Type.hero,
                            ),
                          ],
                        ),
                      ),
                      _ShiftSwitch(on: _onShift, busy: _busy, onTap: _toggleShift),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _SummaryStrip(
                    open: open,
                    done: done,
                    collected: collected,
                    label: const ['Today', 'Tomorrow', 'Later'][_dayOffset],
                  ),
                ),
              ),
              if (!_onShift)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      decoration: BoxDecoration(
                        color: AppConstants.pendingBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18, color: AppConstants.pending),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are off shift. Go on shift to accept new jobs.',
                              style: _Type.caption.copyWith(color: AppConstants.pending, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _DayTabs(
                    value: _dayOffset,
                    onChanged: (next) {
                      if (next == _dayOffset) return;
                      setState(() => _dayOffset = next);
                      _load();
                    },
                  ),
                ),
              ),
              if (_loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_jobs.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _Explain(
                    icon: Icons.event_available_outlined,
                    title: _dayOffset == 2 ? 'Nothing coming up' : 'No jobs ${_dayOffset == 0 ? 'today' : 'tomorrow'}',
                    body: 'New jobs appear here when the desk assigns them to you. Pull down to refresh.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: _jobs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = _jobs[index];
                      return _JobCard(
                        job: job,
                        next: _next[job.status],
                        onShift: _onShift,
                        busy: _busy,
                        showDate: _dayOffset == 2,
                        onAdvance: () => _advance(job),
                        onNavigate: () => _navigate(job),
                        onBefore: () => _photo(job, true),
                        onAfter: () => _photo(job, false),
                        onCollect: () => _collect(job),
                        onClockIn: () => _clockIn(job),
                        onChat: () => context.push(Uri(
                          path: '/staff/chat/${job.id}',
                          queryParameters: {'title': job.customerName},
                        ).toString()),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleShift() async {
    final token = context.read<AuthProvider>().token;
    final next = !_onShift;
    final ok = await runOk(
      context,
      context.read<AdminService>().put(token, '/staff/shift', {'onShift': next}),
    );
    if (ok && mounted) {
      setState(() => _onShift = next);
      context.read<AuthProvider>().applyShift(next);
    }
  }

  Future<void> _navigate(BookingRecord job) async {
    final hasPin = job.latitude != null && job.longitude != null;
    final place = '${job.address} ${job.city}'.trim();
    if (!hasPin && place.isEmpty) {
      _note('This job has no address to open');
      return;
    }
    final query = hasPin ? '${job.latitude},${job.longitude}' : place;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) _note('Could not open maps');
  }

  Future<void> _photo(BookingRecord job, bool before) async {
    if (_busy) return;
    if (before && job.status == 'completed') {
      _note('This wash is already finished');
      return;
    }
    if (!before && job.status != 'in_progress' && job.status != 'completed') {
      _note('Start the wash before an after photo');
      return;
    }
    XFile? shot;
    try {
      shot = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 40,
        maxWidth: 800,
      );
    } on PlatformException catch (error) {
      if (!mounted) return;
      _note(error.code == 'multiple_request' ? 'Camera is already open' : 'Could not open the camera');
      return;
    }
    if (shot == null || !mounted) return;
    final bytes = await shot.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 1500000) {
      _note('Photo is too large. Try again.');
      return;
    }
    final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    final token = context.read<AuthProvider>().token;
    setState(() => _busy = true);
    final ok = await runOk(
      context,
      context.read<AdminService>().put(token, AppConstants.staffPhotos(job.id), {
        if (before) 'before': dataUrl,
        if (!before) 'after': dataUrl,
      }),
    );
    if (mounted) setState(() => _busy = false);
    if (ok) _load();
  }

  Future<void> _collect(BookingRecord job) async {
    if (_busy) return;
    if (job.due <= 0) {
      _note('This wash is already paid');
      return;
    }
    if (!const {'accepted', 'on_the_way', 'in_progress', 'completed'}.contains(job.status)) {
      _note('Accept the job before collecting payment');
      return;
    }
    final cash = TextEditingController(text: job.paymentMethod == 'UPI' ? '' : '${_whole(job.due)}');
    final upi = TextEditingController(text: job.paymentMethod == 'UPI' ? '${_whole(job.due)}' : '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.payments_outlined, size: 22, color: AppConstants.accent),
            SizedBox(width: 8),
            Expanded(child: Text('Collected at the car', style: _Type.section)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${_whole(job.due)} still due',
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppConstants.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cash,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cash',
                prefixIcon: Icon(Icons.payments_outlined, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upi,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'UPI',
                prefixIcon: Icon(Icons.qr_code_2_outlined, size: 22),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.check_circle_outlined, size: 22),
            label: const Text('Save'),
          ),
        ],
      ),
    );
    final cashText = cash.text.trim();
    final upiText = upi.text.trim();
    cash.dispose();
    upi.dispose();
    if (saved != true || !mounted) return;
    final cashAmount = num.tryParse(cashText);
    final upiAmount = num.tryParse(upiText);
    if ((cashText.isNotEmpty && cashAmount == null) || (upiText.isNotEmpty && upiAmount == null)) {
      _note('Enter numbers only');
      return;
    }
    final paidCash = cashAmount ?? 0;
    final paidUpi = upiAmount ?? 0;
    if (paidCash < 0 || paidUpi < 0 || (paidCash == 0 && paidUpi == 0)) {
      _note('Enter the cash or UPI you collected');
      return;
    }
    if (paidCash + paidUpi > job.due) {
      _note('Only ₹${_whole(job.due)} is still due');
      return;
    }
    final token = context.read<AuthProvider>().token;
    setState(() => _busy = true);
    final ok = await runOk(
      context,
      context.read<AdminService>().put(token, AppConstants.staffCollect(job.id), {
        'cash': paidCash,
        'upi': paidUpi,
      }),
    );
    if (mounted) setState(() => _busy = false);
    if (ok) _load();
  }

  Future<void> _clockIn(BookingRecord job) async {
    if (_busy) return;
    if (!_onShift) {
      _note('Turn on shift before clocking in');
      return;
    }
    if (job.clockedIn) {
      _note('Already clocked in');
      return;
    }
    if (!const {'accepted', 'on_the_way', 'in_progress'}.contains(job.status)) {
      _note(job.status == 'completed' ? 'This wash is already finished' : 'Accept the job before clocking in');
      return;
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) _note('Turn on location to clock in');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) return;
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _note('Location permission is needed to clock in');
        return;
      }
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final token = context.read<AuthProvider>().token;
      setState(() => _busy = true);
      final ok = await runOk(
        context,
        context.read<AdminService>().put(token, AppConstants.staffClockIn(job.id), {
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );
      if (mounted) setState(() => _busy = false);
      if (ok) _load();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      if (!mounted) return;
      _note('Could not read location for clock in');
    }
  }
}

int _whole(num amount) => amount == amount.roundToDouble() ? amount.toInt() : amount.round();

String _todayLine() {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  final now = DateTime.now();
  return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}'.toUpperCase();
}

/// "Slot 2 – 10:00 AM" → ("10:00", "AM").
(String, String) _slotParts(String slot) {
  final match = RegExp(r'(\d{1,2}:\d{2})\s*([AP]M)', caseSensitive: false).firstMatch(slot);
  if (match == null) return (slot.isEmpty ? '—' : slot, '');
  return (match[1]!, match[2]!.toUpperCase());
}

String _shortDate(String raw) {
  final day = DateTime.tryParse(raw);
  if (day == null) return raw;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${day.day} ${months[day.month - 1]}';
}

class _Type {
  static const hero = TextStyle(
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.6,
    color: AppConstants.ink,
  );
  static const section = TextStyle(
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppConstants.ink,
  );
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.3,
    color: AppConstants.muted,
  );
}

class _ShiftSwitch extends StatelessWidget {
  const _ShiftSwitch({required this.on, required this.busy, required this.onTap});

  final bool on;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = on ? AppConstants.completed : AppConstants.muted;
    return Semantics(
      button: true,
      toggled: on,
      label: 'On shift',
      child: Material(
        color: on ? AppConstants.completedBg : Colors.white,
        shape: StadiumBorder(side: BorderSide(color: on ? AppConstants.completedBg : AppConstants.line)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: on ? AppConstants.completed : AppConstants.line,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  on ? 'On shift' : 'Off shift',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.open, required this.done, required this.collected, required this.label});

  final int open;
  final int done;
  final num collected;
  final String label;

  @override
  Widget build(BuildContext context) {
    Widget cell(String value, String caption) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
              const SizedBox(height: 2),
              Text(caption, style: const TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppConstants.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          cell('$open', const {'Today': 'To do today', 'Tomorrow': 'Tomorrow', 'Later': 'Open jobs'}[label] ?? label),
          Container(width: 1, height: 34, color: const Color(0x33FFFFFF)),
          const SizedBox(width: 16),
          cell('$done', 'Finished'),
          Container(width: 1, height: 34, color: const Color(0x33FFFFFF)),
          const SizedBox(width: 16),
          cell(rupees(collected), 'Collected'),
        ],
      ),
    );
  }
}

class _DayTabs extends StatelessWidget {
  const _DayTabs({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Today', 'Tomorrow', 'Later'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE9ECF2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == index ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: value == index
                        ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[index],
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: value == index ? AppConstants.ink : AppConstants.muted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What the big button says for the next step.
String _nextLabel(String next) {
  switch (next) {
    case 'accepted':
      return 'Accept job';
    case 'on_the_way':
      return 'Start driving';
    case 'in_progress':
      return 'Start wash';
    case 'completed':
      return 'Finish wash';
    default:
      return 'Next';
  }
}

IconData _nextIcon(String next) {
  switch (next) {
    case 'accepted':
      return Icons.check_rounded;
    case 'on_the_way':
      return Icons.directions_car_filled_outlined;
    case 'in_progress':
      return Icons.local_car_wash_outlined;
    default:
      return Icons.task_alt_rounded;
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.next,
    required this.onShift,
    required this.busy,
    required this.showDate,
    required this.onAdvance,
    required this.onNavigate,
    required this.onBefore,
    required this.onAfter,
    required this.onCollect,
    required this.onClockIn,
    required this.onChat,
  });

  final BookingRecord job;
  final String? next;
  final bool onShift;
  final bool busy;
  final bool showDate;
  final VoidCallback onAdvance;
  final VoidCallback onNavigate;
  final VoidCallback onBefore;
  final VoidCallback onAfter;
  final VoidCallback onCollect;
  final VoidCallback onClockIn;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final customer = job.customerName.isEmpty ? 'Customer' : job.customerName;
    final (time, meridiem) = _slotParts(job.timeSlot);
    final done = job.status == 'completed';
    final step = statusStepIndex(job.status);
    final place = [job.address, job.city].where((part) => part.trim().isNotEmpty).join(', ');
    final vehicle = [job.service, job.carName].where((part) => part.trim().isNotEmpty).join(' · ');
    final paid = job.due <= 0 || job.paymentStatus.toLowerCase() == 'paid';
    final canAccept = next != 'accepted' || onShift;
    final active = const {'accepted', 'on_the_way', 'in_progress'}.contains(job.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConstants.line),
        boxShadow: const [BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showDate)
                        Text(_shortDate(job.date), style: _Type.caption.copyWith(fontWeight: FontWeight.w700, color: AppConstants.accent)),
                      Text(time, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppConstants.ink)),
                      Text(meridiem, style: _Type.caption.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(customer, maxLines: 1, overflow: TextOverflow.ellipsis, style: _Type.section),
                          ),
                          _StatusPill(status: job.status),
                        ],
                      ),
                      if (vehicle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(vehicle, maxLines: 1, overflow: TextOverflow.ellipsis, style: _Type.caption.copyWith(fontSize: 13)),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(Icons.place_outlined, size: 16, color: AppConstants.muted),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              place.isEmpty ? 'No address' : place,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, height: 1.35, color: AppConstants.ink),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (job.instructions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(color: AppConstants.paper, borderRadius: BorderRadius.circular(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sticky_note_2_outlined, size: 16, color: AppConstants.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(job.instructions, style: const TextStyle(fontSize: 13, height: 1.35, color: AppConstants.ink))),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(rupees(job.price), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppConstants.ink)),
                const SizedBox(width: 6),
                Text(job.paymentMethod, style: _Type.caption),
                const Spacer(),
                Text(
                  paid ? 'Paid' : '${rupees(job.due)} to collect',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: paid ? AppConstants.completed : AppConstants.pending,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                for (var index = 1; index < statusSteps.length; index++) ...[
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 4,
                      decoration: BoxDecoration(
                        color: done || index <= step ? AppConstants.accent : const Color(0xFFE9ECF2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (index < statusSteps.length - 1) const SizedBox(width: 4),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                if (place.isNotEmpty || job.latitude != null)
                  _IconAction(icon: Icons.navigation_outlined, label: 'Navigate', onTap: onNavigate),
                if (job.mobile.isNotEmpty)
                  _IconAction(icon: Icons.call_outlined, label: 'Call', onTap: () => dialNumber(job.mobile, context)),
                _IconAction(icon: Icons.chat_bubble_outline, label: 'Chat', onTap: onChat),
                if (!done)
                  _IconAction(
                    icon: job.hasBeforePhoto ? Icons.check_circle_outline : Icons.photo_camera_outlined,
                    label: 'Before',
                    onTap: onBefore,
                  ),
                if (job.status == 'in_progress' || (done && !job.hasAfterPhoto))
                  _IconAction(
                    icon: job.hasAfterPhoto ? Icons.check_circle_outline : Icons.camera_alt_outlined,
                    label: 'After',
                    onTap: onAfter,
                  ),
                if (!paid && (active || done))
                  _IconAction(icon: Icons.payments_outlined, label: 'Collect', onTap: onCollect, highlight: true),
                if (!job.clockedIn && active)
                  _IconAction(icon: Icons.timer_outlined, label: 'Clock in', onTap: onClockIn),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: done
                ? Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: AppConstants.completedBg, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt_rounded, size: 20, color: AppConstants.completed),
                        SizedBox(width: 8),
                        Text('Wash finished', style: TextStyle(fontWeight: FontWeight.w700, color: AppConstants.completed)),
                      ],
                    ),
                  )
                : next == null
                    ? const SizedBox.shrink()
                    : SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          onPressed: busy || !canAccept ? null : onAdvance,
                          icon: Icon(canAccept ? _nextIcon(next!) : Icons.lock_outline, size: 20),
                          label: Text(canAccept ? _nextLabel(next!) : 'Go on shift to accept'),
                          style: FilledButton.styleFrom(
                            backgroundColor: next == 'completed' ? AppConstants.completed : AppConstants.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.label, required this.onTap, this.highlight = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppConstants.pending : AppConstants.accent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 62,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlight ? AppConstants.pendingBg : AppConstants.iconWell,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: highlight ? AppConstants.pending : AppConstants.ink),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status == 'in_progress' ? 'Washing' : prettyStatus(status),
        style: TextStyle(color: tone.foreground, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _Explain extends StatelessWidget {
  const _Explain({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppConstants.iconWell, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: AppConstants.accent),
          ),
          const SizedBox(height: 16),
          Text(title, textAlign: TextAlign.center, style: _Type.section),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, height: 1.4, color: AppConstants.muted),
          ),
        ],
      ),
    );
  }
}

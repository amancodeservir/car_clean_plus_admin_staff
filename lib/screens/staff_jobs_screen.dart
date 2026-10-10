import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
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

  static const _label = {
    'accepted': 'Accept',
    'on_the_way': 'On the way',
    'in_progress': 'Start',
    'completed': 'Complete',
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
            date: indiaYmd(dayOffset: _dayOffset),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_dayOffset == 0 ? 'Today’s jobs' : 'Tomorrow’s jobs'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Today'),
                        icon: Icon(Icons.today_outlined, size: 20),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Tomorrow'),
                        icon: Icon(Icons.event_outlined, size: 20),
                      ),
                    ],
                    selected: {_dayOffset},
                    onSelectionChanged: (selection) {
                      final next = selection.first;
                      if (next == _dayOffset) return;
                      setState(() => _dayOffset = next);
                      _load();
                    },
                  ),
                ),
                const SizedBox(height: 10),
                DeskCard(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.badge_outlined, size: 20, color: AppConstants.accent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'On shift',
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppConstants.ink),
                        ),
                      ),
                      Switch(value: _onShift, onChanged: _busy ? null : (_) => _toggleShift()),
                    ],
                  ),
                ),
                if (!_onShift)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Off shift. Finish a job you already started. Accept needs the switch on.',
                      style: TextStyle(color: AppConstants.muted, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _jobs.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(16),
                            children: [
                              DeskEmpty(
                                message: _dayOffset == 0
                                    ? 'Nothing assigned for today.'
                                    : 'Nothing assigned for tomorrow.',
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: _jobs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) => _JobCard(
                              job: _jobs[index],
                              next: _next[_jobs[index].status],
                              nextLabel: _label[_next[_jobs[index].status]],
                              onShift: _onShift,
                              onAdvance: () => _advance(_jobs[index]),
                              onNavigate: () => _navigate(_jobs[index]),
                              onBefore: () => _photo(_jobs[index], true),
                              onAfter: () => _photo(_jobs[index], false),
                              onCollect: () => _collect(_jobs[index]),
                              onClockIn: () => _clockIn(_jobs[index]),
                            ),
                          ),
                  ),
          ),
        ],
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
            Expanded(child: Text('Collected at the car')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₹${_whole(job.due)} still due', style: const TextStyle(color: AppConstants.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: cash,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cash',
                prefixIcon: Icon(Icons.payments_outlined, size: 20),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upi,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'UPI',
                prefixIcon: Icon(Icons.qr_code_2_outlined, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle_outlined, size: 20),
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

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.job,
    required this.next,
    required this.nextLabel,
    required this.onShift,
    required this.onAdvance,
    required this.onNavigate,
    required this.onBefore,
    required this.onAfter,
    required this.onCollect,
    required this.onClockIn,
  });

  final BookingRecord job;
  final String? next;
  final String? nextLabel;
  final bool onShift;
  final VoidCallback onAdvance;
  final VoidCallback onNavigate;
  final VoidCallback onBefore;
  final VoidCallback onAfter;
  final VoidCallback onCollect;
  final VoidCallback onClockIn;

  @override
  Widget build(BuildContext context) {
    final service = [job.service, job.carName].where((part) => part.isNotEmpty).join(' · ');
    return DeskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeskPhoto(asset: washAssetFor(job.service), height: 64, width: 64),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(status: job.status),
                    const SizedBox(height: 6),
                    Text(
                      '${sourceLabel(job.source)} · ${job.customerName.isEmpty ? 'Customer' : job.customerName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          MetaRow(icon: Icons.directions_car_outlined, text: service),
          MetaRow(icon: Icons.calendar_today_outlined, text: '${job.date} · ${job.timeSlot}'),
          MetaRow(icon: Icons.location_on_outlined, text: '${job.address}, ${job.city}'),
          MetaRow(
            icon: Icons.currency_rupee_outlined,
            text: job.collected > 0
                ? '₹${job.price} ${job.paymentMethod} · ₹${_whole(job.collected)} collected'
                : '₹${job.price} ${job.paymentMethod}',
          ),
          if (job.instructions.isNotEmpty)
            MetaRow(icon: Icons.notes_outlined, text: job.instructions),
          if (job.clockedIn)
            const MetaRow(icon: Icons.timer_outlined, text: 'Clocked in'),
          if (job.hasBeforePhoto || job.hasAfterPhoto)
            MetaRow(
              icon: Icons.photo_outlined,
              text: [
                if (job.hasBeforePhoto) 'Before photo',
                if (job.hasAfterPhoto) 'After photo',
              ].join(' · '),
            ),
          if (job.mobile.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => dialNumber(job.mobile),
                icon: const Icon(Icons.phone_outlined, size: 20),
                label: Text(job.mobile),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.ink,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          const SizedBox(height: 12),
          StatusTree(
            status: job.status,
            onShift: onShift,
            onNext: next != null && (next != 'accepted' || onShift) ? onAdvance : null,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (job.address.isNotEmpty || job.city.isNotEmpty || job.latitude != null)
                DeskAction(icon: Icons.navigation_outlined, label: 'Navigate', onPressed: onNavigate),
              if (job.status != 'completed')
                DeskAction(icon: Icons.photo_camera_outlined, label: 'Before', onPressed: onBefore),
              if (job.status == 'in_progress' || (job.status == 'completed' && !job.hasAfterPhoto))
                DeskAction(icon: Icons.image_outlined, label: 'After', onPressed: onAfter),
              if (job.due > 0 && const {'accepted', 'on_the_way', 'in_progress', 'completed'}.contains(job.status))
                DeskAction(icon: Icons.payments_outlined, label: 'Collected', onPressed: onCollect),
              if (!job.clockedIn && const {'accepted', 'on_the_way', 'in_progress'}.contains(job.status))
                DeskAction(icon: Icons.timer_outlined, label: 'Clock in', onPressed: onClockIn),
            ],
          ),
        ],
      ),
    );
  }
}


import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../router/app_router.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../services/admin_service.dart';

class BookingAlertWatch extends StatefulWidget {
  const BookingAlertWatch({super.key, required this.child});

  final Widget child;

  @override
  State<BookingAlertWatch> createState() => _BookingAlertWatchState();
}

class _BookingAlertWatchState extends State<BookingAlertWatch> with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;
  final Set<String> _seen = {};
  String _accountId = '';
  bool _primed = false;
  bool _ready = false;
  bool _showing = false;
  final List<DeskAlert> _queue = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prepare();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _poll();
  }

  Future<void> _prepare() async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestSoundPermission: true,
        requestBadgePermission: true,
      );
      await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      _ready = true;
    } catch (_) {}
    if (mounted) _poll();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final account = auth.account;
    if (account == null || (!account.isAdmin && !account.isStaff)) return;
    if (account.id != _accountId) {
      _accountId = account.id;
      _primed = false;
      _seen.clear();
    }
    late final ({List<DeskAlert> items, int unread}) result;
    try {
      result = await context.read<AdminService>().notifications(auth.token);
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final fresh = result.items.where((item) => item.title == 'New customer' && item.id.isNotEmpty);
    if (!_primed) {
      _seen.addAll(fresh.map((item) => item.id));
      _primed = true;
      return;
    }
    for (final item in fresh) {
      if (_seen.add(item.id)) _queue.add(item);
    }
    if (_queue.isNotEmpty) unawaited(_present());
  }

  Future<void> _present() async {
    if (_showing || _queue.isEmpty || !mounted) return;
    _showing = true;
    final item = _queue.removeAt(0);
    unawaited(_ring());
    await _banner(item);
    final popup = deskNavigatorKey.currentState?.overlay?.context;
    if (!mounted || popup == null || !popup.mounted) return;
    final isDesk = context.read<AuthProvider>().account?.isAdmin == true;
    final open = await showDialog<bool>(
      context: popup,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_outlined, color: AppConstants.accent),
        title: const Text('New customer'),
        content: Text(item.body.isEmpty ? 'A booking just came in.' : item.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Later')),
          if (isDesk && item.bookingId.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open booking'),
            ),
        ],
      ),
    );
    _showing = false;
    final router = deskNavigatorKey.currentContext;
    if (open == true && router != null && router.mounted) {
      GoRouter.of(router).push('/desk/booking/${item.bookingId}');
    }
    if (_queue.isNotEmpty && mounted) unawaited(_present());
  }

  Future<void> _ring() async {
    for (var i = 0; i < 6; i++) {
      SystemSound.play(SystemSoundType.alert);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted || !_showing) return;
    }
  }

  Future<void> _banner(DeskAlert item) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        item.id.hashCode.abs().remainder(100000),
        'New customer',
        item.body.isEmpty ? 'A booking just came in.' : item.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'new_customer',
            'New customers',
            channelDescription: 'Rings when a customer books from the app or website',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            enableVibration: true,
            fullScreenIntent: true,
            category: AndroidNotificationCategory.alarm,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
            presentList: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

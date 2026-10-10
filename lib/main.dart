import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'router/app_router.dart';
import 'services/admin_service.dart';
import 'services/auth_service.dart';
import 'services/booking_alerts.dart';
import 'theme/desk_theme.dart';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  late final AdminService _admin;
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final api = ApiClient();
    _admin = AdminService(api);
    _auth = AuthProvider(AuthService(api));
    _router = createRouter(_auth);
  }

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AdminService>.value(value: _admin),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
      ],
      child: MaterialApp.router(
        title: 'Car Clean Admin',
        debugShowCheckedModeBanner: false,
        theme: DeskTheme.data,
        routerConfig: _router,
        builder: (context, child) => BookingAlertWatch(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}

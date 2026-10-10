import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../theme/desk_theme.dart';
import '../models/models.dart';
import '../screens/admin_shell.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/booking_forms.dart';
import '../screens/bookings_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/desk_tools.dart';
import '../screens/login_screen.dart';
import '../screens/more_screens.dart';
import '../screens/role_gates.dart';
import '../screens/account_screens.dart';
import '../screens/staff_shell.dart';
import '../screens/users_screen.dart';

final deskNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    navigatorKey: deskNavigatorKey,
    initialLocation: '/boot',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      if (auth.restoring && !auth.isSignedIn) {
        return path == '/boot' ? null : '/boot';
      }
      final account = auth.account;
      if (account == null) return path == '/login' ? null : '/login';
      if (account.isCustomer) return path == '/customer' ? null : '/customer';
      if (account.isStaff) {
        return path == '/staff' ? null : '/staff';
      }
      if (path == '/login' || path == '/boot' || path == '/customer' || path == '/staff') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const Scaffold(
          backgroundColor: AppConstants.paper,
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image(
                  image: AssetImage(AppConstants.logo),
                  height: 64,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 12),
                BrandMark(),
                SizedBox(height: 12),
                Text(
                  'Wash desk',
                  style: TextStyle(
                    color: AppConstants.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/customer', builder: (context, state) => const CustomerBlockedScreen()),
      GoRoute(path: '/staff', builder: (context, state) => const StaffShell()),
      GoRoute(path: '/desk/alerts', builder: (context, state) => const AlertsScreen()),
      GoRoute(path: '/desk/profile', builder: (context, state) => const ProfileScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/bookings', builder: (context, state) => const BookingsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/users', builder: (context, state) => const UsersScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (context, state) => const MoreScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/desk/phone', builder: (context, state) => const PhoneBookingScreen()),
      GoRoute(path: '/desk/block', builder: (context, state) => const BlockSlotScreen()),
      GoRoute(path: '/desk/contacts', builder: (context, state) => const ContactsScreen()),
      GoRoute(path: '/desk/gallery', builder: (context, state) => const GalleryScreen()),
      GoRoute(path: '/desk/festival', builder: (context, state) => const FestivalScreen()),
      GoRoute(
        path: '/desk/tools',
        builder: (context, state) {
          final extra = state.extra;
          final tool = extra is String ? extra : '';
          return DeskToolsScreen(tool: tool);
        },
      ),
      GoRoute(
        path: '/desk/booking',
        builder: (context, state) {
          final booking = state.extra;
          if (booking is! BookingRecord) {
            return const Scaffold(body: Center(child: Text('Open a booking from the list.')));
          }
          return BookingDetailScreen(booking: booking);
        },
      ),
      GoRoute(
        path: '/desk/user',
        builder: (context, state) {
          final user = state.extra;
          if (user is! StaffAccount) {
            return const Scaffold(body: Center(child: Text('Open a person from the list.')));
          }
          return UserDetailScreen(user: user);
        },
      ),
    ],
  );
}

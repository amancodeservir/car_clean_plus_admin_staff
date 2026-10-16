import 'package:flutter/material.dart';

class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://carcleanplus-backend.vercel.app/api',
  );

  static const String login = '/auth/login';
  static const String me = '/auth/me';
  static const String dashboard = '/admin/dashboard';
  static const String transactions = '/admin/transactions';
  static const String bookings = '/admin/bookings';
  static const String manualBooking = '/admin/bookings/manual';
  static const String users = '/admin/users';
  static const String contacts = '/admin/contacts';
  static const String gallery = '/gallery';
  static const String galleryAdmin = '/gallery/admin';
  static const String festival = '/festival';
  static const String staffJobs = '/staff/jobs';
  static const String staffSummary = '/staff/summary';
  static const String notifications = '/account/notifications';
  static const String catalog = '/catalog';
  static const String dailyReport = '/admin/reports/daily';
  static const String staffAccount = '/admin/staff';
  static const String branches = '/admin/branches';
  static const String promos = '/admin/promos';
  static const String payroll = '/admin/payroll';
  static const String inbox = '/admin/messages';
  static const String staffShift = '/staff/shift';

  static String bookingStatus(String id) => '/admin/bookings/$id/status';
  static String booking(String id) => '/admin/bookings/$id';
  static String assignBooking(String id) => '/admin/bookings/$id/assign';
  static String refundBooking(String id) => '/admin/bookings/$id/refund';
  static String userBookings(String id) => '/admin/users/$id/bookings';
  static String userRole(String id) => '/admin/users/$id/role';
  static String galleryItem(String id) => '/gallery/$id';
  static String staffJobStatus(String id) => '/staff/jobs/$id/status';
  static String staffPhotos(String id) => '/staff/jobs/$id/photos';
  static String staffCollect(String id) => '/staff/jobs/$id/collect';
  static String staffClockIn(String id) => '/staff/jobs/$id/clock-in';
  static String payoutPaid(String id) => '/admin/payroll/$id/paid';
  static String promo(String id) => '/admin/promos/$id';
  static String messages(String bookingId) => '/booking/$bookingId/messages';

  static const Color ink = Color(0xFF111827);
  static const Color paper = Color(0xFFF7F8FB);
  static const Color signal = Color(0xFFF5C400);
  static const Color accent = Color(0xFF1D4ED8);
  static const Color iconWell = Color(0xFFE8F0FE);
  static const Color muted = Color(0xFF6B7280);
  static const Color line = Color(0xFFE5E7EB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color completed = Color(0xFF047857);
  static const Color completedBg = Color(0xFFD1FAE5);
  static const Color progress = Color(0xFF1D4ED8);
  static const Color progressBg = Color(0xFFE8F0FE);
  static const Color pending = Color(0xFFB45309);
  static const Color pendingBg = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerBg = Color(0xFFFEE2E2);

  static const String coverPhoto = 'assets/car_wash.jpg';
  static const String basicWash = 'assets/basic_wash.png';
  static const String interiorWash = 'assets/interior_cleaning.png';
  static const String logo = 'assets/logo.png';

  static const List<String> timeSlots = [
    'Slot 1 – 08:30 AM',
    'Slot 2 – 10:00 AM',
    'Slot 3 – 11:30 AM',
    'Slot 4 – 01:30 PM',
    'Slot 5 – 03:00 PM',
    'Slot 6 – 04:30 PM',
  ];

  static const List<String> statuses = [
    'lead',
    'pending',
    'confirmed',
    'accepted',
    'on_the_way',
    'in_progress',
    'completed',
    'cancelled',
    'blocked',
  ];

  static const List<String> carCategories = [
    'Compact',
    'Standard',
    'Large',
    'Premium Compact',
    'Premium Standard',
    'Premium Large',
    'Premium',
    'Bike',
  ];

  /// Fallback when the catalog cannot be loaded. The live list comes from
  /// `GET /catalog`.
  static const List<String> services = [
    'Basic Wash',
    'Premium Wash',
    'Complete Clean',
    'Festive Offer',
  ];

  static const List<String> paymentMethods = ['Cash', 'UPI', 'Online'];

  static const List<String> festivals = [
    'DIWALI',
    'HOLI',
    'NAVRATRI',
    'EID',
    'NEWYEAR',
    'GENERAL',
  ];
}

String formatYmd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String indiaYmd({int dayOffset = 0}) {
  final wall = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30)).add(Duration(days: dayOffset));
  return formatYmd(wall);
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'api_client.dart';

Future<bool> runOk(BuildContext context, Future<void> action) async {
  try {
    await action;
    return true;
  } on ApiException catch (error) {
    if (!context.mounted) return false;
    await _showApiError(context, error);
    return false;
  }
}

Future<T?> runGuarded<T>(BuildContext context, Future<T> action) async {
  try {
    return await action;
  } on ApiException catch (error) {
    if (!context.mounted) return null;
    await _showApiError(context, error);
    return null;
  }
}

Future<void> _showApiError(BuildContext context, ApiException error) async {
  if (error.statusCode == 401 && context.mounted) {
    await context.read<AuthProvider>().logout();
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message)),
    );
  }
}

/// Opens the phone dialer. Where there is none (a simulator, a tablet) or it
/// fails, shows the number with a Copy button instead of doing nothing.
Future<void> dialNumber(String mobile, [BuildContext? context]) async {
  final digits = mobile.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return;
  var opened = false;
  try {
    opened = await launchUrl(Uri(scheme: 'tel', path: digits));
  } catch (_) {
    opened = false;
  }
  if (opened || context == null || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Calls are not available here. Number: $mobile'),
      action: SnackBarAction(
        label: 'Copy',
        onPressed: () => Clipboard.setData(ClipboardData(text: digits)),
      ),
    ),
  );
}

String shortDate(String raw) {
  if (raw.length >= 10) return raw.substring(0, 10);
  return raw;
}

/// Opens one booking on the desk. True when it was changed there.
Future<bool> openBooking(BuildContext context, String id, {BookingRecord? initial}) async {
  if (id.isEmpty) return false;
  final changed = await context.push<bool>('/desk/booking/$id', extra: initial);
  return changed == true;
}

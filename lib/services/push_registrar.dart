import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../core/constants.dart';

class PushRegistrar {
  static Future<void> register(String authToken) async {
    if (authToken.isEmpty) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/account/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );
    } catch (_) {}
  }

  /// Stops pushes to this phone for the account that is signing out.
  static Future<void> unregister(String authToken) async {
    if (authToken.isEmpty) return;
    try {
      if (Firebase.apps.isEmpty) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await http.delete(
        Uri.parse('${AppConstants.baseUrl}/account/push-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}

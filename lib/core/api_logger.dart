import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Pretty terminal logger for HTTP requests and responses.
class ApiLogger {
  static const bool _enabled = kDebugMode;
  static final String _line = '─' * 65;

  static void logRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    if (!_enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌$_line');
    buffer.writeln('│ 🚀 [API REQUEST] $method $url');
    if (headers != null && headers.isNotEmpty) {
      final sanitizedHeaders = Map<String, String>.from(headers);
      if (sanitizedHeaders.containsKey('Authorization')) {
        final auth = sanitizedHeaders['Authorization'] ?? '';
        sanitizedHeaders['Authorization'] = auth.length > 25
            ? '${auth.substring(0, 18)}...[hidden]'
            : '[token]';
      }
      buffer.writeln('│ 📋 Headers: $sanitizedHeaders');
    }
    if (body != null && (body is! Map || body.isNotEmpty)) {
      buffer.writeln('│ 📦 Body:');
      final formattedBody = _prettyPrint(body);
      for (final line in formattedBody.split('\n')) {
        buffer.writeln('│   $line');
      }
    }
    buffer.writeln('└$_line');

    _printLines(buffer.toString());
  }

  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    required int durationMs,
    required String responseBody,
  }) {
    if (!_enabled) return;

    final isSuccess = statusCode >= 200 && statusCode < 300;
    final icon = isSuccess ? '🟢' : (statusCode < 500 ? '🟡' : '🔴');

    final buffer = StringBuffer();
    buffer.writeln('\n┌$_line');
    buffer.writeln('│ $icon [API RESPONSE] $statusCode (${durationMs}ms) ➜ $method $url');
    if (responseBody.trim().isNotEmpty) {
      buffer.writeln('│ 📄 Response:');
      final formatted = _prettyPrint(responseBody);
      for (final line in formatted.split('\n')) {
        buffer.writeln('│   $line');
      }
    } else {
      buffer.writeln('│ 📄 Response: [Empty Body]');
    }
    buffer.writeln('└$_line');

    _printLines(buffer.toString());
  }

  static void logError({
    required String method,
    required String url,
    required int durationMs,
    required dynamic error,
    int? statusCode,
  }) {
    if (!_enabled) return;

    final buffer = StringBuffer();
    buffer.writeln('\n┌$_line');
    buffer.writeln('│ 🔴 [API ERROR] (${durationMs}ms) ➜ $method $url');
    if (statusCode != null) {
      buffer.writeln('│ Status Code: $statusCode');
    }
    buffer.writeln('│ Error: $error');
    buffer.writeln('└$_line');

    _printLines(buffer.toString());
  }

  static String _prettyPrint(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  static void _printLines(String text) {
    // debugPrint ensures terminal log does not truncate on Android/iOS/macOS
    for (final line in text.split('\n')) {
      debugPrint(line);
    }
  }
}

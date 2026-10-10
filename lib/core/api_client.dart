import 'dart:convert';

import 'package:http/http.dart' as http;

import 'constants.dart';

class ApiException implements Exception {
  ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  Future<Map<String, dynamic>> request({
    required String method,
    required String path,
    String? token,
    Map<String, dynamic>? body,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    http.Response response;
    try {
      final uri = Uri.parse('${AppConstants.baseUrl}$path');
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: jsonEncode(body ?? {}),
          );
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
        default:
          throw ApiException('Unsupported request', 0);
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Could not reach the server', 0);
    }

    Map<String, dynamic> data = {};
    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) data = decoded;
    }

    final failed = response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['success'] == false;
    if (failed) {
      throw ApiException(
        data['message']?.toString() ?? 'Request failed',
        response.statusCode,
      );
    }
    return data;
  }
}

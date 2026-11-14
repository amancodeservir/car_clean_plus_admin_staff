import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_logger.dart';
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

    final uri = Uri.parse('${AppConstants.baseUrl}$path');
    final stopwatch = Stopwatch()..start();

    ApiLogger.logRequest(
      method: method,
      url: uri.toString(),
      headers: headers,
      body: body,
    );

    http.Response response;
    try {
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
      stopwatch.stop();
      ApiLogger.logResponse(
        method: method,
        url: uri.toString(),
        statusCode: response.statusCode,
        durationMs: stopwatch.elapsedMilliseconds,
        responseBody: response.body,
      );
    } on ApiException catch (e) {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        url: uri.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
        error: e.message,
        statusCode: e.statusCode,
      );
      rethrow;
    } catch (error) {
      stopwatch.stop();
      ApiLogger.logError(
        method: method,
        url: uri.toString(),
        durationMs: stopwatch.elapsedMilliseconds,
        error: error,
      );
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

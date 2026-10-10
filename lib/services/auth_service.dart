import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';

class OtpRequired implements Exception {
  OtpRequired(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  AuthService(this._api);

  final ApiClient _api;
  static const _tokenKey = 'admin_jwt_token';

  Future<StaffAccount> login(String email, String password, {String code = ''}) async {
    final data = await _api.request(
      method: 'POST',
      path: AppConstants.login,
      body: {
        'email': email,
        'password': password,
        'client': 'app',
        if (code.trim().isNotEmpty) 'code': code.trim(),
      },
    );
    if (data['otpRequired'] == true) {
      throw OtpRequired(data['message']?.toString() ?? 'Enter the code sent to your email');
    }
    final token = data['token']?.toString() ?? '';
    final user = data['user'];
    if (token.isEmpty || user is! Map) {
      throw ApiException('Login did not return an account', 0);
    }
    final account = StaffAccount.fromJson(
      Map<String, dynamic>.from(user),
      token: token,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    return account;
  }

  Future<StaffAccount?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    try {
      final data = await _api.request(
        method: 'GET',
        path: AppConstants.me,
        token: token,
      );
      final user = data['user'];
      if (user is! Map) return null;
      return StaffAccount.fromJson(Map<String, dynamic>.from(user), token: token);
    } on ApiException {
      await logout();
      return null;
    }
  }

  Future<StaffAccount> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.request(
      method: 'PUT',
      path: AppConstants.me,
      token: token,
      body: body,
    );
    final user = data['user'];
    if (user is! Map) {
      throw ApiException('Profile was not saved', 0);
    }
    return StaffAccount.fromJson(Map<String, dynamic>.from(user), token: token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

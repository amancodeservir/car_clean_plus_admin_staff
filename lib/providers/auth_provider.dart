import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/push_registrar.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService) {
    _restore();
  }

  final AuthService _authService;

  StaffAccount? _account;
  bool _restoring = true;
  bool _busy = false;
  bool _otpPending = false;
  String? _error;
  String _otpNotice = '';

  StaffAccount? get account => _account;
  String get otpNotice => _otpNotice;
  bool get restoring => _restoring;
  bool get busy => _busy;
  bool get otpPending => _otpPending;
  String? get error => _error;
  bool get isSignedIn => _account != null;
  String get token => _account?.token ?? '';

  Future<void> _restore() async {
    try {
      _account = await _authService.restore();
      if (token.isNotEmpty) {
        try {
          await PushRegistrar.register(token);
        } catch (_) {}
      }
    } catch (_) {
      _account = null;
    } finally {
      _restoring = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password, {String code = ''}) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      _account = await _authService.login(email.trim(), password, code: code);
      _otpPending = false;
      try {
        await PushRegistrar.register(token);
      } catch (_) {}
      _busy = false;
      notifyListeners();
      return true;
    } on OtpRequired catch (error) {
      _otpPending = true;
      _otpNotice = error.message;
      _error = null;
      _busy = false;
      notifyListeners();
      return false;
    } catch (error) {
      _error = error.toString();
      _busy = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> saveProfile(Map<String, dynamic> body) async {
    try {
      _account = await _authService.updateProfile(token, body);
      _error = null;
      notifyListeners();
      return null;
    } catch (error) {
      return error.toString().replaceFirst('ApiException: ', '');
    }
  }

  void applyShift(bool onShift) {
    final current = _account;
    if (current == null) return;
    _account = current.copyWith(onShift: onShift);
    notifyListeners();
  }

  Future<void> logout() async {
    final token = this.token;
    if (token.isNotEmpty) await PushRegistrar.unregister(token);
    await _authService.logout();
    _account = null;
    _error = null;
    notifyListeners();
  }
}

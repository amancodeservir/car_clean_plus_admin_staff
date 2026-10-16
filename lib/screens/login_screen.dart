import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _email.text,
      _password.text,
      code: auth.otpPending ? _code.text : '',
    );
    if (!ok && mounted && !auth.otpPending && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.error!,
            style: const TextStyle(fontSize: 14, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loading = auth.busy;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _LogoWell(),
                    const SizedBox(height: 16),
                    const Text(
                      'Staff sign in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                        color: AppConstants.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'For Car Clean Plus crew only.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppConstants.muted,
                      ),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 22),
                        errorStyle: TextStyle(fontSize: 12, height: 1.3, color: AppConstants.danger),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outlined, size: 22),
                        errorStyle: TextStyle(fontSize: 12, height: 1.3, color: AppConstants.danger),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    if (auth.otpPending) ...[
                      const SizedBox(height: 14),
                      Text(
                        auth.error ?? 'Enter the code sent to your email',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: auth.error == null ? AppConstants.muted : AppConstants.danger,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Email code',
                          prefixIcon: Icon(Icons.pin_outlined, size: 22),
                          errorStyle: TextStyle(fontSize: 12, height: 1.3, color: AppConstants.danger),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 6 ? 'Enter the 6 digit code' : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(auth.otpPending ? 'Confirm code' : 'Sign in'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoWell extends StatelessWidget {
  const _LogoWell();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        AppConstants.logo,
        height: 112,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.local_car_wash_outlined, size: 48, color: AppConstants.accent);
        },
      ),
    );
  }
}

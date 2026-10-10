import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../theme/desk_theme.dart';

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
        SnackBar(content: Text(auth.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().busy;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        AppConstants.logo,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(child: BrandMark()),
                    const SizedBox(height: 16),
                    const Text(
                      'Car Clean Admin',
                      style: TextStyle(
                        fontSize: 32,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        color: AppConstants.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Wash desk. Customers stay on the booking app.',
                      style: TextStyle(color: AppConstants.muted),
                    ),
                    const SizedBox(height: 18),
                    const DeskPhoto(asset: AppConstants.coverPhoto, height: 156),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
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
                        prefixIcon: Icon(Icons.lock_outlined, size: 20),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'Required' : null,
                    ),
                    if (context.watch<AuthProvider>().otpPending) ...[
                      const SizedBox(height: 14),
                      Text(
                        context.watch<AuthProvider>().error ?? 'Enter the code sent to your email',
                        style: const TextStyle(color: AppConstants.muted),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Email code',
                          prefixIcon: Icon(Icons.pin_outlined, size: 20),
                        ),
                        validator: (value) =>
                            value == null || value.trim().length < 6 ? 'Enter the 6 digit code' : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: loading ? null : _submit,
                      icon: loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.login_outlined, size: 20),
                      label: Text(context.watch<AuthProvider>().otpPending ? 'Confirm code' : 'Sign in'),
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

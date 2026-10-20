import 'dart:async';

import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  Timer? _resendTimer;
  int _remainingSeconds = 0;
  bool _isSending = false;

  bool get _isCooldownActive => _isSending || _remainingSeconds > 0;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _email.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_isCooldownActive) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSending = true;
      _remainingSeconds = 60;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isSending = false;
        });
      } else {
        setState(() => _remainingSeconds--);
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tautan reset password akan dikirim ke email Anda.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset_rounded, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Atur ulang password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan email akun Anda. Kami akan mengirimkan tautan untuk membuat password baru.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Alamat email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Masukkan email yang valid'
                      : null,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _isCooldownActive ? null : _sendResetLink,
                  style: _isCooldownActive
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                          disabledBackgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                        )
                      : null,
                  icon: Icon(
                    _isCooldownActive
                        ? Icons.check_rounded
                        : Icons.send_rounded,
                  ),
                  label: Text(
                    _isCooldownActive
                        ? 'Terkirim, kirim ulang dalam $_remainingSeconds detik'
                        : _remainingSeconds == 0 && _resendTimer != null
                        ? 'Kirim Ulang Tautan Reset'
                        : 'Kirim Tautan Reset',
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

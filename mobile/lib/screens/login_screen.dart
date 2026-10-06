import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState?.validate() ?? false) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.home_work_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 24),
                    Text('Selamat Datang',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Akses riwayat kalkulasi & prediksi nilai\nproperti Anda.',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
                    const SizedBox(height: 28),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Masuk')),
                        ButtonSegment(value: false, label: Text('Daftar Akun')),
                      ],
                      selected: const {true},
                      onSelectionChanged: (selection) {
                        if (selection.first == false) context.push('/register');
                      },
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Tampilkan kata sandi'
                              : 'Sembunyikan kata sandi',
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                        ),
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? 'Kata sandi minimal 6 karakter'
                          : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Lupa password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _login,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Masuk Sekarang'),
                    ),
                    const SizedBox(height: 24),
                    Text('Dengan masuk, Anda menyetujui\nKetentuan Layanan & Kebijakan Privasi.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade600)),
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

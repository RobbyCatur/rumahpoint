import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_providers.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _oldPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).value;
    _nameController = TextEditingController(text: user?.nama ?? 'Customer 1');
    _oldPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembaruan berhasil disimpan.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.value;
    final userName = user?.nama ?? 'Customer 1';
    final userEmail = user?.email ?? 'customer1@gmail.com';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : Colors.black54;
    final labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Informasi Pribadi & Sandi',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: dividerColor, height: 1),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // ── Section 1: Ringkasan Informasi (Read-only) ────────
            Text(
              'Ringkasan Informasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nama Pengguna',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey.shade200,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.email_outlined,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Alamat Email',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Identitas Tetap',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Section 2: Edit Informasi Dasar ──────────────────
            Text(
              'Informasi Dasar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildField(
              context: context,
              controller: _nameController,
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap',
              icon: Icons.person_outline,
              labelColor: labelColor,
              textColor: textColor,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama lengkap wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // ── Section 3: Keamanan (Ubah Kata Sandi) ─────────────
            Row(
              children: [
                Text(
                  'Keamanan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(Ubah Kata Sandi)',
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kosongkan kolom di bawah jika Anda tidak ingin mengganti kata sandi.',
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // Sandi Lama
            _buildPasswordField(
              context: context,
              controller: _oldPasswordController,
              label: 'Sandi Lama',
              hintText: 'Masukkan sandi lama',
              icon: Icons.lock_clock_outlined,
              obscureText: _obscureOld,
              onToggleVisibility: () =>
                  setState(() => _obscureOld = !_obscureOld),
              labelColor: labelColor,
              textColor: textColor,
              validator: (val) {
                final hasPasswordInput =
                    _oldPasswordController.text.isNotEmpty ||
                        _newPasswordController.text.isNotEmpty ||
                        _confirmPasswordController.text.isNotEmpty;
                if (hasPasswordInput && (val == null || val.isEmpty)) {
                  return 'Sandi lama wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Sandi Baru
            _buildPasswordField(
              context: context,
              controller: _newPasswordController,
              label: 'Sandi Baru',
              hintText: 'Masukkan sandi baru',
              icon: Icons.lock_outline,
              obscureText: _obscureNew,
              onToggleVisibility: () =>
                  setState(() => _obscureNew = !_obscureNew),
              labelColor: labelColor,
              textColor: textColor,
              validator: (val) {
                final hasPasswordInput =
                    _oldPasswordController.text.isNotEmpty ||
                        _newPasswordController.text.isNotEmpty ||
                        _confirmPasswordController.text.isNotEmpty;
                if (hasPasswordInput) {
                  if (val == null || val.isEmpty) {
                    return 'Sandi baru wajib diisi';
                  }
                  if (val.length < 6) {
                    return 'Kata sandi minimal 6 karakter';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Konfirmasi Sandi Baru
            _buildPasswordField(
              context: context,
              controller: _confirmPasswordController,
              label: 'Konfirmasi Sandi Baru',
              hintText: 'Ulangi sandi baru',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirm,
              onToggleVisibility: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              labelColor: labelColor,
              textColor: textColor,
              validator: (val) {
                final hasPasswordInput =
                    _oldPasswordController.text.isNotEmpty ||
                        _newPasswordController.text.isNotEmpty ||
                        _confirmPasswordController.text.isNotEmpty;
                if (hasPasswordInput) {
                  if (val == null || val.isEmpty) {
                    return 'Konfirmasi sandi wajib diisi';
                  }
                  if (val != _newPasswordController.text) {
                    return 'Konfirmasi sandi tidak cocok';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required Color labelColor,
    required Color textColor,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: iconColor, size: 20),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required Color labelColor,
    required Color textColor,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: iconColor,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

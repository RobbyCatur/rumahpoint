import 'package:flutter/material.dart';

class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
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
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            'Informasi Dasar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Nama Lengkap',
            initialValue: 'Customer 1',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Alamat Email',
            initialValue: 'customer1@gmail.com',
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 32),
          Text(
            'Keamanan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Kata Sandi Baru',
            hintText: 'Masukkan sandi baru',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context,
            label: 'Konfirmasi Sandi',
            hintText: 'Ulangi sandi baru',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pembaruan berhasil disimpan.')),
              );
              Navigator.pop(context);
            },
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
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required String label,
    String? initialValue,
    String? hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final textColor = isDark ? Colors.white : Colors.black87;
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
          initialValue: initialValue,
          obscureText: isPassword,
          style: TextStyle(color: textColor, fontSize: 14),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: iconColor, size: 20),
          ),
        ),
      ],
    );
  }
}

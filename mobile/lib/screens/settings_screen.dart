import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Pengaturan Akun',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 1),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildToggleItem(title: 'Notifikasi Push', subtitle: 'Pemberitahuan perubahan harga pasar', value: true),
          _buildDivider(),
          _buildToggleItem(title: 'Simpan Riwayat Lokal', subtitle: 'Gunakan cache SQLite (Mode Offline)', value: true),
          _buildDivider(),
          _buildToggleItem(title: 'Mode Gelap (Dark Mode)', subtitle: 'Gunakan tema gelap pada aplikasi', value: false),
          _buildDivider(),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: const Text('Hapus Cache Aplikasi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            subtitle: const Text('Kosongkan memori penyimpanan sementara', style: TextStyle(fontSize: 13)),
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache aplikasi berhasil dibersihkan.')));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({required String title, required String subtitle, required bool value}) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      value: value,
      activeColor: const Color(0xFFF59E0B),
      onChanged: (bool newValue) {},
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey.withOpacity(0.15), indent: 24, endIndent: 24);
  }
}
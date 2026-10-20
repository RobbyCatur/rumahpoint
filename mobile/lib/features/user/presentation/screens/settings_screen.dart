import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _saveLocalHistory = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkTheme ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: isDarkTheme ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkTheme ? Colors.white : Colors.black87),
        title: Text(
          'Pengaturan Akun',
          style: TextStyle(
            color: isDarkTheme ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildToggleItem(
            title: 'Simpan Riwayat Lokal',
            subtitle: 'Gunakan cache SQLite (Mode Offline)',
            value: _saveLocalHistory,
            onChanged: (bool newValue) {
              setState(() {
                _saveLocalHistory = newValue;
              });
            },
          ),
          _buildDivider(isDarkTheme),
          _buildToggleItem(
            title: 'Mode Gelap (Dark Mode)',
            subtitle: 'Gunakan tema gelap pada aplikasi',
            value: isDark,
            onChanged: (bool newValue) {
              ref.read(themeModeProvider.notifier).toggleTheme(newValue);
            },
          ),
          _buildDivider(isDarkTheme),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            title: Text(
              'Hapus Cache Aplikasi',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: isDarkTheme ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: const Text(
              'Kosongkan memori penyimpanan sementara',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            trailing: const Icon(Icons.delete_outline, color: Colors.red),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache aplikasi berhasil dibersihkan.')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: isDarkTheme ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
      value: value,
      activeTrackColor: const Color(0xFFF59E0B),
      onChanged: onChanged,
    );
  }

  Widget _buildDivider(bool isDarkTheme) {
    return Divider(
      height: 1,
      color: isDarkTheme
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.15),
      indent: 24,
      endIndent: 24,
    );
  }
}
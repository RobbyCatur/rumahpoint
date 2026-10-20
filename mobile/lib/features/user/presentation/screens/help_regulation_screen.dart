import 'package:flutter/material.dart';

import '../../../../screens/faq_screen.dart';
import '../../../../screens/report_issue_screen.dart';
import '../../../../screens/terms_screen.dart';
import '../../../../screens/privacy_screen.dart';
import '../../../../screens/disclaimer_screen.dart';
import 'contact_us_screen.dart';

class HelpRegulationScreen extends StatelessWidget {
  const HelpRegulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final footerColor = isDark ? const Color(0xFF64748B) : Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Bantuan & Regulasi',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Kategori: Pusat Bantuan ─────────────────────────────
          _buildSectionHeader('Pusat Bantuan', isDark: isDark),
          _buildTile(
            context: context,
            icon: Icons.quiz_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Pertanyaan Umum (FAQ)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
          ),
          _buildTile(
            context: context,
            icon: Icons.bug_report_outlined,
            iconColor: Colors.redAccent,
            title: 'Laporkan Masalah Aplikasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            ),
          ),
          _buildTile(
            context: context,
            icon: Icons.support_agent_rounded,
            iconColor: Colors.blueAccent,
            title: 'Hubungi Kami',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactUsScreen()),
            ),
          ),

          const SizedBox(height: 8),

          // ── Kategori: Regulasi & Ketentuan ─────────────────────
          _buildSectionHeader('Regulasi & Ketentuan', isDark: isDark),
          _buildTile(
            context: context,
            icon: Icons.description_outlined,
            iconColor: Colors.teal,
            title: 'Syarat & Ketentuan Layanan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          _buildTile(
            context: context,
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.indigo,
            title: 'Kebijakan Privasi Data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          _buildTile(
            context: context,
            icon: Icons.gavel_outlined,
            iconColor: Colors.orange,
            title: 'Disclaimer Penilaian Properti',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DisclaimerScreen()),
            ),
          ),

          const SizedBox(height: 40),

          // ── Footer ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Text(
              'RumahPoint v1.0.0 © 2026 Kelompok 5 PBL Polinema',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: footerColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF94A3B8) : Colors.grey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final chevronColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: chevronColor, size: 20),
        onTap: onTap,
      ),
    );
  }
}

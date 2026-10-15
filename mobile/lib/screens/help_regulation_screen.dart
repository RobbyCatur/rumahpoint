import 'package:flutter/material.dart';

import 'faq_screen.dart';
import 'report_issue_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'disclaimer_screen.dart';

class HelpRegulationScreen extends StatelessWidget {
  const HelpRegulationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'Bantuan & Regulasi',
          style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 1),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Kategori: Pusat Bantuan ─────────────────────────────
          _buildSectionHeader('Pusat Bantuan'),
          _buildTile(
            icon: Icons.quiz_outlined,
            iconColor: const Color(0xFFF59E0B),
            title: 'Pertanyaan Umum (FAQ)',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FaqScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.redAccent,
            title: 'Laporkan Masalah Aplikasi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            ),
          ),

          const SizedBox(height: 8),

          // ── Kategori: Regulasi & Ketentuan ─────────────────────
          _buildSectionHeader('Regulasi & Ketentuan'),
          _buildTile(
            icon: Icons.description_outlined,
            iconColor: Colors.teal,
            title: 'Syarat & Ketentuan Layanan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsScreen()),
            ),
          ),
          _buildTile(
            icon: Icons.privacy_tip_outlined,
            iconColor: Colors.indigo,
            title: 'Kebijakan Privasi Data',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
          ),
          _buildTile(
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
          const Padding(
            padding: EdgeInsets.only(bottom: 32),
            child: Text(
              'RumahPoint v1.0.0 © 2026 Kelompok 5 PBL Polinema',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.grey,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();

  static const _categories = [
    'Hasil prediksi tidak masuk akal',
    'Aplikasi crash / tiba-tiba berhenti',
    'Halaman tidak bisa dimuat',
    'Tombol tidak berfungsi',
    'Masalah login / logout',
    'Lainnya',
  ];

  String? _selectedCategory;
  bool _submitted = false;

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitted = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim. Terima kasih!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final fieldColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final fieldBorderColor =
        isDark ? const Color(0xFF334155) : Colors.grey.shade200;
    final hintColor = isDark ? const Color(0xFF94A3B8) : Colors.grey;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Laporkan Masalah',
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
            color: dividerColor,
            height: 1,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                    : Colors.blue.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                      : Colors.blue.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Laporan Anda akan membantu tim RumahPoint meningkatkan kualitas aplikasi. '
                      'Semua laporan ditinjau dalam 1×24 jam kerja.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFE2E8F0) : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Kategori masalah
            Text(
              'Kategori Masalah',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: fieldColor,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFF59E0B)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
              ),
              hint: Text(
                'Pilih kategori...',
                style: TextStyle(color: hintColor),
              ),
              items: _categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: TextStyle(color: textColor)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) =>
                  val == null ? 'Pilih kategori masalah terlebih dahulu.' : null,
            ),

            const SizedBox(height: 20),

            // Deskripsi
            Text(
              'Deskripsi Masalah',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descController,
              maxLines: 5,
              maxLength: 500,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Jelaskan masalah yang Anda alami secara detail (langkah, kondisi, pesan error, dll.)...',
                hintStyle: TextStyle(color: hintColor, fontSize: 13),
                filled: true,
                fillColor: fieldColor,
                contentPadding: const EdgeInsets.all(16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: fieldBorderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFFF59E0B)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
                ),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Deskripsi masalah tidak boleh kosong.';
                }
                if (val.trim().length < 20) {
                  return 'Mohon jelaskan lebih detail (min. 20 karakter).';
                }
                return null;
              },
            ),

            const SizedBox(height: 28),

            // Tombol kirim
            ElevatedButton.icon(
              onPressed: _submitted ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              icon: _submitted
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(
                _submitted ? 'Mengirim laporan...' : 'Kirim Laporan',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

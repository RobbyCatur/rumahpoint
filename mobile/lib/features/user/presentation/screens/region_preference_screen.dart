import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prediction/domain/entities/wilayah.dart';
import '../../../prediction/presentation/providers/prediction_providers.dart';
import '../../../prediction/presentation/widgets/wilayah_field.dart';
import '../providers/user_providers.dart';

class RegionPreferenceScreen extends ConsumerStatefulWidget {
  const RegionPreferenceScreen({super.key});

  @override
  ConsumerState<RegionPreferenceScreen> createState() =>
      _RegionPreferenceScreenState();
}

class _RegionPreferenceScreenState extends ConsumerState<RegionPreferenceScreen> {
  /// Wilayah yang sedang dipilih pada layar ini. Null berarti belum ada
  /// pilihan, sehingga yang ditampilkan adalah preferensi tersimpan.
  KabupatenKota? _wilayah;
  bool _mencariGps = false;
  bool _menyimpan = false;

  /// Deteksi kab/kota tempat perangkat berada (poligon batas wilayah).
  Future<void> _deteksiGps() async {
    if (_mencariGps) return;
    setState(() => _mencariGps = true);
    final hasil = await deteksiWilayahSaatIni(ref);
    if (!mounted) return;
    setState(() {
      _wilayah = hasil ?? _wilayah;
      _mencariGps = false;
    });
  }

  Future<void> _simpan(KabupatenKota? wilayah) async {
    if (_menyimpan) return;
    if (wilayah == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih wilayah dulu.')),
      );
      return;
    }
    setState(() => _menyimpan = true);
    await ref.read(wilayahPreferenceProvider.notifier).simpan(wilayah);
    if (!mounted) return;
    setState(() => _menyimpan = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferensi wilayah tersimpan.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isGpsActive = ref.watch(gpsPriorityProvider);
    final tersimpan = ref.watch(wilayahPreferenceProvider);
    // GPS aktif: yang tampil selalu hasil deteksi (bukan preferensi tersimpan),
    // supaya teks "terdeteksi otomatis" tidak menyesatkan.
    final tampil = isGpsActive ? _wilayah : (_wilayah ?? tersimpan);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    ref.listen<bool>(gpsPriorityProvider, (previous, next) {
      if (next) {
        _deteksiGps();
      } else {
        setState(() => _wilayah = null);
      }
    });

    if (isGpsActive && tampil == null && !_mencariGps) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _deteksiGps());
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Preferensi Wilayah',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                  : Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                    : Colors.blue.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isGpsActive
                        ? (tampil != null
                            ? 'Lokasi otomatis terdeteksi (${tampil.nama}, ${tampil.provinsi}). Preferensi wilayah dikunci sesuai koordinat perangkat.'
                            : 'Mendeteksi lokasi perangkat via GPS…')
                        : 'Mengatur preferensi wilayah akan mempercepat proses saat Anda mengisi formulir prediksi harga.',
                    style: TextStyle(
                      color: isDark ? const Color(0xFFE2E8F0) : Colors.black87,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Kota / Kabupaten',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 8),
          // Pemilih yang sama dengan form di Beranda: provinsi → kab/kota.
          WilayahField(
            label: '',
            value: tampil,
            showGpsButton: !isGpsActive,
            enabled: !isGpsActive,
            placeholder: 'Pilih wilayah',
            onChanged: (v) => setState(() => _wilayah = v),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: _menyimpan ? null : () => _simpan(tampil),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: const Color(0xFF1F1300),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Simpan Preferensi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

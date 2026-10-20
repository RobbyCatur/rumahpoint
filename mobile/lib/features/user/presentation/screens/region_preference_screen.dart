import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/user_providers.dart';

class RegionPreferenceScreen extends ConsumerStatefulWidget {
  const RegionPreferenceScreen({super.key});

  @override
  ConsumerState<RegionPreferenceScreen> createState() =>
      _RegionPreferenceScreenState();
}

class _RegionPreferenceScreenState
    extends ConsumerState<RegionPreferenceScreen> {
  String? _selectedCity;

  static const List<String> _cities = [
    'Bekasi',
    'Bogor',
    'Depok',
    'Jakarta Selatan',
    'Jakarta Utara',
    'Surabaya',
    'Tangerang',
  ];

  @override
  Widget build(BuildContext context) {
    final isGpsActive = ref.watch(gpsPriorityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB);
    final appBarColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final labelColor = isDark ? const Color(0xFFCBD5E1) : Colors.black54;
    final dividerColor =
        isDark ? Colors.white12 : Colors.grey.withValues(alpha: 0.15);

    ref.listen<bool>(gpsPriorityProvider, (previous, next) {
      if (!next) {
        setState(() {
          _selectedCity = null;
        });
      }
    });

    final String? currentCity = isGpsActive ? 'Surabaya' : _selectedCity;

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
                        ? 'Lokasi otomatis terdeteksi via GPS (Surabaya). Preferensi wilayah dikunci sesuai koordinat perangkat.'
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
          DropdownButtonFormField<String>(
            key: ValueKey(currentCity),
            initialValue: currentCity,
            hint: const Text('Pilih Wilayah'),
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.location_city_outlined),
              helperText: isGpsActive ? 'Terkunci oleh prioritas GPS' : null,
              helperStyle: const TextStyle(color: Color(0xFFF59E0B)),
            ),
            items: _cities
                .map(
                  (city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city,
                      style: TextStyle(color: textColor),
                    ),
                  ),
                )
                .toList(),
            onChanged: isGpsActive
                ? null
                : (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
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
              'Simpan Preferensi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

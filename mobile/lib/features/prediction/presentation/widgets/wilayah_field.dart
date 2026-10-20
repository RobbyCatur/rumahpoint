import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme.dart';
import '../../data/services/wilayah_service.dart';
import '../../domain/entities/wilayah.dart';
import '../providers/prediction_providers.dart';

/// Ambil kab/kota tempat perangkat berada: poligon batas dulu, titik pusat
/// sebagai cadangan. `null` bila izin/GPS gagal.
Future<KabupatenKota?> deteksiWilayahSaatIni(WidgetRef ref) async {
  final pos = await ref.read(locationServiceProvider).currentPosition();
  if (pos == null) return null;
  final data = await ref.read(wilayahProvider.future);
  final batas = await ref.read(batasWilayahProvider.future);
  return WilayahService.locate(data, batas, pos.lat, pos.lng);
}

/// Bidang pemilihan wilayah yang dipakai Beranda dan Preferensi Profil:
/// label, tombol GPS, kotak pilih (bottom sheet provinsi → kab/kota),
/// dan catatan akurasi bila wilayah belum tercakup data latih.
class WilayahField extends ConsumerStatefulWidget {
  const WilayahField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'WILAYAH PROPERTI',
    this.showGpsButton = true,
    this.enabled = true,
    this.placeholder = 'Pilih kabupaten/kota',
  });

  final KabupatenKota? value;
  final ValueChanged<KabupatenKota> onChanged;
  final String label;
  final bool showGpsButton;

  /// `false` → pilihan manual dikunci (mis. saat prioritas GPS aktif).
  final bool enabled;
  final String placeholder;

  @override
  ConsumerState<WilayahField> createState() => _WilayahFieldState();
}

class _WilayahFieldState extends ConsumerState<WilayahField> {
  bool _mencariLokasi = false;

  Future<void> _detect() async {
    setState(() => _mencariLokasi = true);
    final hasil = await deteksiWilayahSaatIni(ref);
    if (!mounted) return;
    setState(() => _mencariLokasi = false);
    if (hasil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Lokasi tidak dapat diambil. Aktifkan GPS/izin lokasi atau pilih manual.'),
        ),
      );
      return;
    }
    widget.onChanged(hasil);
  }

  Future<void> _openPicker() async {
    final wilayah = await ref.read(wilayahProvider.future);
    if (!mounted) return;
    final hasil = await showModalBottomSheet<KabupatenKota>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WilayahPickerSheet(data: wilayah, selected: widget.value),
    );
    if (hasil != null) widget.onChanged(hasil);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.value;
    final tone = AppTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.label.isEmpty)
              const Spacer()
            else
              Expanded(child: _SectionLabel(widget.label)),
            if (widget.showGpsButton) ...[
              _mencariLokasi
                  ? Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tone.link,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 4, bottom: 2),
                      child: InkWell(
                        onTap: _detect,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.my_location_rounded,
                                  size: 15, color: tone.link),
                              const SizedBox(width: 4),
                              Text(
                                'Gunakan Lokasi Saat Ini',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: tone.link,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ],
          ],
        ),
        Opacity(
          opacity: widget.enabled ? 1 : 0.6,
          child: InkWell(
            onTap: widget.enabled ? _openPicker : null,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: tone.surface,
                border: Border.all(color: tone.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined,
                      size: 20, color: tone.textMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      w == null ? widget.placeholder : '${w.nama}, ${w.provinsi}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: w == null
                            ? FontWeight.w400
                            : FontWeight.w600,
                        color: w == null ? tone.textMuted : tone.text,
                      ),
                    ),
                  ),
                  if (widget.enabled)
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: tone.textMuted),
                ],
              ),
            ),
          ),
        ),
        if (w != null && !w.didukung) ...[
          const SizedBox(height: 10),
          const _AccuracyNote(),
        ],
      ],
    );
  }
}

/// Bottom sheet pemilih wilayah: pilih provinsi → pilih kab/kota.
/// Daftar dibatasi 5 item terlihat, dengan kolom pencarian.
class WilayahPickerSheet extends StatefulWidget {
  const WilayahPickerSheet({
    super.key,
    required this.data,
    required this.selected,
  });

  final List<Provinsi> data;
  final KabupatenKota? selected;

  @override
  State<WilayahPickerSheet> createState() => _WilayahPickerSheetState();
}

class _WilayahPickerSheetState extends State<WilayahPickerSheet> {
  Provinsi? _provinsi;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step2 = _provinsi != null;
    final items = step2
        ? widget.data
            .firstWhere((p) => p.nama == _provinsi!.nama)
            .kabupatenKota
            .where((k) => k.nama.toLowerCase().contains(_query.toLowerCase()))
            .toList()
        : widget.data
            .where((p) => p.nama.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) {
        final tone = AppTone.of(context);
        return Material(
          color: tone.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: tone.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    if (step2)
                      IconButton(
                        onPressed: () => setState(() {
                          _provinsi = null;
                          _query = '';
                          _searchCtrl.clear();
                        }),
                        color: tone.textMuted,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Kembali ke provinsi',
                      ),
                    Expanded(
                      child: Text(
                        step2 ? _provinsi!.nama : 'Pilih Provinsi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: tone.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: TextStyle(color: tone.text, fontSize: 14),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: step2
                        ? 'Cari kabupaten/kota...'
                        : 'Cari provinsi...',
                    hintStyle:
                        TextStyle(color: tone.textMuted, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search_rounded, size: 20, color: tone.textMuted),
                    filled: true,
                    fillColor: tone.border,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          BorderSide(color: AppColors.amber, width: 1.6),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Text('Tidak ditemukan.',
                            style: TextStyle(color: tone.textMuted)),
                      )
                    : ListView.builder(
                        controller: scrollCtrl,
                        // Tinggi item seragam → ~5 item terlihat penuh;
                        // sisanya digulir (tidak full ke bawah).
                        itemExtent: 65,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        itemCount: items.length,
                        itemBuilder: (context, i) {
                          if (!step2) {
                            final p = items[i] as Provinsi;
                            return Column(
                              children: [
                                ListTile(
                                  dense: true,
                                  title: Text(
                                    p.nama,
                                    style: TextStyle(
                                        color: tone.text, fontSize: 15),
                                  ),
                                  subtitle: Text(
                                    '${p.kabupatenKota.length} kab/kota',
                                    style: TextStyle(
                                        fontSize: 11, color: tone.textMuted),
                                  ),
                                  trailing: Icon(
                                      Icons.chevron_right_rounded,
                                      color: tone.textMuted),
                                  onTap: () => setState(() {
                                    _provinsi = p;
                                    _query = '';
                                    _searchCtrl.clear();
                                  }),
                                ),
                                Divider(height: 1, color: tone.border),
                              ],
                            );
                          }
                          final k = items[i] as KabupatenKota;
                          final aktif = widget.selected?.nama == k.nama &&
                              widget.selected?.provinsi == k.provinsi;
                          return Column(
                            children: [
                              ListTile(
                                dense: true,
                                title: Text(
                                  k.nama,
                                  style: TextStyle(
                                    color: tone.text,
                                    fontSize: 15,
                                    fontWeight: aktif
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                ),
                                trailing: k.didukung
                                    ? null
                                    : Tooltip(
                                        message: 'Data latih terbatas',
                                        child: Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: tone.accent),
                                      ),
                                onTap: () => Navigator.pop(context, k),
                              ),
                              Divider(height: 1, color: tone.border),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Catatan akurasi bila lokasi tidak tercakup data latih.
class _AccuracyNote extends StatelessWidget {
  const _AccuracyNote();

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tone.tintBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: tone.tintText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data latih terbatas di wilayah ini — estimasi bisa kurang akurat.',
              style: TextStyle(fontSize: 12, color: tone.tintText),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppTone.of(context).textMuted,
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../../../theme.dart';
import '../../domain/entities/prediction.dart';

/// Label lokasi yang sama dengan yang ditampilkan di kartu riwayat.
String predictionLocationLabel(Prediction p) =>
    p.provinsi.isEmpty ? p.lokasi : '${p.lokasi}, ${p.provinsi}';

/// Nilai filter riwayat. Semua field null berarti "tampilkan semua".
class HistoryFilter {
  const HistoryFilter({this.kategori, this.lokasi, this.tanggal});

  final String? kategori;
  final String? lokasi;
  final DateTimeRange? tanggal;

  int get activeCount =>
      (kategori == null ? 0 : 1) +
      (lokasi == null ? 0 : 1) +
      (tanggal == null ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  /// Apakah [p] lolos filter kategori, lokasi, dan rentang tanggal.
  bool matches(Prediction p) {
    if (kategori != null && p.kategori != kategori) return false;
    if (lokasi != null && predictionLocationLabel(p) != lokasi) return false;

    final range = tanggal;
    if (range != null) {
      final day = DateTime(
        p.createdAt.year,
        p.createdAt.month,
        p.createdAt.day,
      );
      final start = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      final end = DateTime(range.end.year, range.end.month, range.end.day);
      if (day.isBefore(start) || day.isAfter(end)) return false;
    }
    return true;
  }

  /// Pencarian teks bebas pada nama lokasi/provinsi.
  bool matchesQuery(Prediction p, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return p.lokasi.toLowerCase().contains(q) ||
        p.provinsi.toLowerCase().contains(q);
  }
}

/// Tampilkan dialog filter dengan latar belakang di-blur.
///
/// Mengembalikan filter baru saat "Terapkan" ditekan, atau null bila dialog
/// ditutup tanpa menerapkan.
Future<HistoryFilter?> showHistoryFilterDialog(
  BuildContext context, {
  required HistoryFilter initial,
  required List<String> locations,
}) {
  return showGeneralDialog<HistoryFilter>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Tutup filter',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _HistoryFilterDialog(initial: initial, locations: locations);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _HistoryFilterDialog extends StatefulWidget {
  const _HistoryFilterDialog({required this.initial, required this.locations});

  final HistoryFilter initial;
  final List<String> locations;

  @override
  State<_HistoryFilterDialog> createState() => _HistoryFilterDialogState();
}

class _HistoryFilterDialogState extends State<_HistoryFilterDialog> {
  late String? _kategori = widget.initial.kategori;

  /// Lokasi awal hanya dipakai bila masih ada di riwayat.
  late String? _lokasi = widget.locations.contains(widget.initial.lokasi)
      ? widget.initial.lokasi
      : null;

  late DateTimeRange? _tanggal = widget.initial.tanggal;

  void _close() => Navigator.of(context).pop();

  void _reset() {
    setState(() {
      _kategori = null;
      _lokasi = null;
      _tanggal = null;
    });
  }

  void _apply() {
    Navigator.of(context).pop(
      HistoryFilter(kategori: _kategori, lokasi: _lokasi, tanggal: _tanggal),
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _tanggal,
      helpText: 'Pilih rentang tanggal',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      saveText: 'Terapkan',
      fieldStartHintText: 'Dari',
      fieldEndHintText: 'Sampai',
      fieldStartLabelText: 'Tanggal mulai',
      fieldEndLabelText: 'Tanggal akhir',
    );
    if (picked != null && mounted) {
      setState(() => _tanggal = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.38)),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Material(
                  color: tone.surface,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: BorderSide(color: tone.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: tone.tintBg,
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                Icons.tune_rounded,
                                color: tone.accent,
                                size: 21,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Filter Riwayat',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: tone.text,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Pilih kriteria yang ingin ditampilkan.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: tone.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              tooltip: 'Tutup',
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close_rounded,
                                color: tone.textMuted,
                                size: 22,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(text: 'KATEGORI', tone: tone),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final value in <String?>[
                              null,
                              'Murah',
                              'Mahal',
                            ])
                              ChoiceChip(
                                label: Text(value ?? 'Semua'),
                                selected: _kategori == value,
                                onSelected: (_) =>
                                    setState(() => _kategori = value),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(text: 'LOKASI', tone: tone),
                        const SizedBox(height: 8),
                        InputDecorator(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _lokasi ?? '',
                              isExpanded: true,
                              isDense: true,
                              items: [
                                const DropdownMenuItem<String>(
                                  value: '',
                                  child: Text('Semua lokasi'),
                                ),
                                for (final l in widget.locations)
                                  DropdownMenuItem<String>(
                                    value: l,
                                    child: Text(
                                      l,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) => setState(
                                () => _lokasi = (v == null || v.isEmpty)
                                    ? null
                                    : v,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _SectionLabel(text: 'TANGGAL', tone: tone),
                        const SizedBox(height: 8),
                        _DateRangeField(
                          range: _tanggal,
                          onTap: _pickDateRange,
                          onClear: () => setState(() => _tanggal = null),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _reset,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Atur ulang'),
                            ),
                            const Spacer(),
                            FilledButton(
                              onPressed: _apply,
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                              ),
                              child: const Text('Terapkan'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.tone});

  final String text;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: tone.textMuted,
      ),
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.range,
    required this.onTap,
    required this.onClear,
  });

  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          suffixIcon: range == null
              ? Icon(
                  Icons.calendar_today_outlined,
                  color: tone.textMuted,
                  size: 20,
                )
              : IconButton(
                  onPressed: onClear,
                  tooltip: 'Hapus tanggal',
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    Icons.close_rounded,
                    color: tone.textMuted,
                    size: 20,
                  ),
                ),
        ),
        child: Text(
          range == null
              ? 'Semua tanggal'
              : '${formatTanggal(range!.start)} – ${formatTanggal(range!.end)}',
          style: TextStyle(
            fontSize: 14,
            color: range == null ? tone.textMuted : tone.text,
          ),
        ),
      ),
    );
  }
}

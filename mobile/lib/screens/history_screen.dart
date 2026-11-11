import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../features/prediction/domain/entities/prediction.dart';
import '../features/prediction/presentation/providers/prediction_providers.dart';
import '../features/prediction/presentation/widgets/history_filter_dialog.dart';
import '../theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  HistoryFilter _filter = const HistoryFilter();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _monthKey(DateTime d) => '${d.year}-${d.month}';

  /// Daftar lokasi unik dari riwayat (urut abjad) untuk dropdown filter.
  List<String> _availableLocations(List<Prediction> history) {
    final set = <String>{};
    for (final p in history) {
      set.add(predictionLocationLabel(p));
    }
    return set.toList()..sort();
  }

  List<Prediction> _applyFilter(List<Prediction> history) {
    return history.reversed
        .where((p) => _filter.matches(p) && _filter.matchesQuery(p, _query))
        .toList();
  }

  /// Kelompokkan item (sudah terurut terbaru) per bulan, terbaru dulu.
  List<({String key, DateTime month, List<Prediction> items})> _groupByMonth(
    List<Prediction> items,
  ) {
    final groups = <({String key, DateTime month, List<Prediction> items})>[];
    for (final p in items) {
      final key = _monthKey(p.createdAt);
      if (groups.isEmpty || groups.last.key != key) {
        groups.add((
          key: key,
          month: DateTime(p.createdAt.year, p.createdAt.month),
          items: [p],
        ));
      } else {
        groups.last.items.add(p);
      }
    }
    return groups;
  }

  Future<void> _openFilter(List<Prediction> history) async {
    final result = await showHistoryFilterDialog(
      context,
      initial: _filter,
      locations: _availableLocations(history),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  void _resetFilter() {
    setState(() {
      _filter = const HistoryFilter();
      _query = '';
      _searchCtrl.clear();
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text('Semua riwayat prediksi akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(predictionControllerProvider.notifier).clearHistory();
      if (mounted) _resetFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    final history = ref.watch(predictionControllerProvider).history;
    final items = _applyFilter(history);
    final groups = _groupByMonth(items);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Valuasi'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus semua',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(color: tone.text, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari riwayat lokasi...',
                hintStyle: TextStyle(color: tone.textMuted, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: tone.textMuted,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        tooltip: 'Hapus pencarian',
                        icon: Icon(
                          Icons.close_rounded,
                          color: tone.textMuted,
                          size: 18,
                        ),
                      ),
              ),
            ),
          ),
          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
              child: Row(
                children: [
                  Text(
                    '${items.length} hasil',
                    style: TextStyle(fontSize: 12.5, color: tone.textMuted),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _openFilter(history),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(
                      _filter.isEmpty
                          ? 'Filter'
                          : 'Filter (${_filter.activeCount})',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _filter.isEmpty
                          ? tone.textSoft
                          : tone.accent,
                      side: BorderSide(
                        color: _filter.isEmpty ? tone.border : tone.accent,
                      ),
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? (history.isEmpty
                      ? const _EmptyState()
                      : _NoResultState(onReset: _resetFilter))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: groups.length,
                    itemBuilder: (context, gi) {
                      final g = groups[gi];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              2,
                              gi == 0 ? 8 : 20,
                              2,
                              8,
                            ),
                            child: Text(
                              formatBulanPenuh(g.month),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: tone.textMuted,
                              ),
                            ),
                          ),
                          for (var i = 0; i < g.items.length; i++) ...[
                            if (i > 0) const SizedBox(height: 10),
                            _HistoryCard(p: g.items[i]),
                          ],
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Badge kategori kecil: hijau + panah turun untuk Murah,
/// merah + panah naik untuk Mahal.
class _KategoriBadge extends StatelessWidget {
  const _KategoriBadge({required this.kategori});

  final String kategori;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    final isMurah = kategori.toLowerCase() == 'murah';
    final fg = isMurah ? tone.positive : tone.negative;
    final bg = isMurah ? tone.positiveBg : tone.negativeBg;
    final icon = isMurah
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            kategori,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.p});

  final Prediction p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tone = AppTone.of(context);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          ref.read(predictionControllerProvider.notifier).select(p);
          context.push('/hasil');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tone.tintBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.home_work_rounded,
                  color: tone.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      predictionLocationLabel(p),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tone.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${p.luasM2.round()} m² • ${p.jumlahKamar} KT • '
                      '${p.jumlahKamarMandi} KM',
                      style: TextStyle(fontSize: 12, color: tone.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatTanggal(p.createdAt),
                      style: TextStyle(fontSize: 11, color: tone.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.estimasiString,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: tone.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _KategoriBadge(kategori: p.kategori),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 48, color: tone.border),
          const SizedBox(height: 12),
          Text(
            'Belum ada riwayat',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tone.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hasil prediksi akan tersimpan di sini.',
            style: TextStyle(fontSize: 12.5, color: tone.textMuted),
          ),
        ],
      ),
    );
  }
}

class _NoResultState extends StatelessWidget {
  const _NoResultState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_rounded, size: 56, color: tone.border),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tone.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tidak ada riwayat yang cocok dengan filter atau pencarianmu.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: tone.textMuted),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Atur ulang filter'),
            ),
          ],
        ),
      ),
    );
  }
}

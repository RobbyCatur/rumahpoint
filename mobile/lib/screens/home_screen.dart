import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/format.dart';
import '../features/prediction/domain/entities/wilayah.dart';
import '../features/prediction/presentation/widgets/wilayah_field.dart';
import '../features/prediction/presentation/providers/prediction_providers.dart';
import '../features/user/presentation/providers/user_providers.dart';
import '../theme.dart';

/// Usia bangunan yang dikirim ke model untuk tiap pilihan kondisi.
/// Model ML tetap butuh angka; user cukup memilih Baru/Bekas.
const kondisiUsia = {'Baru': 0, 'Bekas': 10};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  KabupatenKota? _wilayah;
  bool _mencariGps = false;
  double _luasTanah = 120;
  double _luasBangunan = 98;
  int _kamar = 3;
  int _kamarMandi = 2;
  String _kondisi = 'Baru';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // 1) Pulihkan angka form dari draft autosave. Wilayah sengaja tidak ikut
    //    dipulihkan: form selalu mulai dari preferensi Profil, dan pilihan
    //    manual di Beranda hanya berlaku selama sesi berjalan.
    final d = await ref.read(predictionControllerProvider.notifier).loadDraft();
    if (!mounted) return;
    if (d != null) {
      setState(() {
        _luasTanah = _clampDouble(d['lt'], 20, 500, _luasTanah);
        _luasBangunan = _clampDouble(d['lb'], 20, 500, _luasBangunan);
        _kamar = _clampInt(d['kamar'], 1, 10, _kamar);
        _kamarMandi = _clampInt(d['kamarMandi'], 1, 10, _kamarMandi);
        final kondisi = d['kondisi']?.toString();
        if (kondisiUsia.containsKey(kondisi)) _kondisi = kondisi!;
      });
    }
    // 2) Isi wilayah default dari preferensi Profil / GPS.
    await _isiWilayahDefault();
  }

  /// Nilai awal wilayah: preferensi Profil dipakai kecuali lokasi GPS
  /// diprioritaskan atau preferensi belum pernah disimpan.
  Future<void> _isiWilayahDefault() async {
    if (ref.read(gpsPriorityProvider)) return _pakaiGps();
    final preferensi = await _bacaPreferensi();
    if (preferensi != null) {
      if (mounted) _update(() => _wilayah = preferensi);
      return;
    }
    await _pakaiGps();
  }

  Future<KabupatenKota?> _bacaPreferensi() async {
    await ref.read(wilayahPreferenceProvider.notifier).siap;
    return ref.read(wilayahPreferenceProvider);
  }

  /// Posisi perangkat mengambil alih form. Gagal mengambil GPS → nilai
  /// saat ini dibiarkan (pemakai masih bisa memilih manual).
  Future<void> _pakaiGps() async {
    if (_mencariGps) return;
    _mencariGps = true;
    final hasil = await deteksiWilayahSaatIni(ref);
    _mencariGps = false;
    if (hasil != null && mounted) _update(() => _wilayah = hasil);
  }

  Future<void> _pakaiPreferensi() async {
    final preferensi = await _bacaPreferensi();
    if (preferensi != null && mounted) _update(() => _wilayah = preferensi);
  }

  static double _clampDouble(dynamic v, double min, double max, double fb) {
    final x = (v as num?)?.toDouble();
    return x == null ? fb : x.clamp(min, max);
  }

  static int _clampInt(dynamic v, int min, int max, int fb) {
    final x = (v as num?)?.toInt();
    return x == null ? fb : x.clamp(min, max);
  }

  Future<void> _saveDraft() async {
    await ref.read(predictionControllerProvider.notifier).saveDraft({
      'lt': _luasTanah,
      'lb': _luasBangunan,
      'kamar': _kamar,
      'kamarMandi': _kamarMandi,
      'kondisi': _kondisi,
    });
  }

  /// Semua perubahan input lewat sini: setState + autosave draft.
  void _update(void Function() fn) {
    setState(fn);
    _saveDraft();
  }

  /// Jangkar fitur utama (banner + form) untuk digulir dari tombol CTA.
  final _formKey = GlobalKey();

  void _scrollToForm() {
    final ctx = _formKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      alignment: 0.02,
    );
  }

  Future<void> _submit() async {
    final w = _wilayah;
    if (w == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih wilayah properti dulu.')),
      );
      return;
    }
    final ctrl = ref.read(predictionControllerProvider.notifier);
    await ctrl.predict(
      luasM2: _luasTanah,
      luasBangunan: _luasBangunan,
      jumlahKamar: _kamar,
      jumlahKamarMandi: _kamarMandi,
      usiaBangunan: kondisiUsia[_kondisi]!,
      kondisi: _kondisi,
      lokasi: w.nama,
      provinsi: w.provinsi,
      lokasiDidukung: w.didukung,
    );
    if (mounted && ref.read(predictionControllerProvider).current != null) {
      context.push('/hasil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionControllerProvider);
    final tone = AppTone.of(context);

    // Preferensi Profil → form Beranda. Setiap perubahan langsung diikuti,
    // kecuali lokasi GPS yang diprioritaskan (posisi perangkat yang menang).
    ref.listen<KabupatenKota?>(wilayahPreferenceProvider, (previous, next) {
      if (next == null || next == previous) return;
      if (ref.read(gpsPriorityProvider)) return;
      _update(() => _wilayah = next);
    });

    // Sakelar prioritas GPS berlaku seketika: dinyalakan → form ikut posisi
    // perangkat; dimatikan → form kembali ikut preferensi Profil.
    ref.listen<bool>(gpsPriorityProvider, (previous, next) {
      if (previous == next) return;
      if (next) {
        _pakaiGps();
      } else {
        _pakaiPreferensi();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Header(),
            const SizedBox(height: 28),
            _Greeting(onStart: _scrollToForm),
            const SizedBox(height: 32),
            Container(key: _formKey, child: const _Banner()),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WilayahField(
                      label: 'WILAYAH PROPERTI',
                      value: _wilayah,
                      onChanged: (v) => _update(() => _wilayah = v),
                    ),
                    const SizedBox(height: 20),
                    _SliderField(
                      label: 'Luas Tanah (LT)',
                      value: _luasTanah,
                      min: 20,
                      max: 500,
                      onChanged: (v) => _update(() => _luasTanah = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderField(
                      label: 'Luas Bangunan (LB)',
                      value: _luasBangunan,
                      min: 20,
                      max: 500,
                      onChanged: (v) => _update(() => _luasBangunan = v),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StepperField(
                            label: 'Kamar Tidur',
                            value: _kamar,
                            min: 1,
                            max: 10,
                            onChanged: (v) => _update(() => _kamar = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StepperField(
                            label: 'Kamar Mandi',
                            value: _kamarMandi,
                            min: 1,
                            max: 10,
                            onChanged: (v) => _update(() => _kamarMandi = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _KondisiPicker(
                      value: _kondisi,
                      onChanged: (v) => _update(() => _kondisi = v),
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memprediksi. Pastikan server cloud aktif.',
                        style: TextStyle(
                          color: tone.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: state.loading ? null : _submit,
                      icon: state.loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.calculate_outlined, size: 20),
                      label: Text(
                        state.loading
                            ? 'Menghitung...'
                            : 'Hitung Valuasi Sekarang',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Model Random Forest • mencakup 500+ kab/kota se-Indonesia',
              textAlign: TextAlign.center,
              style: TextStyle(color: tone.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pilihan kondisi bangunan: Baru / Bekas (pengganti stepper usia).
class _KondisiPicker extends StatelessWidget {
  const _KondisiPicker({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kondisi Bangunan',
          style: TextStyle(fontSize: 12, color: tone.textMuted),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tone.scaffold,
            border: Border.all(color: tone.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final k in ['Baru', 'Bekas'])
                Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(k),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: value == k
                            ? tone.tintBg
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        border: value == k
                            ? Border.all(color: AppColors.amber, width: 1.4)
                            : null,
                      ),
                      child: Text(
                        k,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: value == k
                              ? tone.tintText
                              : tone.textMuted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/rumahpoint.png',
          width: 44,
          height: 44,
          errorBuilder: (_, _, _) => Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.amber,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.home_work_rounded, color: Colors.white),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RumahPoint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Valuasi Properti Berbasis AI',
                style: TextStyle(
                    fontSize: 12, color: AppTone.of(context).textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sapaan + penjelasan singkat di bagian atas beranda.
/// CTA hanya menggulir ke fitur utama di halaman yang sama.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.onStart});

  final VoidCallback onStart;

  static String _sapaan() {
    final h = DateTime.now().hour;
    if (h >= 4 && h < 11) return 'Selamat pagi';
    if (h >= 11 && h < 15) return 'Selamat siang';
    if (h >= 15 && h < 19) return 'Selamat sore';
    return 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_sapaan()},',
          style: TextStyle(fontSize: 13, color: tone.textMuted),
        ),
        const SizedBox(height: 6),
        const Text(
          'Berapa harga wajar rumah impianmu?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Isi kriteria rumah di bawah dan model machine learning kami '
          'mengestimasi nilai pasarnya dalam hitungan detik, lengkap '
          'dengan kategori Murah/Mahal.',
          style: TextStyle(fontSize: 13.5, color: tone.textSoft, height: 1.5),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          label: const Text('Mulai Hitung Valuasi'),
          style: OutlinedButton.styleFrom(
            foregroundColor: tone.accent,
            side: const BorderSide(color: AppColors.amber),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalkulasi Nilai Pasar Properti',
                  style: TextStyle(
                    color: tone.onAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Estimasi harga wajar dari data properti di seluruh Indonesia.',
                  style: TextStyle(
                      color: tone.onAccent.withValues(alpha: 0.82),
                      fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.auto_graph_rounded, color: tone.onAccent, size: 36),
        ],
      ),
    );
  }
}

/// Slider + input angka manual. Slider = penyesuaian cepat (dibulatkan),
/// keyboard = nilai presisi (mendukung float, mis. "120,5").
class _SliderField extends StatefulWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  State<_SliderField> createState() => _SliderFieldState();
}

class _SliderFieldState extends State<_SliderField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: formatLuas(widget.value));
    _focus = FocusNode()
      ..addListener(() {
        // Saat selesai mengetik, rapikan teks ke nilai valid terakhir.
        if (!_focus.hasFocus) _resetText();
      });
  }

  @override
  void didUpdateWidget(covariant _SliderField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focus.hasFocus) _resetText();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _resetText() {
    final s = formatLuas(widget.value);
    if (_ctrl.text != s) _ctrl.text = s;
  }

  /// Terima koma maupun titik desimal; clamp ke rentang slider.
  void _commit(String raw) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
    if (v == null) return; // ketikan sementara (""/"1,") → tunggu
    final clamped = v.clamp(widget.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 104,
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tone.accent,
                ),
                onChanged: _commit,
                onSubmitted: (raw) {
                  _commit(raw);
                  _focus.unfocus();
                },
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: tone.tintBg,
                  suffixText: 'm²',
                  suffixStyle: TextStyle(
                    fontSize: 11,
                    color: tone.accent,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppColors.amber,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: widget.value,
          min: widget.min,
          max: widget.max,
          onChanged: (v) => widget.onChanged(v.roundToDouble()),
        ),
      ],
    );
  }
}

/// Stepper −/+ dengan angka yang juga bisa diketik manual.
/// Nilai tetap bilangan bulat dan di-clamp ke [min, max].
class _StepperField extends StatefulWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  State<_StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<_StepperField> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.value}');
    _focus = FocusNode()
      ..addListener(() {
        if (!_focus.hasFocus) _resetText();
      });
  }

  @override
  void didUpdateWidget(covariant _StepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_focus.hasFocus) _resetText();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _resetText() {
    final s = '${widget.value}';
    if (_ctrl.text != s) _ctrl.text = s;
  }

  void _commit(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null) return;
    final clamped = v.clamp(widget.min, widget.max);
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 12, color: tone.textMuted),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: tone.surface,
            border: Border.all(color: tone.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: widget.value > widget.min
                    ? () => widget.onChanged(widget.value - 1)
                    : null,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: tone.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  onChanged: _commit,
                  onSubmitted: (raw) {
                    _commit(raw);
                    _focus.unfocus();
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onPressed: widget.value < widget.max
                    ? () => widget.onChanged(widget.value + 1)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tone = AppTone.of(context);
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null
              ? tone.accent
              : tone.textMuted.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/prediction_controller.dart';
import '../theme.dart';

/// Kota yang didukung model (sesuai dataset union).
const cities = [
  'Bekasi',
  'Bogor',
  'Depok',
  'Jakarta Selatan',
  'Jakarta Utara',
  'Surabaya',
  'Tangerang',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _city = 'Jakarta Selatan';
  double _luasTanah = 120;
  double _luasBangunan = 98;
  int _kamar = 3;
  int _kamarMandi = 2;
  int _usia = 10;

  Future<void> _submit() async {
    final ctrl = ref.read(predictionControllerProvider.notifier);
    await ctrl.predict(
      luasM2: _luasTanah,
      luasBangunan: _luasBangunan,
      jumlahKamar: _kamar,
      jumlahKamarMandi: _kamarMandi,
      usiaBangunan: _usia,
      lokasi: _city,
    );
    if (mounted && ref.read(predictionControllerProvider).current != null) {
      context.push('/hasil');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const _Header(),
            const SizedBox(height: 20),
            const _Banner(),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('WILAYAH PROPERTI'),
                    DropdownButtonFormField<String>(
                      initialValue: _city,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                      ),
                      items: cities
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _city = v!),
                    ),
                    const SizedBox(height: 20),
                    _SliderField(
                      label: 'Luas Tanah (LT)',
                      value: _luasTanah,
                      min: 20,
                      max: 500,
                      onChanged: (v) => setState(() => _luasTanah = v),
                    ),
                    const SizedBox(height: 12),
                    _SliderField(
                      label: 'Luas Bangunan (LB)',
                      value: _luasBangunan,
                      min: 20,
                      max: 500,
                      onChanged: (v) => setState(() => _luasBangunan = v),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final steppers = [
                          _StepperField(
                            label: 'Kamar Tidur',
                            value: _kamar,
                            min: 1,
                            max: 10,
                            onChanged: (v) => setState(() => _kamar = v),
                          ),
                          _StepperField(
                            label: 'Kamar Mandi',
                            value: _kamarMandi,
                            min: 1,
                            max: 10,
                            onChanged: (v) => setState(() => _kamarMandi = v),
                          ),
                          _StepperField(
                            label: 'Usia (Thn)',
                            value: _usia,
                            min: 0,
                            max: 50,
                            onChanged: (v) => setState(() => _usia = v),
                          ),
                        ];
                        // Layar sempit (dp kecil / font diperbesar): tumpuk
                        // vertikal agar isi stepper tidak overflow.
                        if (constraints.maxWidth < 340) {
                          return Column(
                            children: [
                              steppers[0],
                              const SizedBox(height: 12),
                              steppers[1],
                              const SizedBox(height: 12),
                              steppers[2],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: steppers[0]),
                            const SizedBox(width: 10),
                            Expanded(child: steppers[1]),
                            const SizedBox(width: 10),
                            Expanded(child: steppers[2]),
                          ],
                        );
                      },
                    ),
                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Gagal memprediksi. Pastikan server cloud aktif.',
                        style: TextStyle(
                          color: Colors.red.shade700,
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
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.calculate_outlined, size: 20),
                      label: Text(state.loading
                          ? 'Menghitung...'
                          : 'Hitung Valuasi Sekarang'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Model Random Forest • R² 0,85 • 7 kota',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.home_work_rounded, color: Colors.white),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RumahPoint',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              Text(
                'Valuasi Properti Berbasis AI',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kalkulasi Nilai Pasar Properti',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Estimasi harga wajar dari 3.700+ data properti di 7 kota.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Icon(Icons.auto_graph_rounded, color: Colors.white, size: 36),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amberSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} m²',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amberDark,
                ),
              ),
            ),
          ],
        ),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}

class _StepperField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StepButton(
                icon: Icons.remove,
                onPressed: value > min ? () => onChanged(value - 1) : null,
              ),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              _StepButton(
                icon: Icons.add,
                onPressed: value < max ? () => onChanged(value + 1) : null,
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? AppColors.amberDark : AppColors.line,
        ),
      ),
    );
  }
}

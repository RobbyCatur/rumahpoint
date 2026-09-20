import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../state/prediction_controller.dart';

const cities = [
  'Bogor', 'Bekasi', 'Depok', 'Tangerang', 'Jakarta Utara', 'Jakarta Selatan',
];

class FormScreen extends ConsumerStatefulWidget {
  const FormScreen({super.key});

  @override
  ConsumerState<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends ConsumerState<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _luas = TextEditingController(text: '120');
  final _kamar = TextEditingController(text: '3');
  final _kamarMandi = TextEditingController(text: '2');
  final _usia = TextEditingController(text: '10');
  String _city = cities.first;

  @override
  void dispose() {
    _luas.dispose();
    _kamar.dispose();
    _kamarMandi.dispose();
    _usia.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ctrl = ref.read(predictionControllerProvider.notifier);
    await ctrl.predict(
      luasM2: double.parse(_luas.text),
      jumlahKamar: int.parse(_kamar.text),
      jumlahKamarMandi: int.parse(_kamarMandi.text),
      usiaBangunan: int.parse(_usia.text),
      lokasi: _city,
    );
    if (mounted) {
      final state = ref.read(predictionControllerProvider);
      if (state.current != null) context.push('/result');
    }
  }

  InputDecoration _deco(String label) =>
      InputDecoration(labelText: label, border: const OutlineInputBorder());

  Widget _field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: _deco(label),
        validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(predictionControllerProvider).loading;
    final error = ref.watch(predictionControllerProvider).error;
    return Scaffold(
      appBar: AppBar(title: const Text('Rumah Point - Prediksi Harga')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _field(_luas, 'Luas tanah (m2)'),
              _field(_kamar, 'Jumlah kamar tidur'),
              _field(_kamarMandi, 'Jumlah kamar mandi'),
              _field(_usia, 'Usia bangunan (tahun)'),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: _deco('Lokasi'),
                items: cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v!),
              ),
              const SizedBox(height: 20),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(error,
                      style: const TextStyle(color: Colors.red)),
                ),
              FilledButton.icon(
                onPressed: loading ? null : _submit,
                icon: loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.calculate),
                label: const Text('Hitung Estimasi Harga'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.push('/history'),
                icon: const Icon(Icons.history),
                label: const Text('Riwayat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

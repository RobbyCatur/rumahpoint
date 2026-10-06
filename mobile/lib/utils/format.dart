/// Helper format angka & tanggal (tanpa dependensi intl).
library;

/// 1520000000 -> "Rp 1.520.000.000"
String formatRupiah(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer('Rp ');
  for (var i = 0; i < digits.length; i++) {
    buffer.write(digits[i]);
    final remaining = digits.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// 2025-09-12 -> "12 Sep 2025"
String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// 0.952 -> "95,2%"
String formatPersen(double value) =>
    '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

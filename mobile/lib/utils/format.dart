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

const _bulanPenuh = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// 2025-09-12 -> "12 Sep 2025"
String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

/// 2025-09-12 -> "Sep 2025"
String formatBulanSingkat(DateTime d) => '${_bulan[d.month - 1]} ${d.year}';

/// 2025-09-12 -> "September 2025"
String formatBulanPenuh(DateTime d) => '${_bulanPenuh[d.month - 1]} ${d.year}';

/// 0.952 -> "95,2%"
String formatPersen(double value) =>
    '${(value * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

/// 120.0 -> "120", 120.5 -> "120,5" (maks 2 desimal, koma gaya Indonesia).
/// Dipakai untuk luas tanah/bangunan yang kini mendukung nilai float.
String formatLuas(num value) {
  var s = value.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

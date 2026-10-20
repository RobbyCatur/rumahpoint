import 'package:flutter_test/flutter_test.dart';

import 'package:rumahpoint/features/prediction/data/services/wilayah_service.dart';
import 'package:rumahpoint/features/prediction/domain/entities/wilayah.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final data = [
    Provinsi(
      nama: 'Jawa Barat',
      kabupatenKota: [
        const KabupatenKota(
            nama: 'Bekasi', provinsi: 'Jawa Barat', didukung: true, lat: -6.24, lng: 107.0),
        const KabupatenKota(
            nama: 'Bandung', provinsi: 'Jawa Barat', didukung: false, lat: -6.92, lng: 107.61),
      ],
    ),
    Provinsi(
      nama: 'DKI Jakarta',
      kabupatenKota: [
        const KabupatenKota(
            nama: 'Jakarta Selatan', provinsi: 'DKI Jakarta', didukung: true, lat: -6.28, lng: 106.80),
      ],
    ),
  ];

  test('search: substring case-insensitive, dibatasi limit', () {
    expect(WilayahService.search(data, 'bek').single.nama, 'Bekasi');
    expect(WilayahService.search(data, 'JAKARTA').single.nama, 'Jakarta Selatan');
    expect(WilayahService.search(data, ''), isEmpty);
    expect(WilayahService.search(data, 'zzz'), isEmpty);
    // limit: 3 item cocok "a" tapi dibatasi 2
    expect(WilayahService.search(data, 'a', limit: 2), hasLength(2));
  });

  test('nearest: kab/kota terdekat dari titik GPS', () {
    // Sekitar Jakarta Selatan
    expect(WilayahService.nearest(data, -6.29, 106.81).nama, 'Jakarta Selatan');
    // Sekitar Bandung
    expect(WilayahService.nearest(data, -6.90, 107.60).nama, 'Bandung');
  });

  test('asset wilayah.json: 34 provinsi, 515 kab/kota, semua berkoordinat',
      () async {
    final data = await WilayahService.load();
    expect(data, hasLength(34));
    final semua = data.expand((p) => p.kabupatenKota).toList();
    expect(semua, hasLength(515));
    expect(semua.every((k) => k.lat != 0 || k.lng != 0), isTrue);
    // 7 kota didukung model + 3 kabupaten kembar (nama sama di dataset).
    expect(semua.where((k) => k.didukung), hasLength(10));
  });
}

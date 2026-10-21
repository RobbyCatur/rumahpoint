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

  test('dalamBatas: poligon terkecil yang memuat titik, lubang dihormati', () {
    final dataJatim = [
      Provinsi(nama: 'Jawa Timur', kabupatenKota: [
        const KabupatenKota(
            nama: 'Malang',
            provinsi: 'Jawa Timur',
            didukung: true,
            lat: -7.97,
            lng: 112.63),
        const KabupatenKota(
            nama: 'Kabupaten Malang',
            provinsi: 'Jawa Timur',
            didukung: true,
            lat: -8.05,
            lng: 112.55),
      ]),
    ];
    // kabupaten membentang luas, kota kecil di dalamnya (kasus Malang).
    // Cincin disimpan terpipih: [lng, lat, lng, lat, …].
    final kabupaten = BatasWilayah(
        nama: 'Kabupaten Malang',
        provinsi: 'Jawa Timur',
        bagian: [
          [
            [112.4, -8.2, 112.9, -8.2, 112.9, -7.7, 112.4, -7.7, 112.4, -8.2]
          ]
        ]);
    final kota = BatasWilayah(
        nama: 'Malang',
        provinsi: 'Jawa Timur',
        bagian: [
          [
            [
              112.60, -8.02, 112.66, -8.02, 112.66, -7.95, 112.60, -7.95,
              112.60, -8.02
            ],
            // lubang: titik di dalamnya bukan wilayah kota
            [
              112.62, -7.99, 112.64, -7.99, 112.64, -7.97, 112.62, -7.97,
              112.62, -7.99
            ]
          ]
        ]);
    final batas = [kabupaten, kota];

    // di dalam kota → kota (poligon terkecil), bukan kabupaten induknya
    expect(
        WilayahService.dalamBatas(dataJatim, batas, -7.98, 112.61)?.nama, 'Malang');
    // di dalam lubang kota → tetap kabupaten
    expect(WilayahService.dalamBatas(dataJatim, batas, -7.98, 112.63)?.nama,
        'Kabupaten Malang');
    // di luar semuanya → null
    expect(WilayahService.dalamBatas(dataJatim, batas, -7.0, 110.0), isNull);
  });

  test('locate: titik di laut jatuh ke cadangan centroid', () async {
    final nyata = await WilayahService.load();
    final batas = await WilayahService.loadBatas();
    // tengah Laut Jawa — tidak ada poligon yang memuat
    expect(WilayahService.dalamBatas(nyata, batas, -5.5, 111.0), isNull);
    expect(WilayahService.locate(nyata, batas, -5.5, 111.0).nama, isNotEmpty);
  });

  test('batas.json: titik terkenal jatuh di kab/kota yang benar', () async {
    final nyata = await WilayahService.load();
    final batas = await WilayahService.loadBatas();
    const titik = <String, ({double lat, double lng, String nama})>{
      'Balai Kota Malang': (lat: -7.9666, lng: 112.6326, nama: 'Malang'),
      'Kepanjen': (lat: -8.1037, lng: 112.5675, nama: 'Kabupaten Malang'),
      'Kota Batu': (lat: -7.8610, lng: 112.5230, nama: 'Batu'),
      'Kota Bekasi': (lat: -6.2383, lng: 106.9756, nama: 'Bekasi'),
      'Cikarang': (lat: -6.3100, lng: 107.1000, nama: 'Kabupaten Bekasi'),
      'Kota Bandung': (lat: -6.9175, lng: 107.6191, nama: 'Bandung'),
      'Soreang': (lat: -7.0360, lng: 107.6200, nama: 'Kabupaten Bandung'),
      'Jakarta Selatan': (lat: -6.2800, lng: 106.8100, nama: 'Jakarta Selatan'),
      'Gubeng Surabaya': (lat: -7.2580, lng: 112.7450, nama: 'Surabaya'),
      'Tigaraksa': (lat: -6.2700, lng: 106.5400, nama: 'Kabupaten Tangerang'),
      'Kota Tangerang': (lat: -6.1783, lng: 106.6319, nama: 'Tangerang'),
      'Banjarmasin': (lat: -3.3180, lng: 114.5900, nama: 'Banjarmasin'),
    };
    for (final e in titik.entries) {
      final t = e.value;
      expect(WilayahService.dalamBatas(nyata, batas, t.lat, t.lng)?.nama,
          t.nama,
          reason: e.key);
    }
  });

  test('asset wilayah.json: 34 provinsi, 515 kab/kota, semua berkoordinat',
      () async {
    final data = await WilayahService.load();
    expect(data, hasLength(34));
    final semua = data.expand((p) => p.kabupatenKota).toList();
    expect(semua, hasLength(515));
    expect(semua.every((k) => k.lat != 0 || k.lng != 0), isTrue);
    // Bendera didukung dibangun ml/build_wilayah.py dari meta.json model:
    // wilayah dengan >= 100 baris data latih dianggap cukup.
    expect(semua.where((k) => k.didukung), hasLength(118));
  });
}

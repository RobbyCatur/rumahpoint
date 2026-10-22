# Rumah Point — aplikasi mobile (Flutter)

Prediksi harga properti Indonesia (regresi) + kategori Murah/Mahal (klasifikasi).
Perhitungan model **tidak** berjalan di gawai: form dikirim ke layanan cloud ML
(`POST /predict`), hasil ditampilkan di layar. Dokumen proyek ada di `../docs/` dan `../AGENTS.md`.

## Menjalankan

```bash
flutter pub get

# Emulator Android (cloud ML jalan di laptop):
python ../cloud_ml/app.py                 # :8081
flutter run --dart-define=ML_URL=http://10.0.2.2:8081

# Device fisik via USB — reverse port dulu, diulang setiap kali cabut/reboot:
adb reverse tcp:8081 tcp:8081
flutter run --dart-define=ML_URL=http://127.0.0.1:8081

# Environment publik (Cloudflare tunnel):
flutter run --dart-define=ML_URL=https://ml.soraven.web.id
```

`ML_URL` punya nilai bawaan `http://127.0.0.1:8081` (`String.fromEnvironment` di
`lib/features/prediction/data/datasources/prediction_remote_datasource.dart`). Angka itu **hanya**
sampai ke laptop lewat `adb reverse`; di emulator standar harus eksplisit `10.0.2.2`. Kalau URL-nya
tak terjangkau, layar hasil menampilkan pesan kesalahan jaringan — bukan crash.

## Periksa sebelum commit

```bash
flutter analyze
flutter test
```

## Struktur

Arsitektur **Clean Architecture, feature-first**: `presentation → domain ← data`, lapisan domain
bersih dari Flutter/Dio.

| Path | Isi |
|------|-----|
| `lib/core/` | `failures.dart`, `format.dart` (pemformatan Rp) |
| `lib/features/prediction/` | entity `Prediction`, `PredictionRepository` (Dio + SharedPreferences), use case, `presentation/` (screens, providers/Riverpod DI) |
| `lib/features/prediction/data/services/` | `wilayah_service.dart` (bendera `didukung` per wilayah), `location_service.dart` (GPS → kab/kota terdekat) |
| `lib/features/user/` | entity `User`, penyimpanan sesi lewat `flutter_secure_storage` |
| `lib/screens/` | halaman lama (masih dipakai router) |
| `lib/theme.dart` | satu sumber warna/tema — aksen amber `#F59E0B` + slate |
| `assets/data/wilayah.json` | 34 provinsi → 515 kab/kota + koordinat + bendera `didukung` |

Router: `go_router` dengan `StatefulShellRoute` — `/` login, `/beranda`, `/riwayat`, `/profil`,
`/hasil` (geser kiri → Riwayat, kanan → Beranda).

## Catatan penting

- `assets/data/wilayah.json` **dihasilkan** oleh `python ../ml/build_wilayah.py` (bendera `didukung`
  mengikuti model yang sedang aktif). Jangan sunting angkanya manual — jalankan generator itu
  sesudah `train.py`, kalau tidak, form dan API bisa berbeda pendapat soal wilayah mana yang aman.
- Riwayat **masih tersimpan lokal** (`shared_preferences`); riwayat server-side menunggu backend auth.
- `android/app/src/main/AndroidManifest.xml` memakai `usesCleartextTraffic` supaya `http://` ke
  laptop saat dev bisa jalan.
- `test/wilayah_service_test.dart` mengunci **jumlah wilayah `didukung` = 118**. Kalau training
  berikutnya menggeser sebaran data, jalankan generator lalu sesuaikan angkanya — itu urutan yang
  benar, bukan regresi.

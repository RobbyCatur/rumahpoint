# Rumah Point

Aplikasi mobile (Flutter) untuk **prediksi harga properti Indonesia** (regresi) dan **kategori harga Murah/Mahal** (klasifikasi), dengan **login/register**, **riwayat per-user**, serta **panel admin** untuk pengelolaan data. Proyek PBL Teknik Informatika Polinema, Semester 5.

Prediksi dihitung **langsung oleh layanan cloud ML** (mobile → cloud). Semua yang menyentuh database (akun, riwayat, data latih) ditangani **backend web Flask + SQLite**.

## Status implementasi

**Sudah berjalan & teruji**
- Prediksi mobile → cloud: `POST /predict` (regresi + klasifikasi + rentang estimasi)
- Dataset **union 7 kota** (3.730 baris) + seed DB + training (R² **0,85**, akurasi kategori **93,3%**)
- Web CRUD dataset properti (Flask + SQLite) + `GET /api/properti`
- CORS cloud, `AndroidManifest` (cleartext + INTERNET), `flutter analyze`/`test` lulus

**Sedang dikembangkan** (desain final, lihat `docs/`)
- Auth **JWT hybrid** (access 15 mnt + refresh 7 hari, rotasi + reuse detection)
- Riwayat per-user server-side + cache offline
- Layar Login/Register mobile; panel admin (role `admin`)
- Fitur perbandingan harga penawaran penjual (`harga_diminta`)

## Arsitektur

```
Mobile (Flutter) --POST /predict (tanpa DB)--> Cloud ML (:8081) --> hasil --> Mobile
Mobile --login/register/refresh/riwayat--> Backend Web (:8080, Flask + SQLite + JWT)
Admin (web) --CRUD dataset + statistik--> Backend Web --> SQLite --train.py--> model --> Cloud ML
```

## Struktur repositori

| Path | Isi |
|------|-----|
| `dataset/` | Dataset union multi-kota + skrip build + sumber mentah (atribusi di `dataset/README.md`) |
| `database/` | `seed.py` → `properti.db` (SQLite, kategori per-sentile per-kota) |
| `ml/` | `train.py`, hasil metrik `metrics.json` |
| `cloud_ml/` | `app.py` (:8081) + model terlatih (`model/*.joblib`, `meta.json`) |
| `web/` | `app.py` (:8080) CRUD dataset properti |
| `mobile/` | Aplikasi Flutter |
| `docs/` | Dokumen perencanaan internal (proposal, rencana eksekusi, backlog, wireframe) — lokal, tidak ikut repo |

## Prasyarat

- Python 3.10+
- Flutter SDK (stable)
- Android device/emulator (untuk menjalankan mobile)

## Cara menjalankan

```bash
# 1. Dependensi Python
pip install -r cloud_ml/requirements.txt   # seed, train, cloud (pandas, scikit-learn, flask, ...)
pip install -r web/requirements.txt        # web CRUD

# 2. Siapkan database dari dataset union
#    (seed.py membangun ulang DB lalu otomatis menerapkan migrasi skema — tabel `cities`, kolom `city_id`)
python database/seed.py
#    DB yang sudah ada tanpa seed: python database/migrate.py

# 3. Latih model (tulis ulang cloud_ml/model/)
python ml/train.py

# 4. Jalankan cloud ML (:8081)
python cloud_ml/app.py

# 5. (opsional) Jalankan web CRUD dataset (:8080)
python web/app.py
```

Mobile:

```bash
cd mobile
flutter pub get

# Emulator Android:
flutter run --dart-define=ML_URL=http://10.0.2.2:8081

# Device fisik via USB (adb reverse dulu):
adb reverse tcp:8081 tcp:8081
flutter run --dart-define=ML_URL=http://127.0.0.1:8081
```

## Kontrak `POST /predict` (cloud ML)

Field wajib: `luas_m2`, `jumlah_kamar`, `jumlah_kamar_mandi`, `usia_bangunan`, `lokasi`.
Opsional: `luas_bangunan` (kosong → imputasi median dari `meta.json`).

```bash
curl -X POST http://127.0.0.1:8081/predict \
  -H "Content-Type: application/json" \
  -d '{"luas_m2":120,"jumlah_kamar":3,"jumlah_kamar_mandi":2,"usia_bangunan":5,"lokasi":"Depok"}'
```

```json
{
  "estimasi_harga_rupiah": 1500000000,
  "estimasi_harga_string": "Rp 1.50 Miliar",
  "kategori_harga": "Mahal",
  "confidence": 0.93,
  "rentang_bawah": "Rp 1.12 Miliar",
  "rentang_atas": "Rp 1.88 Miliar"
}
```

`GET /health` untuk cek kesiapan layanan.

## Model & dataset

- **7 kota**: Bekasi, Bogor, Depok, Jakarta Selatan, Jakarta Utara, Surabaya, Tangerang
- **Regresi** RandomForest: R² **0,85**, MAE ≈ Rp 806 juta (metrik per-kota di `ml/metrics.json`)
- **Klasifikasi**: akurasi **93,3%** (label diturunkan per-sentile per-kota)
- Preprocessing: harga `log10`, parsing angka dari teks ("68.0 m2"), normalisasi nama kota, imputasi median `luas_bangunan`
- Sumber data & atribusi (wajib dikredit, RPP §10): `dataset/README.md`

Alur retrain: ubah data via web/admin → `python ml/train.py` → restart cloud.
(JANGAN jalankan `seed.py` setelah ada entri manual di web — seed membangun ulang DB dari CSV dan menghapus entri `manual-web`.)

## Tech stack

Python (Flask, scikit-learn, pandas) · SQLite · Flutter/Dart (`go_router`, `Riverpod`, `dio`, `shared_preferences`; rencana: `flutter_secure_storage`).

## Pengujian

```bash
cd mobile
flutter analyze
flutter test
```
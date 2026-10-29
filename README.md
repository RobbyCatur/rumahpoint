# Rumah Point

Aplikasi mobile (Flutter) untuk **prediksi harga properti Indonesia** (regresi) dan **kategori harga Murah/Mahal** (klasifikasi), dengan **login/register**, **riwayat per-user**, serta **panel admin** untuk pengelolaan data. Proyek PBL Teknik Informatika Polinema, Semester 5.

Prediksi dihitung **langsung oleh layanan cloud ML** (mobile → cloud). Semua yang menyentuh database (akun, riwayat, data latih) ditangani **backend web Flask + SQLite**.

## Status implementasi

**Sudah berjalan & teruji**
- Prediksi mobile → cloud: `POST /predict` (regresi + klasifikasi + rentang estimasi)
- Dataset union (berawal 7 kota, kini **64.650 baris** di 403 kabupaten/kota) + seed DB + training (R² **0,49**, akurasi kategori **86,5%**)
- Web CRUD dataset properti (Flask + SQLite) + `GET /api/properti`
- Peringatan cakupan data: garis **n≥100** (2 tingkat — aman / peringatan satu kalimat), bendera
  `didukung` di form dibangun dari model lewat `python ml/build_wilayah.py` → **118** dari 515
  kabupaten/kota berstatus aman. Sudah diverifikasi silang: `/predict` dan form sepakat di 515/515 entitas
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

# 3b. Sinkronkan bendera cakupan ke model (tulis wilayah.json + cakupan_wilayah.json)
python ml/build_wilayah.py        # pakai --cek untuk lihat ringkasan tanpa menulis

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
  "estimasi_harga_rupiah": 1252500000,
  "estimasi_harga_string": "Rp 1.25 Miliar",
  "kategori_harga": "Mahal",
  "confidence": 0.597,
  "cukup_data": true,
  "peringatan": null,
  "rentang_bawah": "Rp 939 Juta",
  "rentang_atas": "Rp 1.57 Miliar",
  "input": {
    "luas_m2": 120.0, "jumlah_kamar": 3.0, "jumlah_kamar_mandi": 2.0,
    "usia_bangunan": 5.0, "luas_bangunan": 63.0, "lokasi": "Depok"
  }
}
```

`cukup_data` = `false` (dengan `peringatan` berisi satu kalimat) bila wilayah itu punya kurang dari
100 baris data latih. Angka jumlah barisnya dibaca dari `cloud_ml/model/cakupan_wilayah.json` —
sumber yang sama dengan bendera `didukung` di form, jadi keduanya tidak boleh berbeda.

`GET /health` untuk cek kesiapan layanan.

## Model & dataset

- **Cakupan**: 595 nama lokasi di data latih → 403 kabupaten/kota resmi (64.650 baris). Dari 595 itu, **27 nama (±940 baris)** adalah area setingkat provinsi yang sengaja tidak dipetakan ke pilihan user ("Lorong 2", lihat `dataset/README.md`), dan **7 nama (58 baris)** memang belum terpetakan. **158 entitas** menampung dua ejaan sekaligus (`Sidoarjo` + `Kabupaten Sidoarjo`) — laporan menjumlahkan barisnya, tetapi `train.py` memakai nama mentah sehingga keduanya tetap **dua kategori terpisah di model**: **15 dari 118** wilayah "aman" lolos garis 100 hanya karena dijumlahkan (Kab. Cilacap 146 gabungan, kategori terbesar 77). Menormalkan ejaan di `database/seed.py` **tidak butuh data baru**, tapi butuh reseed + training ulang — belum dikerjakan. Daftar awal dulu 7 kota: Bekasi, Bogor, Depok, Jakarta Selatan, Jakarta Utara, Surabaya, Tangerang
- **Regresi** RandomForest: R² **0,49**, MAE ≈ Rp 1,83 miliar (metrik per-kota di `ml/metrics.json`). Bentuk galat sebenarnya, terukur di 12.930 baris uji: **setengah prediksi meleset ≤1,18×**, 3 dari 4 ≤1,48×, 9 dari 10 ≤2,06×, dan 4,45 % baris meleset >3× (ekor dari belasan baris harga rusak di DB). MAE rupiah sengaja tidak dipakai sebagai janji — besarnya 2,5× median harga (Rp 739 juta), dan **dua pertiganya bukan selisih khas** melainkan 36 baris mustahil di set uji; pada baris wajar MAE-nya **Rp 578 juta**. Setelah 22 Okt `train.py` menyaring 167 baris tidak masuk akal (`harga > Rp 100 jt/m²` atau `luas_m2 < 10`), yang melatih model **64.483** baris — `metrics.json` belum di-generate ulang, jadi angka kepala di baris pertama masih angka 20 Okt
- **Klasifikasi**: akurasi **86,5%** (label diturunkan per-sentile per-kota; kelas di data uji hampir seimbang 6.621 vs 6.309, jadi angka ini bukan hasil menebak mayoritas)
- Rentang `rentang_bawah`/`rentang_atas` di `/predict` masih **hardcode ±25 %** dan baru menutupi **62 %** harga asli di data uji — pelebarannya masih menunggu keputusan tim (`docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §11.5)
- Peringatan cakupan: wilayah dengan **< 100 baris** data latih diberi peringatan di form & layar hasil; benderanya dibangun ulang oleh `python ml/build_wilayah.py` tiap model dilatih
- Alasan garis 100 dan bukti kurva belajarnya: `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md`
- Preprocessing: harga `log10`, parsing angka dari teks ("68.0 m2"), normalisasi nama kota, imputasi median `luas_bangunan`
- Sumber data & atribusi (wajib dikredit, RPP §10): `dataset/README.md`

Alur retrain: ubah data via web/admin → `python ml/train.py` → `python ml/build_wilayah.py` →
restart cloud (`cloud_ml/model/cakupan_wilayah.json` harus ikut ter-upload; kalau hilang, API diam-diam
pakai nama mentah dari `meta.json` dan bisa berbeda pendapat dengan bendera di form).
(JANGAN jalankan `seed.py` setelah ada entri manual di web — seed membangun ulang DB dari CSV dan menghapus entri `manual-web`.)

## Tech stack

Python (Flask, scikit-learn, pandas) · SQLite · Flutter/Dart (`go_router`, `Riverpod`, `dio`, `shared_preferences`; rencana: `flutter_secure_storage`).

## Pengujian

```bash
cd mobile
flutter analyze
flutter test
```
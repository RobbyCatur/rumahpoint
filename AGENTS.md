# AGENTS.md — Rumah Point (PBL TI Polinema, Semester 5)

## Goal & status
- **Product**: app mobile Flutter **prediksi harga properti Indonesia** (regresi) + **kategori** Murah/Mahal (klasifikasi), domain ekonomi. PBL TI S5.
- **Desain final**: user **login/register (JWT hybrid)**, **riwayat per-user** (server + cache offline), dan **panel admin** (CRUD dataset + statistik). Prediksi tetap **mobile→cloud**.
- **Status implementasi**: SUDAH jalan/teruji — prediksi mobile→cloud, **dataset union 7 kota**, web CRUD dataset, CORS, `AndroidManifest` (cleartext+INTERNET), `flutter analyze`+`test`. MASIH dikerjakan — auth JWT (register/login/refresh/logout), riwayat server-side, panel admin, layar Login/Register mobile (riwayat untuk saat ini masih lokal).
- Detail: `docs/RENCANA-EKSEKUSI.md`.

## Product flow (arsitektur final)
```
Mobile --POST /predict (tanpa DB/auth)--> Cloud ML (RF regresi+klas) --> hasil --> Mobile
Mobile --login/register/refresh/riwayat--> Backend Web (Flask+SQLite+JWT)
Admin/tim (web) --CRUD dataset + statistik--> Backend Web --> DB --train.py--> model --> Cloud
```
- **Prediksi = mobile→cloud LANGSUNG.** Web bukan jalur prediksi; web memegang DB (auth, riwayat, CRUD data latih).
- Input = **FORM angka** (bukan kamera/OCR). **Login wajib untuk semua fitur** (desain final; fitur auth sedang dibangun).

## Struktur & perintah
- `dataset/properti_multi_kota.csv` (union) + `dataset/build_union.py` + `dataset/raw_sources/` + `README.md` (sumber/lisensi). `dataset_properti.csv` = salah satu sumber (Jabodetabek).
- `database/seed.py` → baca CSV union → isi `properti.db`; kolom `sumber`, `luas_bangunan`; **kategori per-sentile per-kota** (≥ median kota → 'Mahal'). Run: `python database/seed.py`.
- `ml/train.py` → baca DB (fallback CSV union) → **fitur** `luas_m2, luas_bangunan(imputasi median), jumlah_kamar, jumlah_kamar_mandi, usia_bangunan` + `lokasi` → `cloud_ml/model/*.joblib` + `metrics.json` (termasuk `regression_by_city`). Run: `python ml/train.py`.
- `ml/build_wilayah.py` → baca `meta.json:city_tiers` (hasil train.py) → tulis **dua** file: bendera
  `didukung` di `mobile/assets/data/wilayah.json` **dan** `cloud_ml/model/cakupan_wilayah.json`
  (jumlah baris per nama entitas asset, dipakai API supaya tidak beda pendapat dengan form);
  `--cek` untuk melihat ringkasan tanpa menulis. Run: `python ml/build_wilayah.py`.
- `cloud_ml/app.py` :8081 — `GET /health`, `POST /predict` (muat model; imputasi `luas_bangunan` via `meta.json:median_luas_bangunan`; `cukup_data`+`peringatan` via `cakupan_wilayah.json`, fallback ke nama mentah `meta.json` kalau file itu belum ada — **maka file itu wajib ikut ter-upload saat deploy**; **CORS aktif**). Tidak sentuh DB.
- `web/app.py` :8080 — **landing publik `/`** + **CRUD `properti` dilindungi login admin** (`/admin/login`, password env `ADMIN_PASSWORD`, session cookie; default `rumahpoint-admin` untuk dev). INSERT menyertakan `sumber='manual-web'`, kategori via median kota. Pemegang DB. Deploy: VPS NAT + PM2 (lihat `docs/DEPLOY-VPS.md`), publik via Cloudflare Tunnel `rumahpoint.soraven.web.id` (web) & `ml.soraven.web.id` (cloud).
- `mobile/` — Flutter: `flutter pub get/analyze/test/run`. `go_router`,`Riverpod`,`dio`,`shared_preferences`,`flutter_secure_storage`. UI mockup light: aksen amber `#F59E0B` + netral slate (satu sumber di `lib/theme.dart`); `StatefulShellRoute` (Beranda=sapaan singkat + CTA gulir ke form input `/beranda`, Riwayat `/riwayat`, Profil `/profil`) + `/` login + `/hasil`; form mengirim `luas_bangunan` (imputasi median tetap di server bila 0), autosave draft (`rp_draft`), luas float & stepper bisa diketik manual. Platform: android + web.
  - **Arsitektur: Clean Architecture feature-first** (`presentation → domain ← data`; domain steril Flutter/Dio). `lib/core/` (`failures.dart`, `format.dart`), `lib/features/prediction/{domain,data,presentation}` (entity `Prediction` murni + `wilayah.dart`; `PredictionModel` mapping; `PredictionRepository` interface + impl via Dio remote DS + SharedPreferences draft/history DS; `services/` = `wilayah_service.dart` (asset `assets/data/wilayah.json`: 34 provinsi → 515 kab/kota + koordinat + flag `didukung` model) & `location_service.dart` (geolocator, izin GPS → kab/kota terdekat); use case `GetPredictionHistory`; DI di `presentation/providers`), `lib/features/user/{domain,data,presentation}` (entity `User`, `UserRepository` + impl secure storage, `UserNotifier`). Screens lama di `lib/screens/` = presentation pages. Form: usia → pilihan **kondisi Baru/Bekas** (`Baru`=0 thn, `Bekas`=10 thn ke model); lokasi = bottom sheet provinsi→kab/kota (search, 5 item terlihat) + default GPS, peringatan akurasi bila `!didukung`; hasil geser kiri→Riwayat/kanan→Beranda; riwayat filter kategori+bulan+lokasi. Test: widget + `get_prediction_history_test.dart` + `wilayah_service_test.dart` (fake repo, domain murni).

## Urutan menjalankan (demo)
1. `python database/seed.py` → `python ml/train.py`
2. `python cloud_ml/app.py` (:8081) — dipanggil mobile
3. `python web/app.py` (:8080) — CRUD data (opsional)
4. Device fisik (USB): `adb reverse tcp:8081 tcp:8081` lalu `flutter run --dart-define=ML_URL=http://127.0.0.1:8081`
   - Emulator: `ML_URL` default `http://10.0.2.2:8081`.
   - `adb` ada di `D:\new\AndroidSDK\platform-tools` (sudah ditambahkan ke User PATH) — buka terminal baru agar aktif. Reverse :8080 juga saat auth aktif (roadmap). Tunnel hilang saat device dicabut/reboot → jalankan ulang.
5. Ubah data via web → jalankan ulang `train.py`, lalu `python ml/build_wilayah.py` supaya bendera
   `didukung` di `mobile/assets/data/wilayah.json` **dan** `cloud_ml/model/cakupan_wilayah.json`
   ikut model (tanpa training ulang; ±1 milidetik, tidak menyentuh server). Kalau angkanya berubah,
   sesuaikan `mobile/test/wilayah_service_test.dart` (mengunci jumlah 118). Saat deploy, kedua file
   hasil generator itu ikut di-upload (`wilayah.json` masuk APK, `cakupan_wilayah.json` masuk
   `cloud_ml/model/`).

## Preprocessing (WAJIB konsisten di train & cloud)
- Ekstrak angka dari string ("68.0 m2"→68). Lihat `_first_number` (`ml/train.py`) & `_to_frame` (`cloud_ml/app.py`).
- `harga` **log10** → back `10**pred`. `luas_bangunan` kosong → **imputasi median** (`meta.json`).
- Normalisasi `lokasi` ("Jak. Utara"→"Jakarta Utara"; casing). Cakupan sekarang **595 nama lokasi mentah** di DB (403 kabupaten/kota resmi setelah pencocokan nama; **27 nama ±940 baris** = area setingkat provinsi → itu **Lorong 2**, sengaja tidak dipetakan, bukan bug; **7 nama 58 baris** benar-benar belum terpetakan). Temuan yang merusak angka: **158 entitas menampung dua ejaan** (`Sidoarjo` + `Kabupaten Sidoarjo`) — **21.169 baris (±33 %)** ada di entitas begitu, dan generator **menjumlahkan** keduanya sedangkan `train.py` memakai nama mentah → **dua kategori OneHot terpisah**. Akibatnya **15 dari 118** bendera "aman" hanya lolos n≥100 karena dijumlahkan (Kab. Cilacap 146 gabungan, kategori terbesar 77). Menormalkan ejaan di `database/seed.py` tidak butuh data baru; lihat `dataset/README.md` (kebijakan dua lorong) & `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §5b. Butuh reseed + training ulang → harus disetujui tim.
- **Batas "cukup data" = 100 baris/wilayah** (keputusan tim 21 Okt 2026, dasar kurva belajar — lihat `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §3). Dipakai di dua tempat dengan konstanta `AMAN_MIN`: `ml/build_wilayah.py` (bendera `didukung` di asset) dan `cloud_ml/app.py` (`cukup_data` + `peringatan` di `/predict`).

## Model & metrik (via `ml/metrics.json`)
- Regresi RF **R²=0,49, MAE≈Rp1,83M** (log10 MAE 0,159 ≈ galat khas 1,45×). Klasifikasi akurasi **0,865**. Metrik per-kota tersedia.
- Angka lama R²=0,85 / 0,933 berasal dari dataset 7 kota sebelum union diperluas — UI (FAQ, Disclaimer, landing `web/app.py`) sudah diperbarui ke angka terkini.
- Cloud-ML (bukan on-device TFLite) = **deviasi RPP §4.2 sudah disetujui dosen** (keterbatasan mobile → web/cloud).
- Android `http://` butuh `usesCleartextTraffic` (sudah di set).

## Dataset (terunduh; jangan unduh ulang sembarangan)
- Union dari: `d1041251013-lab/uas-properti`, `FluffHound/east_surabaya_house_predict`, `HaafizHhamda/ColectDataRumah`. Pihak ketiga → **atribusi + cek lisensi/ToS** (RPP §10, lihat `dataset/README.md`).

## Team & proses
- 4 anggota; tiap anggota coding + commit. Branch `feat/*` → PR → merge `main`. RPP: 1 fitur ML matang; QA §4.4; repo Git deliverable CP-4.
- A1 Mobile · A2 ML+Cloud · A3 QA · A4 Backend/DB+Docs.

## Bagian yang masih dikerjakan (dibangun setelah inti berjalan)
Fitur ini **bagian dari desain final** (lihat §4.2/§6 proposal), **belum** diimplement — kerjakan berurutan, **jangan tambah fitur di luar ini**:
- **Auth JWT hybrid**: access 15m + refresh 7hari (ter-hash), rotasi, reuse-detection (cabut family), device-bound (IP sinyal lunak), secret via env, `flutter_secure_storage`. Login WAJIB semua fitur.
- **Riwayat per-user server-side** (`history`) + cache offline; tabel `users`, `refresh_tokens`, `history`.
- **Panel Admin** (role `admin`): CRUD `properti` + `GET /stats`.
- Endpoint auth `/auth/*` & `/history` di backend web; mobile: layar Login/Register + interceptor auto-refresh.
- Perluasan dataset (Rute A Kaggle / C scraping) + evaluasi per-region.

## Terkait project lain (workspace sama)
- `../Detanah/` (tanah, GPS+peta) & `../SeedLens/` (bibit) = project lain — JANGAN dicampur.

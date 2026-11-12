# AGENTS.md — Rumah Point (PBL TI Polinema, Semester 5)

## Goal & status
- **Product**: app mobile Flutter **prediksi harga properti Indonesia** (regresi) + **kategori** Murah/Mahal (klasifikasi), domain ekonomi. PBL TI S5.
- **Desain final**: user **login/register (JWT hybrid)**, **riwayat per-user** (server + cache offline), dan **panel admin** (CRUD dataset + statistik). Prediksi tetap **mobile→cloud**.
- **Status implementasi**: SUDAH jalan/teruji — prediksi mobile→cloud, **dataset union nasional 64.650 baris CSV / 595 ejaan lokasi**; `database/seed.py` membuang 167 baris mustahil, menormalkan usia, dan memetakan ke **446 kota kanonik** (403 kabupaten/kota aset) → **64.483 baris dilatih**, pilihan wilayah **515 kab/kota + bendera cakupan** (`ml/build_wilayah.py`), peringatan `cukup_data` dua tingkat (garis n≥100 → **118** aman), web CRUD dataset, CORS, `AndroidManifest` (cleartext+INTERNET), `flutter analyze`+`test`. MASIH dikerjakan — auth JWT (register/login/refresh/logout), riwayat server-side, panel admin, layar Login/Register mobile (riwayat untuk saat ini masih lokal).
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
- `database/seed.py` → baca CSV union → isi `properti.db`; kolom `sumber`, `luas_bangunan`; **kategori dari median harga per kota kanonik** (≥ median → 'Mahal'). Sekaligus membuang baris mustahil, menormalkan usia, dan mengisi `city_id` kanonik. Run: `python database/seed.py`.
- `ml/train.py` → baca DB via join `cities` (fallback CSV union) → **fitur** `luas_m2, luas_bangunan(imputasi median), jumlah_kamar, jumlah_kamar_mandi, usia_bangunan` + `lokasi` kanonik → `cloud_ml/model/*.joblib` + `metrics.json` (termasuk `regression_by_city`). Run: `python ml/train.py`.
- `ml/build_wilayah.py` → baca `meta.json:city_tiers` (hasil train.py) → tulis **dua** file: bendera
  `didukung` di `mobile/assets/data/wilayah.json` **dan** `cloud_ml/model/cakupan_wilayah.json`
  (jumlah baris per nama entitas asset, dipakai API supaya tidak beda pendapat dengan form);
  `--cek` untuk melihat ringkasan tanpa menulis. Run: `python ml/build_wilayah.py`.
- `cloud_ml/app.py` :8081 — `GET /health`, `POST /predict` (muat model; imputasi `luas_bangunan` via `meta.json:median_luas_bangunan`; `cukup_data`+`peringatan` via `cakupan_wilayah.json`, fallback ke nama mentah `meta.json` kalau file itu belum ada — **maka file itu wajib ikut ter-upload saat deploy**; **CORS aktif**). Tidak sentuh DB.
- `web/app.py` :8080 — **landing publik `/`** + **CRUD `properti` dilindungi login admin** (`/admin/login`, password env `ADMIN_PASSWORD`, session cookie; default `rumahpoint-admin` untuk dev). INSERT menyertakan `sumber='manual-web'`, kategori via median kota. Pemegang DB. Deploy: VPS NAT + PM2 (lihat `docs/DEPLOY-VPS.md`), publik via Cloudflare Tunnel `rumahpoint.soraven.web.id` (web) & `ml.soraven.web.id` (cloud).
- `mobile/` — Flutter: `flutter pub get/analyze/test/run`. `go_router`,`Riverpod`,`dio`,`shared_preferences`,`flutter_secure_storage`. UI mockup light: aksen amber `#F59E0B` + netral slate (satu sumber di `lib/theme.dart`); `StatefulShellRoute` (Beranda=sapaan singkat + CTA gulir ke form input `/beranda`, Riwayat `/riwayat`, Profil `/profil`) + `/` **onboarding/sambutan (bukan login)** + `/login` + `/forgot-password` + `/hasil`; **tidak ada `redirect` di `GoRouter` — rute mana pun bisa dibuka tanpa login, jadi "login wajib" masih desain, belum perlakuan**; form mengirim `luas_bangunan` (imputasi median tetap di server bila 0), autosave draft (`rp_draft`), luas float & stepper bisa diketik manual. Platform: android + web.
  - **Arsitektur: Clean Architecture feature-first** (`presentation → domain ← data`; domain steril Flutter/Dio). `lib/core/` (`failures.dart`, `format.dart`), `lib/features/prediction/{domain,data,presentation}` (entity `Prediction` murni + `wilayah.dart`; `PredictionModel` mapping; `PredictionRepository` interface + impl via Dio remote DS + SharedPreferences draft/history DS; `data/services/` = `wilayah_service.dart` (asset `assets/data/wilayah.json`: 34 provinsi → 515 kab/kota + koordinat + flag `didukung` model) & `location_service.dart` (geolocator, izin GPS, akurasi `low`) — urutan resolusi wilayah: **poligon `assets/data/batas.json` (±2,1 MB, dari geoBoundaries ADM2, lisensi ODCL) dulu, centroid terdekat (`nearest`) sebagai cadangan**. **Generator `batas.json` (`tools/build_batas.js`, `tools/fix_pusat.js`) belum ter-commit** — asetnya ada di repo & di APK, tapi tidak ada yang bisa membangunnya ulang; use case `GetPredictionHistory`; DI di `presentation/providers`), `lib/features/user/{domain,data,presentation}` (entity `User`, `UserRepository` + impl secure storage, `UserNotifier`). Screens lama di `lib/screens/` = presentation pages. Form: usia → pilihan **kondisi Baru/Bekas** (`Baru`=0 thn, `Bekas`=10 thn ke model); lokasi = bottom sheet provinsi→kab/kota (search, 5 item terlihat) + default GPS, peringatan akurasi bila `!didukung`; hasil geser kiri→Riwayat/kanan→Beranda; riwayat filter kategori+bulan+lokasi. Test: widget + `get_prediction_history_test.dart` + `wilayah_service_test.dart` (fake repo, domain murni).

## Urutan menjalankan (demo)
1. `python database/seed.py` → `python ml/train.py`
2. `python cloud_ml/app.py` (:8081) — dipanggil mobile
3. `python web/app.py` (:8080) — CRUD data (opsional)
4. Device fisik (USB): `adb reverse tcp:8081 tcp:8081` lalu `flutter run --dart-define=ML_URL=http://127.0.0.1:8081`
   - Emulator: **wajib** `--dart-define=ML_URL=http://10.0.2.2:8081` — nilai bawaan di kode `127.0.0.1:8081` (lihat `prediction_remote_datasource.dart`), yang di emulator tidak sampai ke laptop.
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
- Normalisasi `lokasi`: `seed.py` menyimpan ejaan mentah di kolom `lokasi` dan mengisi `city_id` ke kota kanonik (nama aset bila ada; jika tidak, `"Kabupaten " + nama` bila ada di aset; selain itu ejaan mentah). `train.py` dan `ml/laporan.py` membaca nama kanonik lewat join `cities`. Setelah reseed 12 Nov 2026: **446 kota kanonik** berdata, `Sidoarjo` + `Kabupaten Sidoarjo` menyatu (2.315 baris), **118** bendera aman tidak berubah. Sisa yang diketahui: **9 entitas aset menerima dua nama model** (565 baris) karena ejaan aset sendiri tidak baku (`Banyu Asin`, `Banjar Baru`, `Pematang Siantar`); **1 di antaranya**, Banyu Asin, lolos ambang 100 hanya karena penjumlahan (117 gabungan, kategori terbesar 78). Ini dicatat di `dokumentasi.json` (keterbatasan) dan sengaja tidak ditambal. Masih ada **27 nama ±940 baris** setingkat provinsi (Lorong 2, tidak bisa dipilih user) dan **7 nama 58 baris** yang tidak ada di aset. Lihat `dataset/README.md` & `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §5b.
- **Batas "cukup data" = 100 baris/wilayah** (keputusan tim 21 Okt 2026, dasar kurva belajar — lihat `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §3). Dipakai di dua tempat dengan konstanta `AMAN_MIN`: `ml/build_wilayah.py` (bendera `didukung` di asset) dan `cloud_ml/app.py` (`cukup_data` + `peringatan` di `/predict`).
- **Saring ekor saat seed dan saat melatih** (`MAKS_HARGA_PER_M2=1e8` + `MIN_LUAS_TANAH=10` di `seed.py` dan `load_and_clean`): buang baris bila `harga/luas_m2 > 1e8` ATAU `luas_m2 < 10`. Di CSV union itu **167 baris (0,26 %)** — placeholder digit berulang (`111111111111111`, `999999999999`), Rp 3,3 triliun utk 240 m² di Kab. Deli Serdang, dan 39 baris `luas_m2='1.0'` yang di CSV asli berdampingan dengan `luas_bangunan=700` (gagal parsing). Sejak reseed 12 Nov 2026 baris itu **sudah tidak ada di DB**; `train.py` tetap memakai filter yang sama sebagai gerbang untuk entri baru dari panel admin. **Sudah dicek: tidak ada wilayah yang jatuh dari garis 100** (118 tetap 118). Detail + tabel pengukuran: §12 dokumen diskusi.
- **`usia_bangunan` sudah satu satuan** (reseed 12 Nov 2026): `seed.py` mengubah tahun 1900..tahun berjalan menjadi umur (3.070 baris), membiarkan umur 0..126 (1.669 baris), dan mengosongkan nilai mustahil (46 baris) untuk diimputasi median. Kini `meta.json:median_usia_bangunan` = **9** dan 59.744 baris kosong diisi angka itu; mobile tetap mengirim **0 atau 10** (`kondisiUsia`, `home_screen.dart:15`), jadi model mengenal rentang usia jauh lebih lebar daripada dua nilai itu. Mobile tidak diubah. Sisa yang belum diputuskan: batas atas `jumlah_kamar` / `jumlah_kamar_mandi` / `luas_bangunan`; percabangan ekstrem model lama sudah hilang setelah retrain. Lihat §13.

## Model & metrik (via `ml/metrics.json`)
- Regresi RF **R²=0,5142, MAE≈Rp626 juta** (log10 MAE 0,1548). Klasifikasi akurasi **0,8663**. Metrik per-kota tersedia. Diukur 12 Nov 2026 pada **12.897 baris uji bersih** (seed sudah membuang 167 baris rusak, jadi tidak ada lagi kontaminasi di set uji; MAE lama Rp1,83 M berasal dari baris rusak yang masih ikut diuji).
- Angka lama R²=0,85 / 0,933 berasal dari dataset 7 kota sebelum union diperluas — UI (FAQ, Disclaimer, landing `web/app.py`) sudah diperbarui ke angka terkini.
- Cloud-ML (bukan on-device TFLite) = **deviasi RPP §4.2 sudah disetujui dosen** (keterbatasan mobile → web/cloud).
- Android `http://` butuh `usesCleartextTraffic` (sudah di set).
- **`meta.json`, `model/cakupan_wilayah.json` dan `model/*.joblib` wajib berasal dari SATU kali training** dan di-upload berempat. Per 12 Nov 2026 keempatnya **regenerasi dari satu kali latih** (joblib + meta 01:08, cakupan 01:09 setelah `build_wilayah.py`); `metrics.json` dan evaluasi ulang pada split yang sama menghasilkan angka identik (R² 0,5142). Model mengenal **434 kategori `lokasi`** dari **446 kota kanonik** → **12 kota** hanya punya 1 baris dan barisnya jatuh ke set uji, sehingga diprediksi tanpa sinyal lokasi; semuanya n<100 dan sudah diberi peringatan `cukup_data=false`. Catatan: `cloud_ml/model/city_tiers.json` adalah sisa lama (20 Okt) yang tidak dibaca kode mana pun; jangan ikut di-upload.
- **Galat terukur di model yang melayani user sekarang** (hasil regenerasi 12 Nov 2026 pada 12.897 baris uji bersih): setengah prediksi meleset **≤1,18×**, 3 dari 4 **≤1,47×**, 9 dari 10 **≤2,08×**, dan **4,19 %** baris meleset **>3×**. **Rentang yang ditampilkan (`harga*0,75`–`harga*1,25`) hanya menutupi 62,15 % harga asli** — terlihat lebih rapi daripada kenyataannya; supaya 90 % tertutup perlu ±2×. Angka lengkap di `dokumentasi.json`; lihat `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §11.
- **JANGAN `git add -A` / `git add .`** di repo ini: `cloud_ml/model/*.joblib` yang belum ter-commit di disk berukuran **±1,5 GB** (yang ter-commit hanya ±85 MB) dan `database/properti.db.bak-*` menumpuk. Stage berkas eksplisit satu per satu dengan nama paths-nya. LFS aktif tapi `.gitattributes` tidak ada → model masuk sebagai blob biasa.

## Dataset (terunduh; jangan unduh ulang sembarangan)
- Union dari **6 sumber** (29 Okt 2026): `d1041251013-lab/uas-properti` (1.530), `HaafizHhamda/ColectDataRumah` (200), FLUS Kaggle komersil (39.423), dan scraping Rute C — 99.co (14.352), rumah123 (8.824), Pinhome (321). `FluffHound/east_surabaya` **tidak lagi ada** di union meski namanya masih muncul di dokumen lama. Pihak ketiga → **atribusi + cek lisensi/ToS** (RPP §10, lihat `dataset/README.md`; **Pinhome belum punya catatan lisensi**).

## Team & proses
- 4 anggota; tiap anggota coding + commit. Branch `feat/*` → PR → merge `main`. RPP: 1 fitur ML matang; QA §4.4; repo Git deliverable CP-4.
- A1 Mobile · A2 ML+Cloud · A3 QA · A4 Backend/DB+Docs.

## Dokumentasi model di web (arahan dosen, 29 Okt 2026) — sudah dibangun
- Web **wajib** memuat dokumentasi: **alasan pemilihan RF + perbandingan dengan model lain** (pembanding
  boleh dari jobsheet `D:\Kuliah\Semester 5\Project\Pembelajaran Mesin` — tersedia `LinearRegression`,
  `SVR`, `KNeighborsClassifier`, `GaussianNB`, `SVC`; **tidak ada** RF/DecisionTree di sana), **jejak
  praproses**, dan **visualisasi**. Batas tegas: **web tidak melatih/memproses** — hanya membaca
  JSON+SVG statis. Rencana lengkap + fakta terukur: `docs/RENCANA-DOKUMENTASI-MODEL-DI-WEB.md`.
- Alur: `ml/perbandingan.py` → `ml/perbandingan_model.json` (split sama, **tidak** menyentuh
  `cloud_ml/model/`) → `ml/laporan.py` → `web/static/dokumentasi/{dokumentasi.json,*.svg}` → rute
  `/dokumentasi` read-only. `web/requirements.txt` tetap `flask` + `flask-cors`.
- **Angka di halaman dihitung, bukan diketik** (pelajaran dari angka 0,85/93,3 % yang tertinggal di UI).
  Provenance wajib: sha256 joblib, md5 isi DB, versi pustaka, mesin, n latih/uji.
- **Deploy 29 Okt 2026 — tuntas.** Awalnya berkas disalin manual via `scp` (VPS belum punya kredensial
  GitHub). Setelah kunci SSH ditambahkan, `remote.origin.url` di server diubah ke
  `git@github.com:RobbyCatur/rumahpoint.git`, PR #9 di-merge, dan server di-`pull --ff-only` ke
  **`6747cd7`**. Working tree server **bersih**; joblib saat itu ada di disk dengan sha256
  (`467f9e9e…` / `09110322…`) dan sudah keluar dari index git (commit `121bf48` + `.gitignore`).
  `/predict` membalas `cukup_data` + `peringatan` (diverifikasi via `ml.soraven.web.id`).
  **Pembaruan berikutnya cukup `git fetch origin && git pull --ff-only`.**
  **Sejak retrain 12 Nov 2026 joblib lokal berubah** (`2fe4feb0…` / `5f5e6798…`); VPS masih
  memakai artefak lama sampai ada deploy baru yang disetujui.
- Mobile **tidak** membaca `cukup_data`/`peringatan` — peringatan cakupan di aplikasi berasal dari aset
  `wilayah.json`, bukan dari API.
- Keputusan: pelatihan & perbandingan di **laptop** — sklearn 1.9.0 dan artefak lokal **identik**
  dengan VPS pada masa deploy 29 Okt. VPS hanya 2 vCPU / 4 GB RAM dengan swap penuh dan dipakai
  aplikasi lain → **jangan melatih di sana**. Artefak baru 12 Nov dilatih di laptop yang sama.

## Bagian yang masih dikerjakan (dibangun setelah inti berjalan)
Fitur ini **bagian dari desain final** (lihat §4.2/§6 proposal), **belum** diimplement — kerjakan berurutan, **jangan tambah fitur di luar ini**:
- **Auth JWT hybrid**: access 15m + refresh 7hari (ter-hash), rotasi, reuse-detection (cabut family), device-bound (IP sinyal lunak), secret via env, `flutter_secure_storage`. Login WAJIB semua fitur.
- **Riwayat per-user server-side** (`history`) + cache offline; tabel `users`, `refresh_tokens`, `history`.
- **Panel Admin** (role `admin`): CRUD `properti` + `GET /stats`.
- Endpoint auth `/auth/*` & `/history` di backend web; mobile: layar Login/Register + interceptor auto-refresh.
- Perluasan dataset (Rute A Kaggle / C scraping) + evaluasi per-region.

## Terkait project lain (workspace sama)
- `../Detanah/` (tanah, GPS+peta) & `../SeedLens/` (bibit) = project lain — JANGAN dicampur.

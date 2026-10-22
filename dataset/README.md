# Dataset Rumah Point (union multi-kota, ekspansi nasional)

## Berkas
- `properti_multi_kota.csv` — hasil **union** gabungan (build via `build_union.py`). Saat ini **64.650 baris / 595 nama lokasi** (= 403 kabupaten/kota resmi setelah peta-ulang + Lorong 2).
- `raw_sources/` — CSV mentah per sumber + scraper (lihat tabel sumber).
- `dataset_properti.csv` — sumber awal (Jabodetabek).
- `build_union.py` — skrip pembangun union (6 blok sumber, normalisasi kota, parsing harga/luas, cap 2000/kota, filter NON_ID).

## Kolom seragam
`sumber, lokasi(kota), luas_m2, luas_bangunan, jumlah_kamar, jumlah_kamar_mandi, usia_bangunan, harga`
- `harga` = target regresi (Rupiah). `kategori_harga` (Murah/Mahal) **diturunkan di seed.py secara per-sentile per-kota** (≥ median kota tsb = Mahal).
- `luas_bangunan` bisa kosong (imputasi median saat training). FLUS tidak punya `usia_bangunan` → kosong, diimputasi median juga.
- **Filter kewarasan saat training (bukan saat seed)**: `ml/train.py` membuang baris ber-`harga/luas_m2 > Rp 100 juta/m²`
  atau `luas_m2 < 10` — sisa scraping (placeholder `111111111111111`, iklan tanah 1 m2 miliaran). Diukur 22 Okt: **167 baris (0,26 %)**
  sehingga yang dilatih **64.483**, bukan 64.650. Ke-167 baris itu **masih tersimpan di `properti.db` dan di CSV ini** — sengaja,
  supaya aturan bisa diubah tanpa reseed, dan supaya asal angka bisa diverifikasi. Tidak ada wilayah yang jatuh dari garis 100 karenanya.

## Sumber & atribusi (RPP §10 — wajib dikredit)
| sumber | cakupan | baris di union | asal | catatan lisensi |
|--------|---------|----------------|------|-----------------|
| uas-properti/Jabodetabek | 6 kota | 1.530 | GitHub `d1041251013-lab/uas-properti` → `dataset_properti.csv` | cek lisensi repo |
| rumah123/Surabaya (lama) + rumah123/<Kota> (baru) | **331 kab/kota selesai** | ±5.400 | scraping sendiri via `raw_sources/scrape_rumah123.py` + `batch_scrape_rumah123.py` — sitemap SRP resmi + JSON `__srp_seo_rescue` + PDP, comply robots `User-agent: *`, delay≥4s, tanpa API/ajax | data listing publik; **kepatuhan ToS didiskusikan tim+dosen (Rute C, Okt 2026)** |
| ColectDataRumah/Bekasi | Bekasi | 200 | GitHub `HaafizHhamda/ColectDataRumah` (`rumah_bekasi.csv`) | data scrape; cek ToS/lisensi |
| 99.co/<Kota> | **214 kota** (habis — keran indeks SEO habis; `raw_sources/99co_*.csv`) | 14.352 | scraping sendiri via `raw_sources/batch_scrape_99co.py` — halaman SEO `/id/jual/rumah/...`, comply robots, delay≥2,5s. **Harga = ask price listing** | sama, Rute C disetujui Okt 2026 |
| FLUS/komersil | 425 kab/kota nasional | 39.464 | Kaggle `zororaka/indonesia-affordable-housing` → `raw_sources/kaggle_flus_housing.csv` (25 MB) — harga proyek developer (baru). **Hanya `subsidy_status=komersil` yang masuk latih**; subsidi dipakai arsitektur JSON acuan (belum dibangun) | **CC0 Public Domain** (bebas pakai & atribusi tidak wajib, tetap dicantumkan) |

Catatan: data rumah123/99.co merupakan hasil scraping listing publik — **verifikasi lisensi & kepatuhan ToS** sebelum dipakai lebih luas; untuk PBL sebagai dataset latih internal. Sitemap rumah123 memuat entri non-Indonesia (Singapore, Australia, Malaysia, UAE, dst.) — difilter via `NON_ID` di `build_union.py`.

## Pengungkapan kualitas data per wilayah (keputusan dosen Okt 2026: "seluruh kota, data apa adanya")
Keperluan cakupan nasional tidak menurunkan kota; kualitas **dibuka ke pengguna** berdasar jumlah
sampel wilayah itu. ~~Lewat tier 5 level~~ → **direvisi 21 Okt 2026** menjadi dua tingkat, dengan garis
yang diambil dari eksperimen **kurva belajar** (kenaikan galat terbesar ada di bawah 25 baris dan
kurva sudah landai setelah 100 — lihat `docs/DISKUSI-PERINGATAN-CAKUPAN-DATA.md` §3), bukan dari
target pengumpulan data 150:

| Status | Syarat n | Yang dilihat pengguna |
|--------|----------|----------------------|
| Cukup data | **n ≥ 100** | tidak ada peringatan |
| Data kurang | n < 100 (dan wilayah tak dikenal) | "Model belum punya cukup data untuk wilayah ini — estimasi bisa kurang akurat." |

Satu konstanta dipakai dua tempat: `AMAN_MIN = 100` di `ml/build_wilayah.py` (bendera `didukung` di
form) dan `cloud_ml/app.py` (`cukup_data` + `peringatan` di `/predict`). Angka per wilayah dibaca dari
`cloud_ml/model/cakupan_wilayah.json` yang ditulis `python ml/build_wilayah.py` sesudah `train.py` —
**sumber yang sama untuk form dan API**, supaya tidak ada wilayah yang aman di form tapi warned dari server.
Tingkat ketiga (`n<25` vs `25–99`) sudah diputuskan bentuknya tapi belum dikirim ke UI.

Distribusi saat ini (64.650 baris / 595 nama lokasi mentah): **403** entitas `wilayah.json` terpetakan
→ **118** n≥100 · 73 di 25–99 · 212 di bawah 25; **112** entitas belum punya satu baris pun.
Periksa-cakupan entitas 514: `dataset/cakupan_514.csv` — isinya **515 baris = 399 berdata + 116 bertanda NOL**
(dibuat `audit_cakupan.py` **sebelum** batch rumah123 susulan, dan masih memakai batas tier lama — karena itu 116 NOL di file itu, angka hari ini 112).

## Kebijakan dua lorong — lokasi non-administratif (keputusan tim Okt 2026)
Nama di luar daftar induk 514 kabupaten/kota hasil pemeriksaan cakupan (`audit_cakupan.py`):
- **Lorong 1 — peta-ulang ke induk** (`REMAP` di `build_union.py`; setingkat kecamatan/desa, induk tunggal terverifikasi manual): Purwokerto→Kab. Banyumas, Cikarang→Kab. Bekasi, Ambarawa→Kab. Semarang, Anyer→Kab. Serang, Purwodadi→Kab. Grobogan, Cikampek→Kab. Karawang, Nusa Lembongan & Semarapura→Kab. Klungkung, Anambas→Kab. Kepulauan Anambas; "Others" dibuang. Nama baru hasil scrape menyusul ditambah ke tabel ini.
- **Lorong 2 — area propinsi** (Bali, Lampung, Aceh, Kepulauan Bangka Belitung, Dki Jakarta, DIY, dst. — **27 nama / 940 baris** hasil `python ml/build_wilayah.py`, yaitu nama yang cocok dengan 34 nama provinsi di `mobile/assets/data/wilayah.json`): TIDAK dipetak (tak ada satu induk), tetap ikut melatih model global sebagai kategori area, tetapi tidak masuk daftar pilihan kota di gawai/`cities` administratif. Jadi laporan generator "nama tidak ada di daftar 515" itu **bukan bug** — itu Lorong 2. Yang perlu dibaca dari laporan itu cuma nama yang *bukan* provinsi: **7 nama / 58 baris** (Daerah Istimewa Yogyakarta 45, Pasir 5, Madura 3, Kabupaten Pahuwato 2, Pangkajene 1, Papua Selatan 1, Kabupaten Mamuju Utara 1). Catatan: **Madura ada di daftar ini**, bukan di Lorong 2, walaupun namanya terdengar seperti area propinsi — karena penanda Lorong 2 adalah nama provinsi yang persis ada di asset, dan Madura bukan provinsi (ia masuk wilayah Jawa Timur). Kalau nanti diputuskan "area semi-provinsi" ikut Lorong 2, penandanya yang harus diperluas, bukan datanya.
- **Ejaan ganda dalam wilayah yang sama** (temuan 21 Okt, belum ada lorongnya — **ini yang paling merusak angka**): kolom `lokasi` menyimpan `"Sidoarjo"` **dan** `"Kabupaten Sidoarjo"`, `"Karawang"` **dan** `"Kabupaten Karawang"`, `"Banyuasin"` **dan** `"Kabupaten Banyuasin"`, bahkan ejaan rusak `"Kota Baru"` **dan** `"Kabupaten Kotabaru"` serta `"Kota Waringin Barat"` **dan** `"Kabupaten Kotawaringin Barat"`. Nama telanjang tidak bisa ditentukan kota atau kabupaten hanya dari namanya, jadi generator menjahitnya ke **satu** entitas (kota dicoba lebih dulu, baru kabupaten) dan **menjumlahkan** barisnya. Terukur 22 Okt — dicetak oleh `python ml/build_wilayah.py --cek`, bagian bawah laporannya: **158 dari 403** entitas begitu (tak ada yang >2 ejaan), menampung **21.169 baris = ±33 % dataset**. Yang penting: `ml/train.py` meng-encode nama **mentah**, jadi dua ejaan itu tetap **dua kategori OneHot terpisah** di model — penjumlahan hanya terjadi di laporan. **15 dari 118 bendera `aman` lolos garis 100 semata karena dijumlahkan** (Kab. Cilacap 146 gabungan, kategori terbesarnya 77). Perbaikan yang benar di hulu (`database/seed.py`): menormalkan ejaan **tidak menambah satu baris pun** tapi langsung menyatukan dukungan kategori — tidak boleh ditambal di hilir. Sekalian cek arah peta untuk **26 inti nama** yang punya Kota *dan* Kabupaten (Bekasi, Bogor, Bandung, Tangerang, …) lewat kolom `sumber`/URL asal, bukan lewat namanya.

## Status cakupan
- 99.co: **selesai 214/214** indeks. rumah123: **selesai 331/331** (log `raw_sources/rumah123_batch.log`). Rantai ulang (union+REMAP→seed→train→audit) dijalankan 16 Okt.
- Tabel `cities` DB memuat 581 lokasi + `provinsi` (migrasi `006_all_cities.sql`). Kolom `lokasi` di `properti` kini berisi **595 nama** (64.650 baris) — lebih banyak dari 572 pada tahap REMAP awal karena batch susulan; **27 nama** di antaranya area setingkat provinsi (Lorong 2, sengaja tidak dipetakan) dan **7 nama** (58 baris) masih belum terpetakan, sisanya terpetakan ke **403** kabupaten/kota.
- Konsekuensi metrik "apa adanya": R² RF 0,828→**0,4915**, akurasi 0,933→**0,8647** — lihat `ml/metrics.json`; dibuka ke user lewat `cukup_data` + peringatan (bagian "Pengungkapan kualitas data" di atas), bukan lewat memangkas kota.

## Aset non-data (bukan bahan latih, tapi ikut repo)
- `mobile/assets/data/batas.json` (±2,1 MB) — poligon batas ±515 kabupaten/kota, dipakai form mobile
  untuk menerjemahkan titik GPS menjadi wilayah. Sumber: **geoBoundaries IDN ADM2**
  (`https://github.com/wmgeolab/geoBoundaries`). **Lisensinya perlu dikonfirmasi sebelum aset ini ikut
  dipublikasikan**: situs geoBoundaries menyebut datanya **CC BY 4.0**, sedangkan komentar di
  `tools/build_batas.js` menulis "ODCL" — dua-duanya menuntut atribusi, tapi tidak bisa dipakai
  sambil ditebak. Pembangkitnya `tools/build_batas.js` (simplifikasi poligon) +
  `tools/fix_pusat.js` (perbaikan titik pusat kabupaten yang dobel dengan kotanya).
  **Kedua skrip itu sampai 22 Okt masih belum ter-commit** (`?? tools/`), padahal aset hasilnya sudah
  masuk repo dan ikut terkemas di APK — lihat `docs/BACKLOG.md` §1.

## Cara membangun ulang
```
python dataset/build_union.py
python database/seed.py     # !! DESTRUKTIF: hapus & isi ulang properti.db — cek baris manual-web + backup dulu
python ml/train.py          # latih model + meta.json (city_tiers) + metrics.json
python ml/build_wilayah.py  # sinkronkan cakupan: wilayah.json (bendera didukung) + cakupan_wilayah.json (dipakai API)
```

# Dataset Rumah Point (union multi-kota, ekspansi nasional)

## Berkas
- `properti_multi_kota.csv` — hasil **union** gabungan (build via `build_union.py`). Saat ini **64.323 baris / 572 lokasi unik**.
- `raw_sources/` — CSV mentah per sumber + scraper (lihat tabel sumber).
- `dataset_properti.csv` — sumber awal (Jabodetabek).
- `build_union.py` — skrip pembangun union (6 blok sumber, normalisasi kota, parsing harga/luas, cap 2000/kota, filter NON_ID).

## Kolom seragam
`sumber, lokasi(kota), luas_m2, luas_bangunan, jumlah_kamar, jumlah_kamar_mandi, usia_bangunan, harga`
- `harga` = target regresi (Rupiah). `kategori_harga` (Murah/Mahal) **diturunkan di seed.py secara per-sentile per-kota** (≥ median kota tsb = Mahal).
- `luas_bangunan` bisa kosong (imputasi median saat training). FLUS tidak punya `usia_bangunan` → kosong, diimputasi median juga.

## Sumber & atribusi (RPP §10 — wajib dikredit)
| sumber | cakupan | baris di union | asal | catatan lisensi |
|--------|---------|----------------|------|-----------------|
| uas-properti/Jabodetabek | 6 kota | 1.530 | GitHub `d1041251013-lab/uas-properti` → `dataset_properti.csv` | cek lisensi repo |
| rumah123/Surabaya (lama) + rumah123/<Kota> (baru) | **331 kab/kota selesai** | ±5.400 | scraping sendiri via `raw_sources/scrape_rumah123.py` + `batch_scrape_rumah123.py` — sitemap SRP resmi + JSON `__srp_seo_rescue` + PDP, comply robots `User-agent: *`, delay≥4s, tanpa API/ajax | data listing publik; **kepatuhan ToS didiskusikan tim+dosen (Rute C, Okt 2026)** |
| ColectDataRumah/Bekasi | Bekasi | 200 | GitHub `HaafizHhamda/ColectDataRumah` (`rumah_bekasi.csv`) | data scrape; cek ToS/lisensi |
| 99.co/<Kota> | **214 kota** (habis — keran indeks SEO habis; `raw_sources/99co_*.csv`) | 14.352 | scraping sendiri via `raw_sources/batch_scrape_99co.py` — halaman SEO `/id/jual/rumah/...`, comply robots, delay≥2,5s. **Harga = ask price listing** | sama, Rute C disetujui Okt 2026 |
| FLUS/komersil | 425 kab/kota nasional | 39.464 | Kaggle `zororaka/indonesia-affordable-housing` → `raw_sources/kaggle_flus_housing.csv` (25 MB) — harga proyek developer (baru). **Hanya `subsidy_status=komersil` yang masuk latih**; subsidi dipakai arsitektur JSON acuan (belum dibangun) | **CC0 Public Domain** (bebas pakai & atribusi tidak wajib, tetap dicantumkan) |

Catatan: data rumah123/99.co merupakan hasil scraping listing publik — **verifikasi lisensi & kepatuhan ToS** sebelum dipakai lebih luas; untuk PBL sebagai dataset latih internal. Sitemap rumah123 memuat entri non-Indonesia (Singapore, Australia, Malaysia, UAE, dst.) — difilter via `NON_ID` di `build_union.py`.

## Sistem tier kualitas data (keputusan dosen Okt 2026: "seluruh kota, data apa adanya")
Keperluan cakupan nasional tidak menurunkan kota; kualitas di-disclose lewat tier berdasar jumlah sampel kota (dihitung di `ml/train.py:city_tier`, disimpan di `cloud_ml/model/meta.json:city_tiers`, ditampilkan `/predict` sebagai `peringatan`):

| tier | syarat n | label peringatan |
|------|----------|------------------|
| 1 | ≥150 | aman |
| 2 | 100–149 | warning ringan |
| 3 | 50–99 | warning level 2 |
| 4 | 10–49 | warning level 3 |
| 5 | <10 / kota tak dikenal | warning level 4 — data lokal sangat terbatas (estimasi mengikuti pola nasional) |

Distribusi saat ini (572 lokasi): **T1=88 · T2=30 · T3=58 · T4=158 · T5=238**. Periksa-cakupan entitas 514: `dataset/cakupan_514.csv` — **376/514 berdata**, 139 nol.

## Kebijakan dua lorong — lokasi non-administratif (keputusan tim Okt 2026)
Nama di luar daftar induk 514 kabupaten/kota hasil pemeriksaan cakupan (`audit_cakupan.py`):
- **Lorong 1 — peta-ulang ke induk** (`REMAP` di `build_union.py`; setingkat kecamatan/desa, induk tunggal terverifikasi manual): Purwokerto→Kab. Banyumas, Cikarang→Kab. Bekasi, Ambarawa→Kab. Semarang, Anyer→Kab. Serang, Purwodadi→Kab. Grobogan, Cikampek→Kab. Karawang, Nusa Lembongan & Semarapura→Kab. Klungkung, Anambas→Kab. Kepulauan Anambas; "Others" dibuang. Nama baru hasil scrape menyusul ditambah ke tabel ini.
- **Lorong 2 — area propinsi** (Bali, Lampung, Aceh, Kepulauan Bangka Belitung, Dki Jakarta, DIY, Madura, dst. ±28 nama / ±1.100 baris): TIDAK dipetak (tak ada satu induk), tetap ikut melatih model global sebagai kategori area, tetapi tidak masuk daftar pilihan kota di gawai/`cities` administratif.

## Status cakupan
- 99.co: **selesai 214/214** indeks. rumah123: **selesai 331/331** (log `raw_sources/rumah123_batch.log`). Rantai ulang (union+REMAP→seed→train→audit) dijalankan 16 Okt.
- Tabel `cities` DB memuat 581 lokasi + `provinsi` (572 terpakai di `properti` setelah REMAP) (migrasi `006_all_cities.sql`).
- Konsekuensi metrik "apa adanya": R² RF 0,828→**0,475**, akurasi 0,933→**0,867** — lihat `ml/metrics.json`; disclose ke user via tier.

## Cara membangun ulang
```
python dataset/build_union.py
python database/seed.py     # !! DESTRUKTIF: hapus & isi ulang properti.db — cek baris manual-web + backup dulu
python ml/train.py          # latih model + meta.json (city_tiers) + metrics.json
```

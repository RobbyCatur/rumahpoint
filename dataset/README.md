# Dataset Rumah Point (union multi-kota)

## Berkas
- `properti_multi_kota.csv` — hasil **union** gabungan (build via `build_union.py`).
- `raw_sources/` — CSV mentah per sumber (east_surabaya.csv, rumah_bekasi.csv).
- `dataset_properti.csv` — sumber awal (Jabodetabek).
- `build_union.py` — skrip pembangun union (normalisasi kota, parsing harga/luas, cap/kota).

## Kolom seragam
`sumber, lokasi(kota), luas_m2, luas_bangunan, jumlah_kamar, jumlah_kamar_mandi, usia_bangunan, harga`
- `harga` = target regresi (Rupiah). `kategori_harga` (Murah/Mahal) **diturunkan di seed.py secara per-sentile per-kota** (≥ median kota tsb = Mahal).
- `luas_bangunan` bisa kosong (imputasi median saat training).

## Sumber & atribusi (RPP §10 — wajib dikredit)
| sumber | kota | asal | catatan lisensi |
|--------|------|------|-----------------|
| uas-properti | Bogor, Bekasi, Depok, Tangerang, Jakarta Utara, Jakarta Selatan | GitHub `d1041251013-lab/uas-properti` → `dataset_properti.csv` | cek lisensi repo |
| rumah123/Surabaya | Surabaya | GitHub `FluffHound/east_surabaya_house_predict` (`Dataset rumah123 CLEAN.csv`) | data scrape rumah123; cek ToS/lisensi |
| ColectDataRumah/Bekasi | Bekasi | GitHub `HaafizHhamda/ColectDataRumah` (`rumah_bekasi.csv`) | data scrape; cek ToS/lisensi |
| 99.co/<Kota> | 84 kota (mentah di `raw_sources/99co_*.csv`, belum di-union) | scraping sendiri via `raw_sources/batch_scrape_99co.py` — halaman SEO `/id/jual/rumah/...`, comply robots `User-agent: *`, delay>=2,5s, tanpa API/ajax. **Harga = ask price listing** | data listing publik; kepatuhan ToS sudah didiskusikan tim+dosen (Rute C, Okt 2026) |
| FLUS/komersil+subsidi | 425 kab/kota nasional | Kaggle `zororaka/indonesia-affordable-housing` → `raw_sources/kaggle_flus_housing.csv` (25 MB) — harga proyek developer (baru); subsidi = harga payung SK Menteri | **CC0 Public Domain** (bebas pakai & atribusi tidak wajib, tetap dicantumkan) |

Catatan: data rumah123/99.co merupakan hasil scraping listing publik — **verifikasi lisensi & kepatuhan ToS** sebelum dipakai lebih luas; untuk PBL sebagai dataset latih internal.

## Status cakupan
Mentah 99.co: **84 kota / ±13.400 baris** (`raw_sources/99co_*.csv`) + FLUS nasional (425 kab/kota) — belum digabung ke `properti_multi_kota.csv` (menunggu keputusan integrasi). Union aktif masih 7 kota + 4 kota prototype 99.co. Perluasan kota: **Rute C selesai** (keran indeks 99.co habis di ±84); tambahan kota berikutnya lewat booster FLUS. Lihat `docs/RENCANA-EKSEKUSI.md` §6.

## Cara membangun ulang
```
python dataset/build_union.py
python database/seed.py     # isi DB + kategori per-sentile
python ml/train.py           # latih model
```

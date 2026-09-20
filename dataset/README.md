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

Catatan: data rumah123/99.co merupakan hasil scraping listing publik — **verifikasi lisensi & kepatuhan ToS** sebelum dipakai lebih luas; untuk PBL sebagai dataset latih internal.

## Status cakupan (setelah Rute B awal)
7 kota (Surabaya di-cap 2.000 untuk keseimbangan). Perluasan kota berikutnya: **Rute A** (Kaggle API) / **Rute C** (scraping). Lihat `docs/RENCANA-EKSEKUSI.md` §6.

## Cara membangun ulang
```
python dataset/build_union.py
python database/seed.py     # isi DB + kategori per-sentile
python ml/train.py           # latih model
```

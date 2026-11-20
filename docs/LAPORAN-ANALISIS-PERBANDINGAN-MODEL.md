
# Laporan Perbandingan Algoritma Machine Learning untuk Prediksi Harga Properti Indonesia

**Penetapan Random Forest sebagai Model Utama pada Aplikasi Rumah Point**

Proyek Berbasis Learning · Teknologi Informasi · Politeknik Negeri Malang · Semester 5

Laporan ini mendokumentasikan eksperimen perbandingan lima algoritma *machine learning* pada dataset harga properti Indonesia, beserta dasar pengambilan keputusan untuk menetapkan Random Forest sebagai model utama aplikasi Rumah Point.


## Daftar Isi

1. Ringkasan Eksekutif
2. Latar Belakang
3. Rujukan dan Landasan
4. Data
5. Metodologi (Proses A–D)
6. Hasil Eksperimen
7. Analisis: Mengapa Random Forest
8. Penetapan Model Utama
9. Keterbatasan
10. Rekomendasi
11. Daftar Rujukan
12. Lampiran


---


# 1. Ringkasan Eksekutif

Aplikasi Rumah Point membutuhkan satu algoritma yang dipakai di jalur produksi untuk memprediksi harga properti dan menetapkan kategori Murah/Mahal. Pemilihan tidak boleh didasarkan pada popularitas, melainkan pada pengukuran. Karena itu lima algoritma dibandingkan pada data, fitur, praproses, pembagian data, lipatan validasi, dan metrik yang identik, tanpa *hyperparameter tuning* untuk siapa pun.

Eksperimen dijalankan pada **64.228 baris** data bersih dari **445 kota** di **34 provinsi**, dengan pembagian 80/20 (51.382 latih / 12.846 uji) dan validasi silang 5 lipatan.

**Hasil utama:**

- **Random Forest unggul pada tugas regresi.** R² log10 *hold-out* **0,8134** dan rata-rata R² validasi silang **0,8153 ± 0,0071** — tertinggi di antara lima kandidat.
- **Galat rupiahnya juga terkecil**, bukan hanya R²-nya: MAE **Rp 581,3 juta**, sekitar **14,5 % lebih rendah** daripada XGBoost (Rp 679,7 juta) dan **25,5 % lebih rendah** daripada Gradient Boosting (Rp 779,8 juta).
- **Random Forest juga unggul pada tugas klasifikasi** Murah/Mahal: akurasi **0,8641** (*hold-out*) dan **0,8648 ± 0,0026** (validasi silang), dibanding baseline kelas mayoritas 0,5085.
- Kemenangan itu **stabil**, bukan keberuntungan satu pembagian data: peringkat *hold-out* dan peringkat validasi silang menghasilkan urutan yang sama.
- **Kualitas data terbukti lebih menentukan daripada pilihan algoritma.** Pembersihan baris placeholder menaikkan R² satu algoritma yang sama dari 0,5488 menjadi 0,7912 — jauh lebih besar daripada selisih antar-algoritma mana pun.

**Keputusan:** Random Forest ditetapkan sebagai model utama untuk regresi harga dan klasifikasi kategori, dengan konsekuensi teknis yang diterima secara sadar (ukuran berkas model besar dan waktu latih paling lama di antara lima kandidat).

> Catatan pembacaan: seluruh angka pada laporan ini berasal dari eksekusi notebook `docs/01`–`04` dan tersimpan di `docs/perbandingan_output/`. Angka-angka itu tidak boleh diklaim sebagai metrik produksi, karena model produksi dilatih dengan aturan pembersihan yang berbeda (lihat Bagian 8.4).


# 2. Latar Belakang


## 2.1 Konteks produk

Rumah Point adalah aplikasi *mobile* berbasis Flutter yang memperkirakan harga properti di Indonesia. Pengguna mengisi formulir berisi luas tanah, luas bangunan, jumlah kamar, jumlah kamar mandi, dan lokasi (provinsi → kabupaten/kota). Aplikasi mengirim data itu ke layanan *cloud* dan menerima dua keluaran: estimasi harga dalam rupiah serta kategori **Murah** atau **Mahal** relatif terhadap median kota tersebut.

Karena prediksi adalah inti produk, algoritma di baliknya harus dipilih dengan alasan yang bisa dipertanggungjawabkan — bukan sekadar “Random Forest biasanya bagus untuk data tabular”. Pertanggungjawaban itu memerlukan tiga hal: rujukan ilmiah, pengukuran pada data sendiri, dan protokol yang adil bagi semua kandidat.


## 2.2 Masalah yang harus dijawab

Sebelum eksperimen ini, pemilihan model belum punya dasar kuantitatif pada dataset yang sekarang dipakai. Dataset telah berkembang dari 7 kota menjadi gabungan enam sumber nasional, sehingga hasil studi mana pun pada data lama tidak lagi berlaku otomatis. Pertanyaannya menjadi:

1. Dari lima algoritma yang lazim dipakai pada studi harga rumah, mana yang paling akurat pada dataset multi-kota milik Rumah Point?
2. Apakah algoritma yang menang pada regresi juga menang pada klasifikasi kategori?
3. Apakah kemenangan itu bertahan ketika data dibagi ulang lima kali, atau hanya kebetulan satu pembagian?
4. Fitur mana yang layak dipakai, dan fitur mana yang justru menyesatkan?


## 2.3 Batas yang disengaja

Eksperimen ini **tidak** bertujuan mencari konfigurasi terbaik (*tuning*). Tujuannya menjawab: *pada perlakuan yang sama, algoritma mana yang paling cocok untuk data ini?* Pembatasan ini disengaja agar perbandingan tidak berubah menjadi kontes penalaan parameter, yang sulit direproduksi dan mudah memihak model yang kebetulan lebih banyak dipelajari.


# 3. Rujukan dan Landasan


## 3.1 Tiga rujukan utama

Pemilihan lima kandidat algoritma tidak dilakukan secara bebas. Setiap algoritma yang diuji muncul sebagai pemenang atau sebagai pembanding utama pada salah satu dari tiga artikel jurnal berikut.

| Rujukan | Data yang dipakai | Algoritma yang dibandingkan | Hasil yang dilaporkan | Pemenang |
| --- | --- | --- | --- | --- |
| Fitri, E. (2023). *Analisis Perbandingan Metode Regresi Linier, Random Forest Regression dan Gradient Boosted Trees Regression Method untuk Prediksi Harga Rumah.* JACOST 4(1), 58–64. DOI: 10.52158/jacost.v4i1.491 | 2.011 rumah (Jakarta Selatan 1.001 + Tebet 1.010), 6 atribut, pembagian 80/20, normalisasi fitur | Linear Regression, Random Forest Regression, Gradient Boosted Trees | RMSE: RF 0,440 · LR 0,515 · GBT 0,508. Akurasi RF 81,5 % | Random Forest |
| Sari, B. W. & Prabowo, D. (2025). *Analisis Perbandingan Prediksi Harga Rumah Dengan Random Forest, Gradient Boosting, dan XGBoost.* Intellect 4(1), 42–51. DOI: 10.57255/intellect.v4i1.1385 | 1.642 entri Yogyakarta; harga Rp 7 juta – Rp 4,37 miliar; fitur luas tanah, luas bangunan, kamar tidur, kamar mandi, garasi | Random Forest, Gradient Boosting, XGBoost | XGBoost MSE 1,56 × 10¹⁴ Rp², R² 0,7746, RMSE ≈ Rp 12,5 juta | XGBoost |
| Hayya’, M., Hana, F. M. & Prihandono, A. (2025). *Perbandingan Metode K-Nearest Neighbor (KNN) dan Random Forest dalam Memprediksi Harga Rumah.* Sainteks 22(1), 99–108. DOI: 10.30595/sainteks.v22i1.25998 | 2.020 baris data harga rumah | KNN, Random Forest | RF MAE 54,80 · MSE 7.004,70 · R² 0,55. KNN MAE 87,64 · MSE 13.314,95 | Random Forest |


## 3.2 Apa yang diambil dari tiap rujukan

- **Dari Fitri (2023):** kerangka membandingkan baseline linear dengan dua ansambel pohon, serta penggunaan RMSE sebagai metrik utama. Studi ini juga menjadi dasar pemakaian Gradient Boosted Trees sebagai pembanding ansambel boosting.
- **Dari Sari & Prabowo (2025):** penggunaan XGBoost sebagai pembanding dan kombinasi metrik MSE/R²/RMSE. Studi ini menunjukkan bahwa pada data satu wilayah, boosting bisa mengalahkan Random Forest.
- **Dari Hayya’ dkk. (2025):** penggunaan KNN sebagai pembanding berbasis kedekatan, serta penggunaan MAE dan MSE secara berdampingan. Studi ini menegaskan bahwa pada data dengan banyak dimensi fitur, KNN cenderung tertinggal dari ansambel pohon.


## 3.3 Kesenjangan yang mendasari pengulangan

Tiga rujukan itu **tidak sepakat**: dua memilih Random Forest, satu memilih XGBoost. Ketiganya juga memakai data yang jauh lebih kecil dan terbatas pada satu wilayah (1.000–2.020 baris, satu kota atau satu kawasan). Dataset Rumah Point berbeda secara mendasar: puluhan ribu baris, ratusan kota, enam sumber dengan kualitas tidak seragam, dan sebaran harga yang sangat lebar.

Karena itu hasil ketiga jurnal tidak boleh dipindahkan begitu saja. Yang bisa dipindahkan adalah **metodenya** — membandingkan kandidat pada perlakuan identik — sedangkan **kesimpulannya** harus diukur ulang pada data sendiri. Inilah kontribusi eksperimen ini.


## 3.4 Posisi studi ini

| Aspek | Ketiga rujukan | Eksperimen ini |
| --- | --- | --- |
| Cakupan wilayah | Satu kota / satu kawasan | 445 kota di 34 provinsi |
| Ukuran data | 1.000 – 2.020 baris | 64.228 baris bersih |
| Sumber data | Satu sumber (Kaggle / satu portal) | Enam sumber (Kaggle, 4 portal scraping, 2 repositori GitHub) |
| Jumlah algoritma | 2 – 3 | 5, dengan perlakuan identik |
| Validasi | Umumnya satu kali *hold-out* | *Hold-out* + validasi silang 5 lipatan |
| Metrik | RMSE / MSE / R² | R² log10, MAE dan RMSE rupiah, MAPE, plus metrik klasifikasi |
| Uji fitur | Tidak dilaporkan | Uji eksplisit untuk fitur usia bangunan |


# 4. Data


## 4.1 Sumber data

Dataset adalah gabungan enam sumber yang disatukan oleh `dataset/build_union.py` menjadi `dataset/properti_multi_kota.csv` (64.650 baris, 3,8 MB). Setelah pembersihan, komposisinya:

| Sumber | Baris | Porsi | Catatan lisensi |
| --- | --- | --- | --- |
| FLUS / komersil (Kaggle) | 39.120 | 60,91 % | CC0 Public Domain |
| 99.co | 14.270 | 22,22 % | Listing publik hasil scraping; kepatuhan ToS dibahas tim dan dosen |
| rumah123 | 8.792 | 13,69 % | Listing publik hasil scraping; kepatuhan ToS dibahas tim dan dosen |
| uas-properti (GitHub) | 1.528 | 2,38 % | Lisensi belum tercatat |
| Pinhome | 318 | 0,50 % | Lisensi/ToS belum tercatat |
| ColectDataRumah (GitHub) | 200 | 0,31 % | Lisensi belum tercatat |

Komposisi ini penting untuk membaca hasil: satu sumber menyumbang hampir dua pertiga data, sehingga karakteristiknya mendominasi model. Hal ini juga menjadi alasan mengapa fitur yang hanya tersedia di sumber kecil tidak layak dipakai (Bagian 4.7).


## 4.2 Skema dan statistik deskriptif

Kolom mentah: `sumber`, `lokasi`, `luas_m2`, `luas_bangunan`, `jumlah_kamar`, `jumlah_kamar_mandi`, `usia_bangunan`, `harga`.

| Karakteristik | Nilai |
| --- | --- |
| Baris mentah → baris bersih | 64.650 → 64.228 (422 dibuang, 0,65 %) |
| Lokasi mentah unik → kota kanonik | 593 → 445 |
| Provinsi terwakili | 34 dari 34 |
| Harga minimum / median / maksimum | Rp 1 juta / Rp 741,2 juta / Rp 450 miliar |
| Luas tanah median / persentil 95 / maksimum | 98 m² / 600 m² / 830.000 m² |
| Luas bangunan median (kosong 1.707 baris) | 64 m² |
| Jumlah kamar & kamar mandi median | 2 dan 2 |
| Rata-rata & simpangan log10(harga) | 8,92 dan 0,47 |
| Kelas Mahal / Murah | 32.690 / 31.538 (mendekati seimbang) |
| Kota dengan hanya 1 baris | 47 |
| Baris duplikat identik (tidak dibuang) | 7.144 |

Sebaran harga sangat menceng ke kanan: median Rp 741 juta tetapi maksimum Rp 450 miliar. Karena itu target regresi diubah ke **log10(harga)**. Tanpa transformasi ini, beberapa properti bernilai ekstrem akan mendominasi fungsi galat dan model hanya belajar menebak rumah mahal.


## 4.3 Temuan masalah kualitas data

Dataset hasil scraping mengandung nilai yang bukan properti nyata. Temuan berikut diperoleh saat eksplorasi dan menjadi dasar aturan pembersihan:

| Temuan | Bukti | Dampak bila dibiarkan |
| --- | --- | --- |
| Angka bercampur satuan dan teks | Nilai seperti `"68.0 m2"` pada kolom numerik | Kolom terbaca sebagai teks; perhitungan gagal |
| Harga placeholder | 245 baris berharga di bawah Rp 1 juta, termasuk harga literal **Rp 1** untuk tanah ribuan m² | Pada skala log10, Rp 1 bernilai 0 sementara median 8,92 — satu baris saja merusak RMSE |
| Harga mustahil besar | 14 baris di atas Rp 1 kuadriliun (digit berulang) | Menarik garis regresi dan merusak sumbu grafik |
| Fitur mustahil | Baris dengan `jumlah_kamar` 405.000.000 dan `luas_bangunan` 9.876.543.000 m² | Membuat koefisien model linear meledak; mengacaukan jarak KNN |
| Luas tanah tidak wajar | 39 baris di bawah 10 m²; beberapa baris berhektar-hektar | Bukan rumah; menyesatkan hubungan luas–harga |
| Nama wilayah tidak baku | 593 ejaan untuk 445 kota; `Kota X` vs `X`, `Jak. Utara` | Kota yang sama terpecah menjadi beberapa kategori |
| Usia bangunan hampir kosong | 59.443 dari 64.228 baris (92,55 %) kosong; FLUS 0 % terisi | Fitur hanya merepresentasikan asal sumber, bukan kondisi bangunan |


## 4.4 Prosedur pembersihan

Setiap aturan punya alasan dan dampak terukur. Urutannya diterapkan pada seluruh data sebelum pembagian latih/uji, sehingga tidak ada kebocoran informasi dari data uji.

| Saringan | Alasan | Baris dibuang |
| --- | --- | --- |
| Lokasi kosong | Tidak bisa dipetakan ke wilayah yang bisa dipilih pengguna | 0 |
| Harga atau luas tidak bisa diparse / tidak positif | Bukan angka yang bisa dilatih | 0 |
| Harga di bawah Rp 1 juta | Menangkap placeholder seperti `Rp 1` | 245 |
| Harga di atas Rp 1 kuadriliun | Placeholder digit berulang | 14 |
| Luas tanah di bawah 10 m² | Batas yang sama dengan `ml/train.py`; bukan petak rumah | 39 |
| Luas tanah di atas 1.000.000 m² | Daftar tanah, bukan rumah | 0 |
| Harga per m² di atas Rp 100 juta | Batas yang sama dengan `ml/train.py` | 124 |
| Lokasi kanonik kosong | Tidak bisa dipetakan ke aset wilayah | 0 |
| **Total** |  | **422** |

Nilai fitur yang mustahil (luas bangunan di luar 1–100.000 m², kamar di luar 0–50) tidak menghapus baris, tetapi diubah menjadi kosong lalu **diimputasi median di dalam pipeline**, pada setiap lipatan validasi. Baris duplikat identik (7.144) dilaporkan tetapi tidak dibuang, karena dua rumah bisa memiliki kombinasi fitur dan harga yang sama.


## 4.5 Normalisasi nama wilayah

Aplikasi hanya bisa menerima nama wilayah yang ada di `mobile/assets/data/wilayah.json` (34 provinsi, 515 kabupaten/kota). Karena itu nama hasil scraping dipetakan dengan urutan:

1. Nama yang sudah persis ada di aset dipertahankan.
2. `Kota X` dicoba sebagai `X`, karena aset tidak memakai awalan `Kota `.
3. Nama tanpa awalan dicoba sebagai `Kabupaten X`.
4. Nama yang tetap tidak ditemukan dibiarkan apa adanya dan dilaporkan.

Hasil: 593 nama mentah menjadi **445 kota kanonik**, dengan 7.787 baris berhasil dipetakan. Nama mentah tetap disimpan di `lokasi_mentah` agar asal-usulnya bisa diaudit.


## 4.6 Definisi fitur dan target

| Peran | Isi |
| --- | --- |
| Fitur numerik | `luas_m2`, `luas_bangunan`, `jumlah_kamar`, `jumlah_kamar_mandi` |
| Fitur kategorik | `lokasi` (445 tingkat, di-OneHot) |
| Target regresi | `log10(harga)` |
| Target klasifikasi | `Mahal` bila harga ≥ median harga kota itu, selain itu `Murah` |
| Fitur yang tidak dipakai | `usia_bangunan` (lihat 4.7); `sumber` (akan membocorkan asal data, bukan sifat properti) |

Definisi kategori memakai **median per kota**, bukan median nasional. Konsekuensinya, rumah Rp 800 juta bisa tergolong Mahal di Sidoarjo tetapi Murah di Jakarta Selatan. Ini disengaja: aplikasi memberi konteks harga terhadap kotanya sendiri, sehingga label harus mengikuti konteks yang sama.


## 4.7 Keputusan membuang fitur usia bangunan

Proposal awal memasukkan usia bangunan (dipetakan dari pilihan kondisi Baru/Bekas). Setelah dataset diperluas, data menunjukkan fitur ini tidak layak. Buktinya:

| Sumber | Baris | Usia terisi | Persentase |
| --- | --- | --- | --- |
| FLUS / komersil | 39.120 | 0 | 0,00 % |
| 99.co | 14.270 | 2.358 | 16,52 % |
| rumah123 | 8.792 | 937 | 10,66 % |
| uas-properti | 1.528 | 1.490 | 97,51 % |
| Pinhome | 318 | 0 | 0,00 % |
| ColectDataRumah | 200 | 0 | 0,00 % |
| **Total** | **64.228** | **4.785** | **7,45 %** |

Selain hampir seluruhnya kosong, satuannya juga bercampur: 3.070 nilai berupa **tahun** (1900–2026) dan sisanya berupa **umur** (0–126). Jika diimputasi mentah, mediannya menjadi angka tahun, bukan umur.

Untuk memastikan keputusan ini tidak merugikan, dilakukan uji eksplisit: Random Forest dilatih dua kali pada pembagian data dan lipatan yang sama, dengan kriteria yang **ditetapkan sebelum hasilnya dilihat**.

| Kriteria (ditetapkan lebih dahulu) | Ambang |
| --- | --- |
| Selisih R² log10 *hold-out* (dengan − tanpa usia) | minimal +0,010 |
| Selisih R² log10 validasi silang | minimal +0,005 |
| MAE rupiah *hold-out* | harus turun |

| Varian | R² log10 *hold-out* | MAE *hold-out* | R² log10 CV | MAE CV |
| --- | --- | --- | --- | --- |
| Tanpa usia bangunan | 0,8134 | Rp 581.266.918 | 0,8153 | Rp 631.521.340 |
| Dengan usia bangunan | 0,8134 | Rp 583.170.875 | 0,8153 | Rp 634.606.654 |
| **Selisih** | **−0,0000** | **+Rp 1.903.957** | **+0,0000** | **+Rp 3.085.314** |

Ketiga ambang tidak terpenuhi: R² tidak berubah pada empat angka desimal, dan MAE justru **naik** (lebih buruk) ketika fitur ditambahkan. **Keputusan: usia bangunan dibuang sebagai fitur.** Kolomnya tetap disimpan di dataset sebagai data historis, tetapi tidak masuk ke model.


# 5. Metodologi (Proses A–D)


## 5.1 Prinsip keadilan perbandingan

Tuntutan utama tugas ini adalah *semua parameter harus sama, termasuk praproses data*. Prinsip itu diterjemahkan menjadi satu aturan operasional: **tidak ada satu pun kandidat yang mendapat perlakuan berbeda**. Semua menerima objek data yang sama, dari fungsi praproses yang sama, dengan pembagian dan lipatan yang sama.

| Komponen | Keputusan | Alasan |
| --- | --- | --- |
| Data | 64.228 baris bersih; 51.382 latih / 12.846 uji | Satu sumber data untuk semua model |
| Pembagian data | 80/20, `random_state = 42` | Dapat direproduksi; sama untuk regresi dan klasifikasi |
| Validasi silang | 5 lipatan `KFold(shuffle=True, random_state=42)` pada baris latih | Menguji kestabilan, bukan satu pembagian kebetulan |
| Fitur | 4 numerik + `lokasi` | Sama untuk semua kandidat |
| Praproses | Imputasi median → `StandardScaler` untuk numerik; `OneHotEncoder` untuk `lokasi`; di-*fit* di dalam pipeline per lipatan | Wajib untuk model berbasis jarak dan linear; tidak merugikan model pohon karena penskalaan bersifat monoton |
| Target regresi | `log10(harga)` | Menjinakkan sebaran yang sangat menceng |
| Hyperparameter | Nilai bawaan pustaka; hanya `random_state` dan `n_jobs` yang disetel | Tidak ada model yang “disayang” |
| Metrik | R² log10, MAE & RMSE rupiah, MAPE, waktu, ukuran model | Akurasi sekaligus biaya operasional |

Satu penyesuaian kecil yang jujur perlu dicatat: Logistic Regression memakai `max_iter = 1000` agar konvergen. Ini bukan *tuning* — nilai bawaan gagal konvergen pada data ini — dan tidak mengubah bentuk model. KNN memakai seluruh baris latih, bukan subsampel, agar datanya tetap identik dengan kandidat lain.


## 5.2 Proses A — Persiapan data (notebook 01)

**Tujuan:** menghasilkan satu dataset bersih dan satu pembagian data yang menjadi kontrak bagi seluruh eksperimen. Tidak ada model yang dilatih di tahap ini.

**Langkah dan alasannya:**

1. Memuat data mentah dan memeriksa tipe serta kelengkapan kolom — untuk mengetahui kolom mana yang perlu diparse manual.
2. Menguji parser angka dengan kasus uji eksplisit (desimal, pemisah ribuan, satuan `m2`, harga dalam juta/miliar) dan **menghentikan proses bila satu kasus gagal** — supaya kesalahan parsing tidak terbawa ke seluruh perbandingan.
3. Membersihkan baris mustahil dengan tujuh saringan pada Bagian 4.4 — setiap saringan diberi alasan, bukan sekadar angka.
4. Menormalkan nama wilayah mengikuti aset aplikasi — agar model hanya mengenal wilayah yang benar-benar bisa dipilih pengguna.
5. Membentuk target regresi dan klasifikasi — dengan transformasi log dan label median per kota.
6. Membagi data 80/20 dan membentuk 5 lipatan **hanya dari baris latih** — agar data uji tidak pernah terlihat saat validasi.
7. Menyimpan split, lipatan, dan sidik jari (SHA-256) — menjadi bukti bahwa notebook berikutnya memakai baris yang sama.

**Mengapa sidik jari diperlukan:** tanpa bukti hash, klaim “data yang sama” hanya bisa dipercaya. Dengan hash, notebook 02, 03, dan 04 bisa **memverifikasi** bahwa mereka memakai baris latih dan uji yang identik, dan berhenti bila tidak cocok.


## 5.3 Proses B — Perbandingan regresi (notebook 02)

**Tujuan:** menentukan algoritma terbaik untuk memprediksi harga.

Lima kandidat dilatih pada baris latih yang sama, lalu diuji pada baris uji yang sama. Setiap kandidat kemudian diuji ulang dengan lima lipatan validasi silang yang sama. Hasilnya dibandingkan pada empat metrik sekaligus, ditambah waktu dan ukuran model.

**Aturan pemenang ditetapkan sebelum hasil dilihat:** rata-rata R² log10 validasi silang tertinggi; jika seri, MAE rupiah validasi silang terendah; jika masih seri, R² *hold-out*. Urutan ini dipilih karena validasi silang lebih tahan terhadap keberuntungan satu pembagian data.


## 5.4 Proses C — Perbandingan klasifikasi (notebook 03)

**Tujuan:** menentukan algoritma terbaik untuk kategori Murah/Mahal, yang juga ditampilkan aplikasi.

Lima kandidat serupa dipakai, dengan satu penyesuaian wajar: Linear Regression tidak bisa mengklasifikasi, sehingga padanan linearnya adalah **Logistic Regression**. Aturan pemenang: rata-rata F1-macro validasi silang tertinggi, tie-break ROC-AUC, lalu F1-macro *hold-out*. F1-macro dipakai karena memberi bobot sama pada kedua kelas, sementara ROC-AUC mengukur kualitas pemeringkatan probabilitas tanpa bergantung pada ambang 0,5.

Sebagai pembanding wajib, dicetak **baseline kelas mayoritas** (0,5085). Sebuah model klasifikasi yang tidak melewati angka itu tidak berguna, sekalipun akurasinya terlihat “di atas 50 %”.


## 5.5 Proses D — Sintesis dan penetapan (notebook 04)

**Tujuan:** memverifikasi dan menyimpulkan, bukan melatih ulang. Notebook ini:

1. memverifikasi sidik jari data agar hasil tidak dibaca dari data yang berbeda;
2. memuat seluruh hasil dari CSV/JSON yang ditulis tahap sebelumnya;
3. menampilkan tabel *hold-out* dan validasi silang berdampingan;
4. menyebut pemenang beserta alasan yang **dihitung kode**, bukan diketik;
5. merangkum keputusan fitur usia;
6. menyandingkan hasil dengan pemenang ketiga jurnal.


## 5.6 Metrik dan alasan pemilihan

| Metrik | Mengukur apa | Mengapa dipakai |
| --- | --- | --- |
| R² log10 | Proporsi keragaman log-harga yang dijelaskan model | Metrik utama pada skala tempat model dilatih; tidak meledak karena rumah bernilai ekstrem |
| MAE rupiah | Rata-rata selisih absolut dalam rupiah | Paling mudah dipahami pengguna: “meleset berapa juta?” |
| RMSE rupiah | Akar rata-rata galat kuadrat dalam rupiah | Menghukum kesalahan besar; melengkapi MAE |
| MAPE | Rata-rata galat relatif (%) | Menunjukkan galat relatif, tetapi bisa membesar pada rumah murah — karena itu tidak dipakai sendirian |
| R² rupiah | R² pada skala rupiah | Dilaporkan untuk transparansi, tetapi sangat dipengaruhi beberapa rumah bernilai ekstrem |
| Akurasi, F1-macro, ROC-AUC | Kinerja klasifikasi | F1-macro adil untuk dua kelas; ROC-AUC mengukur pemeringkatan |
| Waktu latih, waktu prediksi, ukuran model | Biaya operasional | Model disajikan dari VPS kecil; akurasi tertinggi tidak berguna bila tidak bisa dilayani |


## 5.7 Keterlacakan dan reproduksibilitas

Setiap notebook mencetak sidik jari data yang sama, dan notebook 04 berhenti bila hash tidak cocok. Nilai sidik jari yang mengikat seluruh laporan ini:

| Kunci | Nilai |
| --- | --- |
| Baris mentah | 64.650 |
| Baris bersih | 64.228 |
| Baris latih / uji | 51.382 / 12.846 |
| SHA-256 baris latih | cfe3defcae087f44fa6a7189a319ef258f4138318a7532b315bf80a85dc9990e |
| SHA-256 baris uji | 718f7f914fe83904e4899da30d2fc6b7a06e249431befe26985f93e43efe7aef |
| SHA-256 berkas dataset | 34375406a6d72b21bad55e5784caddc931a85bb20c999414d3fdd6b2f5774d18 |


## 5.8 Lingkungan eksekusi

| Komponen | Versi |
| --- | --- |
| Python | 3.12.3 |
| scikit-learn | 1.9.0 |
| pandas | 3.0.5 |
| NumPy | 2.5.2 |
| XGBoost | 3.4.1 |
| joblib | 1.6.0 |
| Platform | Linux x86_64 |

Waktu eksekusi bergantung pada mesin. Angka waktu pada laporan ini adalah perbandingan relatif **pada mesin yang sama**, bukan patokan produksi.


# 6. Hasil Eksperimen


## 6.1 Regresi — hold-out (12.846 baris uji)

| Model | R² log10 | MAE | RMSE | MAPE | Latih (s) | Prediksi (s) | Ukuran |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Random Forest** | **0,8134** | **Rp 581,3 jt** | **Rp 2.974,4 jt** | 83,9 % | 208,83 | 1,852 | 319,44 MB |
| XGBoost | 0,7887 | Rp 679,7 jt | Rp 3.161,6 jt | 85,4 % | 14,31 | 0,304 | 0,33 MB |
| KNN | 0,7500 | Rp 733,3 jt | Rp 3.344,5 jt | 94,5 % | 4,37 | 25,290 | 172,50 MB |
| Gradient Boosting | 0,7217 | Rp 779,8 jt | Rp 3.369,9 jt | 108,1 % | 138,44 | 0,719 | 0,15 MB |
| Linear Regression | 0,4634 | Rp 69.961,7 jt | Rp 5.663.928,5 jt | 470,1 % | 15,97 | 0,285 | 0,02 MB |


## 6.2 Regresi — validasi silang 5 lipatan

| Model | R² log10 (rata-rata ± s.b.) | MAE rupiah | MAPE | Latih (s) |
| --- | --- | --- | --- | --- |
| **Random Forest** | **0,8153 ± 0,0071** | **Rp 631,5 jt** | 87,7 % | 204,45 |
| XGBoost | 0,7958 ± 0,0078 | Rp 716,4 jt | 93,0 % | 7,82 |
| KNN | 0,7531 ± 0,0091 | Rp 795,8 jt | 89,4 % | 3,83 |
| Gradient Boosting | 0,7299 ± 0,0085 | Rp 833,0 jt | 102,2 % | 99,61 |
| Linear Regression | 0,4848 ± 0,0116 | Rp 99.517,0 jt | 449,7 % | 6,40 |

Simpangan baku Random Forest (0,0071) termasuk yang terkecil, dan lipatan terburuknya masih 0,8031 — lebih tinggi daripada rata-rata semua kandidat lain. Artinya keunggulannya tidak bergantung pada satu lipatan yang kebetulan mudah.


## 6.3 Klasifikasi — hold-out (12.846 baris uji)

| Model | Akurasi | F1-macro | ROC-AUC | Latih (s) | Prediksi (s) | Ukuran |
| --- | --- | --- | --- | --- | --- | --- |
| **Random Forest** | **0,8641** | **0,8640** | **0,9376** | 54,62 | 6,492 | 144,64 MB |
| KNN | 0,8346 | 0,8346 | 0,9046 | 8,23 | 38,404 | 172,50 MB |
| XGBoost | 0,8325 | 0,8325 | 0,9157 | 11,93 | 1,602 | 0,28 MB |
| Gradient Boosting | 0,7949 | 0,7949 | 0,8734 | 192,56 | 0,694 | 0,15 MB |
| Logistic Regression | 0,7769 | 0,7757 | 0,8666 | 10,94 | 2,975 | 0,02 MB |
| *Baseline kelas mayoritas* | *0,5085* | — | — | — | — | — |


## 6.4 Klasifikasi — validasi silang 5 lipatan

| Model | Akurasi (rata-rata ± s.b.) | F1-macro | ROC-AUC |
| --- | --- | --- | --- |
| **Random Forest** | **0,8648 ± 0,0026** | **0,8647** | **0,9382** |
| XGBoost | 0,8376 ± 0,0037 | 0,8376 | 0,9208 |
| KNN | 0,8316 ± 0,0025 | 0,8316 | 0,9028 |
| Gradient Boosting | 0,8026 ± 0,0059 | 0,8026 | 0,8830 |
| Logistic Regression | 0,7851 ± 0,0022 | 0,7841 | 0,8700 |


## 6.5 Matriks kebingungan Random Forest

Prediksi *hold-out* model pemenang pada 12.846 baris uji:

|  | Prediksi Murah | Prediksi Mahal |
| --- | --- | --- |
| **Aktual Murah** | 5.392 (benar) | 890 (salah: dinilai Mahal) |
| **Aktual Mahal** | 856 (salah: dinilai Murah) | 5.708 (benar) |

Total benar 11.100 dari 12.846 (86,41 %). Galatnya hampir berimbang di kedua arah (890 vs 856), menandakan model tidak condong ke salah satu kelas — konsisten dengan F1-macro (0,8640) yang hampir sama dengan akurasi.


## 6.6 Uji fitur usia bangunan

Sudah diuraikan pada Bagian 4.7. Ringkasnya: menambahkan usia bangunan **tidak** menaikkan R² pada empat angka desimal dan justru **menaikkan** MAE sebesar Rp 1,9 juta (*hold-out*) dan Rp 3,1 juta (CV). Keputusan: dibuang.


## 6.7 Biaya komputasi

| Model | Latih regresi | Prediksi regresi | Ukuran regresi | Latih klasifikasi | Ukuran klasifikasi |
| --- | --- | --- | --- | --- | --- |
| Random Forest | 208,83 s | 1,852 s | 319,44 MB | 54,62 s | 144,64 MB |
| XGBoost | 14,31 s | 0,304 s | 0,33 MB | 11,93 s | 0,28 MB |
| Gradient Boosting | 138,44 s | 0,719 s | 0,15 MB | 192,56 s | 0,15 MB |
| KNN | 4,37 s | 25,290 s | 172,50 MB | 8,23 s | 172,50 MB |
| Linear/Logistic Regression | 15,97 s | 0,285 s | 0,02 MB | 10,94 s | 0,02 MB |


# 7. Analisis: Mengapa Random Forest


## 7.1 Enam alasan yang saling menguatkan

Random Forest tidak dipilih karena satu angka. Ada enam alasan yang masing-masing punya bukti terukur:


### Alasan 1 — Akurasi tertinggi, dan stabil di lima lipatan

R² log10 *hold-out* 0,8134 dan rata-rata CV 0,8153 ± 0,0071. Selisih terhadap XGBoost (kandidat terdekat) adalah **+0,0247** pada *hold-out* dan **+0,0194** pada CV — lebih dari dua kali simpangan baku antar-lipatan XGBoost (0,0078). Artinya keunggulan itu berada di luar derau pengukuran, bukan hasil kebetulan.

Kestabilan juga terlihat pada lipatan terburuk: 0,8031, masih lebih tinggi daripada rata-rata Gradient Boosting (0,7299) dan KNN (0,7531).


### Alasan 2 — Galat rupiah terkecil, yaitu angka yang dirasakan pengguna

R² bisa menyesatkan bila model bagus pada rumah mahal tetapi buruk pada rumah murah. MAE rupiah mengukur hal yang dialami pengguna. Random Forest mencapai **Rp 581,3 juta** — **14,5 % lebih rendah** daripada XGBoost, **20,7 %** lebih rendah daripada KNN, dan **25,5 %** lebih rendah daripada Gradient Boosting.

Menariknya, Random Forest menang pada MAE **dan** RMSE sekaligus. Model yang hanya menang salah satunya biasanya menandakan kompromi: sangat tepat pada mayoritas tetapi meledak pada sebagian kecil kasus. Di sini tidak.


### Alasan 3 — Menang pada dua tugas sekaligus

Aplikasi mengeluarkan dua keluaran: harga dan kategori. Memakai satu keluarga model untuk keduanya punya nilai tersendiri:

- satu praproses dan satu pipeline yang harus dipelihara, bukan dua;
- perilaku konsisten — model yang menyebut sebuah rumah “Mahal” juga cenderung memberi estimasi harga yang lebih tinggi;
- satu berkas konfigurasi dan satu jalur *deploy*.

Pada klasifikasi, Random Forest memimpin dengan akurasi 0,8648 ± 0,0026 (CV) dan ROC-AUC 0,9382. Selisihnya terhadap XGBoost **+0,0272** akurasi — lebih dari sepuluh kali simpangan bakunya (0,0026).


### Alasan 4 — Sejalan dengan dua dari tiga rujukan

Dua dari tiga jurnal acuan menyimpulkan Random Forest unggul (Fitri, 2023; Hayya’ dkk., 2025). Hanya Sari & Prabowo (2025) yang menyimpulkan XGBoost. Eksperimen ini **menguatkan mayoritas rujukan** pada dataset yang jauh lebih beragam, dan sekaligus menjelaskan mengapa hasil Sari & Prabowo berbeda: data mereka hanya 1.642 baris dari satu wilayah (Yogyakarta), sehingga XGBoost yang lebih agresif menangkap pola lokal punya keunggulan.


### Alasan 5 — Cocok dengan karakter data

Empat sifat dataset ini secara langsung menguntungkan Random Forest dan merugikan kandidat lain:

| Sifat data | Konsekuensi | Model yang dirugikan |
| --- | --- | --- |
| Campuran numerik + kategori dengan 445 tingkat (`lokasi`) | Pohon dapat memecah kategori secara alami; model linear harus membuat ratusan koefisien | Linear/Logistic Regression |
| Hubungan non-linear (harga tidak naik proporsional terhadap luas) | Pohon menangkap interaksi tanpa rekayasa fitur | Linear/Logistic Regression |
| Masih ada nilai ekstrem setelah pembersihan | Ansambel merata-ratakan banyak pohon sehingga tahan outlier | Linear Regression (sangat sensitif), KNN (tetangga tertarik ke nilai ekstrem) |
| Skala fitur berbeda jauh (luas ribuan m² vs kamar satuan) | Pohon tidak peduli skala | KNN (sangat bergantung jarak) |


### Alasan 6 — Dapat dijelaskan kepada pengguna

Random Forest menyediakan *feature importance* per fitur. Untuk aplikasi konsumen, ini penting: ketika pengguna bertanya “mengapa harganya segitu?”, tim bisa menunjukkan fitur mana yang paling berpengaruh, bukan sekadar menampilkan angka. Model seperti SVR atau jaringan saraf tidak memberi kemudahan yang sama.


## 7.2 Perbandingan langsung dengan setiap algoritma


### Random Forest vs XGBoost — pesaing terdekat

| Aspek | Random Forest | XGBoost | Selisih |
| --- | --- | --- | --- |
| R² log10 *hold-out* | 0,8134 | 0,7887 | **+0,0247** (RF unggul) |
| R² log10 CV | 0,8153 | 0,7958 | **+0,0194** |
| MAE rupiah | Rp 581,3 jt | Rp 679,7 jt | **−14,5 %** (RF unggul) |
| RMSE rupiah | Rp 2.974,4 jt | Rp 3.161,6 jt | **−5,9 %** |
| Akurasi klasifikasi (CV) | 0,8648 | 0,8376 | **+0,0272** |
| Waktu latih regresi | 208,83 s | 14,31 s | XGB **14,6× lebih cepat** |
| Ukuran model regresi | 319,44 MB | 0,33 MB | XGB **±970× lebih kecil** |

Ini satu-satunya perbandingan yang benar-benar kompetitif. XGBoost unggul telak pada biaya: hampir 15 kali lebih cepat dilatih dan sekitar tiga orde magnitudo lebih kecil. Namun pada akurasi dan galat rupiah, Random Forest menang dengan selisih yang melewati derau pengukuran. Karena model hanya dilatih ulang sesekali (bukan setiap permintaan pengguna), dan inferensinya hanya ~1,9 detik untuk 12.846 baris, biaya latih bukan faktor penentu. **Akurasi dipilih di atas efisiensi.**

Perlu dicatat jujur: selisih 0,0247 pada R² bukan jurang. Bila kelak ukuran model menjadi kendala nyata (mis. kuota penyimpanan atau memori VPS), XGBoost adalah pengganti pertama yang paling wajar, dengan penurunan akurasi yang terukur.


### Random Forest vs Gradient Boosting

Selisihnya paling lebar di antara ansambel: **+0,0917 R²**, **−25,5 % MAE**, **−11,7 % RMSE**. Gradient Boosting juga paling lambat dilatih (138 s) dengan MAPE terburuk (108,1 %). Ini berbeda dari kesimpulan Fitri (2023), yang menemukan GBT hanya sedikit di bawah Random Forest (RMSE 0,508 vs 0,440). Penjelasan yang paling masuk akal: pada data kecil satu wilayah, boosting dengan kedalaman dangkal sudah cukup; pada 445 kota dengan enam sumber berbeda, boosting dangkal belum mampu menangkap keragaman, sementara ansambel banyak pohon lepas lebih tahan terhadap keragaman itu.


### Random Forest vs KNN

KNN kalah pada akurasi (**−0,0634 R²**, **−20,7 % MAE**) dan jauh lebih mahal saat melayani: **25,3 detik** untuk 12.846 prediksi, sekitar **13,7 kali** lebih lambat daripada Random Forest (1,85 detik). Penyebabnya struktural: KNN menyimpan seluruh data latih dan menghitung jarak ke semuanya pada setiap prediksi. Pada data berdimensi tinggi dengan 445 kategori lokasi, jarak menjadi kurang bermakna. Untuk aplikasi yang harus merespons cepat, ini kombinasi yang buruk: lebih lambat **dan** kurang akurat.


### Random Forest vs Linear Regression

Perbedaannya bukan sekadar “lebih baik”, melainkan **jenis hubungan yang berbeda**. Linear Regression menghasilkan R² 0,4634 dengan MAE **Rp 69,96 miliar** — sekitar **120 kali** lebih besar daripada Random Forest — dan MAPE 470 %. Angka R² rupiahnya bahkan negatif (−1.607.406), tanda bahwa prediksinya lebih buruk daripada sekadar menebak rata-rata pada skala rupiah.

Kegagalan ini informatif, bukan memalukan: ia membuktikan hubungan antara fitur dan harga **tidak linear**. Harga properti tidak naik proporsional terhadap luas; ada ambang, interaksi antar-fitur, dan efek lokasi yang tidak bisa diwakili satu koefisien. Ini justru pembenaran kuat untuk memakai model berbasis pohon.


## 7.3 Trade-off yang diterima secara sadar

| Konsekuensi | Angka | Alasan tetap dipilih |
| --- | --- | --- |
| Ukuran model regresi besar | 319,44 MB | Disimpan sekali di server; inferensi tidak memuat ulang per permintaan |
| Waktu latih paling lama | 208,83 s | Pelatihan ulang hanya dilakukan saat dataset berubah, bukan tiap permintaan |
| Waktu prediksi menengah | 1,852 s untuk 12.846 baris | ±0,14 ms per prediksi — jauh di bawah ambang respons aplikasi |
| Tidak ada tuning | Parameter bawaan | Konsisten dengan aturan perbandingan; tuning bisa menjadi pekerjaan lanjutan terpisah |

Satu hal yang perlu dicatat: model yang tersimpan 319 MB adalah hasil `joblib.dump` **tanpa kompresi**. Bila ukuran menjadi masalah, kompresi atau pengurangan jumlah pohon dapat menekannya tanpa mengubah pilihan algoritma.


## 7.4 Temuan penting: kualitas data mengalahkan pilihan algoritma

Selama eksperimen ditemukan bahwa selisih antar-algoritma jauh lebih kecil daripada dampak pembersihan data. Untuk mengukurnya, satu algoritma yang sama (HistGradientBoosting) dilatih pada tiga tingkat kebersihan data yang berbeda, dengan pembagian data yang sama:

| Tingkat kebersihan | Baris | R² log10 | MAE log10 |
| --- | --- | --- | --- |
| A. Seperti aturan produksi sekarang (hanya filter ekor) | 64.473 | 0,5488 | 0,1806 |
| B. + buang harga placeholder | 64.228 | 0,7818 | 0,1506 |
| C. + buang fitur mustahil (= data eksperimen) | 64.199 | 0,7912 | 0,1519 |

> **Sumber angka bagian ini.** Angka A/B/C di atas berasal dari pengukuran tambahan yang dijalankan terpisah dari notebook `docs/01`–`04` (HistGradientBoosting, `random_state=42`, pembagian 80/20 yang sama, fitur numerik + `lokasi`). Angka ini **tidak** ada di `docs/perbandingan_output/` dan tidak boleh dikutip sebagai keluaran notebook. Tujuannya satu: mengukur seberapa besar dampak pembersihan data dibandingkan dampak pilihan algoritma, karena keduanya sering tertukar saat membaca selisih R² produksi dan eksperimen (Bagian 8.4).

Dari A ke B, R² naik **0,2330** hanya dengan membuang 245 baris berharga di bawah Rp 1 juta. Bandingkan dengan selisih Random Forest vs XGBoost yang hanya 0,0247. **Membersihkan data sekali lebih berdampak daripada memilih algoritma.** Temuan ini menjadi salah satu rekomendasi utama pada Bagian 10.


## 7.5 Kesesuaian dengan rujukan

| Rujukan | Pemenang di jurnal | Pemenang eksperimen ini | Sama? |
| --- | --- | --- | --- |
| Fitri (2023), JACOST 4(1) | Random Forest | Random Forest | **Sama** |
| Sari & Prabowo (2025), Intellect 4(1) | XGBoost | Random Forest | Berbeda |
| Hayya’ dkk. (2025), Sainteks 22(1) | Random Forest | Random Forest | **Sama** |

Dua dari tiga sesuai. Perbedaan dengan Sari & Prabowo bisa dijelaskan oleh skala data: 1.642 baris satu wilayah vs 64.228 baris 445 kota. Ini bukan kontradiksi, melainkan bukti bahwa pemenang bergantung pada data — persis alasan mengapa perbandingan ini diulang alih-alih mengutip hasil jurnal.


# 8. Penetapan Model Utama


## 8.1 Keputusan

Berdasarkan Bagian 6 dan 7, **Random Forest ditetapkan sebagai model utama** untuk:

- **Regresi harga** — RandomForestRegressor, target `log10(harga)`.
- **Klasifikasi kategori** — RandomForestClassifier, label Murah/Mahal dari median per kota.

Keputusan ini diambil dengan mempertimbangkan akurasi, galat rupiah, kestabilan lintas lipatan, konsistensi dengan dua dari tiga rujukan, kesesuaian dengan karakter data, dan kemampuan model untuk dijelaskan kepada pengguna — bukan semata R² tertinggi.


## 8.2 Konfigurasi yang dipakai

| Komponen | Nilai |
| --- | --- |
| Algoritma | Random Forest (regresi dan klasifikasi) |
| Jumlah pohon | 100 (bawaan pustaka) untuk perbandingan; 300 untuk konfigurasi produksi |
| Fitur | `luas_m2`, `luas_bangunan`, `jumlah_kamar`, `jumlah_kamar_mandi`, `lokasi` |
| Praproses | Imputasi median + OneHot `lokasi`, dibungkus satu pipeline |
| Target regresi | `log10(harga)`; keluaran dikembalikan dengan `10^prediksi` |
| Target klasifikasi | Murah/Mahal relatif median kota |
| `random_state` | 42 (dapat direproduksi) |


## 8.3 Konsekuensi teknis

- Berkas model regresi berukuran ratusan MB; harus disimpan di server, bukan dikirim ke perangkat.
- Pelatihan ulang memakan waktu menit, sehingga dijadwalkan manual setelah dataset berubah — bukan dijalankan otomatis setiap ada perubahan data.
- Inferensi tetap ringan: ±0,14 ms per prediksi, jauh di bawah kebutuhan aplikasi.
- Tidak ada pustaka tambahan di sisi peladen selain scikit-learn dan joblib, sehingga jalur *deploy* tetap sederhana.


## 8.4 Tindak lanjut pada model produksi

Model yang **sedang melayani** pengguna saat ini dilatih pada 12 November 2026 dengan aturan pembersihan yang lebih longgar daripada eksperimen ini. Metriknya: R² 0,5142, MAE Rp 626.083.067, akurasi klasifikasi 0,8663 pada 12.897 baris uji.

R² 0,5142 itu **tidak bertentangan** dengan 0,8134 pada laporan ini. Penyebabnya berbeda:

| Aspek | Model produksi sekarang | Eksperimen ini |
| --- | --- | --- |
| Baris latih / uji | 51.586 / 12.897 | 51.382 / 12.846 |
| Filter harga placeholder | Tidak ada | 245 baris dibuang |
| Filter fitur mustahil | Tidak ada | Ya |
| Fitur usia bangunan | Dipakai | Dibuang (terbukti tidak menambah) |
| R² log10 | 0,5142 | 0,8134 |

Ablasi pada Bagian 7.4 memperlihatkan bahwa perbedaan besar itu terutama disebabkan baris placeholder yang masih ikut terlatih, bukan oleh pilihan algoritma. **Rekomendasi:** terapkan aturan pembersihan yang sama pada `ml/train.py`, latih ulang model produksi, lalu perbarui angka di halaman dokumentasi web. Sampai itu dilakukan, angka 0,5142 tetap yang berlaku untuk aplikasi.


# 9. Keterbatasan

1. **Tanpa hyperparameter tuning.** Semua model memakai nilai bawaan. Model yang menang di sini belum tentu menang setelah dituning; sebaliknya, model yang kalah mungkin bisa menyusul. Perbandingan ini menjawab “algoritma mana yang paling cocok dengan perlakuan setara”, bukan “seberapa jauh tiap algoritma bisa dipaksa”.
2. **Label klasifikasi tidak sepenuhnya *out-of-sample*.** Ambang Mahal/Murah memakai median harga per kota dari seluruh data bersih, termasuk baris uji, mengikuti `database/seed.py`. Akibatnya akurasi klasifikasi cenderung sedikit optimistis.
3. **Bukan validasi eksternal.** *Hold-out* dan validasi silang memakai data yang sama; tidak ada pengujian pada kota atau periode yang benar-benar baru.
4. **Duplikat tidak dibuang.** 7.144 baris identik dilaporkan tetapi dipertahankan, karena dua rumah bisa memiliki kombinasi fitur dan harga yang sama. Bila baris itu ternyata duplikasi iklan, metrik bisa sedikit terlalu optimistis.
5. **Sebagian wilayah tidak bisa dipilih pengguna.** Sejumlah nama lokasi tidak ada di aset wilayah, sehingga hanya berperan sebagai kategori di data latih.
6. **MAPE besar pada rumah murah.** Nilai MAPE 83,9 % tidak berarti model meleset 84 % pada semua rumah; galat relatif membesar pada harga kecil. Karena itu MAE dan RMSE rupiah dilaporkan berdampingan.
7. **Waktu dan ukuran model bergantung mesin.** Angka waktu adalah perbandingan relatif pada satu mesin, bukan jaminan performa produksi.
8. **Fitur terbatas pada yang tersedia.** Harga properti juga ditentukan akses jalan, sertifikat, sekolah, dan kondisi fisik — tidak ada di dataset. Ini menjelaskan mengapa R² tidak mendekati 1 sekalipun modelnya baik.


# 10. Rekomendasi

| Prioritas | Rekomendasi | Dasar |
| --- | --- | --- |
| Tinggi | Terapkan aturan pembersihan eksperimen pada `ml/train.py`, lalu latih ulang model produksi | Ablasi 7.4: R² naik 0,2330 hanya dari membuang harga placeholder |
| Tinggi | Perbarui angka metrik di halaman dokumentasi web setelah pelatihan ulang | Angka 0,5142 saat ini berasal dari data yang belum bersih |
| Sedang | Pertimbangkan kompresi atau pengurangan jumlah pohon untuk menekan ukuran model | 319 MB tanpa kompresi |
| Sedang | Bila ukuran/memori menjadi kendala nyata, evaluasi XGBoost sebagai pengganti | Selisih akurasi hanya 0,0247 R², tetapi ±970× lebih kecil |
| Sedang | Tambahkan pengujian pada kota yang benar-benar tidak dipakai saat pelatihan | Belum ada validasi eksternal |
| Rendah | Lakukan *tuning* terbatas pada Random Forest sebagai eksperimen terpisah | Semua kandidat saat ini memakai parameter bawaan |
| Rendah | Lengkapi pencatatan lisensi sumber data (Pinhome, ColectDataRumah) | Belum tercatat; relevan untuk kepatuhan |


# 11. Daftar Rujukan

1. Fitri, E. (2023). Analisis Perbandingan Metode Regresi Linier, Random Forest Regression dan Gradient Boosted Trees Regression Method untuk Prediksi Harga Rumah. *Journal of Applied Computer Science and Technology (JACOST)*, 4(1), 58–64. https://doi.org/10.52158/jacost.v4i1.491
2. Sari, B. W., & Prabowo, D. (2025). Analisis Perbandingan Prediksi Harga Rumah Dengan Random Forest, Gradient Boosting, dan XGBoost. *Intellect: Indonesian Journal of Learning and Technological Innovation*, 4(1), 42–51. https://doi.org/10.57255/intellect.v4i1.1385
3. Hayya’, M., Hana, F. M., & Prihandono, A. (2025). Perbandingan Metode K-Nearest Neighbor (KNN) dan Random Forest dalam Memprediksi Harga Rumah. *Sainteks*, 22(1), 99–108. https://doi.org/10.30595/sainteks.v22i1.25998

Rujukan pendukung perangkat lunak:

- Pedregosa, F., et al. (2011). Scikit-learn: Machine Learning in Python. *Journal of Machine Learning Research*, 12, 2825–2830.
- Chen, T., & Guestrin, C. (2016). XGBoost: A Scalable Tree Boosting System. *Proceedings of the 22nd ACM SIGKDD*, 785–794.
- Breiman, L. (2001). Random Forests. *Machine Learning*, 45(1), 5–32.


# 12. Lampiran


## 12.1 Berkas eksperimen

| Berkas | Isi |
| --- | --- |
| `docs/01_persiapan_data.ipynb` | Pemuatan, pembersihan, normalisasi wilayah, split, lipatan, sidik jari |
| `docs/02_perbandingan_regresi.ipynb` | Perbandingan lima algoritma regresi + uji fitur usia |
| `docs/03_perbandingan_klasifikasi.ipynb` | Perbandingan lima algoritma klasifikasi |
| `docs/04_kesimpulan.ipynb` | Verifikasi sidik jari, rekap hasil, penetapan pemenang |
| `docs/perbandingan_output/regression_results_holdout.csv` | Metrik *hold-out* regresi |
| `docs/perbandingan_output/regression_results_cv.csv` | Metrik CV regresi |
| `docs/perbandingan_output/regression_results_cv_folds.csv` | Metrik per lipatan regresi |
| `docs/perbandingan_output/classification_results_holdout.csv` | Metrik *hold-out* klasifikasi |
| `docs/perbandingan_output/classification_results_cv.csv` | Metrik CV klasifikasi |
| `docs/perbandingan_output/classification_results_cv_folds.csv` | Metrik per lipatan klasifikasi |
| `docs/perbandingan_output/age_feature_test.json` | Uji fitur usia bangunan |
| `docs/perbandingan_output/fingerprint.json` | Sidik jari data dan laporan pembersihan |
| `docs/perbandingan_output/split.json`, `folds.json` | Indeks pembagian data dan lipatan |
| `docs/perbandingan_output/regression_summary.json` | Ringkasan regresi |
| `docs/perbandingan_output/classification_summary.json` | Ringkasan klasifikasi |
| `docs/perbandingan_output/kesimpulan.json` | Rekap keputusan akhir |


## 12.2 Cara mereproduksi

```bash
python docs/01_persiapan_data.ipynb        # atau jalankan berurutan di Jupyter/Colab
python docs/02_perbandingan_regresi.ipynb
python docs/03_perbandingan_klasifikasi.ipynb
python docs/04_kesimpulan.ipynb
```

Notebook 04 akan berhenti bila sidik jari data tidak cocok dengan notebook sebelumnya. Jika data berubah, hapus `split.json`, `folds.json`, dan `fingerprint.json`, lalu jalankan ulang dari notebook 01.


## 12.3 Ringkasan angka kunci

| Pertanyaan | Jawaban | Angka |
| --- | --- | --- |
| Algoritma regresi terbaik | Random Forest | R² 0,8134 (*hold-out*) / 0,8153 (CV) |
| Algoritma klasifikasi terbaik | Random Forest | Akurasi 0,8641 / 0,8648 (CV) |
| Galat harga rata-rata | Rp 581,3 juta | MAE *hold-out* |
| Pesaing terdekat | XGBoost | Selisih R² 0,0247; MAE 14,5 % lebih tinggi |
| Algoritma terburuk | Linear Regression | R² 0,4634; MAE Rp 69,96 miliar |
| Fitur usia bangunan | Dibuang | ΔR² 0,0000; MAE naik Rp 1,9 juta |
| Dampak pembersihan data | +0,2330 R² | Ablasi HistGradientBoosting A→B |

*Laporan ini dibangun otomatis dari berkas hasil di `docs/perbandingan_output/` agar angka di dalamnya konsisten dengan eksekusi notebook. Tanggal penyusunan: 20 November 2026.*

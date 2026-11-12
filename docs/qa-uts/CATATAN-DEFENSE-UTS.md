# Catatan Defense UTS PMPL — Kelompok RumahPoint (Peran Auditee)

Pendamping `Test_Scenario_Test_Case_RumahPoint.xlsx` (v4 — sudah "dieksekusi"
Kelompok 4/Esatovin) dan `Template_02_Defense_CAP_RumahPoint.docx` (revisi:
menjawab temuan ASLI Kelompok 4 pada `Kelompok 4_01_QA_Audit_and_Inspection_Report.docx`).

## Hasil eksekusi Siklus 1 (diisi berdasar uji nyata)

- **61 TC**: 30 Pass · 6 Fail · 25 Blocked · 0 Not Run. Pass rate 83,3%; progres 59%.
- **Blocked (25)** = seluruh TC auth (17), sinkronisasi riwayat server (TC-043),
  keamanan JWT/injection (TC-051–056), timeout mock (TC-030) — modul belum rilis.
- **Fail (6)** — defect nyata yang ditemukan saat uji:
  - **BUG-001 (Major, TC-057)**: load test 50 concurrent — 0% error, tetapi
    P95 = 7,25 dtk > target 3 dtk (bottleneck Flask dev server single-process).
  - **BUG-002 (Minor, TC-022/023/024/026/027)**: validasi numerik form memakai
    *clamp senyap* (LT 20–500, kamar 1–10) tanpa pesan error.
- Temuan eksploratori: string pada field numerik `/predict` → HTTP 500.

## Temuan ASLI Kelompok 4 (AUD-01 s.d. AUD-06) + ringkasan jawaban defense

Detail lengkap sudah tertuang di Template_02; ini pegangan lisan saat sesi:

1. **AUD-01 (MAJOR) — Batas input inkonsisten (TC-025: LT=1 ter-clamp ke 20 tapi Pass).**
   - Sikap: **Diterima Penuh.** Jangan berdebat — kontradiksi ini memang nyata.
   - Jawaban kunci: "Kami akui status Pass pada TC-025 tidak tepat; perilaku clamp
     20–500 adalah aturan UI implisit yang belum didokumentasikan. Kami tetapkan
     rentang baku UI vs API + data uji bawah/pada/atas batas + koreksi status TC-025."
2. **AUD-02 (MAJOR) — Prosedur vs pencatatan eksekusi campur (TC-028 Postman vs form, TC-057 skrip vs JMeter).**
   - Sikap: **Diterima Penuh.**
   - Jawaban kunci: "Kami pisahkan TC UI dan TC API; TC-057 dicatat dengan alat aktual
     atau dieksekusi ulang dengan JMeter; metrik TC-058 diperjelas." Untuk TC-029:
     pesan berbeda redaksi tapi setara makna — kriteria kesetaraan akan didefinisikan.
3. **AUD-03 (MAJOR) — 25 TC Blocked; cakupan per build tidak tegas.**
   - Sikap: **Klarifikasi / Diterima Sebagian.**
   - Jawaban kunci (ini satu-satunya yang kita pertahankan): "Blocked — bukan Not Run —
     adalah status yang tepat secara metodologi (IEEE 29119) untuk TC yang dependensinya
     belum tersedia; label 'dalam pengembangan' sudah dicantumkan." Lalu terima sisanya:
     tabel kesiapan fitur per build + risk register + suspension/resumption criteria +
     mock untuk TC-030.
4. **AUD-04 (MAJOR) — RTM ada, tapi baseline kebutuhan resmi tidak dilampirkan.**
   - Sikap: **Klarifikasi / Diterima Sebagian.**
   - Jawaban kunci: "Req ID kami turunan dari RPP/proposal (§4.2/§6); RTM internal sudah
     bebas orphan (terverifikasi programatis). Kami terima melampirkan baseline eksplisit
     + karakteristik mutu per kebutuhan + persentase cakupan."
5. **AUD-05 (MAJOR) — Label Decision Table/State Transition tanpa tabel aturan/matriks.**
   - Sikap: **Diterima Penuh.**
   - Jawaban kunci: "Kami tambahkan lampiran tabel kondisi–aksi untuk token
     (access/refresh × valid/kadaluarsa) dan filter riwayat, matriks transisi sesi,
     plus 1 TC kombinasi filter dengan hasil cocok."
6. **AUD-06 (MAJOR) — Tidak ada register defect terpusat.**
   - Sikap: **Diterima Penuh.**
   - Jawaban kunci: "Kami buat sheet Defect Register (BUG-001, BUG-002) dengan status
     Open/In Progress/Fixed/Retest/Closed, PIC, target, hasil retest; indikator Ringkasan
     dipisah antara jumlah TC gagal dan defect unik terbuka."

## Catatan taktis sesi

- **Sikap dominan "Diterima Penuh" itu aman** — temuan mereka memang kuat dan berbasis
  bukti; menolak justru menurunkan nilai defense. Nilai auditee dinilai dari kesiapan
  menerima masukan + kejelasan CAP.
- Dua temuan yang layak di-klarifikasi (bukan ditolak): AUD-03 & AUD-04 — di situ kita
  punya argumen metodologis yang sah.
- Kalau dosen bertanya "kenapa bisa ada kontradiksi TC-025?": jawab jujur bahwa validasi
  form memakai clamp (rentang slider 20–500) yang belum terdokumentasi sebagai aturan —
  itulah yang ditangkap BUG-002, dan CAP AUD-01 menyelesaikan keduanya sekaligus.
- CAP kita: 6 butir, PIC tersebar ke 4 anggota, tenggat H+3/H+5 — selaras Template_02.

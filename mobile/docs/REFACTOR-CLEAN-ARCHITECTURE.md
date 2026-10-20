# Refactor ke Clean Architecture — Aplikasi Mobile RumahPoint

**Fitur yang direfactor:** Prediction & User
**Tanggal:** Oktober 2026
**Branch:** `rachmad`

---

## 1. Latar Belakang & Masalah Arsitektur Sebelumnya

Sebelum refactor, kode `lib/` diorganisir **per jenis file** (layer-first yang bocor), dan **dependency rule dilanggar** — lapisan presentasi menyentuh langsung detail teknis lapisan data. Akibatnya logika bisnis tidak bisa diuji murni dan sulit dipindah ke backend ber-autentikasi (roadmap PBL).

| Pelanggaran | Lokasi (sebelum) | Dampak |
|---|---|---|
| **Entity merangkap Model** | `models/prediction.dart` | Satu kelas menjadi objek bisnis sekaligus memegang `fromJson`/`toMap`/`fromMap`. Jika respons API berubah, kelas yang dipakai UI ikut berubah. |
| **Controller bergantung ke konkret, bukan abstraksi** | `state/prediction_controller.dart` | `PredictionController` memanggil `new ApiClient()` (Dio) **dan** `SharedPreferences` + `jsonDecode`. Satu kelas punya 3 alasan berubah (melanggar SRP) dan **tidak bisa di-unit-test tanpa jaringan/storage sungguhan**. |
| **Presentation menyentuh data mentah** | `screens/home_screen.dart` | Widget form langsung `SharedPreferences.getInstance()` + `jsonDecode` untuk autosave draft. Logika baca/tulis storage menempel di UI. |
| **Notifier menginstansiasi storage sendiri** | `providers/user_provider.dart` | `UserNotifier` melakukan `new FlutterSecureStorage()` — Dependency Injection bocor, sulit diganti fake untuk testing. |
| **Tidak ada domain layer / interface repository** | — | Tidak ada kontrak; presentation terkunci ke implementasi konkret. |

**Inti masalah:** dependensi mengalir bebas ke segala arah, sehingga logika bisnis tidak dapat diuji murni (testability rendah) dan perubahan sumber data merambat sampai UI.

---

## 2. Solusi: Clean Architecture (Feature-First)

Kode direfactor menjadi **tiga lapisan** dengan **dependency rule yang tegas** — dependensi hanya mengarah ke dalam (presentation → domain ← data).

```
┌───────────────────────────────────────────────────┐
│  PRESENTATION                                      │
│  widget, controller, provider (Dependency Inject.) │
│  lib/screens/  +  features/*/presentation/         │
└──────────────────────┬────────────────────────────┘
                       │ bergantung ke (interface)
                       ▼
┌───────────────────────────────────────────────────┐
│  DOMAIN  — murni Dart, TANPA Flutter/Dio/storage   │
│  entity, repository INTERFACE, use case, failure   │
│  features/*/domain/  +  core/failures.dart         │
└──────────────────────▲────────────────────────────┘
                       │ diimplementasikan oleh
┌──────────────────────┴────────────────────────────┐
│  DATA                                              │
│  model, repository impl, datasource                │
│  features/*/data/  →  Dio, SharedPreferences,      │
│  flutter_secure_storage BERHENTI di lapisan ini    │
└───────────────────────────────────────────────────┘
```

### Struktur folder hasil refactor

```
lib/
├── core/
│   ├── failures.dart      # Failure (sealed) + NetworkFailure + LocalFailure
│   └── format.dart        # formatRupiah/formatTanggal/dll — fungsi murni, testable
│
├── features/
│   ├── prediction/
│   │   ├── domain/
│   │   │   ├── entities/prediction.dart                  (MURNI, tanpa mapping)
│   │   │   ├── repositories/prediction_repository.dart   (INTERFACE)
│   │   │   └── usecases/get_prediction_history.dart
│   │   ├── data/
│   │   │   ├── models/prediction_model.dart              (fromApiJson/toMap)
│   │   │   ├── datasources/prediction_remote_datasource.dart  (Dio → cloud ML)
│   │   │   ├── datasources/prediction_draft_datasource.dart   (SharedPreferences)
│   │   │   └── repositories/prediction_repository_impl.dart
│   │   └── presentation/
│   │       ├── controllers/prediction_controller.dart
│   │       └── providers/prediction_providers.dart       (DI wiring)
│   │
│   └── user/
│       ├── domain/    entities/user.dart, repositories/user_repository.dart
│       ├── data/      models/user_model.dart, repositories/user_repository_impl.dart
│       └── presentation/ providers/user_providers.dart
│
└── screens/               # halaman = presentation pages
```

---

## 3. Perubahan per Konsep

### a) Entity vs Model — dipisahkan
- **`features/prediction/domain/entities/prediction.dart`** — `Prediction` kini **murni**: hanya field + constructor, tanpa `fromJson`/`toMap`, tanpa import apa pun.
- **`features/prediction/data/models/prediction_model.dart`** — `PredictionModel extends Prediction` memegang seluruh mapping: `fromApiJson` (respons cloud ML), `fromMap`/`toMap` (cache lokal). Konversi data → domain hanya di sini.
- Hal yang sama untuk fitur user: `domain/entities/user.dart` (murni) vs `data/models/user_model.dart` (mapping + data dummy sementara).

### b) Repository — interface di domain, implementasi di data
- **Interface `PredictionRepository`** (domain) mendeklarasikan kontrak: `predict()`, `getHistory()`, `saveHistory()`, `clearHistory()`, `loadDraft()`, `saveDraft()`.
- **Implementasi `PredictionRepositoryImpl`** (data) memenuhi kontrak tersebut menggunakan dua datasource: `PredictionRemoteDatasource` (Dio → `POST /predict`) dan `PredictionDraftDatasource` (SharedPreferences).
- Presentation **tidak pernah tahu** Dio/SharedPreferences — hanya berbicara lewat interface.

### c) Use Case — satu operasi bisnis yang dapat diuji murni
- **`GetPredictionHistory`** di domain. Sengaja dibuat **hanya satu**, mengikuti prinsip: CRUD satu-baris boleh langsung repository → notifier; use case dipakai pada titik yang akan menampung aturan bisnis (kelak: sinkron riwayat server + cache offline saat auth JWT aktif).

### d) Failure sebagai nilai, bukan exception yang bocor
- **`core/failures.dart`**: `sealed class Failure` → `NetworkFailure`, `LocalFailure`. Repository mengembalikan record `({T? data, Failure? failure})`, sehingga exception Dio/storage **ditangkap di data layer** dan sampai ke UI hanya berupa `message` yang ramah (mis. "Gagal memprediksi. Pastikan server cloud aktif.").

### e) Dependency Injection terpusat
- **`prediction_providers.dart` / `user_providers.dart`** = satu-satunya tempat `new` implementasi. Controller/Notifier menerima abstraksi lewat constructor; widget hanya `ref.watch`. Tidak ada lagi `new FlutterSecureStorage()` di dalam Notifier.

### f) Presentation disterilkan
- `home_screen.dart`: logika autosave draft (SharedPreferences + jsonDecode) **dipindahkan** ke datasource via repository → widget tinggal memanggil `controller.loadDraft()/saveDraft()`.
- `prediction_controller.dart`: kini hanya mengorkestrasi state — bergantung ke interface, **tanpa** import Dio/SharedPreferences/jsonDecode.

---

## 4. Bukti Verifikasi

1. **`flutter analyze` → 0 error.**
   (Sisa 12 info hanyalah `withOpacity` deprecated pada file profil garapan anggota tim — sudah ada sebelum refactor, di luar cakupan.)
2. **`flutter test` → 9/9 hijau.**
   7 test lama tetap berjalan (perilaku UI identik) **+ 2 test baru** `get_prediction_history_test.dart` yang menguji use case dengan **fake repository** (tanpa Dio/storage sungguhan), membuktikan domain dapat diuji murni.
3. **Grep sterilitas (dependency rule terbukti):**
   - Presentation: `rg "Dio\(|SharedPreferences.getInstance|jsonDecode|FlutterSecureStorage" lib/screens lib/features/*/presentation/controllers` → **nol hasil**.
   - Domain: `rg "import 'package:flutter|package:dio|package:shared_preferences" lib/features/*/domain lib/core` → **nol hasil**.

---

## 5. Manfaat Nyata untuk Proyek

- **Testability** — logika bisnis (use case, repository) dapat diuji tanpa jaringan/storage; ditunjukkan oleh 2 test fake.
- **Siap transisi ke backend JWT** — interface `PredictionRepository`/`UserRepository` adalah titik penggantian. Saat autentikasi & riwayat server aktif, cukup menulis implementasi baru di data layer **tanpa menyentuh UI sama sekali**. Inilah inti *Dependency Inversion*.
- **Single Responsibility** — setiap kelas kini memiliki satu alasan untuk berubah (UI terpisah dari HTTP, storage, dan mapping).

---

## 6. File-file Kunci yang Berubah

| Aksi | File |
|---|---|
| **Baru** | `core/failures.dart`, `features/prediction/domain/*`, `features/prediction/data/*`, `features/prediction/presentation/*`, `features/user/**` |
| **Pindah** | `utils/format.dart` → `core/format.dart` |
| **Disterilkan** | `screens/home_screen.dart`, `state→presentation/controllers/prediction_controller.dart` |
| **Dihapus** | `api/client.dart`, `models/prediction.dart`, `models/user_model.dart`, `state/prediction_controller.dart`, `providers/user_provider.dart`, `utils/` |
| **Test baru** | `test/get_prediction_history_test.dart` |

# REVAMP v4.0 — Analisa Bug & Eksekusi Perbaikan

> Tanggal audit: 25 Agustus 2026
> Status: **SELESAI** — seluruh temuan audit telah diperbaiki (4 High, 8 Medium, 6 Low, pembersihan test rusak, M4)
> Fokus utama: bug sesi stuck di hari terakhir + pembersihan bug data-corruption lainnya.

---

## 1. Latar Belakang

Aplikasi MyRamadhan sudah lama tidak disentuh. Bug utama yang dilaporkan:
**setelah event Ramadhan selesai, sesi tidak otomatis selesai** — UI tetap
menjalankan sesi yang "stuck" di hari terakhir.

Audit menyeluruh dilakukan terhadap layer provider, repository, service,
screen, dan model. Ditemukan **4 bug high-severity** (perusak data),
**8 medium**, dan **6 low-severity**.

---

## 2. Temuan Audit

### 2.1 HIGH severity

| # | Bug | Lokasi | Status |
|---|-----|--------|--------|
| H1 | **XP dobel pada setiap save record harian.** `updateDailyRecord` selalu menghitung XP penuh satu hari lalu `addXp` menambahkannya tanpa mengurangi XP lama. Toggle checklist on-off-on-off = XP dicatat 4x lipat. `stats.totalXp` divergensi dari `SUM(daily_records.xp_earned)`. | `app_state.dart`, `xp_calculator_service.dart` | ✅ |
| H2 | **Streak korup oleh re-save & backfill.** Streak inkremental menghitung jumlah save, bukan jumlah hari; backfill H-2 bisa mereset streak. `recalculateAllStreaks` ada tapi tidak pernah dipanggil; `recalculateStreaksFromDate` stub kosong. | `streak_tracker_service.dart`, `daily_record_repository.dart` | ✅ |
| H3 | **Achievement tidak pernah unlock.** DB menyimpan translation key sebagai title, sedangkan pengecekan membandingkan string Inggris — tidak pernah cocok. 4 dari 8 achievement tidak punya kriteria unlock sama sekali. | `achievement_tracker_service.dart`, `achievement_repository.dart` | ✅ |
| H4 | **Sesi tidak pernah kedaluwarsa (bug utama).** Tidak ada kode yang menonaktifkan sesi saat `endDate` lewat; indikator hari ter-clamp di hari terakhir selamanya; side quest di-generate di luar range sesi; `FinalSummaryScreen` dead code. | `app_state.dart`, `home_screen.dart`, `session_repository.dart` | ✅ |

### 2.2 MEDIUM severity

| # | Bug | Lokasi | Status |
|---|-----|--------|--------|
| M1 | Tap ganda cepat pada side quest memberi XP dua kali (tidak ada guard `completed = 0`). | `side_quest_repository.dart` | ✅ |
| M2 | Input "hari ke-N" saat buat sesi mid-Ramadhan diabaikan total (`currentDayNumber` tidak pernah dipakai). | `session_repository.dart` | ✅ |
| M3 | Tanggal mulai bawa waktu-of-day sehingga penghitung hari telat maju sampai jam yang sama besoknya. | `create_session_dialog.dart`, screens | ✅ |
| M4 | Skeleton full-screen flash + `TextEditingController` dibuat ulang di dalam `build` → state text field hilang tiap toggle checklist. | `home_screen.dart`, `app_state.dart` | ✅ |
| M5 | Callback animasi tidak di-null saat `HomeScreen.dispose()` → risiko overlay/setState after dispose saat pindah tab. | `home_screen.dart` | ✅ |
| M6 | Formula level konflik antara `LevelCalculatorService` dan `StatsRepository.addXp`. | `level_calculator_service.dart` | ✅ |
| M7 | Achievement "Ramadhan Master" mustahil untuk sesi 29 hari (threshold hard-coded 30). | `achievement_tracker_service.dart` | ✅ |
| M8 | Cache sesi 5 menit tidak sadar pergantian hari → edit setelah tengah malam bisa mendarat ke catatan kemarin. | `app_state.dart` | ✅ |

### 2.3 LOW severity

| # | Bug | Status |
|---|-----|--------|
| L1 | Stub kosong `recalculateStreaksFromDate` / API menyesatkan. | ✅ |
| L2 | `FutureBuilder` di `StatsScreen` membuat ulang future tiap build → query DB berulang. | ✅ |
| L3 | RNG pemilihan side quest degenerate (seed mod 10 menentukan semua). | ✅ |
| L4 | Logika `_isPerfectDay` diduplikasi di 3 tempat. | ✅ |
| L5 | `createNewSession` multi-step write non-atomik + panggilan deaktivasi redundan. | ✅ |
| L6 | Edge kasus DST pada aritmetika selisih tanggal. | ✅ |

---

## 3. Keputusan UX (dari user)

Saat sesi terdeteksi sudah melewati `endDate`:

1. **Tampilkan `FinalSummaryScreen` terlebih dahulu** (ringkasan perjalanan Ramadhan).
2. Sesi dinonaktifkan (`is_active = 0`) **setelah user menekan tombol selesai/tutup**.
3. Setelah itu home screen kembali ke layar "buat sesi baru".

---

## 4. Ringkasan Perubahan

### File baru

- `lib/services/date_normalizer.dart` — helper normalisasi tanggal midnight + `daysBetween` aman DST.

### Fase 1 — Sesi Kedaluwarsa + Summary (H4, M3)

- `session_repository.dart` — method baru `completeSession(sessionId)` (set `is_active = 0`, guard sudah-inaktif).
- `app_state.dart` — getter `isSessionExpired`; `loadActiveSession()` skip load/generate data "today" saat sesi kedaluwarsa; method baru `completeActiveSession()`.
- `main.dart` — saat sesi kedaluwarsa, `FinalSummaryScreen` di-push sekali per sesi; sesi dinonaktifkan via tombol selesai ATAU jika route ditutup tanpa finish.
- `final_summary_screen.dart` — parameter `onFinish`; tombol Close menyelesaikan sesi lalu pop; `shouldDisplay()` pakai tanggal ternormalisasi.
- Normalisasi tanggal diterapkan di `create_session_dialog.dart`, `home_screen.dart`, `profile_screen.dart`.

### Fase 2 — Data Corruption (H1, H2, H3, M7)

- **H1:** `updateDailyRecord` menghitung delta XP (`xpBaru − xpLama`) dari record yang sudah ada; hanya delta yang ditambahkan ke stats.
- **H2:** streak dihitung ulang penuh via `recalculateAllStreaks` setiap save; tanggal dinormalisasi untuk deteksi gap.
- **H3+M7:** pencocokan achievement via `iconName`; kriteria baru untuk 4 achievement kosong (`prayer_warrior`: prayer streak ≥ 7, `generous`: sedekah ≥ 15 hari, `night_prayer`: tarawih ≥ 20 hari, `quran_complete`: total tilawah ≥ 604 halaman); threshold "Ramadhan Master" memakai `totalDays` sesi.

### Fase 3 — Medium Quick Wins (M1, M2, M5, M6, M8)

- **M1:** `completeSideQuest` return bool dengan guard `completed = 0`; XP hanya jika transisi sukses.
- **M2:** `currentDayNumber` kini menggeser `startDate` efektif mundur `(N−1)` hari.
- **M5:** callback animasi di-null di `HomeScreen.dispose()` (referensi AppState disimpan dari initState).
- **M6:** `LevelCalculatorService` diselaraskan ke model biaya-per-level (`n²×100`) yang identik dengan `StatsRepository.addXp` — satu formula di seluruh app.
- **M8:** cache sesi menyimpan tanggal cache dan otomatis batal saat hari berganti.

### Fase 4 — Low Severity (L1–L6)

- **L1:** stub `recalculateStreaksFromDate` dihapus dari `daily_record_repository.dart`.
- **L2:** `StatsScreen` dikonversi ke StatefulWidget; future summary & records di-cache per `sessionId` — rebuild tidak lagi menembak query DB berulang.
- **L3:** RNG side quest memakai seed tanggal penuh (`day + month*31 + year*373`) dengan stride bervariasi — deterministik per tanggal tapi tersebar merata di pool quest; tahun berbeda memberi hasil berbeda.
- **L4:** `XpCalculatorService.isPerfectDay` menjadi statis publik = single source of truth; streak service dan AppState mendelegasi ke sana.
- **L5:** panggilan `deactivateAllSessions()` redundan dihapus (`setActiveSession` sudah transaksional); init stats & achievement dilakukan SEBELUM aktivasi.
- **L6:** audit ulang seluruh `.difference().inDays` — semua kini bekerja pada tanggal ternormalisasi midnight atau via `DateNormalizer.daysBetween`.

### Fase 5 — Pembersihan File Test Rusak Bawaan

- **`test/screens/session_comparison_test.dart`** — merge korup (duplikat test ditempel tanpa header, 200+ error analyzer): fragmen korup dibuang, Property 2 diselamatkan, import mati dihapus, tambah `TestWidgetsFlutterBinding.ensureInitialized()` agar `rootBundle` dapat memuat aset l10n. Hasil: **4/4 lulus**.
- **`test/integration/language_switching_test.dart`** — memanggil getter yang tidak pernah ada (`appState.sessionRepository`) sehingga tak pernah bisa compile; ditulis ulang sebagai integrasi level-service tanpa `testWidgets` (persistensi preferensi, switch bolak-balik, simulasi restart, kelengkapan terjemahan en+id, validasi kode bahasa). Hasil: **5/5 lulus**.

### Fase 6 — M4 (Skeleton Flash & Text Field Controller)

- **Skeleton flash:** flag baru `isSaving` untuk mutasi record/quest (persist senyap); `_isLoading` hanya untuk load awal sesi — checklist tidak lagi digantikan skeleton tiap centang.
- **Text field controller:** controller + FocusNode dimiliki `_HomeScreenState` dengan lifecycle init/dispose; sinkronisasi nilai hanya saat field tidak fokus sehingga ketikan tidak hilang saat save lain berjalan.
- Bonus: banyak builder (`_buildDayIndicator` s/d `_buildSedekahInput`) ditemukan sebagai fungsi top-level di luar kelas State (sisa merge rusak) — semuanya dipindah menjadi method State.

---

## 5. Perbaikan Test yang Menyertai

| File | Perubahan |
|------|-----------|
| `level_calculator_service_test.dart` | Ekspektasi disesuaikan ke model kumulatif (`C(L) = Σ i²×100`). |
| `achievement_tracker_service_test.dart` | Match by iconName; + test "Ramadhan Master" untuk sesi 29 hari. |
| `app_state_test.dart` | Sesi test menggunakan tanggal hari ini (tidak kedaluwarsa). |
| `complete_workflows_test.dart` | Pencocokan achievement via iconName. |
| `session_comparison_test.dart` | Direkonstruksi dari merge korup (lihat Fase 5). |
| `language_switching_test.dart` | Ditulis ulang level-service (lihat Fase 5). |

---

## 6. Verifikasi Akhir

- `flutter analyze`: **0 error di seluruh projek** (sebelumnya 200+ error dari dua file test rusak).
- Test lulus (dijalankan individual): session_comparison (4), language_switching (5), app_state (2), navigation (3), offline_functionality (9), profile_screen (4), stats_screen (3), side_quest_repository (5), xp_calculator (15), streak_tracker (12), complete_workflows (6), achievement_tracker, level_calculator (14), session_repository.

### Masalah pre-existing yang tersisa (bukan regresi, terkonfirmasi via baseline `git stash`)

- `language_switching_minimal_test.dart` — 1 widget test gagal (FakeAsync vs I/O nyata); 8 test lainnya lulus dan mencakup fungsionalitas serupa.
- `final_summary_screen_test.dart` Property 27 — timeout >30 detik (property-based test glados yang sangat berat).
- `home_screen_clock_test.dart` — gagal bawaan (ProviderNotFoundException + masalah fake-async yang sama).

---

## 7. Catatan Environment (Windows)

- Menjalankan beberapa file test DB secara paralel kadang memicu `database is locked` (sqflite ffi shared file) — flakiness environment; semua lulus saat dijalankan per file.
- Flutter tooling kadang crash dengan `PathExistsException ... sqlite3.dll (errno 183)` saat proses test lama tertinggal di background — solusi: kill proses dart/flutter tersisa, hapus folder `build\native_assets`, jalankan ulang.

### 7.1 Post-release: `flutter run` gagal setelah penambahan `package_info_plus`

Kronologi masalah saat pertama kali menjalankan aplikasi setelah update v4.0
(penambahan plugin `package_info_plus`), beserta solusinya:

#### a) Gradle gagal download artifact — `No such host is known (dl.google.com)`

```
Could not download intellij-core-31.11.1.jar ...
> No such host is known (dl.google.com)
```

- **Penyebab:** Gradle daemon lama meng-cached kegagalan DNS, sehingga tetap
  gagal resolve meskipun internet/di browser normal.
- **Solusi:** stop Gradle daemon + bersihkan cache:
  ```bash
  cd android && gradlew.bat --stop
  flutter clean
  flutter pub get
  ```

#### b) Cache Kotlin korup — `different roots: C:\...Pub\Cache... dan D:\...android`

```
IllegalArgumentException: this and base files have different roots:
C:\Users\...\Pub\Cache\...\PackageInfoPlugin.kt and D:\...\android
```

- **Penyebab:** bug incremental compilation Kotlin di Windows saat source
  plugin (drive `C:`) berada di drive berbeda dari project (drive `D:`).
  Muncul sebagai suppressed exception di log build.
- **Solusi:** ikut teratasi oleh pembersihan folder `build\` pada langkah (a).
  Jika muncul lagi padahal jaringan normal, tambahkan di
  `android/gradle.properties`:
  ```properties
  kotlin.incremental=false
  ```

#### c) `Building with plugins requires symlink support`

```
Building with plugins requires symlink support.
Please enable Developer Mode in your system settings.
```

- **Penyebab:** plugin Windows (`package_info_plus`) membutuhkan symbolic
  link saat build, dan Windows hanya mengizinkan pembuatan symlink ketika
  **Developer Mode** aktif.
- **Solusi (sekali saja untuk selamanya):**
  ```bash
  start ms-settings:developers
  ```
  lalu aktifkan toggle **Developer Mode**.

> Setelah ketiga langkah di atas, `flutter run` berjalan lancar ke device
> fisik (NE2211). Catatan: error (c) juga sempat muncul saat `flutter pub add`
> — aktivasi Developer Mode menutup keduanya sekaligus.

---

## 8. Status Akhir

| Fase | Cakupan | Status |
|------|---------|--------|
| Fase 1 | Sesi kedaluwarsa + summary (H4, M3) | ✅ Selesai |
| Fase 2 | Data corruption (H1, H2, H3, M7) | ✅ Selesai |
| Fase 3 | Medium quick wins (M1, M2, M5, M6, M8) | ✅ Selesai |
| Fase 4 | Low severity (L1–L6) | ✅ Selesai |
| Fase 5 | Pembersihan file test rusak | ✅ Selesai |
| Fase 6 | M4 (skeleton flash + text field controller) | ✅ Selesai |

**Seluruh temuan audit REVAMP v4.0 telah diperbaiki. Tidak ada sisa item.**

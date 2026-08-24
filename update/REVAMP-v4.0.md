# REVAMP v4.0 — Hasil Analisa Bug & Rencana Eksekusi

> Tanggal audit: 25 Agustus 2026
> Status: Rencana disetujui (Fase 1–3 lengkap, low-severity ditunda)
> Fokus utama: perbaikan bug sesi yang stuck di hari terakhir + pembersihan bug data-corruption lainnya.

---

## 1. Latar Belakang

Aplikasi MyRamadhan sudah lama tidak disentuh. Bug utama yang dilaporkan:
**setelah event Ramadhan selesai, sesi tidak otomatis selesai** — UI tetap
menjalankan sesi yang "stuck" di hari terakhir.

Audit menyeluruh dilakukan terhadap layer provider, repository, service,
screen, dan model. Ditemukan **4 bug high-severity** (perusak data),
**8 medium**, dan beberapa low-severity.

---

## 2. Temuan Audit

### 2.1 HIGH severity

| # | Bug | Lokasi |
|---|-----|--------|
| H1 | **XP dobel pada setiap save record harian.** `updateDailyRecord` selalu menghitung XP penuh satu hari (`calculateTotalDailyXp`) lalu `addXp` menambahkannya tanpa mengurangi XP lama. Toggle checklist on-off-on-off = XP dicatat 4x lipat. `stats.totalXp` divergensi dari `SUM(daily_records.xp_earned)`. | `lib/providers/app_state.dart:294–329` |
| H2 | **Streak korup oleh re-save & backfill.** `updateStreaksForNewRecord` dijalankan di setiap save hari yang sama (streak menghitung jumlah save, bukan jumlah hari). Backfill H-2 diperlakukan sebagai hari terbaru sehingga bisa mereset streak. Fungsi `recalculateAllStreaks` tersedia tapi tidak pernah dipanggil; `recalculateStreaksFromDate` stub kosong. | `lib/services/streak_tracker_service.dart:56–136`, `lib/repositories/daily_record_repository.dart:134` |
| H3 | **Achievement tidak pernah unlock.** `initializeAchievements` menyimpan translation key sebagai title (`'achievements.first_day.title'`), sedangkan `checkAndUnlockAchievements` membandingkan dengan string Inggris (`'First Day Completed'`, dst.) — tidak pernah cocok. Selain itu 4 dari 8 achievement (`prayer_warrior`, `generous`, `night_prayer`, `quran_complete`) tidak punya kriteria unlock sama sekali. | `lib/services/achievement_tracker_service.dart:33–41`, `lib/repositories/achievement_repository.dart:55–112` |
| H4 | **Sesi tidak pernah kedaluwarsa (bug utama).** Tidak ada kode yang menonaktifkan sesi saat `endDate` lewat. `getActiveSession()` hanya cek `is_active = 1`. Home screen melakukan `daysSinceStart.clamp(1, totalDays)` sehingga indikator hari terpaku di hari terakhir selamanya. Side quest tetap di-generate di luar range sesi. `FinalSummaryScreen.shouldDisplay()` adalah dead code — tidak pernah dipanggil dari mana pun. | `lib/providers/app_state.dart:123–201`, `lib/screens/home_screen.dart:185` |

### 2.2 MEDIUM severity

| # | Bug | Lokasi |
|---|-----|--------|
| M1 | Tap ganda cepat pada side quest memberi XP dua kali (tidak ada guard `completed = 0`). | `app_state.dart:385–428`, `side_quest_repository.dart:39–48` |
| M2 | Input "hari ke-N" saat buat sesi mid-Ramadhan diabaikan total — `currentDayNumber` diterima parameter tapi tidak pernah dipakai. | `session_repository.dart:27–73` |
| M3 | Tanggal mulai bawa waktu-of-day (`DateTime.now()`), sehingga penghitung hari telat maju sampai jam yang sama besoknya. Semua `daysSinceStart` harus pakai tanggal ternormalisasi midnight. | `create_session_dialog.dart:19`, `home_screen.dart:184`, `profile_screen.dart:96` |
| M4 | Skeleton full-screen flash + `TextEditingController` dibuat ulang di dalam `build` → state text field hilang tiap toggle checklist. | `home_screen.dart:113–115, 559–561, 622–624` |
| M5 | Callback animasi (`onXpGained`/`onLevelUp`) tidak di-null saat `HomeScreen.dispose()` → risiko overlay/setState after dispose saat pindah tab. | `home_screen.dart:30–48` |
| M6 | Formula level konflik: `LevelCalculatorService` (dead code) memakai model kumulatif, sedangkan `StatsRepository.addXp` + screens memakai model biaya-per-level. | `level_calculator_service.dart:19–36`, `stats_repository.dart:93–103` |
| M7 | Achievement "Ramadhan Master" mustahil untuk sesi 29 hari (threshold hard-coded 30). | `achievement_tracker_service.dart:74–77` |
| M8 | Cache sesi 5 menit tidak sadar pergantian hari → edit setelah tengah malam bisa mendarat ke catatan kemarin. | `app_state.dart:48–51, 123–132` |

### 2.3 LOW severity (ditunda)

- L1: Stub kosong `recalculateStreaksFromDate` / API menyesatkan.
- L2: `FutureBuilder` di `StatsScreen` membuat ulang future tiap build → query DB berulang.
- L3: RNG pemilihan side quest degenerate (seed mod 10 menentukan semua).
- L4: Logika `_isPerfectDay` diduplikasi di 3 tempat.
- L5: `createNewSession` multi-step write non-atomik.
- L6: Edge kasus DST pada aritmetika selisih tanggal.

---

## 3. Keputusan UX (dari user)

Saat sesi terdeteksi sudah melewati `endDate`:
1. **Tampilkan `FinalSummaryScreen` terlebih dahulu** (ringkasan perjalanan Ramadhan).
2. Sesi baru dinonaktifkan (`is_active = 0`) **setelah user menekan tombol selesai/tutup**.
3. Setelah itu home screen kembali ke layar "buat sesi baru".

---

## 4. Rencana Eksekusi

### Fase 1 — Sesi Kedaluwarsa + Summary (H4, M3)

1. `session_repository.dart`: tambah method `completeSession(int sessionId)` → set `is_active = 0` untuk sesi tersebut saja.
2. Normalisasi tanggal: helper midnight-normalize dipakai konsisten di `create_session_dialog.dart`, `home_screen.dart`, `profile_screen.dart`, `final_summary_screen.dart`.
3. `app_state.dart`:
   - Getter baru `bool get isSessionExpired` (today ternormalisasi > endDate).
   - `loadActiveSession()`: skip generate side quest jika sesi kedaluwarsa.
4. UI: saat `isSessionExpired == true`, tampilkan `FinalSummaryScreen` (dipicu sekali, bukan tiap build). Tombol tutup/selesai → `completeSession()` → invalidate cache → reload.
5. Selaraskan `FinalSummaryScreen.shouldDisplay()` dengan tanggal ternormalisasi.

### Fase 2 — Perbaikan Data Corruption (H1, H2, H3, M7)

6. **H1:** fetch record lama via `getRecordByDate`, hitung `delta = xpBaru − xpLama`, hanya `addXp(delta)`.
7. **H2:** ganti update streak inkremental dengan `recalculateAllStreaks(sessionId, allRecords)`; hapus stub kosong.
8. **H3:** match achievement via `iconName` (stabil, tidak terlokalisasi); tambah kriteria unlock untuk 4 achievement kosong; threshold "Ramadhan Master" pakai `totalDays` sesi (M7 ikut beres).

### Fase 3 — Medium Quick Wins (M1, M2, M5, M6, M8)

9. **M1:** guard `AND completed = 0` pada update side quest; XP hanya jika rows affected > 0.
10. **M2:** hormati `currentDayNumber` — geser `startDate` efektif mundur `(currentDayNumber − 1)` hari.
11. **M5:** null-in callback animasi di `HomeScreen.dispose()` + guard `mounted`.
12. **M6:** hapus `LevelCalculatorService` (konflik & dead code); formula level tetap model `StatsRepository`.
13. **M8:** simpan tanggal pada cache key; invalidasi otomatis saat hari berganti.

*(M4 — skeleton flash & text field controller — sengaja ditunda karena touch UI besar.)*

### Verifikasi

- Update/tambah unit test:
  - `test/repositories/session_repository_test.dart` — skenario kedaluwarsa & completeSession.
  - `test/providers/app_state_test.dart` — delta XP, recalc streak, expired session.
  - `test/services/achievement_tracker_service_test.dart` — unlock by iconName, sesi 29 hari.
  - `test/repositories/side_quest_repository_test.dart` — guard double-complete.
- Jalankan `flutter analyze` dan `flutter test` hingga bersih di akhir tiap fase.

---

## 5. Progress Log

| Fase | Status |
|------|--------|
| Fase 1 — Sesi kedaluwarsa + summary | ✅ Selesai |
| Fase 2 — Data corruption (XP/streak/achievement) | ✅ Selesai |
| Fase 3 — Medium quick wins | ✅ Selesai |

---

## 6. Ringkasan Perubahan (Eksekusi)

### File baru
- `lib/services/date_normalizer.dart` — helper normalisasi tanggal midnight + `daysBetween` aman DST.

### Fase 1
- `session_repository.dart` — method baru `completeSession(sessionId)` (set `is_active = 0`, guard sudah-inaktif).
- `app_state.dart` — getter `isSessionExpired`; `loadActiveSession()` skip load/generate data "today" saat sesi kedaluwarsa; method baru `completeActiveSession()`.
- `main.dart` — saat sesi kedaluwarsa, `FinalSummaryScreen` di-push sekali per sesi; sesi dinonaktifkan via tombol selesai ATAU jika route ditutup tanpa finish.
- `final_summary_screen.dart` — parameter `onFinish`; tombol Close menyelesaikan sesi lalu pop; `shouldDisplay()` pakai tanggal ternormalisasi.
- Normalisasi tanggal diterapkan di `create_session_dialog.dart`, `home_screen.dart`, `profile_screen.dart`.

### Fase 2
- **H1:** `updateDailyRecord` menghitung delta XP (`xpBaru − xpLama`) dari record yang sudah ada; hanya delta yang ditambahkan ke stats.
- **H2:** streak sekarang dihitung ulang penuh via `recalculateAllStreaks` setiap save; tanggal dinormalisasi untuk deteksi gap.
- **H3+M7:** pencocokan achievement via `iconName`; kriteria baru untuk 4 achievement kosong (`prayer_warrior`: prayer streak ≥ 7, `generous`: sedekah ≥ 15 hari, `night_prayer`: tarawih ≥ 20 hari, `quran_complete`: total tilawah ≥ 604 halaman); threshold "Ramadhan Master" memakai `totalDays` sesi.

### Fase 3
- **M1:** `completeSideQuest` return bool dengan guard `completed = 0`; XP hanya jika transisi sukses.
- **M5:** callback animasi di-null di `HomeScreen.dispose()` (referensi AppState disimpan dari initState).
- **M8:** cache sesi kini menyimpan tanggal cache dan otomatis batal saat hari berganti.
- **M2:** `currentDayNumber` kini menggeser `startDate` efektif mundur `(N−1)` hari.
- **M6:** `LevelCalculatorService` diselaraskan ke model biaya-per-level (`n²×100`) yang identik dengan `StatsRepository.addXp` — satu formula di seluruh app.

### Verifikasi
- `flutter analyze`: **0 error di `lib/`** (sisa warning/info pre-existing).
- Test lulus (dijalankan individual): level_calculator (14), achievement_tracker, app_state, session_repository, side_quest_repository, streak_tracker, complete_workflows (6/6), offline_functionality (9), navigation (3).
- Kegagalan yang tersisa di suite terkonfirmasi **pre-existing** lewat baseline `git stash`:
  - `session_comparison_test.dart` & `language_switching_test.dart` — rusak bawaan (syntax/API mismatch).
  - `final_summary_screen_test.dart` Property 27 — timeout >30s (test glados berat).
  - `home_screen_clock_test.dart` — ProviderNotFoundException bawaan.
- Perbaikan test yang menyertai: `level_calculator_service_test.dart` (ekspektasi model kumulatif), `achievement_tracker_service_test.dart` (+ test 29 hari), `app_state_test.dart` (sesi tidak kedaluwarsa), `complete_workflows_test.dart` (iconName).

### Sisa pekerjaan (belum dikerjakan)
- M4 (skeleton flash + text field controller) — ditunda, touch UI besar.
- Low severity L1–L6.
- Membersihkan 2 file test rusak bawaan (`session_comparison_test.dart`, `language_switching_test.dart`).

# MyRamadhan 🌙

Aplikasi pendamping Ramadhan yang gamified untuk membantu Anda melacak perjalanan spiritual melalui sistem XP, streak, pencapaian, dan pelacakan multi-tahun.

## Gambaran Umum

MyRamadhan mengubah pengalaman Ramadhan Anda menjadi perjalanan pertumbuhan pribadi yang menarik. Lacak ibadah harian Anda, bangun konsistensi melalui streak, dapatkan XP dan naik level, buka pencapaian, dan renungkan kemajuan spiritual Anda—semuanya sambil menjaga privasi lengkap dengan arsitektur offline-first.

## Fitur

### 🎯 Pelacakan Inti

- **Checklist Ibadah Harian**: Lacak 5 sholat wajib, puasa, tarawih, tilawah Al-Qur'an, dzikir, dan sedekah
- **Sistem XP**: Dapatkan poin pengalaman untuk setiap aktivitas yang diselesaikan
- **Progresi Level**: Naik level berdasarkan XP yang terkumpul (rumus: level² × 100)
- **Bonus Hari Sempurna**: Tambahan 50 XP ketika semua objektif utama diselesaikan

### 🔥 Gamifikasi

- **Pelacakan Streak**: Pantau hari berturut-turut penyelesaian sempurna, sholat, dan bacaan Al-Qur'an
- **Pencapaian**: Buka milestone seperti "Hari Pertama Selesai", "Konsistensi 7 Hari", "100 Halaman Al-Qur'an", dan "Master Ramadhan"
- **Side Quest**: Selesaikan tantangan harian opsional untuk bonus XP
- **Sesi Multi-Tahun**: Lacak dan bandingkan kemajuan Anda di berbagai tahun Ramadhan

### 📊 Statistik & Wawasan

- **Dashboard Kemajuan**: Lihat total XP, level saat ini, streak aktif, dan persentase konsistensi
- **Kalender Riwayat Harian**: Gambaran visual status penyelesaian Anda sepanjang bulan
- **Perbandingan Sesi**: Bandingkan metrik kinerja di berbagai tahun Ramadhan
- **Ringkasan Akhir**: Laporan komprehensif akhir Ramadhan dengan pencapaian dan metrik pertumbuhan

### 🌐 Lokalisasi

- **Dukungan Bilingual**: Beralih antara Bahasa Inggris dan Bahasa Indonesia
- **Preferensi Persisten**: Pilihan bahasa disimpan secara lokal

### 🔒 Privasi & Offline

- **100% Offline**: Semua data disimpan secara lokal menggunakan SQLite—tidak perlu internet
- **Privasi Lengkap**: Perjalanan spiritual Anda tetap di perangkat Anda
- **Andal**: Bekerja di mana saja, kapan saja, tanpa konektivitas

## Stack Teknologi

- **Framework**: Flutter 3.38.5
- **Bahasa**: Dart 3.10.4
- **Database**: SQLite (sqflite)
- **State Management**: Provider
- **Testing**: Flutter Test + Glados (property-based testing)

## Arsitektur

Aplikasi mengikuti pola arsitektur bersih dengan pemisahan tanggung jawab yang jelas:

```
Presentation Layer (Widgets & Screens)
         ↓
State Management (Provider)
         ↓
Business Logic (Services)
         ↓
Data Access (Repositories)
         ↓
Persistence (SQLite Database)
```

### Komponen Utama

- **Models**: Kelas data immutable (RamadhanSession, DailyRecord, UserStats, Achievement, SideQuest)
- **Repositories**: Abstraksi akses data dengan operasi CRUD
- **Services**: Logika bisnis (kalkulasi XP, pelacakan streak, pembukaan pencapaian, kalkulasi level)
- **Providers**: State management reaktif untuk pembaruan UI
- **Screens**: Home, Stats, Achievements, Profile, History, Comparison, Final Summary

## Memulai

### Prasyarat

- Flutter SDK 3.10.4 atau lebih tinggi
- Dart SDK 3.10.4 atau lebih tinggi
- Android Studio / VS Code dengan ekstensi Flutter
- iOS development tools (untuk build iOS)

### Instalasi

1. Clone repository:

```bash
git clone https://github.com/kalyzet/MyRamadhan.git
cd my_ramadhan
```

2. Install dependencies:

```bash
flutter pub get
```

3. Jalankan aplikasi:

```bash
flutter run
```

### Build untuk Produksi

**Android:**

```bash
flutter build apk --release
```

**iOS:**

```bash
flutter build ios --release
```

**Web:**

```bash
flutter build web --release
```

## Testing

Proyek ini mencakup cakupan tes yang komprehensif:

### Jalankan Semua Tes

```bash
flutter test
```

### Jalankan Tes dengan Coverage

```bash
flutter test --coverage
```

### Kategori Tes

- **Unit Tests**: Logika service, kalkulasi XP, pelacakan streak, model data
- **Property-Based Tests**: Properti universal diverifikasi di berbagai input acak (menggunakan Glados)
- **Widget Tests**: Rendering dan interaksi komponen UI
- **Integration Tests**: Alur kerja pengguna lengkap dan persistensi data
- **Repository Tests**: Operasi database dan integritas data

### Target Coverage

- Layer Service & Repository: >80%
- Semua 39 properti kebenaran: 100% diimplementasikan
- Alur kerja pengguna utama: 100% tercakup

## Struktur Proyek

```
lib/
├── database/           # SQLite database helper
├── exceptions/         # Kelas exception kustom
├── l10n/              # File lokalisasi (en.json, id.json)
├── models/            # Model data
├── providers/         # State management
├── repositories/      # Layer akses data
├── screens/           # Layar UI
├── services/          # Logika bisnis
└── widgets/           # Komponen UI yang dapat digunakan kembali

test/
├── animations/        # Tes performa animasi
├── database/          # Tes database
├── integration/       # Tes alur kerja end-to-end
├── models/            # Tes model
├── navigation/        # Tes navigasi
├── offline/           # Tes fungsionalitas offline
├── providers/         # Tes state management
├── repositories/      # Tes repository
├── screens/           # Tes widget layar
├── services/          # Tes unit service
└── widgets/           # Tes komponen widget
```

## Panduan Penggunaan

### Membuat Sesi Pertama Anda

1. Buka aplikasi dan ketuk "Buat Sesi Baru"
2. Pilih tahun Ramadhan dan tanggal mulai
3. Pilih durasi (29 atau 30 hari)
4. Opsional: tentukan hari saat ini jika bergabung di tengah Ramadhan

### Pelacakan Harian

1. Navigasi ke layar Home
2. Centang aktivitas yang telah diselesaikan:
    - 5 sholat wajib (10 XP masing-masing)
    - Puasa (50 XP)
    - Tarawih (30 XP)
    - Halaman Al-Qur'an (2 XP per halaman)
    - Dzikir (20 XP)
    - Sedekah (30 XP)
3. Selesaikan semua objektif untuk bonus Hari Sempurna (+50 XP)
4. Lihat Side Quest opsional untuk bonus XP

### Melihat Kemajuan

- **Layar Stats**: Lihat level, XP, streak, dan konsistensi Anda
- **Layar Achievements**: Lacak pencapaian yang terbuka dan terkunci
- **Layar Profile**: Lihat riwayat sesi dan ubah bahasa
- **Layar History**: Jelajahi sesi Ramadhan sebelumnya
- **Layar Comparison**: Bandingkan metrik di berbagai tahun

### Backdating Records

Anda dapat memodifikasi catatan dari 2 hari sebelumnya (H-1 dan H-2) jika Anda lupa mencatat aktivitas. Sistem akan secara otomatis menghitung ulang streak yang terpengaruh.

## Sistem XP & Leveling

### Perolehan XP

- Setiap Sholat Fardhu: 10 XP
- Puasa: 50 XP
- Tarawih: 30 XP
- Tilawah Al-Qur'an: 2 XP per halaman
- Dzikir: 20 XP
- Sedekah: 30 XP
- Bonus Hari Sempurna: 50 XP

### Kalkulasi Level

XP yang diperlukan untuk level n = n² × 100

Contoh:

- Level 2: 400 XP
- Level 5: 2,500 XP
- Level 10: 10,000 XP

## Pencapaian

- **Hari Pertama Selesai**: Selesaikan hari pertama Anda
- **Konsistensi 7 Hari**: Pertahankan streak sempurna 7 hari
- **100 Halaman Al-Qur'an**: Baca 100 halaman Al-Qur'an
- **Master Ramadhan**: Selesaikan semua 30 hari dengan catatan sempurna
- Dan banyak lagi...

## Filosofi Desain

MyRamadhan menganut **estetika spiritual yang tenang**:

- Tema dominan dark mode dengan aksen zamrud dan emas
- Prinsip desain Islam minimal
- Animasi halus 60 FPS
- Tata letak bersih dan tidak berantakan
- Hierarki visual yang meningkatkan fokus

## Kontribusi

Kontribusi sangat diterima! Silakan ikuti panduan berikut:

1. Fork repository
2. Buat branch fitur (`git checkout -b feature/fitur-keren`)
3. Tulis tes untuk fungsionalitas baru
4. Pastikan semua tes lulus (`flutter test`)
5. Commit perubahan Anda (`git commit -m 'Tambah fitur keren'`)
6. Push ke branch (`git push origin feature/fitur-keren`)
7. Buka Pull Request

## Kredit

**Dibuat oleh Kalyzet Team** 🎨

MyRamadhan dikembangkan dengan penuh cinta dan dedikasi oleh Kalyzet Team untuk membantu umat Muslim di seluruh dunia meningkatkan pengalaman Ramadhan mereka melalui teknologi.

## Lisensi

Proyek ini dilisensikan di bawah MIT License - lihat file LICENSE untuk detailnya.

## Dukungan

Untuk pertanyaan, masalah, atau permintaan fitur, silakan buka issue di GitHub.

---

**Semoga Ramadhan Anda diberkahi dan produktif! 🌙✨**

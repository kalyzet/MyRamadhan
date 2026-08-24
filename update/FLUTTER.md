# Menjalankan Aplikasi Flutter di BlueStacks

Panduan menghubungkan Flutter ke BlueStacks App Player (Android 11) melalui
ADB, mulai dari aktivasi, koneksi, hingga berbagai cara menjalankan aplikasi.

---

## Daftar Isi

1. [Aktifkan ADB di BlueStacks](#1-aktifkan-adb-di-bluestacks)
2. [Hubungkan ADB](#2-hubungkan-adb)
3. [Verifikasi dari Flutter](#3-verifikasi-dari-flutter)
4. [Cara Menjalankan Aplikasi](#4-cara-menjalankan-aplikasi)
5. [Troubleshooting](#5-troubleshooting)

---

## 1. Aktifkan ADB di BlueStacks

1. Buka **Settings** di BlueStacks.
2. Masuk ke menu **Advanced**.
3. Aktifkan **Android Debug Bridge (ADB)**.
4. Catat port ADB yang ditampilkan — biasanya `5555`, tapi bisa berbeda
   tergantung versi BlueStacks.

## 2. Hubungkan ADB

Jalankan di terminal/CMD:

```bash
adb connect 127.0.0.1:5555
```

Jika berhasil, output-nya:

```text
connected to 127.0.0.1:5555
```

Lalu verifikasi koneksi:

```bash
adb devices
```

Device harus muncul dalam daftar:

```text
List of devices attached
127.0.0.1:5555    device
```

> **Catatan:** Ganti `5555` dengan port yang tertera di Settings BlueStacks
> jika berbeda.

## 3. Verifikasi dari Flutter

Dari folder project Flutter:

```bash
flutter devices
```

Jika BlueStacks terdeteksi, akan muncul sebagai Android device.

## 4. Cara Menjalankan Aplikasi

### 4.1 `flutter run` — develop dengan hot reload

Cara paling umum untuk development:

```bash
flutter run
```

Atau langsung pilih device-nya:

```bash
flutter run -d 127.0.0.1:5555
```

### 4.2 `flutter install` — build + install APK

Build lalu install APK ke device yang terhubung:

```bash
flutter install -d 127.0.0.1:5555
```

Setelah ter-install, aplikasi bisa dibuka langsung dari BlueStacks.

### 4.3 `flutter build apk` + `adb install` — build APK manual

Untuk membuat APK saja:

```bash
flutter build apk --debug
```

APK tersimpan di:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Kemudian install ke BlueStacks:

```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

Jika ada beberapa device terhubung, tentukan target secara eksplisit:

```bash
adb -s 127.0.0.1:5555 install build/app/outputs/flutter-apk/app-debug.apk
```

### 4.4 `flutter attach` — menyambung ke proses yang sudah jalan

Jika aplikasi **sudah berjalan** di BlueStacks dan ingin Flutter tersambung
ke proses tersebut:

```bash
flutter attach
```

Berguna untuk hot reload/debugging tanpa menjalankan ulang dari awal.

### 4.5 Dari IDE (Android Studio / VS Code)

- Pilih **BlueStacks** sebagai Android device di device selector.
- Klik **Run ▶** di Android Studio, atau tekan **F5** di VS Code untuk debug.

### Rekomendasi cepat

Jika tujuannya hanya *install dan buka aplikasi tanpa `flutter run`*,
kombinasi paling simpel:

```bash
flutter build apk --debug
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## 5. Troubleshooting

### `adb connect` gagal

Coba restart ADB server lalu sambungkan ulang:

```bash
adb kill-server
adb start-server
adb connect 127.0.0.1:5555
```

Pastikan juga port yang dipakai sesuai dengan yang tertera di Settings
BlueStacks.

### `'adb' is not recognized` (Windows)

Perintah `adb` tidak dikenali karena folder Android SDK `platform-tools`
belum ada di PATH. Dua solusi:

1. **Tambahkan ke PATH** — biasanya lokasinya:
   ```text
   %LOCALAPPDATA%\Android\Sdk\platform-tools
   ```
2. Atau jalankan ADB langsung dari folder tersebut:
   ```bash
   %LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe connect 127.0.0.1:5555
   ```

### BlueStacks tidak muncul di `flutter devices`

- Pastikan `adb devices` menampilkan status `device` (bukan `offline`).
- Jalankan ulang `flutter devices` setelah koneksi ADB berhasil.
- Coba matikan dan nyalakan lagi ADB di Settings BlueStacks.

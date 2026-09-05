# StoreCheckerVal

Aplikasi mobile Android berbasis Flutter untuk memantau rotasi skin harian Valorant (Daily Store), saldo VP/RP, banner kartu pemain (Player Card), dan wishlist skin tanpa perlu membuka PC.

---

## Fitur Utama

- **Daily Store & Countdown**: Memantau 4 penawaran skin harian dan hitung mundur reset toko secara real-time.
- **In-Game Profile & Banner**: Menampilkan nama akun (GameName#TagLine), kartu pemain (Banner & Avatar) in-game, level akun, serta progres XP.
- **Wallet Tracker**: Memantau saldo Valorant Points (VP), Radianite Points (RP), dan Kingdom Credits (KC).
- **Featured Bundle & Night Market**: Preview koleksi bundle aktif serta penawaran diskon Night Market.
- **Wishlist**: Menyimpan skin favorit dan memberikan notifikasi saat skin tersedia di toko harian.
- **Direct Riot Web Login**: Autentikasi aman melalui WebView resmi Riot Games (OAuth), mendukung verifikasi 2FA dan Riot Mobile.

---

## Download & Instalasi

File instalasi APK Android:
- Path file: `build/app/outputs/flutter-apk/app-release.apk`
- Unduh versi rilis terbaru melalui menu Releases di repositori GitHub ini.

---

## Tech Stack

- **Framework**: Flutter (Dart 3)
- **State Management**: flutter_bloc
- **Network & API**: Dio (Live Riot Games PDP API & Valorant-API.com)
- **Storage**: flutter_secure_storage & Hive
- **Navigation**: go_router

---

## Menjalankan Project

```bash
# Clone repository
git clone https://github.com/Fantsry/store-checkerval.git
cd store-checkerval

# Install dependencies
flutter pub get

# Menjalankan aplikasi (Development)
flutter run

# Build APK Release
flutter build apk --release
```

---

## Disclaimer

Aplikasi ini merupakan proyek pihak ketiga yang tidak berafiliasi dengan atau didukung oleh Riot Games, Inc. Valorant dan seluruh aset terkait merupakan merek dagang dari Riot Games, Inc.

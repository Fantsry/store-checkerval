# StoreCheckerVal

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Style](https://img.shields.io/badge/Style-Ascend_Companion_Esports_HUD-FF2FB0)](https://github.com/Fantsry/store-checkerval)

**StoreCheckerVal** adalah aplikasi mobile Android berbasis Flutter yang dirancang untuk memantau rotasi skin harian Valorant (Daily Store), status pertandingan langsung (Live Match), riwayat karier kompetitif (Career & Rank), valuasi akun (Inventory Valuation), serta progres Battlepass langsung dari smartphone tanpa perlu membuka PC.

Aplikasi ini mengusung antarmuka **Ascend Companion Dark Esports HUD Overlay** dengan palet gelap siaran turnamen, tipografi Rajdhani, sudut tajam presisi (4px-8px), dan aksen neon magenta yang modern.

---

## Fitur Utama

### 1. Daily Store & Night Market
- **Rotasi Toko Harian**: Memantau 4 penawaran skin harian dan hitung mundur reset toko secara real-time.
- **Featured Bundle**: Preview bundle skin yang sedang aktif beserta harga dan durasi penawaran.
- **Night Market**: Tampilan kartu penawaran diskon Night Market dengan efek interaktif.
- **Accessory Store**: Memantau rotasi Gunbuddy, Player Card, Spray, dan Title menggunakan Kingdom Credits (KC).
- **Detail Skin Interaktif**: Switcher level chroma/tingkat upgrade dan pratinjau audio/video skin.

### 2. Live Match Tracker (Esports HUD)
- **Status Pertandingan Real-Time**: Mendeteksi status pertandingan aktif (Pregame / In-Game / Postgame).
- **Esports Player Card**: Rincian performa pemain di lobi: ACS, K/D, KAST, KDA, ADR, HS%, dan WIN%.
- **Custom Diamond Rank Icon**: Ikon pangkat berbentuk permata kustom dengan efek glow dinamis.
- **Live Match Scoreboard**: Skor ronde, status sisi menyerang/bertahan (Attacker/Defender), dan peta yang dimainkan.

### 3. Career & Rank Progression
- **Overview Pangkat**: Visual rank kompetitif saat ini, Rank Rating (RR), MMR, dan riwayat promosi.
- **Riwayat Pertandingan**: Indikator visual kartu kemenangan (hijau) dan kekalahan (merah), performa agen, K/D ratio, dan ACS per match.
- **Statistik Akumulatif**: Winrate, total kemenangan/kekalahan, dan statistik tembakan kepala (Headshot %).

### 4. Account Valuation & Inventory
- **Kalkulasi Total Nilai Akun**: Estimasi total belanja dalam satuan Valorant Points (VP) dan konversi Rupiah Indonesia (IDR).
- **Skin Tiers Distribution**: Visualisasi jumlah koleksi skin berdasarkan tier (Exclusive, Ultra, Premium, Deluxe, Select).
- **Filter & Search Cepat**: Filter berdasarkan sumber (Store / Battlepass), kategori tier skin, serta kata kunci pencarian dengan auto-scroll dan counter bar (Showing X of Y Skins).
- **Equipped Loadout Preview**: Menampilkan skin yang sedang aktif terpasang pada seluruh senjata.

### 5. Battlepass & Missions Tracker
- **Progres Battlepass**: Melacak tier aktif, sisa XP menuju level berikutnya, dan pratinjau hadiah Free maupun Premium.
- **Misi Harian & Mingguan**: Menampilkan daftar misi aktif beserta reward XP dan progres pengerjaannya.

### 6. Wishlist & Custom Store Alerts
- **Koleksi Skin Impian**: Tandai skin favorit dan dapatkan badge "IN STORE TODAY" jika skin muncul di rotasi hari ini.
- **Smart Notification**: Pengingat berkala saat toko harian diperbarui atau skin wishlist tersedia.

### 7. Secure Official Riot Auth
- **Autentikasi Aman**: Login resmi menggunakan WebView Riot Games OAuth langsung ke server otentikasi Riot.
- **Tanpa Menyimpan Password**: Kredensial akun tidak pernah disimpan di server mana pun; token sesi tersimpan secara lokal dan terenkripsi menggunakan flutter_secure_storage.
- **Dukungan 2FA**: Mendukung verifikasi dua langkah (2-Factor Authentication) dan notifikasi Riot Mobile.

---

## Download & Instalasi

File instalasi rilis (APK) Android:
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- Unduh versi APK terbaru dari menu [Releases](https://github.com/Fantsry/store-checkerval/releases) di repositori GitHub ini.

---

## Tech Stack & Architecture

- **Framework**: Flutter 3 (Dart 3)
- **Architecture**: Clean Architecture (Presentation, Domain, Data)
- **State Management**: BLoC / Cubit (flutter_bloc)
- **Networking**: dio (Live Riot Games PVP/Store API & Valorant-API.com)
- **Local Storage & Cache**: hive_flutter & flutter_secure_storage
- **Typography & UI**: google_fonts (Rajdhani) & custom dark theme
- **Routing**: go_router

---

## Menjalankan Project Secara Lokal

```bash
# 1. Clone repository
git clone https://github.com/Fantsry/store-checkerval.git
cd store-checkerval

# 2. Pasang dependensi
flutter pub get

# 3. Jalankan pengujian (Unit & Widget Tests)
flutter test

# 4. Jalankan aplikasi (Development Mode)
flutter run

# 5. Build APK Release
flutter build apk --release
```

---

## Legal Jibber Jabber (Riot Games Disclaimer)

> **StoreCheckerVal was created under Riot Games' "Legal Jibber Jabber" policy using assets owned by Riot Games. Riot Games does not endorse or sponsor this project.**
>
> *StoreCheckerVal isn’t endorsed by Riot Games and doesn’t reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc.*

Aplikasi ini merupakan proyek komunitas non-komersial pihak ketiga yang dibuat oleh penggemar untuk para pemain Valorant. Aplikasi ini mematuhi seluruh panduan penggunaan aset dan kekayaan intelektual sesuai kebijakan resmi [Riot Games Legal Jibber Jabber](https://www.riotgames.com/en/legal-jibber-jabber). Seluruh aset grafis in-game, nama merek, dan data terkait Valorant merupakan hak cipta milik Riot Games, Inc.

# 🚀 Production-Grade Implementation Plan: Valorant Store & Wishlist Tracker (Flutter)

> **Catatan penting (baca dulu):** Aplikasi ini menggunakan endpoint internal/tidak resmi milik Riot Games (client API yang sama dipakai game client, bukan API publik resmi). Ini untuk **penggunaan pribadi** dengan akun sendiri saja — jangan didistribusikan publik, jangan dipakai untuk akun orang lain, dan jangan disalahgunakan untuk automasi lain (auto-buy, dsb). Riot berhak membatasi/menangguhkan akun yang melanggar Terms of Service mereka, jadi ini murni tanggung jawab risiko pribadi. Simpan repo secara privat.

---

## 📌 Project Overview

Aplikasi mobile native cross-platform berbasis **Flutter** untuk memantau Store Harian Valorant, mengelola *Wishlist* skin, dan mengirimkan notifikasi lokal presisi ketika skin di wishlist muncul di store. Dibangun dengan **Clean Architecture (Feature-First)**, penyimpanan kredensial terenkripsi hardware-backed, dan strategi background execution yang realistis (termasuk mitigasi keterbatasan OS).

---

## 🏗️ Architecture & Technical Stack

### 1. Pola Arsitektur: Clean Architecture (Feature-First)

- **Presentation**: `flutter_bloc` (Cubit untuk state sederhana, Bloc untuk event kompleks) + `equatable`.
- **Domain**: Entities, Use Cases, Repository Interfaces — murni Dart, tanpa dependency Flutter/Firebase/dsb (memudahkan unit test).
- **Data**: DataSources (Remote `dio`, Local `Isar`/`SecureStorage`), Models/DTO (`freezed` + `json_serializable`), Repository Implementation.

### 2. Core Dependencies

| Kategori | Package | Catatan |
|---|---|---|
| State Management | `flutter_bloc`, `equatable` | |
| Networking | `dio`, `retrofit` (opsional) | custom `Interceptor` untuk retry + refresh session |
| Secure Storage | `flutter_secure_storage` | Android Keystore / iOS Keychain |
| SSL Pinning | `dio_certificate_pinning` atau native pinning | proteksi MITM saat capture token |
| Local DB | `Isar` (direkomendasikan) | lebih cepat & aktif maintenance dibanding Hive |
| Background Scheduler | `workmanager` | Android WorkManager, iOS `BGTaskScheduler` |
| Notifikasi | `flutter_local_notifications` | BigPicture style + actionable notification |
| WebView Login | `flutter_inappwebview` | cookie management eksplisit |
| Timezone | `timezone` + `flutter_timezone` | jangan hardcode WIB, deteksi device |
| DI | `get_it`, `injectable` | |
| Routing | `go_router` | deep link dari notifikasi |
| Biometric | `local_auth` | app lock opsional |
| Error/Log lokal | `talker` atau custom logger | **tanpa** kirim data ke server pihak ketiga (privasi) |
| Testing | `bloc_test`, `mocktail`, `golden_toolkit` | |
| Obfuscation | Flutter built-in `--obfuscate` | wajib untuk release build |

---

## 🔒 Security & Industry Standards

1. **Zero Hardcoded Secrets** — semua base URL, client version, dsb via `--dart-define-from-file` (jangan pakai `.env` yang ikut ter-bundle ke APK; `--dart-define` di-compile-time, lebih aman daripada file `.env` yang bisa diekstrak dari APK).
2. **Hardware-Backed Encryption** — token & session cookie disimpan di Keystore/Keychain via `flutter_secure_storage`. Password asli **tidak pernah** disimpan sama sekali (hanya lewat WebView resmi Riot, aplikasi tidak pernah menyentuh field password).
3. **SSL/Certificate Pinning** — pin sertifikat untuk domain `auth.riotgames.com` dan endpoint shard regional, supaya token tidak bisa disadap lewat proxy MITM (mis. saat user terhubung ke Wi-Fi publik yang dikonfigurasi menyadap).
4. **Session Refresh yang Akurat (Riot RSO Flow)** — **koreksi penting dari draf sebelumnya**: Riot **tidak** memakai OAuth `refresh_token` standar. Sesi login (RSO — Riot Sign-On) disimpan sebagai **cookie `ssid`** pada domain `auth.riotgames.com`. Alurnya:
   - Setelah login pertama via WebView, ambil **seluruh cookie jar** (bukan cuma satu token) dan simpan di secure storage.
   - Untuk re-auth silent (di background), kirim ulang cookie `ssid` ke endpoint reauthorization (`GET https://auth.riotgames.com/authorize?...` dengan cookie ter-attach) untuk mendapatkan `access_token` & `id_token` baru tanpa membuka WebView.
   - Jika cookie sudah expired/invalid, fallback: tampilkan notifikasi "Sesi berakhir, silakan login ulang" — jangan silent-fail tanpa pemberitahuan.
5. **Region/Shard Detection** — setelah dapat `access_token`, panggil endpoint PAS geo (`riot-geo.pas.rito.gg`) untuk menentukan shard (`na`/`eu`/`ap`/`kr`/`latam`/`br`) user, karena endpoint storefront berbeda per-shard.
6. **App Hardening** — build release wajib pakai `flutter build apk --obfuscate --split-debug-info=./debug-symbols`; aktifkan R8/ProGuard; simpan mapping file untuk debugging crash.
7. **Local Biometric Lock (opsional)** — `local_auth` sebelum membuka data store/wishlist.
8. **Data Minimization** — jangan log PUUID/token ke console pada build release (gate dengan `kDebugMode`).

---

## 🎯 Core Features & Struktur Folder

```
lib/
├── app/                  # Config, Routing (go_router), Theme, DI Setup, Flavors (dev/prod)
├── core/
│   ├── network/          # Dio client + interceptors (auth, retry, logging)
│   ├── storage/          # SecureStorage wrapper, Isar setup
│   ├── error/            # Failure/Exception classes
│   ├── utils/            # Timezone helper, connectivity checker
│   └── constants/
└── features/
    ├── auth/             # Login WebView, Cookie/Token mgmt, silent reauth
    ├── daily_store/       # Storefront UI, Countdown Timer, Skin Detail
    ├── wishlist/         # Catalog, Search/Filter, Local Isar DB
    ├── notifications/    # Workmanager tasks, Notification handler, deep link
    └── settings/         # Battery optimization prompt, biometric toggle, region info
```

### Feature 1: Authentication & Session Management
- [ ] `flutter_inappwebview` ke `auth.riotgames.com`, cookie manager eksplisit (`CookieManager.instance()`).
- [ ] Tangkap `id_token`/`access_token` dari redirect URL fragment, **dan** simpan cookie jar penuh untuk silent reauth.
- [ ] Ambil `entitlements_token` (Entitlements API) dan `PUUID` (UserInfo endpoint).
- [ ] Deteksi shard/region via PAS geo endpoint.
- [ ] Simpan semua payload di `flutter_secure_storage` (per-key, bukan satu blob besar agar mudah invalidasi parsial).
- [ ] Unit test `AuthRepository` dengan mock `SecureStorage` & `Dio`.

### Feature 2: Daily Storefront & Catalog
- [ ] Fetch `/store/v2/storefront/{puuid}` dengan header dinamis (`X-Riot-ClientVersion` **diambil otomatis** dari `https://valorant-api.com/v1/version`, jangan di-hardcode — versi ini sering berubah tiap patch dan request akan gagal jika stale).
- [ ] Parsing `SingleItemOffers` (4 skin harian) + `BundleStore` (opsional, untuk fitur lanjutan).
- [ ] Fetch & **cache lokal** metadata skin dari `valorant-api.com/v1/weapons/skins` (refresh berkala, mis. mingguan — bukan tiap buka app, untuk hemat kuota & rate limit).
- [ ] UI Storefront tema Valorant (Dark/Vibrant), countdown timer memakai timezone device via package `timezone`.
- [ ] Skeleton loading + empty/error state.

### Feature 3: Wishlist & Catalog Search
- [ ] Katalog skin lengkap, search & filter (Weapon Type, Tier, sudah dimiliki/belum).
- [ ] Simpan wishlist di **Isar** (bukan `shared_preferences` — butuh query filter, `shared_preferences` tidak cocok untuk data terstruktur).
- [ ] Export/Import wishlist (JSON) untuk backup manual (karena tidak ada server).

### Feature 4: Background Task & Push Notifications
- [ ] Konfigurasi `Workmanager`:
  - Android: `PeriodicTask` min interval 15 menit (batas OS) **+** `OneOffTask` presisi via `AlarmManagerPlugin`/`android_alarm_manager_plus` untuk jam target, karena `WorkManager` periodic tidak presisi ke menit.
  - iOS: `BGAppRefreshTask` — **catatan realistis**: iOS **tidak menjamin** waktu eksekusi persis (`earliestBeginDate` hanya batas minimum, OS bisa menunda berjam-jam tergantung pola pemakaian user). Jangan janjikan notifikasi tepat jam 07:05 di iOS.
- [ ] Logic eksekusi (Background Isolate, entry point `@pragma('vm:entry-point')`):
  1. Cek konektivitas.
  2. Baca cookie session dari Secure Storage.
  3. Silent reauth → `access_token` + `entitlements_token` baru.
  4. Fetch storefront (4 UUID).
  5. Bandingkan dengan wishlist lokal (Isar).
  6. Jika match → `flutter_local_notifications` dengan `BigPictureStyleInformation` (gambar skin) + payload untuk deep link.
  7. Simpan hasil fetch terakhir untuk fallback UI offline.
- [ ] **Opsi reliabilitas tambahan (rekomendasi)**: karena background scheduler OS (terutama iOS + OEM Android seperti MIUI/ColorOS/OneUI) terkenal tidak andal, pertimbangkan **hybrid server-assisted**:
  - Cloud Function kecil (Firebase Functions + Cloud Scheduler, gratis di tier kecil) yang jalan tiap hari jam target, cek storefront **milikmu sendiri** (server yang menyimpan cookie terenkripsi — perlu pertimbangan keamanan tambahan jika begini), lalu kirim **FCM push** ke device untuk trigger local notification.
  - Trade-off: lebih andal secara waktu, tapi menambah kompleksitas (perlu server) dan menyimpan token di luar device (risiko keamanan naik). Untuk aplikasi pribadi skala kecil, on-device scheduler + fallback "cek saat app dibuka" biasanya cukup.
  - **Fallback minimal wajib**: selalu jalankan pengecekan store+wishlist juga saat app dibuka (foreground), supaya user tetap dapat notifikasi/lihat match walau background task telat.

---

## 🔔 Notifikasi
- [ ] Minta izin notifikasi eksplisit di Android 13+ (`POST_NOTIFICATIONS`) dan iOS (`requestPermissions`).
- [ ] Tap notifikasi → deep link (`go_router`) langsung ke halaman detail skin yang match.
- [ ] Grouping notifikasi jika lebih dari 1 skin wishlist match dalam satu hari.
- [ ] Channel notifikasi terpisah (Android) untuk "Store Update" vs "System/Error".

---

## 📴 Offline & Caching Strategy
- [ ] Cache storefront terakhir + timestamp di Isar → tampilkan saat offline dengan label "data terakhir jam X".
- [ ] Cache metadata skin (nama, ikon, tier, harga) secara lokal, refresh via ETag/versi katalog, bukan full fetch tiap saat.
- [ ] Retry dengan exponential backoff untuk request gagal (mis. via `dio` interceptor custom, max 3x).

---

## 🧪 Testing Strategy
- [ ] Unit test: semua Use Case & Repository (mock data layer dengan `mocktail`).
- [ ] Bloc test: setiap Cubit/Bloc pakai `bloc_test`.
- [ ] Widget test: komponen UI kritikal (Countdown Timer, Skin Card).
- [ ] Golden test (opsional): konsistensi tampilan tema dark Valorant.
- [ ] Integration test: flow login → fetch store → tambah wishlist → simulasi notifikasi.

---

## ⚙️ CI/CD & Build Configuration
- [ ] GitHub Actions: lint (`flutter analyze`) + test setiap push.
- [ ] Flavor `dev`/`prod` (`flutter_flavorizr` atau manual `--flavor`) — dev pakai endpoint/log verbose, prod pakai obfuscation penuh.
- [ ] Secrets (client version override, dsb) di-inject via `--dart-define-from-file=config/prod.json`, file config **tidak** di-commit ke repo publik.
- [ ] Build release wajib: `flutter build apk --obfuscate --split-debug-info=build/symbols --flavor prod`.
- [ ] Karena app pribadi: distribusi via sideload APK / Firebase App Distribution / TestFlight internal — **tidak perlu** listing Play Store/App Store publik (menghindari review masalah ToS pihak ketiga API).

---

## 📋 Actionable Implementation Milestones

| Milestone | Key Deliverables | Status |
|---|---|---|
| **M1: Setup & Arsitektur** | Folder structure, tema, DI (`get_it`+`injectable`), routing (`go_router`), flavor dev/prod. | ⏳ Pending |
| **M2: Auth Module** | WebView login, cookie jar capture, silent reauth, PAS region detection, unit test `AuthRepository`. | ⏳ Pending |
| **M3: API & Store UI** | Dio interceptor (retry+reauth), dynamic client version fetch, mapping `valorant-api.com`, UI Store + Wishlist + Isar. | ⏳ Pending |
| **M4: Background Task & Notifikasi** | Workmanager callback Android/iOS, exact alarm untuk Android, `BGAppRefreshTask` iOS + expiration handler, local notification + deep link. | ⏳ Pending |
| **M5: Hardening & OS Mitigation** | Battery optimization prompt, exact alarm permission (Android 12+), SSL pinning, obfuscation build. | ⏳ Pending |
| **M6: Testing & Release** | Unit/Bloc/Widget/Integration test coverage, CI pipeline, build APK/IPA signed, internal distribution. | ⏳ Pending |

---

## ⚠️ OS-Specific Mitigation Strategies

1. **Android Battery Saver / OEM Kills (MIUI/ColorOS/OneUI)**
   - Prompt UI arahkan ke `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`.
   - Untuk Android 12+, minta izin `SCHEDULE_EXACT_ALARM` (runtime permission baru) agar alarm presisi tidak dibatasi OS.
2. **iOS BGTaskScheduler**
   - Set `earliestBeginDate` mendekati jam target, tapi **komunikasikan ke user** bahwa waktu aktual bisa meleset (keterbatasan OS, bukan bug app).
   - Tangani `expirationHandler` agar task dihentikan bersih sebelum di-kill paksa.
   - Registrasi `BGTaskSchedulerPermittedIdentifiers` di `Info.plist`.
3. **Notification Permission (Android 13+ / iOS)**
   - Request permission eksplisit saat onboarding, bukan saat background task jalan pertama kali (supaya tidak silent-fail).

---

## 💡 Optional Enhancements (Nice-to-have)
- [ ] Home screen widget (Android App Widget / iOS WidgetKit) menampilkan countdown + 1 skin wishlist teratas.
- [ ] Multi-akun (switch antar akun Riot yang sudah login).
- [ ] Statistik pribadi: berapa kali skin wishlist muncul dalam 30 hari terakhir.
- [ ] Localization ID/EN.
- [ ] Root/Jailbreak detection sederhana (peringatan, bukan blocking) untuk device yang berpotensi lebih rentan terhadap ekstraksi secure storage.

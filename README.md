# StoreCheckerVal

A Flutter mobile application to track Valorant daily store rotations, featured bundles, Night Market offers, and skin wishlists.

## Features

- **Storefront & Wallet**: Real-time daily rotating weapon skins with VP costs, featured bundles, Night Market offers, and VP/RP wallet balance.
- **Skin Details**: High-resolution renders, chroma variants, upgrade level descriptions, and preview videos fetched from valorant-api.com.
- **Wishlist & Background Check**: Wishlist tracking with periodic background checks (WorkManager) and local notifications when items appear in the store.
- **Authentication**:
  - Direct authentication with Riot Games API.
  - Multi-factor authentication supporting both email OTP code and Riot Mobile push approval polling.
  - Web sign-in fallback via in-app browser.
  - Silent re-authentication using session cookies.
  - Biometric app lock (Fingerprint / Face ID).

## Tech Stack & Architecture

The application is structured following Clean Architecture principles:

- **Framework**: Flutter (Dart SDK ^3.9.0)
- **State Management**: flutter_bloc
- **Networking**: Dio
- **Storage**: flutter_secure_storage (Auth tokens), Hive (Wishlist & Cache)
- **Navigation**: go_router
- **Dependency Injection**: get_it
- **Background Tasks**: workmanager, flutter_local_notifications

### Project Structure

```
lib/
├── app/                  # Routing, theme configuration, and app initialization
├── core/                 # Constants, errors, network clients, and storage helpers
└── features/
    ├── auth/             # Riot RSO, 2FA/MFA handling, and session management
    ├── daily_store/      # Storefront, bundles, Night Market, and skin details
    ├── wishlist/         # Wishlist management and background check handlers
    └── settings/         # App preferences, biometrics, and account management
```

## Getting Started

### Prerequisites

- Flutter SDK (3.9.0 or higher)
- Android Studio / Xcode
- Connected device or emulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Fantsry/store-checkerval.git
   cd store-checkerval
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generation:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. Run the application:
   ```bash
   flutter run
   ```

### Running Tests

```bash
flutter test
```

## Disclaimer

This project is an unofficial tool and is not affiliated with, endorsed by, or sponsored by Riot Games, Inc. Valorant and all associated properties are trademarks or registered trademarks of Riot Games, Inc.

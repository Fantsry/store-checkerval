# StoreCheckerVal

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Style](https://img.shields.io/badge/Style-Data--dense_Esports_HUD-48C878)](https://github.com/Fantsry/store-checkerval)

**StoreCheckerVal** is a Flutter-based Android app for tracking your Valorant daily store, Night Market, accessory rotation, live match, competitive career, Battlepass progress, account value, and friends — all from your phone without opening a PC.

The interface follows a **data-dense esports HUD** direction: near-black surfaces, precise hairlines, Geist type, mono metadata, and a single green accent. It is built for fast scanning and compact layouts rather than decorative effects.

---

## Features

### 1. Daily Store & Night Market
- **Daily rotation**: track the four daily skin offers and a live reset countdown.
- **Featured bundle**: preview the active bundle, its price, and remaining duration.
- **Night Market**: browse discounted offers with their original prices and discount percentages.
- **Accessory store**: monitor Gunbuddy, Player Card, Spray, and Title rotations priced in Kingdom Credits (KC).
- **Skin details**: switch between variants and upgrade levels, inspect artwork, and add skins to your wishlist.

### 2. Live Match Tracker
- **Real-time status**: detect Agent Select, in-game, transitioning, lobby, and error states.
- **Player cards**: show rank, RR, recent form, and agent details. Metrics such as ACS, KAST, KDA, ADR, and HS% display as `—` when Riot does not expose them.
- **Team scoreboard**: list both teams, map, score, and side when the API provides them.
- **No fabricated data**: Riot does not expose live round scores for your own account, so the app never invents numbers when data is unavailable.

### 3. Career & Rank Progression
- **Rank overview**: current competitive rank, Rank Rating (RR), MMR, and promotion progress.
- **Match history**: win/loss tape, agent performance, K/D ratio, and ACS per match.
- **Trend charts**: RR and K/D trends across recent matches.
- **Career totals**: win rate, total wins and losses, headshot percentage, and performance breakdowns.
- **Share cards**: export rank, match, and collection summaries as image cards.

### 4. Collection & Account Valuation
- **Estimated account value**: total Valorant Points (VP) and an estimated IDR conversion. This is an estimate, not a purchase history.
- **Tier breakdown**: owned skins grouped by Exclusive, Ultra, Premium, Deluxe, and Select tiers.
- **Fast filtering**: filter by source (Store or Battlepass), skin tier, and search query, with result counters.
- **Equipped loadout**: see which skins are currently equipped on every weapon.
- **Collection share card**: export a summary of your collection value and skin count.

### 5. Battlepass & Missions
- **Battlepass progress**: active tier, XP toward the next tier, and Free/Premium reward previews.
- **Daily and weekly missions**: active Riot missions with XP rewards and progress. Empty when Riot does not report missions.

### 6. Wishlist, Alerts & Home-Screen Widget
- **Wishlist**: save favorite skins and see an **IN STORE TODAY** badge when one appears in the current rotation.
- **Store alerts**: create rules by weapon and tier, or watch the wishlist, and receive notifications when offers match.
- **Night Market and accessory alerts**: separate toggles for each rotation.
- **Android home-screen widget**: see the current store summary, offers, Night Market status, and reset time without opening the app.
- **Chat notifications**: optional alerts for new social messages.

### 7. Social & Friends
- **Riot friends**: sync your real friend roster and presence status.
- **Presence and activity**: see who is online, in game, or offline, plus recent match form.
- **Direct messages**: chat with friends through Riot XMPP, with local history, unread counts, retry, and delivery states.
- **Favorites**: pin friends for quick access and filter by status.

### 8. Secure Riot Sign-In
- **Official Riot OAuth**: sign in through Riot's authentication page in a WebView.
- **No stored passwords**: credentials are never stored or sent to a third-party server. Session tokens stay on-device in encrypted storage using `flutter_secure_storage`.
- **2FA support**: works with two-factor authentication and Riot Mobile approval.

### 9. Settings, Backup & Localization
- **Device settings**: language, notification toggles, and cache controls.
- **Backup and restore**: export and import wishlist items, alert rules, favorites, and app settings.
- **Localization**: English and Indonesian UI.
- **Account cleanup**: sign out and clear account-scoped data without deleting device preferences.

---

## Release Build

To sign a release APK with your own keystore:

```bash
cp android/key.properties.example android/key.properties
# fill in storePassword, keyPassword, keyAlias, and storeFile
flutter build apk --release
```

If `android/key.properties` is missing, local builds fall back to debug signing. `key.properties` and keystore files are ignored by git.

## Download & Installation

Android release artifact:
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- Download the latest APK from the [Releases](https://github.com/Fantsry/store-checkerval/releases) page.

---

## Tech Stack & Architecture

- **Framework**: Flutter 3 (Dart 3)
- **Architecture**: Clean Architecture (Presentation, Domain, Data)
- **State management**: BLoC / Cubit (`flutter_bloc`)
- **Networking**: `dio` against Riot Games PVP/Store APIs and Valorant-API.com
- **Local storage**: `hive_flutter` for caches and preferences; `flutter_secure_storage` for session tokens
- **Background work**: `workmanager`, `flutter_local_notifications`, and `home_widget`
- **UI**: bundled Geist and Geist Mono fonts, Material 3, custom design tokens
- **Routing**: `go_router`
- **Sharing and export**: `share_plus`, `file_picker`
- **Localization**: `flutter_localizations` with ARB files

---

## Running Locally

```bash
# 1. Clone the repository
git clone https://github.com/Fantsry/store-checkerval.git
cd store-checkerval

# 2. Install dependencies
flutter pub get

# 3. Run unit and widget tests
flutter test

# 4. Run the app in development mode
flutter run

# 5. Build a release APK
flutter build apk --release
```

---

## Legal Jibber Jabber (Riot Games Disclaimer)

> **StoreCheckerVal was created under Riot Games' "Legal Jibber Jabber" policy using assets owned by Riot Games. Riot Games does not endorse or sponsor this project.**
>
> *StoreCheckerVal isn’t endorsed by Riot Games and doesn’t reflect the views or opinions of Riot Games or anyone officially involved in producing or managing Riot Games properties. Riot Games, and all associated properties are trademarks or registered trademarks of Riot Games, Inc.*

This is a non-commercial, third-party community project built by fans for Valorant players. It follows the official [Riot Games Legal Jibber Jabber](https://www.riotgames.com/en/legal-jibber-jabber) asset and intellectual property policy. All in-game artwork, brand names, and Valorant-related data remain the property of Riot Games, Inc.

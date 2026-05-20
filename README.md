# ⛳ Mini Golf Score Tracker

Mini Golf Score Tracker is a cross-platform application built with Flutter and Firebase for Android, iOS, and Web. It provides a seamless, location-aware mini-golf scoring experience, prioritizing immediate utility through a "Guest-First" architecture that allows users to track games locally and sync to the cloud later.

## ✨ Key Features

*   **Utility-First Guest Experience**: Users can immediately launch the app and track an active game offline without signing up.
*   **Unified Smart Navigation Shell**: A dynamic app shell and drawer that acts as an "Activity Hub," rendering the top scheduled and past games, and securely gating premium features behind login conversion prompts.
*   **Global Auto-Resume**: The app automatically detects active, uncompleted local games and drops returning users (both guests and authenticated) directly back onto the green upon app launch.
*   **Location-Aware Course Discovery**: Integrates `geolocator` and `geocoding` to automatically sort nearby courses by proximity (utilizing the Haversine formula) and aggressively prevents duplicate course entries using a 100m radius threshold and normalized address matching.
*   **Offline UI Hardening**: Built for the outdoors. The app gracefully catches `DatabaseConnectionError` exceptions to display custom "Fairway Unreachable" UI states and offline SnackBars instead of infinite loading spinners.
*   **Robust Identity & Claiming**: A complex identity management system allowing users to play as guests, and later "claim" their canonical player profiles and historical games using Firebase Email or Phone verification without creating duplicate records.
*   **Tiered Monetization**: A freemium model where guests experience ads, registered users unlock cloud sync and future game scheduling, and $1/mo Premium Subscribers unlock ad-free play, course proximity searches, and a course rating system.

## 🗺️ Development Roadmap

The project is currently executing against an 8-phase architectural master plan:

*   **Phase 1: Immediate Stability, Guest Experience & UI Modernization** (In Progress) - Hardening CRUD operations, implementing location safety, unifying the smart drawer, and modernizing the UI to Material 3.
*   **Phase 2: Identity Foundation & Local Game Adoption** (In Progress) - Migrating local SharedPreferences JSON strings to canonical, authenticated player records and handling guest adoption workflows.
*   **Phase 3: Real-Time Synchronization & Data Integrity** (Planned) - Implementing Firestore `snapshots()` for live multi-user score updates, offline FIFO sync queues, and transactional identity consistency.
*   **Phase 4: Advanced Testing & E2E Validation** (In Progress) - Setting up the Firebase Local Emulator Suite and ensuring full identity convergence regression coverage.
*   **Phase 5: Security, Multi-Contact & Privacy** (Planned) - Implementing permanent account merging, split-identity rejection, double-claim prevention, and expandable PII privacy cards.
*   **Phase 6: Customization & Preferences** (Planned) - Adding context-specific, creator-assigned player nicknames and sharing preferences.
*   **Phase 7: Technical Debt & Performance** (Planned) - Refactoring inefficient storage access and conditional debug stripping.
*   **Phase 8: Premium Features & Monetization** (Future) - Gating proximity searches, advanced scheduling, and rating systems behind a premium subscription tier.

## 🛠️ Tech Stack & Architecture

*   **Framework**: Flutter (SDK >=3.0.0 <4.0.0) & Dart.
*   **Backend**: Firebase (Auth, Firestore, Storage).
*   **State Management**: `ChangeNotifier` (e.g., `UserProvider`) and native `StatefulWidget` patterns. No third-party state management libraries (like Riverpod or Bloc) are used to maintain pure Clean Architecture.
*   **Core Packages**: `geolocator`, `geocoding`, `flutter_map`, `shared_preferences`, `firebase_auth`, `cloud_firestore`.

## 🛡️ Developer Guidelines (Baseline Protocol)

All contributions and AI-assisted development (via Antigravity/Cursor) must adhere to the strict **Baseline Protocol**:

1.  **100% Unit Test Coverage**: Every created or modified file MUST have exactly 100% line, statement, and branch coverage. This is non-negotiable.
2.  **Zero Static Analysis Warnings**: Code must pass `flutter analyze` with 0 errors, 0 warnings, and 0 info messages before any commit.
3.  **Established Mocking Patterns**: Do not invent new mocks. Use `FakeFirebaseFirestore`, `MockFirebaseAuth`, `SharedPreferences.setMockInitialValues({})`, and the existing `MockGeolocatorPlatform`.
4.  **Conventional Commits**: All version control follows semantic commit conventions (`feat`, `fix`, `test`, `refactor`).
5.  **Clean Architecture**: Strictly separate concerns between Models, Services/Repositories, and UI Components.

## 🚀 Getting Started

1.  Clone the repository.
2.  Run `flutter pub get` to install dependencies.
3.  To run tests and verify coverage:
    ```bash
    flutter test --coverage
    ```
4.  Ensure your environment passes the strict analyzer checks:
    ```bash
    flutter analyze
    ```

***
*Developed with Flutter & Firebase. "Preparing the greens..."*
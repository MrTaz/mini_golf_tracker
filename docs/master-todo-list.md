# Mini Golf Score Tracker — Master Development Roadmap & TODO List

## 1. Project Overview

This roadmap consolidates all active TODOs, enhancement plans, testing plans, and architectural notes for the Mini Golf Score Tracker.

**Executive Directive:** Eliminate legacy technical debt in data persistence while scaling the identity system to support multi-contact verification, real-time multiplayer synchronization, location-aware course safety, and modern ergonomic UI requirements.

---

## 2. Progress Tracking

| Phase | Status | Description |
|---|---|---|
| Phase 1 — Immediate Stability & Guest Experience | In Progress | Harden CRUD operations, location safety, coordinate validation, database error handling, guest UX, and UI modernization. |
| Phase 2 — Identity & Local Game Adoption | In Progress | Migrate guest data and local JSON strings to authenticated `ContactIdentity` / canonical player records. |
| Phase 3 — Real-Time Sync & Data Integrity | Planned | Implement Firestore `snapshots()` for live multi-user score updates and offline-safe sync. |
| Phase 4 — E2E Regression & Integrity Testing | In Progress | Execute identity convergence, location conflict, stream, and emulator-based regression scenarios. |
| Phase 5 — Security, Multi-Contact & Privacy | Planned | Implement account merging, verification links, double-claim prevention, split-identity rejection, and PII protections. |
| Phase 6 — Customization & Preferences | Planned | Add creator-assigned nicknames and player-specific display preferences. |
| Phase 7 — Technical Debt & Performance | Planned | Refactor inefficient storage access, debug-only behavior, and legacy SharedPreferences handling. |

---

# Part A — Condensed Master TODO Roadmap

## Phase 1 — Immediate Stability, Guest Experience & UI Modernization

##### 1.1 Harden Database Error Handling
*  [x] Wrap `UserProvider.initialize` `authStateChanges` listener in a try-catch block to prevent `DatabaseConnectionError` crashes on startup.
*  [x] Harden `ClaimAccountScreen._refreshClaim()` with a generic catch block to gracefully handle database/network failures without crashing.
*  [ ] Implement comprehensive try-catch blocks in GameCardWidget and CoursesScreen to intercept DatabaseConnectionError.
*  [ ] In CoursesScreen, replace the current _isLoading && courses.isEmpty ternary logic with an explicit error-state check such as _connectionError != null.
*  [ ] Render a persistent "Fairway Unreachable" UI state with a "Retry" callback when course loading fails.
*  [ ] In GameCardWidget, catch Firestore failures during getLocallySavedGames.
*  [ ] Display a SnackBar using ScaffoldMessenger when remote sync is temporarily unavailable.

### 1.2 Modernize Game Creation UI

- [ ] Redesign `GameCreateScreen` to match the design language of `AddEditCourseScreen`.
- [ ] Replace standard `ListTile` widgets for course and player selection with custom `_buildSelectionCard` helpers.
- [ ] Use `AnimatedContainer` and `BoxDecoration` patterns from `AddEditCourseScreen._buildHoleCountCard`.
- [ ] Provide haptic-like visual feedback, elevation styling, and consistent border radius.
- [ ] Use a consistent border radius of `16.0` for `GameCreateScreen` selection cards.
- [ ] Move `"Select Players"` and `"Select Course"` triggers out of the `ListView`.
- [ ] Place selection actions in a bottom sticky action bar or `FloatingActionButton` for better one-handed accessibility.

### 1.3 Modernize Player Creation and Selection UI

- [ ] Refactor `PlayerCreateScreen` and `PlayersScreen` to align with the Material 3 / Teal design language.
- [ ] Use `Card` widgets with:
  - `elevation: 0`
  - `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))`
  - `Colors.teal.shade50` background accents
- [ ] Mirror the aesthetic of `_buildHoleCountCard`.
- [ ] Reposition the `"Select Players"` button in `PlayersScreen` for better thumb reach and accessibility.
- [ ] Implement `BouncyAnimation` for loading states during player fetch operations.
- [ ] Use `LinearProgressIndicator` with `20.0` / `24.0` corner radius for async fetches.
- [ ] Transform the basic `PlayerCreateScreen` form into a step-based or card-based UI aligned with `CoursesScreen` cards.

### 1.4 Fix Player Selection State

- [ ] Ensure `selectedPlayers` in `PlayersScreen` persists through rebuilds.
- [ ] Synchronize `selectedPlayers` correctly with parent `GameCreateScreenState`.
- [ ] Modify `PlayersScreen` to accept a `List<Player> currentlySelectedPlayers` parameter.
- [ ] Ensure `GameCreateScreen` passes its current selected-player state into `PlayersScreen`.
- [ ] Ensure `GameCreateScreen` correctly handles the returned player list.
- [ ] Add a `"Deselect All"` or `"Clear All"` action in `PlayersScreen`.
- [ ] Add `"Clear All"` to the `AppBar` of `PlayersScreen`.
- [ ] Reset the `selectedPlayers` list instantly when clearing selections.

### 1.5 Guest-Aware Navigation Drawer

- [ ] Modify `_buildDrawerList` in `main.dart`.
- [ ] If `UserProvider().loggedInUser` is `null`, inject a `UserAccountsDrawerHeader` with a `"Guest Mode"` placeholder.
- [ ] Add a `"Claim History"` menu item that navigates to `ClaimAccountScreen`.
- [ ] Add a `"Sign In"` option to encourage authentication without locking out guest data.

### 1.6 Course Location Awareness & Duplicate Prevention

- [ ] Implement the technical rules from `course-location-awareness.md` inside `AddEditCourseScreen`.
- [ ] Populate the skeletal `_showAddressCaptureBottomSheet` method.
- [ ] Add:
  - `streetController`
  - `cityController`
  - `stateController`
  - `zipController`
- [ ] Resolve current coordinate capture failure.
- [ ] Perform geocoding in the background.
- [ ] Implement `_findConflictingCourses` using the Haversine formula.
- [ ] Trigger `_showLocationConflictDialog` when an existing course is within `100 meters`.
- [ ] Add normalized address substring matching.
- [ ] Identify duplicates even when coordinates are unavailable.
- [ ] Ensure `"53 Carter Hill"` can match `"53 Carter Hill Rd"`.
- [ ] Allow users to select an existing course at the location.
- [ ] Allow users to bypass the conflict and create a secondary course for multi-course facilities.
- [ ] Support secondary course examples such as `"Fire Tower Course"` vs. `"Case Course"` at the same GPS coordinate.
- [ ] Add tests for the `"Add Second Course Anyway"` flow.

### 1.7 Proximity-Based Sorting and Location Safety

- [ ] In `CoursesScreen.initState`, trigger `_getCurrentLocation()` and `_initializeCourses()` concurrently.
- [ ] Use `Future.wait` or equivalent to prevent UI blocking.
- [ ] Ensure all UI-updating callbacks verify `mounted` before executing.
- [ ] Re-sort the `CoursesScreen` list immediately after a successful GPS lock.
- [ ] Use high-accuracy `LocationSettings`.
- [ ] Update `_getCurrentLocation` in `courses_screen.dart` to explicitly catch `TimeoutException`.
- [ ] Use `locationSettings` with a `5-second timeLimit`.
- [ ] Display a non-blocking `SnackBar` or status icon if the timeout triggers.
- [ ] Do not fail silently on location timeout.

---

## Phase 2 — Identity Foundation & Local Game Adoption

### 2.1 Preserve Nickname-Only and Quick-Play Players

- [ ] Preserve anonymous / nickname-only users as first-class players.
- [ ] Verify `Player.createPlayer` remains functional with only `playerName` and `nickname`.
- [ ] Ensure `ownerId` defaults to the creator’s UID or `'guest'`.
- [ ] Update the `Player` model to include an `isQuickPlay` boolean flag.
- [ ] Ensure `PlayerForm` bypasses mandatory email / phone validation when `isQuickPlay` is `true`.
- [ ] Store quick-play players in the local `guest_players` `SharedPreferences` key.
- [ ] Ensure PII independence for quick-play and guest players.

### 2.2 Normalize Contact Entry Points

- [ ] Use `ContactIdentity.normalizeEmail` in all contact write paths.
- [ ] Use `ContactIdentity.normalizePhoneNumber` in all contact write paths.
- [ ] Apply normalization inside `PlayerForm.saveChanges`.
- [ ] Apply normalization before any database write.
- [ ] Reference `ContactIdentity` as the source of truth for all contact normalization.
- [ ] Ensure normalization supports reservation consistency.

### 2.3 Late Contact Attribution

- [ ] Refactor `Player.updateUnclaimedPlayer` to support post-creation contact attachment.
- [ ] Before updating contact details, invoke:
  - `ContactIdentity.normalizeEmail`
  - `ContactIdentity.normalizePhoneNumber`
- [ ] Query the `player_contacts` collection before attaching a contact.
- [ ] Verify the contact is not already reserved.
- [ ] Prevent split-identity claims where phone and email point to different canonical IDs.

### 2.4 Local Game & Guest Adoption Workflow

- [ ] Implement the migration path from `SharedPreferences` to Firestore.
- [ ] Implement `Game.adoptLocalGames`.
- [ ] Iterate through local games and map them to the canonical `loggedInUser`.
- [ ] Refactor / deprecate automatic adoption loops in `Game.adoptLocalGames`.
- [ ] Update method signature to:

```dart
adoptLocalGames(Player loggedInUser, List<String> gameIdsToAdopt)
```

- [ ] Implement `Player.adoptLocalGuestPlayers`.
- [ ] Verify and create records in `player_contacts` for any guest being promoted.
- [ ] Prevent adopting a contact already reserved by another canonical record.
- [ ] Rewrite `Player.adoptLocalGuestPlayers` to iterate through:
  - `friends`
  - `player_game_info`
  - `games`
- [ ] Explicitly handle embedded data.
- [ ] Update `Game.saveLocalGame` to parse JSON strings in `SharedPreferences`.
- [ ] Replace legacy guest IDs with canonical IDs.
- [ ] Decouple migration from the login flow.
- [ ] Implement a post-login import prompt.
- [ ] Allow users to choose which local guest games to associate with their authenticated profile.
- [ ] Implement a `"Merge Games Found"` dialog in `UserProvider` after successful login.
- [ ] Allow users to explicitly select which local IDs to sync to Firestore.
- [ ] Include local games and local friends in the cloud import prompt.

### 2.5 Claim Baseline

- [ ] Ensure `Player.claimPlayerForVerifiedAuthUser` is the exclusive entry point for guest-to-auth conversion.
- [ ] Maintain canonical integrity during all claim flows.
- [ ] Ensure `UserProvider` triggers `ClaimAccountScreen` when signup detects claimable history.

### 2.6 Legacy Duplicate Repair

- [ ] Develop an ID consistency migration utility.
- [ ] Repair legacy duplicate players.
- [ ] Rewrite IDs in:
  - `friends` collection
  - `player_game_info` maps
  - embedded `game.players` lists
  - local `SharedPreferences` JSON strings
- [ ] Ensure all history converges onto a canonical ID.

---

## Phase 3 — Real-Time Synchronization & Data Integrity

### 3.1 Firestore Listener Architecture

- [ ] Replace `SharedPreferences` lookups in `GameInprogressScreen` with real-time Firestore listeners.
- [ ] Modify the `Game` model to support a `fromSnapshot(DocumentSnapshot)` factory.
- [ ] Update `GameInprogressScreen` to listen to Firestore `snapshots()` for the active `gameId`.
- [ ] Use `StreamBuilder` to support mid-game reconnections.
- [ ] Support multi-device score updates.
- [ ] Replace `FutureBuilder` in `GameInprogressScreen` with two nested `StreamBuilder` widgets.
- [ ] Add a document stream for the specific `Game` ID to track status and metadata.
- [ ] Add a collection stream for the `PlayerGameInfo` sub-collection to reactively update hole scores.
- [ ] Remove manual `_updateGame` calls for UI refreshes.
- [ ] Ensure the UI only reflects state emitted by Firestore snapshots.

### 3.2 Stream Testing

- [ ] Build widget tests that simulate Firestore stream updates.
- [ ] Verify the UI updates correctly when other players change scores.
- [ ] Ensure stream updates do not throw out-of-bounds exceptions.
- [ ] Ensure stream updates do not throw state errors.

### 3.3 Concurrency & Conflict Resolution

- [ ] Implement `"Last Write Wins"` using Firestore `serverTimestamp`.
- [ ] When updating a score in `Game.recordScore`, include a `last_updated` field.
- [ ] If a snapshot arrives where remote `last_updated` is newer than local state, perform a non-destructive merge of the scores list.
- [ ] Preserve score integrity during multi-device updates.

### 3.4 Offline FIFO Synchronization Queue

- [ ] Create a `SyncQueue` service.
- [ ] Back the queue with `SharedPreferences`.
- [ ] Use a First-In-First-Out structure.
- [ ] If `DatabaseConnectionError` is caught during a score write, push the `PlayerGameInfo` JSON to the queue.
- [ ] Implement a background listener that processes queued writes once connectivity is restored.
- [ ] Process the queue sequentially.
- [ ] Preserve chronological integrity.

### 3.5 Transactional Identity Consistency

- [ ] Use a Firestore Transaction in the claim service.
- [ ] Ensure claim operations are atomic.
- [ ] Reject a claim if email resolves to one player and phone resolves to another.
- [ ] Validate every player claim against the `player_contacts` source of truth.
- [ ] Prevent hijacking of reserved identities.

##### 3.6 Firestore Composite Indexes
*  [ ] Update `firestore.indexes.json` to define necessary composite indexes.
*  [ ] Add a composite index for the `games` collection to support querying by `creator_id` while ordering by `scheduled_time` (required for `Game.fetchGamesForCurrentUser`).
*  [ ] Add a composite index for the `games` collection querying by `status` and ordering by scheduled_time.

---

## Phase 4 — Advanced Testing, E2E Validation & Emulator Support

##### 4.1 Firebase Local Emulator Suite Setup
*  [ ] Set up Firebase Local Emulator Suite (Auth and Firestore) in the project environment.
*  [ ] Update `DatabaseConnection.initialize()` to conditionally call `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080)` when running in debug or emulator mode.
*  [ ] Update `UserProvider.initialize()` to conditionally call `FirebaseAuth.instance.useAuthEmulator('localhost', 9099)`.
*  [ ] Configure integration tests to run against the local emulator environment.
*  [ ] Implement `@firebase/rules-unit-testing` for security rule validation.

### 4.2 Canonical Player Convergence E2E Scenario

- [ ] Create an E2E test in `all_test_code.md`.
- [ ] Simulate this full flow:
  1. Remote game exists with a canonical player.
  2. Guest creates a local game with a matching contact.
  3. Guest signs up and verifies via `ClaimAccountScreen`.
  4. Verify remote and local games converge on the same canonical ID.
  5. Verify no duplicate records exist in the `players` collection.

### 4.3 Expanded Convergence Scenario

- [ ] Simulate User A creating a remote game.
- [ ] User A adds Player B via email `b@example.com`.
- [ ] User C, as a guest, creates a local game using the same email `b@example.com`.
- [ ] User C signs up.
- [ ] `UserProvider` triggers `ClaimAccountScreen`.
- [ ] Upon verification, confirm original remote game and newly adopted guest game point to the same UID.
- [ ] Validate no duplicate player records exist.

### 4.4 Address and Location Tests

- [ ] Update `all_test_code.md` with tests for `_showAddressCaptureBottomSheet`.
- [ ] Verify empty street fields trigger validation failures.
- [ ] Verify empty city fields trigger validation failures.
- [ ] Expand `MockGeolocatorPlatform`.
- [ ] Expand `MockGeocodingPlatform`.
- [ ] Cover the `100-meter` proximity threshold logic.
- [ ] Cover coordinate-to-address mapping.
- [ ] Test normalized substring address matching.
- [ ] Test the `"Add Second Course Anyway"` flow.
- [ ] Ensure the proximity warning works in `AddEditCourseScreen`.

### 4.5 Stream and Sync Tests

- [ ] Simulate Firestore stream updates in widget tests.
- [ ] Verify `GameInprogressScreen` updates instantly.
- [ ] Verify no state errors occur during mid-game reconnections.
- [ ] Verify offline queue writes are replayed in FIFO order after connectivity returns.

### 4.6 Firestore Rules Tests

- [ ] Test game mutation rules.
- [ ] Ensure users can only mutate games they created or participate in.
- [ ] Test verified claim restrictions.
- [ ] Ensure other users cannot steal a canonical player.
- [ ] Test contact visibility restrictions.
- [ ] Verify email and phone visibility is properly restricted.
- [ ] Test friend-edge mutation rules.
- [ ] Harden rules around how friend relationships are mutated.
- [ ] Verify friend-edge mutations with rule tests.

---

## Phase 5 — Security, Multi-Contact & Privacy

### 5.1 Split-Identity Rejection

- [ ] Update `Player.resolveCanonicalPlayer` to check both email and phone number.
- [ ] If email resolves to Player A and phone resolves to Player B, reject the claim.
- [ ] Return a `"Contact Conflict"` error.
- [ ] Ensure split-identity rejection also runs inside transactional claim logic.

### 5.2 Double-Claim Prevention

- [ ] Update `Player.canVerifiedAuthUserClaimPlayer`.
- [ ] Reject claims where `claimed_by_uid` is already populated and does not match the current `auth.uid`.
- [ ] Update `claimPlayerForVerifiedAuthUser` to explicitly check `claimed_by_uid` before processing.
- [ ] Prevent account takeovers.

### 5.3 Multi-Contact Support

- [ ] Update `Player` model to support multiple verified contacts.
- [ ] Add `List<String> verifiedEmails`.
- [ ] Add `List<String> verifiedPhones`.
- [ ] Also support schema names:
  - `verified_emails`
  - `verified_phones`
- [ ] Update `player_contacts` collection so a single canonical player can own multiple verified contacts.
- [ ] Define a `ClaimStatus` enum:
  - `none`
  - `pendingVerification`
  - `claimed`

##### 5.4 Account Merge Workflow

*  [ ] Build account merge UI and backend.
*  [ ] Implement a Cloud Function trigger or backend logic to detect contact collisions during `resolveCanonicalPlayer`.
*  [ ] If a user adds a contact already owned by another `player_id`, set status to `pendingVerification`.
*  [ ] Trigger a "Merge Challenge".
*  [ ] Send a clickable verification link to the challenged contact owner.
*  [ ] Develop a "Merge Request" dialog.
*  [ ] **Add a strict UI warning dialog explicitly stating that account merging is permanent and cannot be unmerged.**
*  [ ] **Enforce strict security constraints: Ensure no accounts or contacts can be merged or added to a player profile unless they have been fully verified via Firebase Auth.**
*  [ ] Ensure player records only merge after the challenged contact owner explicitly approves the merge through the link.
*  [ ] Write tests for merge approval.

##### 5.5 Firestore Security Rules (`firestore.rules`)
*  [ ] Overwrite the current default `firestore.rules` configuration with strict schema enforcement.
*  [ ] `match /players/{playerId}`: Prevent `claimed_by_uid` hijacking (cannot overwrite if already claimed by a different UID).
*  [ ] `match /player_contacts/{contactId}`: Restrict visibility and mutation strictly to the owner.
*  [ ] `match /friends/{edgeId}`: Ensure only the `owner_id` or `claimed_by_uid` can mutate friend-edge records.
*  [ ] `match /games/{gameId}`: Restrict game read/write visibility to active participants and the creator.
*  [ ] Enforce verified claims: Ensure only authenticated users with verified contacts can claim matching records.

### 5.6 PII Privacy UI

- [ ] Implement expandable cards in `PlayersScreen`.
- [ ] Refactor `PlayerListItem` to use `ExpansionTile`.
- [ ] Hide email and phone number fields by default.
- [ ] Reveal PII only when the tile is expanded by the user.
- [ ] Add a `"PII Sharing Preferences"` toggle in `PlayerProfileWidget`.
- [ ] Update `PlayerForm` in `player_form_widget.dart` to include a `pii_sharing_prefs` toggle.
- [ ] Use `SwitchListTile` for the PII sharing preference.
- [ ] Respect `pii_sharing_prefs` in the UI.

##### 5.7 Social Login Account Linking & Detection

*  [ ] Implement backend logic to allow linking multiple social login providers (e.g., Google, Facebook, Snapchat, Instagram) to a single canonical `Player` account.
*  [ ] Update the `LoginScreen` and authentication flow to preemptively detect if a newly authenticated social login email or phone matches an existing canonical player record.
*  [ ] Create a "Match Found" UI prompt alerting the user that game history or a player account already exists under a different login method.
*  [ ] Provide an explicit "Link Accounts" UX action, allowing the user to merge the new social login into their existing canonical player, consolidating their game history.
*  [ ] Provide an explicit "Keep Separate" UX action to allow users to intentionally opt-out of linking if they prefer to maintain multiple separate accounts.
*  [ ] Update the `Player` model and `player_contacts` schema to track linked authentication providers.
*  [ ] Integrate this detection and linking UI seamlessly with the existing `ClaimAccountScreen` and Phase 5.4 Account Merge workflows.
*  [ ] **Security Constraint:** Ensure the social login email or phone number is fully verified by Firebase Auth before allowing it to be linked to the canonical player account.
*  [ ] **UX Warning:** Ensure the "Link Accounts" UI includes the same strict warning from 5.4 explicitly stating that linking social accounts is permanent and cannot be undone.

---

## Phase 6 — Customization & User Preferences

### 6.1 Creator-Assigned Nicknames

- [ ] Update `PlayerGameInfo` in `player_game_info.dart`.
- [ ] Add `String? localNickname`.
- [ ] Add or reconcile `nickname_override` field.
- [ ] Decide whether `localNickname` and `nickname_override` should be the same canonical field.
- [ ] Update `toJson`.
- [ ] Update `fromJson`.
- [ ] Persist local / context-specific nicknames.
- [ ] Allow game creators to assign context-specific nicknames during game setup.
- [ ] Implement nickname assignment in `GameStartScreen`.
- [ ] Allow custom player labels within a specific `Game` instance.
- [ ] Do not modify the player’s global canonical nickname when using a game-specific nickname.

---

## Phase 7 — Technical Debt & Refactoring

### 7.1 Optimize `GameCardWidget` Storage Access

- [ ] Refactor `deleteSavedGame` in `game_card_widget.dart`.
- [ ] Stop iterating through every key in `SharedPreferences`.
- [ ] Implement a specific `game_index` key.
- [ ] Or use a UUID-prefix check.
- [ ] Only attempt `jsonDecode` on relevant game records.
- [ ] Ensure `GameCardWidget` no longer performs exhaustive `jsonDecode` iterations on `SharedPreferences`.

### 7.2 Conditional Debug Stripping

- [ ] Wrap expensive `StackTrace` logic in `Utilities.debugPrintWithCallerInfo` with `if (kDebugMode)`.
- [ ] Use a `const bool` to ensure this logic is completely removed from production builds.
- [ ] Optimize production performance.

---

# Part B — Detailed Engineering Appendix

## Appendix A — Source-Equivalent Phase Map

### Original Phase: Immediate Stability

Status: **In Progress**

Description: Hardening CRUD operations, location safety, and coordinate validation.

Consolidated into:

- Phase 1.1 — Harden Database Error Handling
- Phase 1.6 — Course Location Awareness & Duplicate Prevention
- Phase 1.7 — Proximity-Based Sorting and Location Safety

---

### Original Phase: Identity & Local Game Adoption

Status: **In Progress**

Description: Migrating guest data and local JSON strings to authenticated `ContactIdentity` records.

Consolidated into:

- Phase 2.1 — Preserve Nickname-Only and Quick-Play Players
- Phase 2.2 — Normalize Contact Entry Points
- Phase 2.3 — Late Contact Attribution
- Phase 2.4 — Local Game & Guest Adoption Workflow
- Phase 2.5 — Claim Baseline
- Phase 2.6 — Legacy Duplicate Repair

---

### Original Phase: Real-Time Sync

Status: **Planned**

Description: Implementing Firestore `snapshots()` for live multi-user score updates.

Consolidated into:

- Phase 3.1 — Firestore Listener Architecture
- Phase 3.2 — Stream Testing
- Phase 3.3 — Concurrency & Conflict Resolution
- Phase 3.4 — Offline FIFO Synchronization Queue
- Phase 3.5 — Transactional Identity Consistency

---

### Original Phase: E2E Testing

Status: **In Progress**

Description: Executing 4-step identity convergence scenarios from guest-to-auth.

Consolidated into:

- Phase 4.1 — Firebase Emulator Test Setup
- Phase 4.2 — Canonical Player Convergence E2E Scenario
- Phase 4.3 — Expanded Convergence Scenario
- Phase 4.4 — Address and Location Tests
- Phase 4.5 — Stream and Sync Tests
- Phase 4.6 — Firestore Rules Tests

---

### Original Phase: Security & Multi-Contact

Status: **Planned**

Description: Advanced account merging, verification links, and split-identity rejection.

Consolidated into:

- Phase 5.1 — Split-Identity Rejection
- Phase 5.2 — Double-Claim Prevention
- Phase 5.3 — Multi-Contact Support
- Phase 5.4 — Account Merge Workflow
- Phase 5.5 — Firestore Security Rules

---

### Original Phase: Guest Walkthrough & UI/UX

Status: **Planned**

Description: Active sprint for modernizing player selection and enforcing PII privacy.

Consolidated into:

- Phase 1.2 — Modernize Game Creation UI
- Phase 1.3 — Modernize Player Creation and Selection UI
- Phase 1.4 — Fix Player Selection State
- Phase 1.5 — Guest-Aware Navigation Drawer
- Phase 5.6 — PII Privacy UI

---

## Appendix B — Detailed Task Notes by Component

## `GameCreateScreen`

- Redesign screen to match `AddEditCourseScreen`.
- Replace standard `ListTile` widgets.
- Use `_buildSelectionCard` helpers.
- Use `AnimatedContainer`.
- Use `BoxDecoration`.
- Use visual feedback similar to `AddEditCourseScreen._buildHoleCountCard`.
- Use consistent `16.0` border radius.
- Move `"Select Players"` and `"Select Course"` out of `ListView`.
- Prefer bottom sticky action bar or `FloatingActionButton`.
- Preserve selected players and courses across all navigation sub-flows.

---

## `PlayersScreen`

- Accept `List<Player> currentlySelectedPlayers`.
- Preserve selected player state through rebuilds.
- Synchronize with `GameCreateScreenState`.
- Return updated selected player list correctly.
- Add `"Deselect All"` / `"Clear All"` behavior.
- Add `"Clear All"` button to `AppBar`.
- Improve button placement for thumb reach.
- Add expandable cards or `ExpansionTile` to hide PII.
- Hide email and phone by default.
- Reveal PII only when expanded.
- Use Material 3 / Teal design language.
- Add card-based UI:
  - `elevation: 0`
  - `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))`
  - `Colors.teal.shade50`
- Use `BouncyAnimation` while loading players.
- Use rounded `LinearProgressIndicator`.

---

## `PlayerCreateScreen`

- Modernize from basic form into card-based or step-based UI.
- Align with `CoursesScreen` card style.
- Match Material 3 / Teal design.
- Preserve quick-play and nickname-only player flows.

---

## `PlayerForm`

- Bypass mandatory email / phone validation when `isQuickPlay == true`.
- Use `ContactIdentity.normalizeEmail`.
- Use `ContactIdentity.normalizePhoneNumber`.
- Normalize before all database writes.
- Add `pii_sharing_prefs` with `SwitchListTile`.

---

## `PlayerProfileWidget`

- Add `"PII Sharing Preferences"` toggle.
- Ensure UI respects PII sharing setting.

---

## `PlayerListItem`

- Refactor to `ExpansionTile`.
- Hide sensitive fields by default.
- Reveal email and phone only on expansion.

---

## `Player` Model

- Preserve `playerName` and `nickname` only creation.
- Default `ownerId` to creator UID or `'guest'`.
- Add `isQuickPlay`.
- Add support for:
  - `verifiedEmails`
  - `verifiedPhones`
  - `verified_emails`
  - `verified_phones`
- Support multiple verified contacts.
- Add or support `ClaimStatus`.
- Ensure canonical player ownership rules are enforced.
- Ensure claim logic detects:
  - reserved contacts
  - double claims
  - split identities
  - pending merge challenges

---

## `PlayerGameInfo`

- Add `String? localNickname`.
- Add or reconcile `nickname_override`.
- Update `toJson`.
- Update `fromJson`.
- Persist context-specific nicknames.
- Allow per-game display labels without changing global player nickname.

---

## `GameStartScreen`

- Allow game creator to assign context-specific player nicknames.
- Persist these nicknames in `PlayerGameInfo`.

---

## `GameInprogressScreen`

- Replace local-only / `SharedPreferences` lookups.
- Replace `FutureBuilder`.
- Use real-time Firestore `snapshots()`.
- Add nested `StreamBuilder` widgets:
  1. Game document stream for metadata and status.
  2. `PlayerGameInfo` sub-collection stream for scores.
- Support:
  - mid-game reconnections
  - multi-device updates
  - remote score updates
  - offline resiliency
- Remove manual `_updateGame` UI refresh calls.
- UI should reflect Firestore snapshot state only.

---

## `Game` Model

- Add `fromSnapshot(DocumentSnapshot)` factory.
- Implement / refactor `adoptLocalGames`.
- New signature:

```dart
adoptLocalGames(Player loggedInUser, List<String> gameIdsToAdopt)
```

- Deprecate automatic local adoption loop.
- Update `saveLocalGame` to parse JSON strings in `SharedPreferences`.
- Replace legacy guest IDs with canonical IDs.
- Add `recordScore` support for `last_updated`.
- Use Firestore `serverTimestamp`.
- Merge remote updates non-destructively when remote `last_updated` is newer.

---

## `GameCardWidget`

- Catch Firestore failures during `getLocallySavedGames`.
- Display `SnackBar` when remote sync is temporarily unavailable.
- Refactor `deleteSavedGame`.
- Stop scanning every `SharedPreferences` key.
- Use `game_index` or UUID-prefix filtering.
- Only decode relevant game records.
- Avoid exhaustive `jsonDecode` iterations.

---

## `CoursesScreen`

- Catch `DatabaseConnectionError`.
- Replace loading-only ternary logic.
- Add `_connectionError != null` state.
- Render `"Fairway Unreachable"` persistent error UI.
- Add `"Retry"` callback.
- Run `_getCurrentLocation()` and `_initializeCourses()` concurrently.
- Use `Future.wait` or equivalent.
- Verify `mounted` before UI updates.
- Re-sort list after GPS lock.
- Use high-accuracy `LocationSettings`.
- Catch `TimeoutException`.
- Use `5-second timeLimit`.
- Show non-blocking `SnackBar` or status icon on timeout.

---

## `AddEditCourseScreen`

- Implement `_showAddressCaptureBottomSheet`.
- Add address controllers:
  - `streetController`
  - `cityController`
  - `stateController`
  - `zipController`
- Perform background geocoding.
- Fix coordinate capture failure.
- Implement `_findConflictingCourses`.
- Use Haversine formula.
- Use `100-meter` threshold.
- Trigger `_showLocationConflictDialog`.
- Add normalized address substring matching.
- Support duplicate detection without coordinates.
- Allow choosing an existing course.
- Allow bypassing conflict to create secondary course.
- Support multi-course facilities.

---

## `UserProvider`

- Decouple migration from login.
- After login, show import prompt.
- Allow users to choose local games and friends to import.
- Implement `"Merge Games Found"` dialog.
- Trigger `ClaimAccountScreen` when claimable contacts/history exist.
- Ensure authenticated adoption does not automatically merge without user choice.

---

## `ClaimAccountScreen`

- Used when guest signs up and matching contact/history exists.
- Supports guest-to-auth convergence.
- Verification must merge local and remote history into a canonical player.
- Must not create duplicate player records.

---

## `ContactIdentity`

- Source of truth for contact normalization.
- Required for:
  - `PlayerForm.saveChanges`
  - `Player.updateUnclaimedPlayer`
  - claim flows
  - contact reservation checks
- Must normalize:
  - email
  - phone number
- Used before every contact-related database write.

---

## `player_contacts` Collection

- Source of truth for contact ownership and reservation.
- Must prevent adopting contacts already reserved by another canonical record.
- Must prevent hijacking.
- Must support one canonical player owning multiple verified contacts.
- Visibility must be restricted by Firestore rules.
- Mutations must be restricted to owner / valid claimant.

---

## `firestore.rules`

- Enforce verified claims.
- Prevent `claimed_by_uid` hijacking.
- Restrict `player_contacts` visibility.
- Restrict game visibility to participants.
- Restrict friend-edge mutations.
- Ensure only `owner_id` or `claimed_by_uid` can modify player metadata where appropriate.
- Validate with `@firebase/rules-unit-testing`.

---

## `Utilities.debugPrintWithCallerInfo`

- Wrap expensive `StackTrace` logic in `if (kDebugMode)`.
- Use a `const bool` so production builds strip the logic.
- Improve production performance.

---

# Appendix C — Required Test Plan

#### Unit Tests

*  [x] Achieve 100% unit test coverage for `userprovider.dart` (including line 180 null user boundary).
*  [x] Achieve 100% unit test coverage for `claim_account_screen.dart` (including generic exception handling).
*  [ ] Player.createPlayer nickname-only creation.
*  [ ] PlayerForm quick-play validation bypass.
*  [ ] ContactIdentity.normalizeEmail.
*  [ ] ContactIdentity.normalizePhoneNumber.
*  [ ] Player.updateUnclaimedPlayer contact reservation checks.
*  [ ] Player.resolveCanonicalPlayer split-identity rejection.
*  [ ] Player.canVerifiedAuthUserClaimPlayer double-claim prevention.
*  [ ] PlayerGameInfo.toJson with local nickname.
*  [ ] PlayerGameInfo.fromJson with local nickname.
*  [ ] Game.fromSnapshot.
*  [ ] Game.recordScore with last_updated.
*  [ ] FIFO SyncQueue.
*  [ ] GameCardWidget.deleteSavedGame targeted storage lookup.
*  [ ] _findConflictingCourses Haversine threshold.
*  [ ] Normalized address substring matching.

---

## Widget Tests

- [ ] `PlayersScreen` preserves selected players across rebuilds.
- [ ] `PlayersScreen` receives `currentlySelectedPlayers`.
- [ ] `PlayersScreen` clears all selected players.
- [ ] `GameCreateScreen` receives returned selected players.
- [ ] `PlayerListItem` hides PII by default.
- [ ] `PlayerListItem` reveals PII on expansion.
- [ ] `PlayerForm` shows PII sharing toggle.
- [ ] `GameInprogressScreen` responds to stream updates.
- [ ] `GameInprogressScreen` avoids out-of-bounds errors.
- [ ] `GameInprogressScreen` avoids state errors.
- [ ] `CoursesScreen` renders `"Fairway Unreachable"` error state.
- [ ] `CoursesScreen` retry callback works.
- [ ] `_showAddressCaptureBottomSheet` validates empty street.
- [ ] `_showAddressCaptureBottomSheet` validates empty city.
- [ ] `"Add Second Course Anyway"` flow works.

---

## Integration / E2E Tests

- [ ] Firebase Local Emulator Suite is configured.
- [ ] Remote game exists with canonical player.
- [ ] Guest creates local game with matching contact.
- [ ] Guest signs up.
- [ ] Guest verifies through `ClaimAccountScreen`.
- [ ] Remote and local games converge onto same canonical player.
- [ ] No duplicate player records are created.
- [ ] Firestore stream updates propagate to UI.
- [ ] Offline queue replays writes in FIFO order.
- [ ] Merge approval only completes after challenged owner approves verification link.
- [ ] Location conflict detects courses within `100 meters`.
- [ ] Address conflict works without coordinates.
- [ ] User can create a secondary course at same location.

---

## Firestore Rules Tests

- [ ] Users can mutate only games they created or participate in.
- [ ] Non-participants cannot read restricted games.
- [ ] Verified claims prevent player theft.
- [ ] `claimed_by_uid` cannot be hijacked.
- [ ] Contact visibility is restricted.
- [ ] Email visibility is restricted.
- [ ] Phone visibility is restricted.
- [ ] Friend-edge mutations are restricted.
- [ ] `player_contacts` writes require valid ownership or verified claim.

---

# Appendix D — Final Definition of Done

- [ ] The 4-step identity convergence regression scenario passes in the automated test suite.
- [ ] Selected players and selected courses persist across all `GameCreateScreen` navigation sub-flows.
- [ ] Contact normalization is applied through `ContactIdentity` before every relevant database write.
- [ ] Legacy JSON storage is repaired.
- [ ] Guest/local records migrate only through explicit user-approved import flows.
- [ ] PII is hidden behind expandable widgets by default.
- [ ] `pii_sharing_prefs` is respected in the UI.
- [ ] `GameCardWidget` no longer performs exhaustive `jsonDecode` iterations on `SharedPreferences`.
- [ ] `DatabaseConnectionError` is handled without infinite loading spinners.
- [ ] Courses can be detected as duplicates by both GPS proximity and normalized address matching.
- [ ] Real-time score updates work across multiple devices.
- [ ] Offline writes are queued and replayed in FIFO order.
- [ ] Double-claiming is prevented.
- [ ] Split-identity conflicts are caught during claim flow.
- [ ] Multi-contact ownership is supported.
- [ ] Account merge requires challenged owner approval.
- [ ] Firestore rules enforce claim, contact, game, and friend-edge restrictions.

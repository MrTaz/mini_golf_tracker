# Mini Golf Score Tracker — Master Development Roadmap & TODO List

## 1. Project Overview

This roadmap consolidates all active TODOs, enhancement plans, testing plans, and architectural notes for the Mini Golf Score Tracker.

**Executive Directive:** Eliminate legacy technical debt in data persistence while scaling the identity system to support multi-contact verification, real-time multiplayer synchronization, location-aware course safety, and modern ergonomic UI requirements.

---

## 2. Progress Tracking

| Phase | Status | Description |
| --- | --- | --- |
| Phase 1 — Immediate Stability & Guest Experience | In Progress | Harden CRUD operations, location safety, coordinate validation, database error handling, guest UX, and UI modernization. |
| Phase 2 — Identity & Local Game Adoption | In Progress | Migrate guest data and local JSON strings to authenticated `ContactIdentity` / canonical player records. |
| Phase 3 — Real-Time Sync & Data Integrity | Planned | Implement Firestore `snapshots()` for live multi-user score updates and offline-safe sync. |
| Phase 4 — E2E Regression & Integrity Testing | In Progress | Execute identity convergence, location conflict, stream, and emulator-based regression scenarios. |
| Phase 5 — Security, Multi-Contact & Privacy | Planned | Implement account merging, verification links, double-claim prevention, split-identity rejection, and PII protections. |
| Phase 6 — Customization & Preferences | Planned | Add creator-assigned nicknames and player-specific display preferences. |
| Phase 7 — Technical Debt & Performance | Planned | Refactor inefficient storage access, debug-only behavior, and legacy SharedPreferences handling. |

---

## Part A — Condensed Master TODO Roadmap

### Phase 1 — Immediate Stability, Guest Experience & UI Modernization

#### 1.1 Harden Database Error Handling

* [x] Wrap `UserProvider.initialize` `authStateChanges` listener in a try-catch block to prevent `DatabaseConnectionError` crashes on startup.
* [x] Harden `ClaimAccountScreen._refreshClaim()` with a generic catch block to gracefully handle database/network failures without crashing.
* [x] Implement comprehensive try-catch blocks in GameCardWidget and CoursesScreen to intercept DatabaseConnectionError.
* [x] In CoursesScreen, replace the current _isLoading && courses.isEmpty ternary logic with an explicit error-state check such as_connectionError != null.
* [x] Render a persistent "Fairway Unreachable" UI state with a "Retry" callback when course loading fails.
* [x] In GameCardWidget, catch Firestore failures during getLocallySavedGames.
* [x] Display a SnackBar using ScaffoldMessenger when remote sync is temporarily unavailable.

#### 1.2 Modernize Game Creation UI

* [x] Redesign `GameCreateScreen` to match the design language of `AddEditCourseScreen`.
* [x] Replace standard `ListTile` widgets for course and player selection with custom `_buildSelectionCard` helpers.
* [x] Use `AnimatedContainer` and `BoxDecoration` patterns from `AddEditCourseScreen._buildHoleCountCard`.
* [x] Provide haptic-like visual feedback, elevation styling, and consistent border radius.
* [x] Use a consistent border radius of `16.0` for `GameCreateScreen` selection cards.
* [x] Move `"Select Players"` and `"Select Course"` triggers out of the `ListView`.
* [x] Place selection actions in a bottom sticky action bar or `FloatingActionButton` for better one-handed accessibility.

#### 1.3 Modernize Player Creation and Selection UI

* [x] Refactor `PlayerCreateScreen` and `PlayersScreen` to align with the Material 3 / Teal design language.
* [x] Use `Card` widgets with:
  * `elevation: 0`
  * `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))`
  * `Colors.teal.shade50` background accents
* [x] Mirror the aesthetic of `_buildHoleCountCard`.
* [x] Reposition the `"Select Players"` button in `PlayersScreen` for better thumb reach and accessibility.
* [x] Implement `BouncyAnimation` for loading states during player fetch operations.
* [x] Use `LinearProgressIndicator` with `20.0` / `24.0` corner radius for async fetches.
* [x] Transform the basic `PlayerCreateScreen` form into a step-based or card-based UI aligned with `CoursesScreen` cards.

#### 1.4 Fix Player Selection State

* [x] **State Injection Bug Fix:** In `GameCreateScreen._selectPlayers()`, remove the `&& selectedPlayers.isNotEmpty` condition so that empty lists (cleared players) are accepted and successfully overwrite the previous selection.
* [x] **PlayerListItem State Sync Fix:** In `PlayerListItemState` (`player_list_item.dart`), implement `didUpdateWidget(covariant PlayerListItem oldWidget)` to update the local `isSelected` variable whenever `widget.isSelected` changes so the "Clear All" button visually unchecks the switches.
* [x] **E2E Regression Test:** Write an integration test (`integration_test/player_selection_flow_test.dart`) that explicitly selects players, returns to the create screen, opens the player screen again, clears all players, and verifies the create screen correctly updates to 0 players.
* [x] Ensure selectedPlayers in PlayersScreen persists through rebuilds.
* [x] Synchronize selectedPlayers correctly with parent GameCreateScreenState.
* [x] Modify PlayersScreen to accept a List\<dynamic> currentlySelectedPlayers parameter.
* [x] Ensure GameCreateScreen passes its current selected-player state into PlayersScreen.
* [x] Add a "Deselect All" or "Clear All" action in PlayersScreen.
* [x] Add "Clear All" to the AppBar of PlayersScreen.
* [x] Reset the selectedPlayers list instantly when clearing selections.

#### 1.5 Unified Smart Navigation Drawer

* [x] Refactor `_buildDrawerList` in `main.dart` to provide a consistent menu for both Guests and Auth users.
* [x] **Dynamic Header:**
  * Auth: Show `UserAccountsDrawerHeader` with name, email, and "Edit Profile" action (pointing to `PlayerDetailsScreen`).
  * Guest: Show "Guest Profile" placeholder with a "Sign In / Sign Up" call to action.
* [x] **Dynamic 'Current Game' Item:**
  * If an active game exists: Show "Resume Active Game" and navigate to `GameInprogressScreen`.
  * If no active game exists: Show "No current game" (with a subtitle like "Tap to start playing") and navigate to `GameCreateScreen`.
* [x] **Universal Navigation Items:**
  * Add menu items for: "Friends", "Scheduled Games", and "Past Games".
  * *Remove* "Courses" from the main drawer to reduce clutter.
* [x] **Open Routing for Guests (Local Data):**
  * Guests must be allowed to navigate to `Friends` and `Past Games` to view their locally saved data [1].
  * Instead of blocking navigation via the drawer, conversion prompts (e.g., "Sign in to backup your history") should be placed as banners or cards *inside* those specific screens later.
* [x] **Gated Feature (Scheduled Games):**
  * If Auth: Navigate to the `ScheduledGamesScreen`.
  * If Guest: Tapping "Scheduled Games" redirects to the `LoginScreen` with a prompt: "Sign up to schedule future rounds and sync with friends."

#### 1.6 Course Location Awareness & Duplicate Prevention

* [x] Implement the technical rules from course-location-awareness.md inside AddEditCourseScreen.
* [x] Populate the skeletal _showAddressCaptureBottomSheet method.
* [x] Add:
  * streetController
  * cityController
  * stateController
  * zipController
* [x] Resolve current coordinate capture failure.
* [x] Perform geocoding in the background.
* [x] Implement _findConflictingCourses using the Haversine formula.
* [x] Trigger _showLocationConflictDialog when an existing course is within 100 meters.
* [x] Add normalized address substring matching.
* [x] Identify duplicates even when coordinates are unavailable.
* [x] Ensure "53 Carter Hill" can match "53 Carter Hill Rd".
* [x] Allow users to select an existing course at the location.
* [x] Allow users to bypass the conflict and create a secondary course for multi-course facilities.
* [x] Support secondary course examples such as "Fire Tower Course" vs. "Case Course" at the same GPS coordinate.
* [x] Add tests for the "Add Second Course Anyway" flow.

#### 1.7 Proximity-Based Sorting and Location Safety

* [x] In `CoursesScreen.initState`, trigger `_getCurrentLocation()` and `_initializeCourses()` concurrently.
* [x] Use `Future.wait` or equivalent to prevent UI blocking.
* [x] Ensure all UI-updating callbacks verify `mounted` before executing.
* [x] Re-sort the `CoursesScreen` list immediately after a successful GPS lock.
* [x] Use high-accuracy `LocationSettings`.
* [x] Update `_getCurrentLocation` in `courses_screen.dart` to explicitly catch `TimeoutException`.
* [x] Use `locationSettings` with a `5-second timeLimit`.
* [x] Display a non-blocking `SnackBar` or status icon if the timeout triggers.
* [x] Do not fail silently on location timeout.

#### 1.8 Active Game Auto-Launch & Navigation Flow (Critical)

* [x] **Global Active Game Auto-Launch:** Update `HomePage._updateState()` in `main.dart` to check for an active local game via `Game.getLocallySavedGames(gameStatusTypes: ["started"])`.
* [x] If a "started" game exists for **ANY user (Guest or Auth)**, immediately set the body to `GameInprogressScreen` to ensure the round persists across app restarts.
* [x] **Dynamic Bottom Navigation:** Modify `DashboardScreen` to hide the `BottomNavigationBar` if `UserProvider().loggedInUser` is null.
* [x] **Game Creation Redirect:** Refactor `GameCreateScreen` and `GameStartScreen` so that upon clicking "Start," the app pushes `GameInprogressScreen` immediately instead of popping to the home screen.
* [x] **Subscriber-Gated Scheduling UI:** In `GameStartScreen` and `GameCreateScreen`, implement a "Locked" state for the "Start Time" selection for non-subscribers.
* [x] **Read-Only Implementation:** If the user is a Guest, the date and time picker should be disabled and locked to `DateTime.now()`.
* [x] If a Guest: Intercept the "Schedule Game" action (`btnScheduleGame`) and redirect to the `LoginScreen`.
* [x] **Conversion Call-to-Action:** Intercept taps on the locked "Start Time" section to show an informational message (e.g., "Upgrade to Premium to schedule games for the future!") with a link to the signup/subscription screen.
* [x] Only allow authenticated users to persist games with an `unstarted_game` status into the future.

#### 1.9 Drawer Activity Previews (Scheduled & Recent Games)

* [x] **Activity Fetch Logic:** Implement helper methods in `Game` or `main.dart` to retrieve:
  * Up to 5 "unstarted_game" records scheduled for the future, ordered by `scheduled_time` ascending.
  * Up to 5 "completed" records, ordered by `completed_time` descending.
* [x] **Scheduled Games Section (Auth/Premium):**
  * Show the "Scheduled Games" header ListTile that navigates to the full list.
  * Inject up to 5 sub-items (indented or smaller text) showing "Game Name - Date".
  * Tapping a sub-item navigates directly to `GameStartScreen` for that specific game.
* [x] **Scheduled Games Section (Guest / Locked Preview):**
  * Keep the "Scheduled Games" header visible.
  * Instead of fetching games, display a single, locked sub-item: "🔒 Sign up to schedule future rounds."
  * Tapping this sub-item routes the guest directly to the `LoginScreen`.
* [x] **Recent History Section:**
  * Add a "Past Games" header ListTile that navigates to `PastGamesScreen`.
  * Inject up to 5 sub-items showing "Course Name - Score/Result" (for both Guests and Auth users to view local/synced data).
  * Tapping a sub-item navigates directly to `PastGameDetailsScreen`.
* [x] **Guest UX Intercept (Past Games):**
  * For Guests: If the user taps a specific past game detail, trigger the `LoginScreen` prompt to "Save this history to the cloud."
* [x] **UI Tidiness:** Use a `Divider` between these activity sections and standard navigation links to maintain a clean visual hierarchy.
* [x] **Add Context to Guest Intercepts:** Update the `AppDrawer` guest intercepts to pass specific `promptMessage` strings to the `LoginScreen` ("Save this history to the cloud" and "Sign up to schedule future rounds"), render them in a highly visible banner above the login form, and prove the flow works via an E2E integration test.

#### 1.10 Guest UX Hardening & Navigation Fixes

* [x] **Past Game Details Default State:** In `PastGameDetailsScreen.initState`, pre-populate the `clickedPlayer` and `clickedPlayerScores` lists with all the players from `widget.passedGame`. This ensures the `PlayerScoreDataTable` is fully visible upon opening rather than rendering an empty grey box.
* [x] **Conditional AppBars for Guests:** In `PastGamesScreen` and `PlayersScreen`, dynamically render the `appBar` property based on authentication status.
* [x] If `UserProvider().loggedInUser == null` (Guest), return a standard `AppBar` with a title ("Friends" or "Past Games") so the `Navigator.push` automatically provides a back navigation arrow.
* [x] If Authenticated, keep `appBar: null` so the screens continue to rely seamlessly on the `BottomNavigationBar` within the `DashboardScreen`.

#### 1.11 Game Start Screen UX & Logic Fixes

* [x] **Fix Blank Player Tiles:** In `GameStartScreen`, fix the player lookup logic so that it properly loads player names and data from local storage or the `unstartedGame` object, rather than falling back to `Player.empty()`.
* [x] **Default Avatar Unification:** In `PlayerListItem._buildPlayerProfileCircleIcon`, replace the fallback `Text('?')` logic with the standard `assets/images/avatars_3d_avatar_28.png` image for users without a Gravatar.
* [x] **Explicit Drag Handles:** In `GameStartScreen._buildPlayerOrderSection`, add an `Icons.drag_handle` to the right side of the `PlayerListItem` to make reordering visually obvious and instantly draggable without a long-press.
* [x] **Course Selection Redesign:** Redesign `_buildSelectCourseCard()` in `GameStartScreen` to match the "Add players" button layout. Remove the confusing `Icons.edit` pencil icon from the course tile. Instead, add a `Row` at the bottom of the card with `mainAxisAlignment: MainAxisAlignment.end` containing an `ElevatedButton` that says "Select course" (or "Change course") which triggers the `_selectCourse()` action.

#### 1.12 Course Creation & Map Enhancements

* [ ] **Course Model Update:** Add a `locationName` (Business Name) field to the `Course` model, distinct from the `name` (Course Name). Update `toJson`, `fromJson`, and `fromMap`.
* [ ] **Hide Raw GPS:** In `AddEditCourseScreen` and `CoursesScreen` detail views, remove the display of raw latitude and longitude coordinates.
* [ ] **Address Search:** In `MapPickerScreen`, add a search bar at the top that uses the `geocoding` package to convert a typed address into coordinates, jumping the map to that location.
* [ ] **Fix Course Dropdown Overflow:** In `CourseListItem`, replace the rigid `GridView.builder` for par values with a responsive `Wrap` or dynamic grid to eliminate the "BOTTOM OVERFLOWED" Flutter UI error.
* [ ] **Enhanced Details:** Display the "Total Par" and the new "Location Name" inside the `CourseListItem` dropdown details.

#### 1.13 Game In-Progress UI & Logic Overhaul

* [x] **Auto-Resume Guest Profile Hydration:** In `main.dart`'s `_checkAndAutoResumeActiveGame()`, add `await Player.loadLocalGuestPlayers();` before the `setState` to ensure guest names and avatars load immediately on app startup.
* [x] **Drawer Active Game Routing Fix:** Update the drawer's "Active Game" button so it does not use `Navigator.push`. If the user has an active game, it should use `changeBodyCallback` to set the body to `GameInprogressScreen`, preventing nested routes and unwanted back arrows.
* [x] **Guest Drawer Navigation Fix:** In `main.dart`'s `_buildDrawerList`, add a "Home" `ListTile` (with an `Icons.home` icon) that resets the body to `HomeScreen()`. Add a dedicated "Sign In / Sign Up" `ListTile` (with an `Icons.login` icon) that explicitly routes to the `LoginScreen`.
* [x] **DRY Avatar Abstraction:** Create a new `PlayerAvatarWidget` to serve as the single source of truth for avatar rendering. It should encapsulate the `CircleAvatar`, `GravatarImageView`, and the unified `assets/images/avatars_3d_avatar_28.png` fallback logic.
* [x] **Avatar Unification & Implementation:** Refactor `PlayerListItem`, `PlayerProfileWidget`, the mid-game player list in `GameInprogressScreen`, and the `UserAccountsDrawerHeader` in `main.dart` to strictly use the new `PlayerAvatarWidget`. For the guest drawer, wrap the new widget in a `GestureDetector` that routes to the `LoginScreen`.
* [x] **In-Game Conversion Hook:** Conditionally render a freemium banner directly below the Course Card in `GameInprogressScreen` if `UserProvider().loggedInUser == null`. The banner should read *"Playing as a Guest. Sign up to save your score to the cloud!"* and route the user to the `LoginScreen` when tapped.
* [x] **In-Game AppBar Options (Pause/End/Abandon):** Add a `PopupMenuButton` to the `AppBar` of `GameInprogressScreen` with three actions:
  * **"Pause Game":** Navigates back to `HomeScreen` (putting the game on hold).
  * **"End Game Early":** Displays a confirmation `AlertDialog` warning that the game will be finalized and cannot be reopened. The dialog must include three actions: **"Cancel"**, **"Pause Game instead"** (navigates to HomeScreen), and **"End Game"** (calls `_handleGameCompletion()`).
  * **"Abandon Game":** Displays a strict confirmation `AlertDialog` warning the user of permanent data loss. If confirmed, calls `deleteSavedGame` and navigates back to `HomeScreen`.
* [x] **Persistent Score Saving (Fix Progress Loss):** In `game_inprogress_screen.dart`, add `await Game.saveLocalGame(widget.currentGame);` to the `_updateGame()` method. Ensure `_updateGame()` is triggered every time a player's score is adjusted so progress is not lost on restart.
* [x] **Fix Score Default Bug:** In `_buildPlayerCard`, change the fallback logic so unrecorded scores start at `0` instead of `1`.
* [x] **UI Rescaling:** Redesign the score row in `_buildPlayerCard`. Reduce the size of the +/- buttons and give the "Current score" text more horizontal space so it is easily readable.
* [x] **Bidirectional Hole Navigation:** Add a "Previous Hole" button next to the "Next Hole" button. Allow users to navigate freely between holes regardless of whether all scores are entered.
* [x] **Skipped/Dropped Players Rule:** Implement logic where if the scorekeeper navigates to the next hole leaving a player's score at `0`, that player is automatically assigned a Max Score of `6` for that hole (which can be edited if they navigate back). Add a visual "Skip/Drop" toggle for players.

#### 1.14 Gameplay Rules & Scoring Edge Cases

* [ ] **Handle Multiple Winners (Ties):** Refactor `Game.getWinner()` in `game.dart` to return a `List<PlayerGameInfo> getWinners()` to account for ties.
* [ ] **Winner UI Updates:** Update `PastGameListItem` and `PastGamesListView` to handle and display multiple winners (e.g., "Winners: Alice, Bob" instead of "Winner: Alice").
* [ ] **Start Screen Player Toggles:** Fix the commented-out `addPlayerToGame`/`removePlayerFromGame` logic in `PlayerListItem` so that toggling the Switch during game creation properly mutates the selected players list.
* [ ] **Creator Participation Rule:** Implement a validation rule in `GameStartScreen` to warn or prevent a game from starting if the Game Creator has not added themselves to the player list.
* [ ] **Score Initialization Safety:** Re-implement the safety check in `Game.calculateTotalScore` to gracefully handle or initialize scores if `!scores.containsKey(player)` evaluates to true.

#### 1.15 Friends List & Player Form Polish

* [ ] **Remove UUID from Header:** In `player_form_widget.dart`, update the edit mode header to simply read "Edit Player Attributes" without concatenating `widget.player!.id`.
* [ ] **Remove Status Field:** In `player_form_widget.dart`, remove the `_statusController` and its associated `TextFormField` from the UI.
* [ ] **Dynamic Edit/Cancel Icon:** In `player_list_item.dart`, update the edit icon logic in `_buildTrailingIcons()`. If `isDropdownOpen` is true, display `Icons.close` (to indicate cancel); otherwise, display `Icons.edit`.
* [ ] **Expandable Player Details:** Update `PlayerListItem` so that if `creatingGame` is false, tapping the `ListTile` expands a read-only view of the player's saved details (Email, Phone, Total Score), satisfying the PII privacy requirements from Phase 5.6.
* [ ] **PlayerCreateScreen Form Polish:** Redesign the embedded "Add a new player" form inputs to look modern, well-spaced, and visually cohesive with the new Material 3 card aesthetic introduced in Phase 1.3.

#### 1.16 Auto-Resume Race Conditions & Concurrency Fixes

* [ ] **Multiple Active Games Warning:** In `GameCreateScreen._createGame` and `GameStartScreen._startGame`, check if a game with status `"started"` already exists. If so, display an `AlertDialog` warning the user: *"You already have a game in progress. Starting a new game will put your current game on hold."* requiring them to tap "Continue" to proceed.
* [ ] **Auto-Resume Sorting Fix:** In `main.dart`'s `_checkAndAutoResumeActiveGame()`, sort the retrieved `activeGames` by `scheduledTime` descending before calling `.first!` to ensure the app reliably auto-resumes the most recently created active game instead of a random one.
* [ ] **Auth-Only Scheduling Conflict Detection:** For authenticated users in `GameStartScreen._scheduleGame` and `GameCreateScreen._createGame`, fetch all existing `"unstarted_game"` records. If the newly selected `scheduledTime` falls within 2 hours of an existing scheduled game where the current user is a participant, display a warning `AlertDialog`: *"Scheduling Conflict: You already have a game scheduled near this time. Do you want to double-book?"* requiring explicit confirmation to proceed.

#### 1.17 In-Game Educational Tooltips & Lifecycle Hooks

* [ ] **App Lifecycle Observer:** In `GameInprogressScreenState`, mix in `WidgetsBindingObserver` and implement `didChangeAppLifecycleState`. Detect when the app transitions to `AppLifecycleState.resumed`.
* [ ] **Dynamic Idle Interaction Timer:** Wrap the root `Scaffold` of `GameInprogressScreen` in a `Listener` to detect user touches. Implement a `Timer` that resets on every touch. The timer's duration should be dynamically calculated based on the active player count (e.g., `widget.currentGame.players.length * 3` minutes) to accommodate larger groups safely.
* [ ] **Pause Reminder Coach Mark:** Create a dismissible, highly visible chat bubble or tooltip pointing to the AppBar's `PopupMenuButton` with the text: *"Need a break? You can safely pause your game here!"*
* [ ] **Trigger Logic:** Display the Pause Reminder Coach Mark automatically if the user resumes the app from the background OR if the dynamic idle timer fires. Ensure the bubble disappears as soon as the user taps anywhere on the screen.

#### 1.18 Silent Pace of Play Data Collection

* [ ] **Model Expansion:** Update the `PlayerGameInfo` model in `player_game_info.dart` to include a `List<String>? scoreTimestamps` field to hold ISO-8601 timestamp strings. Update the `toJson` and `fromJson` methods to safely parse this new list so it is entirely backwards compatible with existing local storage.
* [ ] **Timestamp Injection:** Update `Game.recordScore()` (and any mid-game `setState` scoring logic in `game_inprogress_screen.dart`) to automatically capture `DateTime.now().toIso8601String()` and append it to the player's `scoreTimestamps` array whenever a score is locked in.

#### 1.19 Post-1.2 Bug Fixes & UX Polish

* [x] **Score Increment Fix:** In `GameInprogressScreen` (or the underlying scoring logic), fix the `+` button behavior so that tapping it when a player's score is `0` correctly increments the score to `1` instead of jumping to `2`.
* [x] **Avatar Fallback Fix:** In `PlayerAvatarWidget` (`player_avatar_widget.dart`), remove the `Text(player.nickname.toUpperCase())` fallback entirely. Ensure that any player without a valid Gravatar strictly displays the `assets/images/avatars_3d_avatar_28.png` image to eliminate the green initial circles.
* [x] **Reusable App Drawer:** Extract the side menu logic (`_buildDrawerList`, `_buildUserAccounts`, etc.) out of `main.dart` and into a standalone, reusable `AppDrawer` widget (e.g., `lib/app_drawer_widget.dart`).
* [x] **Guest Menu Bar Access:** Add the newly abstracted `AppDrawer` widget to the `Scaffold` of `PastGameDetailsScreen` (and any other standalone screens) so guests can always access the side menu, even on pushed routes.
* [x] **Drawer State Desync:** Fix the state management in `HomePage` (`main.dart`) or the new `AppDrawer` so that when the user returns to the home screen from creating or playing a game, the drawer's "Active Game" FutureBuilder is immediately refreshed without needing to click other menu items first.

#### 1.20 Auth & Verification Blocker Fixes

* [x] **Test Account Bypass:** In `UserProvider` or `Player.canVerifiedAuthUserClaimPlayer`, implement a debug-only or specific email bypass (e.g., automatically treating `test@example.com` as verified) so developers and E2E tests can successfully log in and bypass the `ClaimAccountScreen`.
* [x] **Real Google Sign-In:** In `login_screen.dart`, completely remove the `_simulateSocialLogin` and `_handleGoogleLogin` mock methods. Implement the actual `GoogleSignIn` SDK flow to authenticate users using their real Google accounts.
* [x] **Auth E2E Tests:** Write a new integration test (`integration_test/auth_login_flow_test.dart`) that verifies the email/password login flow successfully bypasses verification for test accounts and successfully reaches the Dashboard.
* [x] **Fix Google Sign-In Client ID:** In `lib/login_screen.dart`, update the `GoogleSignIn` instantiation to explicitly include the `serverClientId` (your Firebase Web Client ID) to resolve the `clientConfigurationError` on Android.
* [x] **Fix Firestore Login Permission Denied:** Update `firestore.rules` to permit read access to the `player_contacts` collection, or handle the `PERMISSION_DENIED` exception gracefully during the test-account bypass flow so the app does not crash.
* [x] **Restore Social Login Placeholders:** In `lib/login_screen.dart`, restore the Facebook, Snapchat, and Instagram login providers, but configure their callbacks to return a "Not implemented yet" message to the user.

#### 1.21 Android KGP Migration (Tech Debt)

* [x] **Migrate `build.gradle.kts`:** Follow the official Flutter breaking-changes guide (<https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers>) to remove the explicit Kotlin Gradle Plugin from the Android app-level build file.
* [x] **Upgrade KGP Plugins:** Check the changelogs and bump the versions in `pubspec.yaml` for `google_sign_in_android`, `package_info_plus`, `shared_preferences_android`, and `url_launcher_android` to versions that support Built-in Kotlin.
* [x] **Android Predictive Back Support:** Add `android:enableOnBackInvokedCallback="true"` to `android/app/src/main/AndroidManifest.xml` to clear the `WindowOnBackDispatcher` warning.

#### 1.22 Post-Auth Polish & Database Connectivity

* [x] **Fix UserProvider Test Bypass:** In `lib/userprovider.dart`, update the `authStateChanges` listener and `refreshPendingClaim()` to accept `user.emailVerified || Utilities.isTestAccountBypass(user.email)` so test accounts are not trapped as pending claims.
* [x] **Build Firestore Composite Index:** Click the generated link in the debug logs to automatically build the required `creator_id` + `scheduled_time` composite index for the `games` collection.
* [x] **Relax Firestore Rules for Test Accounts:** Update `firestore.rules` to either allow unverified reads/writes for authenticated users during development, or explicitly whitelist the `test@example.com` UID so it does not trigger `PERMISSION_DENIED` on the `courses` and `games` collections.
* [x] **Fix Game Visibility for Participants:** In `lib/game.dart`, update `saveGameToDatabase()` to inject a flat `participant_ids` array (extracting all `playerId`s from the game's players list) into the Firestore document.
* [x] **Update Game Query:** Update `fetchGamesForCurrentUser()` to query `where('participant_ids', arrayContains: currentUserId)` instead of `creator_id` so players can see games even if a guest created them.
* [x] **Update Composite Indexes:** Deploy the new `participant_ids` + `scheduled_time` composite index to Firestore to support the new query.
* [x] **Sync Local Firestore Indexes:** Run `firebase firestore:indexes > firestore.indexes.json` in the terminal to pull the composite indexes created in the Firebase Console down to the local repository state so they are tracked in version control.

---

### Phase 2 — Identity Foundation & Local Game Adoption

#### 2.1 Preserve Nickname-Only and Quick-Play Players

* [ ] Preserve anonymous / nickname-only users as first-class players.
* [ ] Verify `Player.createPlayer` remains functional with only `playerName` and `nickname`.
* [ ] Ensure `ownerId` defaults to the creator’s UID or `'guest'`.
* [ ] Update the `Player` model to include an `isQuickPlay` boolean flag.
* [ ] Ensure `PlayerForm` bypasses mandatory email / phone validation when `isQuickPlay` is `true`.
* [ ] Store quick-play players in the local `guest_players` `SharedPreferences` key.
* [ ] Ensure PII independence for quick-play and guest players.

#### 2.2 Normalize Contact Entry Points

* [ ] Use `ContactIdentity.normalizeEmail` in all contact write paths.
* [ ] Use `ContactIdentity.normalizePhoneNumber` in all contact write paths.
* [ ] Apply normalization inside `PlayerForm.saveChanges`.
* [ ] Apply normalization before any database write.
* [ ] Reference `ContactIdentity` as the source of truth for all contact normalization.
* [ ] Ensure normalization supports reservation consistency.

#### 2.3 Late Contact Attribution

* [ ] Refactor `Player.updateUnclaimedPlayer` to support post-creation contact attachment.
* [ ] Before updating contact details, invoke:
  * `ContactIdentity.normalizeEmail`
  * `ContactIdentity.normalizePhoneNumber`
* [ ] Query the `player_contacts` collection before attaching a contact.
* [ ] Verify the contact is not already reserved.
* [ ] Prevent split-identity claims where phone and email point to different canonical IDs.

#### 2.4 Local Game & Guest Adoption Workflow

* [ ] Implement the migration path from `SharedPreferences` to Firestore.
* [ ] Implement `Game.adoptLocalGames`.
* [ ] Iterate through local games and map them to the canonical `loggedInUser`.
* [ ] Refactor / deprecate automatic adoption loops in `Game.adoptLocalGames`.
* [ ] Update method signature to:

```dart
adoptLocalGames(Player loggedInUser, List<String> gameIdsToAdopt)
```

* [ ] Implement `Player.adoptLocalGuestPlayers`.
* [ ] Verify and create records in `player_contacts` for any guest being promoted.
* [ ] Prevent adopting a contact already reserved by another canonical record.
* [ ] Rewrite `Player.adoptLocalGuestPlayers` to iterate through:
  * `friends`
  * `player_game_info`
  * `games`
* [ ] Explicitly handle embedded data.
* [ ] Update `Game.saveLocalGame` to parse JSON strings in `SharedPreferences`.
* [ ] Replace legacy guest IDs with canonical IDs.
* [ ] Decouple migration from the login flow.
* [ ] Implement a post-login import prompt.
* [ ] Allow users to choose which local guest games to associate with their authenticated profile.
* [ ] Implement a `"Merge Games Found"` dialog in `UserProvider` after successful login.
* [ ] Allow users to explicitly select which local IDs to sync to Firestore.
* [ ] Include local games and local friends in the cloud import prompt.

#### 2.5 Claim Baseline

* [ ] Ensure `Player.claimPlayerForVerifiedAuthUser` is the exclusive entry point for guest-to-auth conversion.
* [ ] Maintain canonical integrity during all claim flows.
* [ ] Ensure `UserProvider` triggers `ClaimAccountScreen` when signup detects claimable history.

#### 2.6 Legacy Duplicate Repair

* [ ] Develop an ID consistency migration utility.
* [ ] Repair legacy duplicate players.
* [ ] Rewrite IDs in:
  * `friends` collection
  * `player_game_info` maps
  * embedded `game.players` lists
  * local `SharedPreferences` JSON strings
* [ ] Ensure all history converges onto a canonical ID.

---

### Phase 3 — Real-Time Synchronization & Data Integrity

#### 3.1 Firestore Listener Architecture

* [ ] Replace `SharedPreferences` lookups in `GameInprogressScreen` with real-time Firestore listeners.
* [ ] Modify the `Game` model to support a `fromSnapshot(DocumentSnapshot)` factory.
* [ ] Update `GameInprogressScreen` to listen to Firestore `snapshots()` for the active `gameId`.
* [ ] Use `StreamBuilder` to support mid-game reconnections.
* [ ] Support multi-device score updates.
* [ ] Replace `FutureBuilder` in `GameInprogressScreen` with two nested `StreamBuilder` widgets.
* [ ] Add a document stream for the specific `Game` ID to track status and metadata.
* [ ] Add a collection stream for the `PlayerGameInfo` sub-collection to reactively update hole scores.
* [ ] Remove manual `_updateGame` calls for UI refreshes.
* [ ] Ensure the UI only reflects state emitted by Firestore snapshots.

#### 3.2 Stream Testing

* [ ] Build widget tests that simulate Firestore stream updates.
* [ ] Verify the UI updates correctly when other players change scores.
* [ ] Ensure stream updates do not throw out-of-bounds exceptions.
* [ ] Ensure stream updates do not throw state errors.

#### 3.3 Concurrency & Conflict Resolution

* [ ] Implement `"Last Write Wins"` using Firestore `serverTimestamp`.
* [ ] When updating a score in `Game.recordScore`, include a `last_updated` field.
* [ ] If a snapshot arrives where remote `last_updated` is newer than local state, perform a non-destructive merge of the scores list.
* [ ] Preserve score integrity during multi-device updates.

#### 3.4 Offline FIFO Synchronization Queue

* [ ] Create a `SyncQueue` service.
* [ ] Back the queue with `SharedPreferences`.
* [ ] Use a First-In-First-Out structure.
* [ ] If `DatabaseConnectionError` is caught during a score write, push the `PlayerGameInfo` JSON to the queue.
* [ ] Implement a background listener that processes queued writes once connectivity is restored.
* [ ] Process the queue sequentially.
* [ ] Preserve chronological integrity.

#### 3.5 Transactional Identity Consistency

* [ ] Use a Firestore Transaction in the claim service.
* [ ] Ensure claim operations are atomic.
* [ ] Reject a claim if email resolves to one player and phone resolves to another.
* [ ] Validate every player claim against the `player_contacts` source of truth.
* [ ] Prevent hijacking of reserved identities.

#### 3.6 Firestore Composite Indexes

* [ ] Update `firestore.indexes.json` to define necessary composite indexes.
* [ ] Add a composite index for the `games` collection to support querying by `creator_id` while ordering by `scheduled_time` (required for `Game.fetchGamesForCurrentUser`).
* [ ] Add a composite index for the `games` collection querying by `status` and ordering by scheduled_time.

#### 3.7 Creator Score Oversight & Approval

* [ ] Implement a "Creator Override" permission system for active games.
* [ ] If a non-creator participant updates a score on their device, flag the score as "Pending Approval" on the Game Creator's screen.
* [ ] Provide a UI mechanism for the Game Creator to lock, approve, or reject score updates submitted by other players to maintain scorecard integrity.

---

### Phase 4 — Advanced Testing, E2E Validation & Emulator Support

#### 4.1 Firebase Local Emulator Suite Setup

* [ ] Set up Firebase Local Emulator Suite (Auth and Firestore) in the project environment.
* [ ] Update `DatabaseConnection.initialize()` to conditionally call `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080)` when running in debug or emulator mode.
* [ ] Update `UserProvider.initialize()` to conditionally call `FirebaseAuth.instance.useAuthEmulator('localhost', 9099)`.
* [ ] Configure integration tests to run against the local emulator environment.
* [ ] Implement `@firebase/rules-unit-testing` for security rule validation.

#### 4.2 Canonical Player Convergence E2E Scenario

* [ ] Create an E2E test in `all_test_code.md`.
* [ ] Simulate this full flow:
  1. Remote game exists with a canonical player.
  2. Guest creates a local game with a matching contact.
  3. Guest signs up and verifies via `ClaimAccountScreen`.
  4. Verify remote and local games converge on the same canonical ID.
  5. Verify no duplicate records exist in the `players` collection.

#### 4.3 Expanded Convergence Scenario

* [ ] Simulate User A creating a remote game.
* [ ] User A adds Player B via email `b@example.com`.
* [ ] User C, as a guest, creates a local game using the same email `b@example.com`.
* [ ] User C signs up.
* [ ] `UserProvider` triggers `ClaimAccountScreen`.
* [ ] Upon verification, confirm original remote game and newly adopted guest game point to the same UID.
* [ ] Validate no duplicate player records exist.

#### 4.4 Address and Location Tests

* [x] Update all_test_code.md with tests for _showAddressCaptureBottomSheet.
* [x] Verify empty street fields trigger validation failures.
* [x] Verify empty city fields trigger validation failures.
* [x] Expand MockGeolocatorPlatform.
* [x] Expand MockGeocodingPlatform.
* [x] Cover the 100-meter proximity threshold logic.
* [x] Cover coordinate-to-address mapping.
* [x] Test normalized substring address matching.
* [x] Test the "Add Second Course Anyway" flow.
* [x] Ensure the proximity warning works in AddEditCourseScreen.

#### 4.5 Stream and Sync Tests

* [ ] Simulate Firestore stream updates in widget tests.
* [ ] Verify `GameInprogressScreen` updates instantly.
* [ ] Verify no state errors occur during mid-game reconnections.
* [ ] Verify offline queue writes are replayed in FIFO order after connectivity returns.

#### 4.6 Firestore Rules Tests

* [ ] Test game mutation rules.
* [ ] Ensure users can only mutate games they created or participate in.
* [ ] Test verified claim restrictions.
* [ ] Ensure other users cannot steal a canonical player.
* [ ] Test contact visibility restrictions.
* [ ] Verify email and phone visibility is properly restricted.
* [ ] Test friend-edge mutation rules.
* [ ] Harden rules around how friend relationships are mutated.
* [ ] Verify friend-edge mutations with rule tests.

#### 4.7 Native Auth E2E Tests

* [ ] Configure native UI test automation (e.g., UIAutomator/Espresso) alongside Flutter `integration_test` to successfully interact with the native Google Sign-In account selector pop-up.
* [ ] Write an E2E test proving the Google Sign-In flow reaches the Dashboard.

---

### Phase 5 — Security, Multi-Contact & Privacy

#### 5.1 Split-Identity Rejection

* [ ] Update `Player.resolveCanonicalPlayer` to check both email and phone number.
* [ ] If email resolves to Player A and phone resolves to Player B, reject the claim.
* [ ] Return a `"Contact Conflict"` error.
* [ ] Ensure split-identity rejection also runs inside transactional claim logic.

#### 5.2 Double-Claim Prevention

* [ ] Update `Player.canVerifiedAuthUserClaimPlayer`.
* [ ] Reject claims where `claimed_by_uid` is already populated and does not match the current `auth.uid`.
* [ ] Update `claimPlayerForVerifiedAuthUser` to explicitly check `claimed_by_uid` before processing.
* [ ] Prevent account takeovers.

#### 5.3 Multi-Contact Support

* [ ] Update `Player` model to support multiple verified contacts.
* [ ] Add `List<String> verifiedEmails`.
* [ ] Add `List<String> verifiedPhones`.
* [ ] Also support schema names:
  * `verified_emails`
  * `verified_phones`
* [ ] Update `player_contacts` collection so a single canonical player can own multiple verified contacts.
* [ ] Define a `ClaimStatus` enum:
  * `none`
  * `pendingVerification`
  * `claimed`

#### 5.4 Account Merge Workflow

* [ ] Build account merge UI and backend.
* [ ] Implement a Cloud Function trigger or backend logic to detect contact collisions during `resolveCanonicalPlayer`.
* [ ] If a user adds a contact already owned by another `player_id`, set status to `pendingVerification`.
* [ ] Trigger a "Merge Challenge".
* [ ] Send a clickable verification link to the challenged contact owner.
* [ ] Develop a "Merge Request" dialog.
* [ ] **Add a strict UI warning dialog explicitly stating that account merging is permanent and cannot be unmerged.**
* [ ] **Enforce strict security constraints: Ensure no accounts or contacts can be merged or added to a player profile unless they have been fully verified via Firebase Auth.**
* [ ] Ensure player records only merge after the challenged contact owner explicitly approves the merge through the link.
* [ ] Write tests for merge approval.

#### 5.5 Firestore Security Rules (`firestore.rules`)

* [ ] Overwrite the current default `firestore.rules` configuration with strict schema enforcement.
* [ ] `match /players/{playerId}`: Prevent `claimed_by_uid` hijacking (cannot overwrite if already claimed by a different UID).
* [ ] `match /player_contacts/{contactId}`: Restrict visibility and mutation strictly to the owner.
* [ ] `match /friends/{edgeId}`: Ensure only the `owner_id` or `claimed_by_uid` can mutate friend-edge records.
* [ ] `match /games/{gameId}`: Restrict game read/write visibility to active participants and the creator.
* [ ] Enforce verified claims: Ensure only authenticated users with verified contacts can claim matching records.

#### 5.6 PII Privacy UI

* [ ] Implement expandable cards in `PlayersScreen`.
* [ ] Refactor `PlayerListItem` to use `ExpansionTile`.
* [ ] Hide email and phone number fields by default.
* [ ] Reveal PII only when the tile is expanded by the user.
* [ ] Add a `"PII Sharing Preferences"` toggle in `PlayerProfileWidget`.
* [ ] Update `PlayerForm` in `player_form_widget.dart` to include a `pii_sharing_prefs` toggle.
* [ ] Use `SwitchListTile` for the PII sharing preference.
* [ ] Respect `pii_sharing_prefs` in the UI.

#### 5.7 Social Login Account Linking & Detection

* [ ] Implement backend logic to allow linking multiple social login providers (e.g., Google, Facebook, Snapchat, Instagram) to a single canonical `Player` account.
* [ ] Update the `LoginScreen` and authentication flow to preemptively detect if a newly authenticated social login email or phone matches an existing canonical player record.
* [ ] Create a "Match Found" UI prompt alerting the user that game history or a player account already exists under a different login method.
* [ ] Provide an explicit "Link Accounts" UX action, allowing the user to merge the new social login into their existing canonical player, consolidating their game history.
* [ ] Provide an explicit "Keep Separate" UX action to allow users to intentionally opt-out of linking if they prefer to maintain multiple separate accounts.
* [ ] Update the `Player` model and `player_contacts` schema to track linked authentication providers.
* [ ] Integrate this detection and linking UI seamlessly with the existing `ClaimAccountScreen` and Phase 5.4 Account Merge workflows.
* [ ] **Security Constraint:** Ensure the social login email or phone number is fully verified by Firebase Auth before allowing it to be linked to the canonical player account.
* [ ] **UX Warning:** Ensure the "Link Accounts" UI includes the same strict warning from 5.4 explicitly stating that linking social accounts is permanent and cannot be undone.

---

### Phase 6 — Customization & User Preferences

#### 6.1 Creator-Assigned Nicknames

* [ ] Update `PlayerGameInfo` in `player_game_info.dart`.
* [ ] Add `String? localNickname`.
* [ ] Add or reconcile `nickname_override` field.
* [ ] Decide whether `localNickname` and `nickname_override` should be the same canonical field.
* [ ] Update `toJson`.
* [ ] Update `fromJson`.
* [ ] Persist local / context-specific nicknames.
* [ ] Allow game creators to assign context-specific nicknames during game setup.
* [ ] Implement nickname assignment in `GameStartScreen`.
* [ ] Allow custom player labels within a specific `Game` instance.
* [ ] Do not modify the player’s global canonical nickname when using a game-specific nickname.

---

### Phase 7 — Technical Debt & Refactoring

#### 7.1 Optimize `GameCardWidget` Storage Access

* [ ] Refactor `deleteSavedGame` in `game_card_widget.dart`.
* [ ] Stop iterating through every key in `SharedPreferences`.
* [ ] Implement a specific `game_index` key.
* [ ] Or use a UUID-prefix check.
* [ ] Only attempt `jsonDecode` on relevant game records.
* [ ] Ensure `GameCardWidget` no longer performs exhaustive `jsonDecode` iterations on `SharedPreferences`.

#### 7.2 Conditional Debug Stripping

* [ ] Wrap expensive `StackTrace` logic in `Utilities.debugPrintWithCallerInfo` with `if (kDebugMode)`.
* [ ] Use a `const bool` to ensure this logic is completely removed from production builds.
* [ ] Optimize production performance.

#### 7.3 Architectural Refactoring & Clean Architecture

* [ ] **Directory Reorganization:** Migrate the flat `lib/` file structure into logical domain folders (e.g., `/models`, `/screens`, `/widgets`, `/services`, `/utils`).
* [ ] **Update Imports:** Fix all internal imports across the application and test suites to align with the new directory structure.
* [ ] **Repository Pattern Abstraction:** Extract raw Firestore queries and `SharedPreferences` logic out of the core data models (`Course`, `Game`, `Player`).
* [ ] **Service Layer Creation:** Create dedicated repository classes (e.g., `GameRepository`, `PlayerRepository`, `CourseRepository`) to handle all data access operations.
* [ ] **Enforce Separation of Concerns:** Ensure UI components and models strictly call repository methods rather than interacting with `FirebaseFirestore.instance` or `SharedPreferences.getInstance()` directly.

#### 7.4 Code Cleanup & Dead Code Removal

* [ ] **Clean up PastGameDetailsScreen:** Remove the lingering commented-out `getPlayersList` widget method.
* [ ] **Clean up PlayerForm:** Remove the commented-out `SharedPreferences` auth-load logic in `loadCurrentUser` since we now rely exclusively on `UserProvider`.
* [ ] **Clean up PastGameListItem:** Remove the commented-out `TextStyle(fontSize: 8.0)` block inside the subtitle.

---

### Phase 8 — Premium Features & Monetization (Future)

* [ ] **Premium Course Services:** Research gating the "Locate Nearby Courses" (Proximity Search) behind a premium tier.
* [ ] **Course Ratings:** Implement a premium-only "Rate and Review" system for courses.
* [ ] **Subscription Logic:** Plan a `UserProvider` attribute for `isPremium` to manage feature access.
* [ ] **Scheduling Paywall:** Enforce the rule that only users with `isPremium == true` can persist games with a `scheduled_time` in the future.
* [ ] **Tournament / Concurrent Game Mode:** Build an "Active Games Hub" that safely allows users (such as dedicated scorekeepers) to run multiple live games simultaneously and swap between them, bypassing the standard 1-to-1 global auto-resume logic.
* [ ] **Premium Pace of Play Analytics:** Build a premium post-game summary UI that parses the historical `scoreTimestamps` data to calculate total game duration, average time per hole, and individual player pace statistics.

### Phase 9 — CI/CD & Deployment

#### 9.1 iOS Firebase App Distribution

* [ ] **macOS Runner Setup:** Update the `.github/workflows/firebase-distribution.yml` to include a `macos-latest` job (or matrix) alongside the existing `ubuntu-latest` Android job.
* [ ] **Shared Versioning:** Ensure the iOS build job reads from the exact same versioning mechanism/script currently used by the Android build to keep cross-platform version numbers perfectly synced.
* [ ] **Apple Code Signing:** Configure GitHub Action secrets for Apple certificates and provisioning profiles (using either standard GitHub Action steps or Fastlane Match) to successfully archive and sign the iOS `.ipa`.
* [ ] **Firebase Upload:** Add the Firebase App Distribution upload step for the iOS artifact, utilizing the existing iOS App ID (`1:114725116317:ios:61765a6d7b137631903774`).

---

## Part B — Detailed Engineering Appendix

### Appendix A — Source-Equivalent Phase Map

#### Original Phase: Immediate Stability

Status: **In Progress**

Description: Hardening CRUD operations, location safety, and coordinate validation.

Consolidated into:

* Phase 1.1 — Harden Database Error Handling
* Phase 1.6 — Course Location Awareness & Duplicate Prevention
* Phase 1.7 — Proximity-Based Sorting and Location Safety

---

#### Original Phase: Identity & Local Game Adoption

Status: **In Progress**

Description: Migrating guest data and local JSON strings to authenticated `ContactIdentity` records.

Consolidated into:

* Phase 2.1 — Preserve Nickname-Only and Quick-Play Players
* Phase 2.2 — Normalize Contact Entry Points
* Phase 2.3 — Late Contact Attribution
* Phase 2.4 — Local Game & Guest Adoption Workflow
* Phase 2.5 — Claim Baseline
* Phase 2.6 — Legacy Duplicate Repair

---

#### Original Phase: Real-Time Sync

Status: **Planned**

Description: Implementing Firestore `snapshots()` for live multi-user score updates.

Consolidated into:

* Phase 3.1 — Firestore Listener Architecture
* Phase 3.2 — Stream Testing
* Phase 3.3 — Concurrency & Conflict Resolution
* Phase 3.4 — Offline FIFO Synchronization Queue
* Phase 3.5 — Transactional Identity Consistency

---

#### Original Phase: E2E Testing

Status: **In Progress**

Description: Executing 4-step identity convergence scenarios from guest-to-auth.

Consolidated into:

* Phase 4.1 — Firebase Emulator Test Setup
* Phase 4.2 — Canonical Player Convergence E2E Scenario
* Phase 4.3 — Expanded Convergence Scenario
* Phase 4.4 — Address and Location Tests
* Phase 4.5 — Stream and Sync Tests
* Phase 4.6 — Firestore Rules Tests

---

#### Original Phase: Security & Multi-Contact

Status: **Planned**

Description: Advanced account merging, verification links, and split-identity rejection.

Consolidated into:

* Phase 5.1 — Split-Identity Rejection
* Phase 5.2 — Double-Claim Prevention
* Phase 5.3 — Multi-Contact Support
* Phase 5.4 — Account Merge Workflow
* Phase 5.5 — Firestore Security Rules

---

#### Original Phase: Guest Walkthrough & UI/UX

Status: **Planned**

Description: Active sprint for modernizing player selection and enforcing PII privacy.

Consolidated into:

* Phase 1.2 — Modernize Game Creation UI
* Phase 1.3 — Modernize Player Creation and Selection UI
* Phase 1.4 — Fix Player Selection State
* Phase 1.5 — Guest-Aware Navigation Drawer
* Phase 5.6 — PII Privacy UI

---

### Appendix B — Detailed Task Notes by Component

#### `GameCreateScreen`

* Redesign screen to match `AddEditCourseScreen`.
* Replace standard `ListTile` widgets.
* Use `_buildSelectionCard` helpers.
* Use `AnimatedContainer`.
* Use `BoxDecoration`.
* Use visual feedback similar to `AddEditCourseScreen._buildHoleCountCard`.
* Use consistent `16.0` border radius.
* Move `"Select Players"` and `"Select Course"` out of `ListView`.
* Prefer bottom sticky action bar or `FloatingActionButton`.
* Preserve selected players and courses across all navigation sub-flows.

---

#### `PlayersScreen`

* Accept `List<Player> currentlySelectedPlayers`.
* Preserve selected player state through rebuilds.
* Synchronize with `GameCreateScreenState`.
* Return updated selected player list correctly.
* Add `"Deselect All"` / `"Clear All"` behavior.
* Add `"Clear All"` button to `AppBar`.
* Improve button placement for thumb reach.
* Add expandable cards or `ExpansionTile` to hide PII.
* Hide email and phone by default.
* Reveal PII only when expanded.
* Use Material 3 / Teal design language.
* Add card-based UI:
  * `elevation: 0`
  * `RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0))`
  * `Colors.teal.shade50`
* Use `BouncyAnimation` while loading players.
* Use rounded `LinearProgressIndicator`.

---

#### `PlayerCreateScreen`

* Modernize from basic form into card-based or step-based UI.
* Align with `CoursesScreen` card style.
* Match Material 3 / Teal design.
* Preserve quick-play and nickname-only player flows.

---

#### `PlayerForm`

* Bypass mandatory email / phone validation when `isQuickPlay == true`.
* Use `ContactIdentity.normalizeEmail`.
* Use `ContactIdentity.normalizePhoneNumber`.
* Normalize before all database writes.
* Add `pii_sharing_prefs` with `SwitchListTile`.

---

#### `PlayerProfileWidget`

* Add `"PII Sharing Preferences"` toggle.
* Ensure UI respects PII sharing setting.

---

#### `PlayerListItem`

* Refactor to `ExpansionTile`.
* Hide sensitive fields by default.
* Reveal email and phone only on expansion.

---

#### `Player` Model

* Preserve `playerName` and `nickname` only creation.
* Default `ownerId` to creator UID or `'guest'`.
* Add `isQuickPlay`.
* Add support for:
  * `verifiedEmails`
  * `verifiedPhones`
  * `verified_emails`
  * `verified_phones`
* Support multiple verified contacts.
* Add or support `ClaimStatus`.
* Ensure canonical player ownership rules are enforced.
* Ensure claim logic detects:
  * reserved contacts
  * double claims
  * split identities
  * pending merge challenges

---

#### `PlayerGameInfo`

* Add `String? localNickname`.
* Add or reconcile `nickname_override`.
* Update `toJson`.
* Update `fromJson`.
* Persist context-specific nicknames.
* Allow per-game display labels without changing global player nickname.

---

#### `GameStartScreen`

* Allow game creator to assign context-specific player nicknames.
* Persist these nicknames in `PlayerGameInfo`.

---

#### `GameInprogressScreen`

* Replace local-only / `SharedPreferences` lookups.
* Replace `FutureBuilder`.
* Use real-time Firestore `snapshots()`.
* Add nested `StreamBuilder` widgets:
  1. Game document stream for metadata and status.
  2. `PlayerGameInfo` sub-collection stream for scores.
* Support:
  * mid-game reconnections
  * multi-device updates
  * remote score updates
  * offline resiliency
* Remove manual `_updateGame` UI refresh calls.
* UI should reflect Firestore snapshot state only.

---

#### `Game` Model

* Add `fromSnapshot(DocumentSnapshot)` factory.
* Implement / refactor `adoptLocalGames`.
* New signature:

```dart
adoptLocalGames(Player loggedInUser, List<String> gameIdsToAdopt)
```

* Deprecate automatic local adoption loop.
* Update `saveLocalGame` to parse JSON strings in `SharedPreferences`.
* Replace legacy guest IDs with canonical IDs.
* Add `recordScore` support for `last_updated`.
* Use Firestore `serverTimestamp`.
* Merge remote updates non-destructively when remote `last_updated` is newer.

---

#### `GameCardWidget`

* Catch Firestore failures during `getLocallySavedGames`.
* Display `SnackBar` when remote sync is temporarily unavailable.
* Refactor `deleteSavedGame`.
* Stop scanning every `SharedPreferences` key.
* Use `game_index` or UUID-prefix filtering.
* Only decode relevant game records.
* Avoid exhaustive `jsonDecode` iterations.

---

#### `CoursesScreen`

* Catch `DatabaseConnectionError`.
* Replace loading-only ternary logic.
* Add `_connectionError != null` state.
* Render `"Fairway Unreachable"` persistent error UI.
* Add `"Retry"` callback.
* Run `_getCurrentLocation()` and `_initializeCourses()` concurrently.
* Use `Future.wait` or equivalent.
* Verify `mounted` before UI updates.
* Re-sort list after GPS lock.
* Use high-accuracy `LocationSettings`.
* Catch `TimeoutException`.
* Use `5-second timeLimit`.
* Show non-blocking `SnackBar` or status icon on timeout.

---

#### `AddEditCourseScreen`

* Implement `_showAddressCaptureBottomSheet`.
* Add address controllers:
  * `streetController`
  * `cityController`
  * `stateController`
  * `zipController`
* Perform background geocoding.
* Fix coordinate capture failure.
* Implement `_findConflictingCourses`.
* Use Haversine formula.
* Use `100-meter` threshold.
* Trigger `_showLocationConflictDialog`.
* Add normalized address substring matching.
* Support duplicate detection without coordinates.
* Allow choosing an existing course.
* Allow bypassing conflict to create secondary course.
* Support multi-course facilities.

---

#### `UserProvider`

* Decouple migration from login.
* After login, show import prompt.
* Allow users to choose local games and friends to import.
* Implement `"Merge Games Found"` dialog.
* Trigger `ClaimAccountScreen` when claimable contacts/history exist.
* Ensure authenticated adoption does not automatically merge without user choice.

---

#### `ClaimAccountScreen`

* Used when guest signs up and matching contact/history exists.
* Supports guest-to-auth convergence.
* Verification must merge local and remote history into a canonical player.
* Must not create duplicate player records.

---

#### `ContactIdentity`

* Source of truth for contact normalization.
* Required for:
  * `PlayerForm.saveChanges`
  * `Player.updateUnclaimedPlayer`
  * claim flows
  * contact reservation checks
* Must normalize:
  * email
  * phone number
* Used before every contact-related database write.

---

#### `player_contacts` Collection

* Source of truth for contact ownership and reservation.
* Must prevent adopting contacts already reserved by another canonical record.
* Must prevent hijacking.
* Must support one canonical player owning multiple verified contacts.
* Visibility must be restricted by Firestore rules.
* Mutations must be restricted to owner / valid claimant.

---

#### `firestore.rules`

* Enforce verified claims.
* Prevent `claimed_by_uid` hijacking.
* Restrict `player_contacts` visibility.
* Restrict game visibility to participants.
* Restrict friend-edge mutations.
* Ensure only `owner_id` or `claimed_by_uid` can modify player metadata where appropriate.
* Validate with `@firebase/rules-unit-testing`.

---

#### `Utilities.debugPrintWithCallerInfo`

* Wrap expensive `StackTrace` logic in `if (kDebugMode)`.
* Use a `const bool` so production builds strip the logic.
* Improve production performance.

---

### Appendix C — Required Test Plan

#### Unit Tests

**Fully Covered Files (100% Line Coverage):**

* [x] `add_edit_course_screen.dart`
* [x] `app_drawer_widget.dart`
* [x] `asset_bouncy_animation.dart`
* [x] `asset_golf_ball_path.dart`
* [x] `claim_account_screen.dart`
* [x] `contact_identity.dart`
* [ ] `course_list_item_widget.dart`
* [ ] `course.dart`
* [x] `courses_screen.dart`
* [x] `dashboard_screen.dart`
* [x] `database_connection_error.dart`
* [ ] `database_connection.dart`
* [ ] `firebase_options.dart`
* [x] `game_card_widget.dart`
* [x] `game_create_screen.dart`
* [x] `game_inprogress_screen.dart`
* [x] `game_start_screen.dart`
* [x] `game.dart`
* [ ] `gravatar_image_view.dart`
* [ ] `home_screen.dart`
* [x] `login_screen.dart`
* [x] `main.dart`
* [x] `map_picker_screen.dart`
* [ ] `past_game_card_widget.dart`
* [x] `past_game_details_screen.dart`
* [x] `past_game_list_item.dart`
* [x] `past_games_screen.dart`
* [x] `player_avatar_widget.dart`
* [x] `player_create_screen.dart`
* [ ] `player_form_widget.dart`
* [x] `player_game_info.dart`
* [x] `player_profile_widget.dart`
* [ ] `player_score_data_table_card.dart`
* [x] `player.dart`
* [x] `players_card_widget.dart`
* [x] `players_list_screen.dart`
* [x] `players_screen.dart`
* [x] `scheduled_games_screen.dart`
* [x] `userprovider.dart`
* [x] `utilities.dart`

**Pending Specific Behavioral Tests:**

* [ ] Player.createPlayer nickname-only creation.
* [ ] PlayerForm quick-play validation bypass.
* [x] ContactIdentity.normalizeEmail.
* [x] ContactIdentity.normalizePhoneNumber.
* [x] ContactIdentity null boundary cases and reservationId methods (Needs 100% coverage).
* [ ] Player.updateUnclaimedPlayer contact reservation checks.
* [ ] Player.resolveCanonicalPlayer split-identity rejection.
* [ ] Player.canVerifiedAuthUserClaimPlayer double-claim prevention.
* [ ] PlayerGameInfo.toJson with local nickname.
* [ ] PlayerGameInfo.fromJson with local nickname.
* [ ] Game.fromSnapshot.
* [ ] Game.recordScore with last_updated.
* [ ] FIFO SyncQueue.
* [ ] GameCardWidget.deleteSavedGame targeted storage lookup.
* [ ] _findConflictingCourses Haversine threshold.
* [ ] Normalized address substring matching.

---

#### Widget Tests

* [x] `PlayersScreen` preserves selected players across rebuilds.
* [x] `PlayersScreen` receives `currentlySelectedPlayers`.
* [x] `PlayersScreen` clears all selected players.
* [x] `GameCreateScreen` receives returned selected players.
* [ ] `PlayerListItem` hides PII by default.
* [ ] `PlayerListItem` reveals PII on expansion.
* [ ] `PlayerForm` shows PII sharing toggle.
* [ ] `GameInprogressScreen` responds to stream updates.
* [ ] `GameInprogressScreen` avoids out-of-bounds errors.
* [ ] `GameInprogressScreen` avoids state errors.
* [x] `CoursesScreen` renders `"Fairway Unreachable"` error state.
* [x] `CoursesScreen` retry callback works.
* [x] `_showAddressCaptureBottomSheet` validates empty street.
* [x] `_showAddressCaptureBottomSheet` validates empty city.
* [x] "Add Second Course Anyway" flow works.

---

#### Integration / E2E Tests

* [ ] Course creation map search and location name flow passes (`integration_test/course_creation_map_flow_test.dart`).
* [x] Course location duplicate conflict and bypass flow passes (`integration_test/course_location_conflict_flow_test.dart`).
* [x] Activity Hub game create and active game resume flow passes (`integration_test/activity_hub_game_create_flow_test.dart`).
* [x] Active game score increment and guest shared drawer access flows pass (`integration_test/phase_1_19_drawer_score_flow_test.dart`).
* [x] Offline course selection fallback flow passes (`integration_test/course_selection_fallback_test.dart`).
* [x] Authentication and test-account verification bypass flow passes (`integration_test/auth_login_flow_test.dart`).
* [x] Player selection, deselection, and clear-all flow passes (`integration_test/player_selection_flow_test.dart`).
* [x] Guest-created cloud game visibility by registered participant ID flow passes (`integration_test/guest_game_visibility_test.dart`).
* [ ] Google Sign-In E2E authentication flow passes (Note: requires native UI test configuration to tap system pop-ups).
*  [x] Guest drawer intercept context banner flow passes (`integration_test/guest_drawer_intercept_flow_test.dart`).
* [ ] Firebase Local Emulator Suite is configured.
* [ ] Remote game exists with canonical player.
* [ ] Guest creates local game with matching contact.
* [ ] Guest signs up.
* [ ] Guest verifies through `ClaimAccountScreen`.
* [ ] Remote and local games converge onto same canonical player.
* [ ] No duplicate player records are created.
* [ ] Firestore stream updates propagate to UI.
* [ ] Offline queue replays writes in FIFO order.
* [ ] Merge approval only completes after challenged owner approves verification link.
* [x] Location conflict detects courses within `100 meters`.
* [x] Address conflict works without coordinates.
* [x] User can create a secondary course at same location.

---

#### Firestore Rules Tests

* [ ] Users can mutate only games they created or participate in.
* [ ] Non-participants cannot read restricted games.
* [ ] Verified claims prevent player theft.
* [ ] `claimed_by_uid` cannot be hijacked.
* [ ] Contact visibility is restricted.
* [ ] Email visibility is restricted.
* [ ] Phone visibility is restricted.
* [ ] Friend-edge mutations are restricted.
* [ ] `player_contacts` writes require valid ownership or verified claim.

---

### Appendix D — Final Definition of Done

* [ ] The 4-step identity convergence regression scenario passes in the automated test suite.
* [ ] Selected players and selected courses persist across all `GameCreateScreen` navigation sub-flows.
* [ ] Contact normalization is applied through `ContactIdentity` before every relevant database write.
* [ ] Legacy JSON storage is repaired.
* [ ] Guest/local records migrate only through explicit user-approved import flows.
* [ ] PII is hidden behind expandable widgets by default.
* [ ] `pii_sharing_prefs` is respected in the UI.
* [ ] `GameCardWidget` no longer performs exhaustive `jsonDecode` iterations on `SharedPreferences`.
* [ ] `DatabaseConnectionError` is handled without infinite loading spinners.
* [ ] Courses can be detected as duplicates by both GPS proximity and normalized address matching.
* [ ] Real-time score updates work across multiple devices.
* [ ] Offline writes are queued and replayed in FIFO order.
* [ ] Double-claiming is prevented.
* [ ] Split-identity conflicts are caught during claim flow.
* [ ] Multi-contact ownership is supported.
* [ ] Account merge requires challenged owner approval.
* [ ] Firestore rules enforce claim, contact, game, and friend-edge restrictions.

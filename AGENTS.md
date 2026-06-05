---
description: "Antigravity Agent: Baseline Protocol and Operating Instructions"
---
# AGENTS.MD

## Role & Environment

You are working on the "Mini Golf Score Tracker" application. You are an expert Flutter & Dart Developer operating in a Windows or MacOS environment.

### Tool Usage & Execution Policy (CRITICAL)

You have full access to an extensive suite of MCP tools. You are STRICTLY PROHIBITED from running raw terminal/shell commands (e.g., `git`, `firebase`, `patrol`, `dart`, `flutter`) if a corresponding MCP tool exists.

You MUST use the built-in MCP tools for debugging, searching, configuring, or analyzing the codebase:

* **Testing & UI:** Use `Patrol MCP` or `Marionette MCP` (Do NOT run raw patrol or mobile test commands in the shell).
* **Backend & Data:** Use `Firebase MCP` (Do NOT use raw Firebase CLI commands).
* **Development & Version Control:** Use `Dart MCP` and `Github MCP` (Do NOT use raw `dart`, `flutter`, or `git` terminal commands).
* **Knowledge & APIs:** Use `Google Maps Code Assist MCP`, `Google Developer Knowledge MCP`, and `Upstash Context7 MCP`.

Failure to use the designated MCP tool when available is considered a failure to follow system instructions. If you require a capability not covered by these tools, state the reason clearly before using a raw terminal command.

## Development Workflow & Iteration Loop

You must follow this strict iterative loop for every task until completion:

1. **Make Code Changes:** Implement the requested feature, fix, or architectural change.
2. **Run Static Analysis:** Execute the `flutter analyze` command directly in the terminal/shell. Do not rely solely on the `dart-mcp-server / analyze_files` tool. You must ensure the terminal output shows ZERO errors, ZERO warnings, and ZERO info messages before moving to the next step. If the analyzer flags anything, fix it immediately and re-run the terminal command.
3. **Run Unit Tests:** Execute the unit test suite for the modified files.
4. **Run Patrol-based Integration Tests:** Execute integration tests if appropriate for the modified workflow.
5. **Repeat:** Continue this cycle until the code is perfect, fully analyzed, fully tested, and the task is complete.

## Code Quality, Architecture & State Management

* **Clean Architecture:** Strictly separate concerns. Break down features into separate files for Models, Services/Repositories, Interfaces, and UI Components/Widgets.
* **State Management:** This project uses `ChangeNotifier` (e.g., `UserProvider`) and standard `StatefulWidget` `setState` patterns. Do not introduce third-party state management libraries (like Riverpod, Bloc, or GetX) unless explicitly instructed.
* **DRY Principle:** Abstract repetitive logic into utilities or base classes. This applies equally to both application code and test code.
* **FutureBuilder Safety:** NEVER instantiate a `Future` directly inside a `build()` method or pass an un-cached method call to a `FutureBuilder` (e.g., `future: fetchGames()`). You MUST cache all futures in state variables (using `initState` or `didUpdateWidget`) to prevent infinite rebuild loops, CPU spikes, and memory leaks.
* **Behavioral Data Assertions:** Unit and widget tests must go beyond simple line coverage. When modifying or saving data models, state objects, or forms, you must write explicit `expect()` assertions to verify the exact mutated data state (e.g., verifying the saved document payload in the `FakeFirebaseFirestore` database) rather than relying solely on successful UI execution.

## Testing Requirements & Established Mocks

* **100% Unit Test Coverage (HARD REQUIREMENT):**  Every file you create or modify MUST have 100% test coverage.
  * You may NOT simply assume coverage is 100% because the tests pass.
  * You MUST run `flutter test --coverage`.
  * You MUST programmatically verify your coverage by creating a temporary script named `check_coverage.dart` in the project root with the following code (replacing `TARGET_FILE.dart` with your modified file):

       ```dart
       import 'dart:io';
       void main() {
         var lines = File('coverage/lcov.info').readAsLinesSync();
         bool inTarget = false;
         List<String> uncovered = [];
         for (var line in lines) {
           if (line.startsWith('SF:') && line.contains('TARGET_FILE.dart')) {
             inTarget = true;
           } else if (line == 'end_of_record') {
             inTarget = false;
           } else if (inTarget && line.startsWith('DA:') && line.endsWith(',0')) {
             uncovered.add(line.split(':')[3].split(','));
           }
         }
         print(uncovered.isEmpty ? '100% COVERAGE' : 'UNCOVERED LINES: $uncovered');
       }
       ```

  * Run the script using `dart run check_coverage.dart`.
  * Delete the `check_coverage.dart` file immediately after verification to keep the workspace clean and prevent static analysis warnings.
  * If the script outputs ANY uncovered lines, you must write additional tests to cover them BEFORE outputting your Completion Report.
* **Use Existing Mocking Patterns:** Do not invent new ways to mock Firebase or local storage. You must use the established patterns in the codebase:
  * **Firestore:** Use `FakeFirebaseFirestore` and inject it via `DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore)`.
  * **Auth:** Use `MockFirebaseAuth` and inject it via `UserProvider().setAuthInstanceForTesting(mockAuth)`.
  * **Storage:** Use `SharedPreferences.setMockInitialValues({})`.
  * **Location:** Use the existing `MockGeolocatorPlatform` and `MockGeocodingPlatform`.
* **Patrol E2E & Integration Tests:** We have migrated our integration testing infrastructure to Patrol. If you are implementing or modifying a workflow, you must write or update end-to-end tests to validate that flow using the Patrol framework (`patrolTest` blocks).
  * All integration tests must be placed in the appropriate domain-based subdirectory within the `patrol_test/` folder (e.g., `auth/`, `courses/`, `game_setup/`, `gameplay/`, `navigation/`).
  * When writing Patrol tests, inject `final tester = $.tester;` at the top of the test block to leverage standard Flutter widget test assertions where appropriate, and utilize Patrol's native automation (e.g., `$.native.tap()`) when physical OS-level UI interaction is required.
  * Do not create tests in the legacy `integration_test/` folder.
* **Test Driven:** Validate your code by running the tests before finalizing your work.

## Documentation & Business Rules

* Before modifying identity management, authentication, or claiming logic, you must read the `identity-roadmap.md` and `claim-service-contract.md` files.
* Before modifying course creation or location logic, you must read the `course-location-awareness.md` file.

## Version Control & Commits

* **Conventional Commits:** We use a standard version library that relies on semantic versioning. You must make regular Git commits using the Conventional Commits format:
  * `feat(scope): description` (for new features)
  * `fix(scope): description` (for bug fixes)
  * `test(scope): description` (for adding missing tests)
  * `refactor(scope): description` (for code changes)
* Ensure commit messages are descriptive and atomic.

## Output: The Completion Report

While a task is in progress, you may converse normally to debug or clarify requirements. However, **whenever you complete a task, your final turn MUST output a standardized "Completion Report" in markdown format.** Do not append conversational fluff before or after this report.
**CRITICAL:** You must include the exact console output of the Dart coverage script proving `100% COVERAGE` inside the Testing & Coverage Status section of your report. You are not allowed to output this report until the script confirms there are no uncovered lines.

### Antigravity Completion Report

**Task Completed:** [Brief summary of the objective]

**1. Static Analysis & Architecture:**

* [Confirmation that analysis passed with 0 errors, warnings, and info messages]
* [List of files created or modified, noting Clean Architecture separation]

**2. Testing & Coverage Status:**

* [Confirmation of 100% coverage for modified files]
* [Summary of unit and integration tests added]
* [Note any DRY improvements made in the test suite]

**3. Git Commits Log:**

* [List the exact Conventional Commit messages used]

**4. Edge Cases & Notes:**

* [Document any unexpected behavior, technical debt resolved, or architectural decisions made]

---
description: "Antigravity Agent: Baseline Protocol and Operating Instructions"
---

# AGENTS.MD

## Role & Environment

You are working on the "Mini Golf Score Tracker" application. You are an expert Flutter & Dart Developer operating in a Windows or MacOS environment.

### Tool Usage & Execution Policy (CRITICAL)

You have full access to an extensive suite of MCP tools. You are STRICTLY PROHIBITED from running raw terminal/shell commands (e.g., `git`, `firebase`, `patrol`, `dart`, `flutter`) if a corresponding MCP tool exists. You MUST use the built-in MCP tools for debugging, searching, configuring, or analyzing the codebase:

* **Testing & UI:** Use `Patrol MCP` or `Marionette MCP` (Do NOT run raw patrol or mobile test commands in the shell).
* **Backend & Data:** Use `Firebase MCP` (Do NOT use raw Firebase CLI commands).
* **Development & Version Control:** Use `Dart MCP` and `Github MCP` (Do NOT use raw `dart`, `flutter`, or `git` terminal commands).
* **Knowledge & APIs:** Use `Google Maps Code Assist MCP`, `Google Developer Knowledge MCP`, and `Upstash Context7 MCP`.

**PowerShell Hacking & Piping Restriction:** You are strictly forbidden from chaining terminal commands using PowerShell pipes (`|`), `Select-String`, or `Select-Object` to capture test output. Do not attempt to truncate logs manually to bypass your system limits. Rely entirely on the event-driven, token-optimized data structures returned directly by your connected MCP actions.

Failure to use the designated MCP tool when available is considered a failure to follow system instructions. If you require a capability not covered by these tools, state the reason clearly before using a raw terminal command.

## Development Workflow & Iteration Loop

You must follow this strict iterative loop for every task until completion:

1. **Make Code Changes:** Implement the requested feature, fix, or architectural change.
2. **Run Static Analysis:** Invoke the `dart-mcp-server / analyze_files` tool (or your platform's native Dart static analysis MCP hook) to parse the workspace. Do not spawn a raw shell process for this step. Ensure the tool returns ZERO errors, ZERO warnings, and ZERO info messages before moving forward. If anything is flagged, fix it immediately.
3. **Run Unit Tests:** Execute the unit test suite exclusively using the `Dart MCP` test tool infrastructure to benefit from warm-VM execution and token-saving JSON payloads. Do not invoke raw terminal testing strings.
4. **Run Patrol-based Integration Tests:** Execute integration tests via `Patrol MCP` if appropriate for the modified workflow.
5. **Repeat:** Continue this cycle until the code is perfect, fully analyzed, fully tested, and the task is complete.
6. **Incremental Refactoring (The Boy Scout Rule):** When tasked with updating a feature currently residing in the flat `./lib` directory, your first sub-task is to migrate that feature's core logic into the `lib/features/[feature_name]/` sub-directories. Do not add code to the legacy flat files.

## Code Quality, Architecture & State Management

* **Directory Structure: (STRICT CONSTRAINTS)** You must strictly follow this Clean Architecture skeleton:
  * `lib/core/` (shared utilities, network clients, base classes)
  * `lib/features/[feature_name]/data/` (models, repositories, data sources)
  * `lib/features/[feature_name]/domain/` (entities, service interfaces)
  * `lib/features/[feature_name]/presentation/` (widgets, controllers/providers)
* **Anti-Bloat Rule: (STRICT CONSTRAINTS)** Individual Dart files must never exceed **250 lines of code**. If a change causes a file to cross this limit, you MUST break it down, extract widgets into separate files, or move reusable logic to a service layer before submitting.
* **DRY Service Extraction: (STRICT CONSTRAINTS)** Do not append business logic directly into existing presentation files. Repetitive tasks or multi-service orchestrations must be refactored into domain-level services or shared repository extensions.
* **State Management:** This project uses `ChangeNotifier` (e.g., `UserProvider`) and standard `StatefulWidget` `setState` patterns. Do not introduce third-party state management libraries (like Riverpod, Bloc, or GetX) unless explicitly instructed.
* **DRY Principle:** Abstract repetitive logic into utilities or base classes. This applies equally to both application code and test code.
* **FutureBuilder Safety:** NEVER instantiate a `Future` directly inside a `build()` method or pass an un-cached method call to a `FutureBuilder` (e.g., `future: fetchGames()`). You MUST cache all futures in state variables (using `initState` or `didUpdateWidget`) to prevent infinite rebuild loops, CPU spikes, and memory leaks.
* **Behavioral Data Assertions:** Unit and widget tests must go beyond simple line coverage. When modifying or saving data models, state objects, or forms, you must write explicit `expect()` assertions to verify the exact mutated data state (e.g., verifying the saved document payload in the `FakeFirebaseFirestore` database) rather than relying solely on successful UI execution.

## Testing Requirements & Established Mocks

* **100% Unit Test Coverage (HARD REQUIREMENT):** Every file you create or modify MUST have 100% test coverage.
* You may NOT simply assume coverage is 100% because the tests pass.
* **Verifying Coverage via MCP:** Instruct your `Dart MCP` server to execute the test harness with coverage monitoring enabled to generate the local `coverage/lcov.info` payload.
* To programmatically verify this coverage without triggering shell filters, invoke your local verification logic by passing a clean file-read or script execution call targeting your file directly through your MCP workspace utilities. For confirmation tracking, you may generate a temporary script named `check_coverage.dart` in the project root containing the following code (replacing `TARGET_FILE.dart` with your modified file):

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
      uncovered.add(line.split(':')[1].split(',')[0]);
    }
  }
  print(uncovered.isEmpty ? '100% COVERAGE' : 'UNCOVERED LINES: \$uncovered');
}
```

* Execute this checking payload through your file runner tool, capture its unadulterated stdout message, and delete the temporary `check_coverage.dart` file immediately afterward to keep the workspace clean.
* If the output highlights ANY uncovered lines, you must write additional tests to cover them BEFORE outputting your Completion Report.
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

* **Conventional Commits:** We use a standard version library that relies on semantic versioning. You must make regular Git commits using the Conventional Commits format via your Git/GitHub MCP toolkit:
  * `feat(scope): description` (for new features)
  * `fix(scope): description` (for bug fixes)
  * `test(scope): description` (for adding missing tests)
  * `refactor(scope): description` (for code changes)
* Ensure commit messages are descriptive and atomic.

## Output: The Completion Report

While a task is in progress, you may converse normally to debug or clarify requirements. However, **whenever you complete a task, your final turn MUST output a standardized "Completion Report" in markdown format.** Do not append conversational fluff before or after this report.

**CRITICAL:** You must include the exact console output of the Dart coverage verification step proving `100% COVERAGE` inside the Testing & Coverage Status section of your report. You are not allowed to output this report until the validation confirms there are no uncovered lines.

### Antigravity Completion Report

**Task Completed:** [Brief summary of the objective]

**1. Static Analysis & Architecture:**

* [Confirmation that analysis passed via MCP with 0 errors, warnings, and info messages]
* [List of files created or modified, noting Clean Architecture separation]

**2. Testing & Coverage Status:**

* [Confirmation of 100% coverage for modified files]
* [Summary of unit and integration tests added via Dart/Patrol MCP tool suites]
* [Note any DRY improvements made in the test suite]

**3. Git Commits Log:**

* [List the exact Conventional Commit messages dispatched via Git/GitHub MCP tools]

**4. Edge Cases & Notes:**

* [Document any unexpected behavior, technical debt resolved, or architectural decisions made]

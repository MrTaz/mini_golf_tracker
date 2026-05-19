---
description: "Antigravity Agent: Baseline Protocol and Operating Instructions"
---

# Role & Environment
You are an expert Flutter & Dart Developer operating in a Windows environment with full access to Dart, Flutter, and Firebase MCP tools. You are working on the "Mini Golf Score Tracker" application.

# Development Workflow & Iteration Loop
You must follow this strict iterative loop for every task until completion:
1. **Make Code Changes:** Implement the requested feature, fix, or architectural change.
2. **Run Static Analysis:** Execute the `flutter analyze` command directly in the terminal/shell. Do not rely solely on the `dart-mcp-server / analyze_files` tool. You must ensure the terminal output shows ZERO errors, ZERO warnings, and ZERO info messages before moving to the next step. If the analyzer flags anything, fix it immediately and re-run the terminal command.
3. **Run Unit Tests:** Execute the unit test suite for the modified files.
4. **Run Integration Tests:** Execute integration tests if appropriate for the modified workflow.
5. **Repeat:** Continue this cycle until the code is perfect, fully analyzed, fully tested, and the task is complete.

# Code Quality, Architecture & State Management
*   **Clean Architecture:** Strictly separate concerns. Break down features into separate files for Models, Services/Repositories, Interfaces, and UI Components/Widgets.
*   **State Management:** This project uses `ChangeNotifier` (e.g., `UserProvider`) and standard `StatefulWidget` `setState` patterns. Do not introduce third-party state management libraries (like Riverpod, Bloc, or GetX) unless explicitly instructed.
*   **DRY Principle:** Abstract repetitive logic into utilities or base classes. This applies equally to both application code and test code.

# Testing Requirements & Established Mocks
*   **100% Unit Test Coverage:** Every file you create or modify MUST have 100% test coverage. This includes all lines, statements, functions, and logical branches. Verify this explicitly by inspecting the generated coverage files if available.
*   **Use Existing Mocking Patterns:** Do not invent new ways to mock Firebase or local storage. You must use the established patterns in the codebase:
    *   **Firestore:** Use `FakeFirebaseFirestore` and inject it via `DatabaseConnection.setFirestoreInstanceForTesting(fakeFirestore)`.
    *   **Auth:** Use `MockFirebaseAuth` and inject it via `UserProvider().setAuthInstanceForTesting(mockAuth)`.
    *   **Storage:** Use `SharedPreferences.setMockInitialValues({})`.
    *   **Location:** Use the existing `MockGeolocatorPlatform` and `MockGeocodingPlatform`.
*   **Integration Tests:** If you are implementing or modifying a workflow, you must write integration tests to validate the end-to-end behavior of that flow.
*   **Test Driven:** Validate your code by running the tests before finalizing your work.

# Documentation & Business Rules
*   Before modifying identity management, authentication, or claiming logic, you must read the `identity-roadmap.md` and `claim-service-contract.md` files.
*   Before modifying course creation or location logic, you must read the `course-location-awareness.md` file.

# Version Control & Commits
*   **Conventional Commits:** We use a standard version library that relies on semantic versioning. You must make regular Git commits using the Conventional Commits format:
    *   `feat(scope): description` (for new features)
    *   `fix(scope): description` (for bug fixes)
    *   `test(scope): description` (for adding missing tests)
    *   `refactor(scope): description` (for code changes)
*   Ensure commit messages are descriptive and atomic.

# Output: The Completion Report
While a task is in progress, you may converse normally to debug or clarify requirements. However, **whenever you complete a task, your final turn MUST output a standardized "Completion Report" in markdown format.** Do not append conversational fluff before or after this report.

### Antigravity Completion Report
**Task Completed:** [Brief summary of the objective]

**1. Static Analysis & Architecture:**
*   [Confirmation that analysis passed with 0 errors, warnings, and info messages]
*   [List of files created or modified, noting Clean Architecture separation]

**2. Testing & Coverage Status:**
*   [Confirmation of 100% coverage for modified files]
*   [Summary of unit and integration tests added]
*   [Note any DRY improvements made in the test suite]

**3. Git Commits Log:**
*   [List the exact Conventional Commit messages used]

**4. Edge Cases & Notes:**
*   [Document any unexpected behavior, technical debt resolved, or architectural decisions made]
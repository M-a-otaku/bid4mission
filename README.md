<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

# Bid4Mission

A Flutter mobile/web app for posting and bidding on short-term tasks ("missions").
This repository contains an app where Employers create missions, Hunters (service providers) discover them, submit proposals, and Employers accept, confirm or reject completions. The project uses GetX for state management and routing, a small repository/service layer for backend requests, and supports localization (English / Persian).

This README explains how to run the project, the main folder structure, the app architecture and data flow, and example user scenarios (receive mission, add mission, manage roles and statuses).

---

## Table of contents

- Project overview
- Requirements & prerequisites
- Quick start — run the app
- Folder structure (high level)
- Architecture & patterns
- Roles & Status enums
- Common flows / example scenarios
  - Hunter: discover & request a mission
  - Employer: create a mission
  - Employer: confirm or reject a mission completion
  - Automatic expiration and failure rules
- Theming & localization
- Debugging and development tips
- Tests and next steps

---

## Project overview

Bid4Mission is a Flutter app that demonstrates a small marketplace for one-off tasks:

- Employers create missions with title, description, category, budget and deadline.
- Hunters browse missions, search and filter (server-backed search and suggestions), and submit proposals/bids.
- Employers can accept proposals, and Hunters can mark a mission as completed; Employers then confirm or reject completion.
- The app stores transient UI overlays for user actions until the server confirms changes and includes logic to auto-fail or expire missions when deadlines pass.

This repo is meant to be run locally and tested against a JSON-based server (or your own backend).

---

## Requirements & prerequisites

- Flutter SDK (2.10+ recommended; use the channel/SDK used by this repo). Verify with:

```bash
flutter --version
```

- A device or emulator for Android / iOS, or use web with `flutter run -d chrome`.
- (Optional) A JSON server or REST API endpoint that the app talks to (by default the sample project used a JSON server): ensure the URLs in `lib/.../UrlRepository` (or repository classes) point to your server.

---

## Quick start — run the app

1. Clone the repo and fetch packages:

```bash
git clone <repo-url>
cd Bid4Mission
flutter pub get
```

2. Run on an Android emulator:

```bash
flutter emulators --launch <name>
flutter run -d <emulator-id>
```

3. Run on Windows (desktop) / Web / iOS as needed:

```bash
# web
flutter run -d chrome

# windows
flutter run -d windows

# ios (macOS host)
flutter run -d <ios-simulator>
```

4. Hot reload / Restart while developing:

- `r` → hot reload
- `R` → full restart (useful after changing controllers or theme storage logic)


---

## Folder structure (high level)

A condensed overview of the most important folders and files in this repo:

- `lib/` — app code
  - `bid4mission.dart` — package export entry (if used as a package)
  - `main.dart` — app entry
  - `src/`
    - `app.dart` — top-level widget and route binding
    - `generated/` — generated localization files (e.g. `locales.g.dart`)
    - `infrastructure/` — app-wide services and commons
      - `commons/` — enums (e.g. `status.dart`, `role.dart`), util helpers
      - `repositories/` — network/data access classes
      - `services/` — theme service, localization, storage helpers
    - `pages/` — feature pages and their subfolders
      - `missions/` — mission list, create/edit mission, controllers
      - `profile/` — hunter/employer profiles and proposal management
      - ... other pages
    - `components/` — shared widgets (chips, inputs, dialogs)

- `assets/` — images and static assets
- `i18n/` — raw localization JSONs (fa_IR.json, en_US.json)
- `test/` — unit/widget tests (sample)

This project's controllers typically live alongside their views (GetX controllers), repositories wrap HTTP calls, and models/dtos live in the relevant feature folder.

---

## Architecture & patterns

The app follows a small MV(U)C-like pattern using GetX for state management and navigation. Key patterns:

- Controllers (GetxController) hold UI state and expose reactive fields (`.obs`). They orchestrate calls to repositories and expose computed getters for the UI.
- Repositories are responsible for HTTP requests and low-level data mapping (JSON ↔ models). They return either futures or a Result/Either style (depending on implementation).
- Models and DTOs (Data Transfer Objects) are small classes in `pages/*/models` used to convert API payloads into UI-friendly objects. Use `parseStatus` and `statusToString` helpers to map status strings to the app's `Status` enum.
- Views (Widgets) are kept mostly declarative and read reactive fields or getters from controllers using `Obx`, `GetX`, or `GetView<T>`.
- Theme toggling and persistence are handled by a ThemeService which reads/writes the selected theme mode to local storage and notifies GetX navigation to change the app theme.
- Localization: JSON files live in `i18n/`; a generation step produces `locales.g.dart`. Use `LocaleKeys.*.tr` or the generated helpers for translations.

Data flow example (Hunter submits a proposal):

1. Hunter taps "Submit proposal" → view calls controller.submitBid(missionId, ...)
2. Controller validates input, shows a loading dialog and calls a repository method like `ProposalRepository.submitProposal(dto)`
3. Repository performs POST to server and returns result/failure
4. Controller updates local proposals list (applies overlay) and calls `loadMissions()` or `loadProposals()` to refresh from server
5. UI reacts to controller's `proposals` observable and updates lists

---

## Roles & Status enums

The app uses enums to represent roles and mission/proposal statuses. Look at `lib/src/infrastructure/commons/role.dart` and `lib/src/infrastructure/commons/status.dart`.

- Roles (Role enum): `hunter`, `employer` — prefer using the enum rather than raw strings throughout the codebase.
- Status (Status enum): typical values include `open`, `inProgress` (or `in_progress`), `pendingApproval` (`pending_approval`), `completed`, `failed`, `expired`.

Use the provided extension helpers to test statuses (e.g., `mission.status.isPendingApproval`) and to get a UI color for a status (`mission.status.color`).

---

## Common flows / example scenarios

Below are step-by-step scenarios showing how the main user journeys are implemented and which code areas to look at.

### 1) Hunter: discover & request a mission (receive mission)

- UI: `pages/missions/mission_list/views/missions_list_view.dart` — shows the list, search, and filters.
- Search & suggestions: a SmartTagInput component queries the server for categories/suggestions (server-backed, UTF-8 safe decoding). Look for code in `components` or a `SuggestionRepository`.
- When user taps a mission card (and role==hunter):
  - If mission.status == Status.open, controller opens the submit bid dialog (`controller.submitBid(...)`).
  - The submit dialog enforces numeric budget input (ThousandsSeparatorInputFormatter used) and validation.
- Controller flow: `MissionsListController.submitBid` calls the proposal repository to create a proposal. On success, the controller updates local proposals and optionally refreshes the mission list.

Key files: controller file in `pages/missions/*/controllers`, `ProposalRepository` implementation, submit dialog widget.


### 2) Employer: create a mission (add mission)

- UI: `pages/missions/create_mission` view and controller. The FAB for employers opens the create mission form.
- Validations:
  - Title/description not empty.
  - Budget must be numeric (formatter ensures thousand separators visually) and positive.
  - Deadline must be not earlier than now (UI prevents selecting past date/time for both day and time fields).
- On submit:
  - Controller builds a DTO and calls repository `MissionRepository.createMission(dto)` (POST).
  - On success, controller navigates back to the list and refreshes missions.

Key files: create/edit mission views, `MissionRepository`.


### 3) Employer: confirm or reject a mission completion (UI improvements)

- When a hunter marks a mission as completed, the mission moves (or the proposal moves) to a `pendingApproval` state.
- On the employer's mission list view, pending items show a prominent confirm/reject button bar (instead of small icons). The confirm path calls `controller.confirmMissionCompletion(mission: mission)` which calls the repository to update the mission's status (PATCH/PUT). The reject path calls `controller.rejectMission(mission: mission)` which updates status to `failed`.
- The controller uses a `processingMissionIds` set to disable the buttons while awaiting server response and to avoid duplicate clicks.

Key behavior to check in the code:
- Local overlay: when Hunter signals completion, the controller often sets a local flag (e.g., `_locallyPendingApproval`) so UI reflects the requested state before the server responds. `HunterProfileController` and `MissionsListController` contain logic to reconcile server state after refresh.
- Preventing duplicate clicks: UI disables buttons while `processingMissionIds` contains the mission id.


### 4) Automatic expiration and failure rules

- When missions are fetched the controllers check `deadline` vs now and apply rules:
  - If a mission's deadline has passed and it had an accepted proposal in progress, it may be auto-marked as `failed`. The controller may send a request to the server to persist this change and update local lists.
  - If the mission had `pendingApproval` and deadline passed, some logic treats it as `failed` (or reconciles to whichever server-side rule you prefer). See `HunterProfileController._normalizeProposals` and `_autoFailExpiredAcceptedProposals` for sample logic.

Note: Business rules for expiration can be tuned both in the controller and on the server. The app tries to apply a safe local overlay first then reconcile with server responses.

---

## Theming & localization

- Themes: The app supports dark/light themes and persists the user's choice in local storage (ThemeService). Floating action button, AppBar and other components should obtain colors from ThemeData (recommended to centralize FloatingActionButtonTheme in the theme data).
- Localization: Source JSON files live in `i18n/` (fa_IR.json, en_US.json). Generated code produces `locales.g.dart` and `LocaleKeys` helpers. Use `LocaleKeys.*.tr` to access translations.

---

## Debugging and development tips

- Look for `Get.log('[ControllerName] ...')` statements added in controllers (helpful when tracing why an item appears in one list and not another).
- Use `flutter run` in debug mode and watch the console for the Get.log debug lines.
- If you get the "setState() or markNeedsBuild() called during build" error with GetX, the typical cause is changing theme or calling `update()` while widgets are building; move such calls to post-frame or avoid toggling UI state inside `onInit` of a controller that is being built in the same frame.
- When editing enums (Status/Role) prefer to update all usage sites; search for the old strings and replace with `Status`/`Role` enum usage.

Common commands useful during development:

```bash
# get dependencies
flutter pub get

# run on chrome
flutter run -d chrome

# analyze and run tests
flutter analyze
flutter test
```

---

## Tests and next steps

- Add unit tests for controllers: create small tests mocking repositories and verify the controller's list shaping methods (e.g., `_recomputeCategories`, expiration logic).
- Add integration tests for key flows: create mission → submit proposal → employer confirm.
- Consider centralizing all color tokens into a single `AppColors` file and reference from ThemeData so theme changes and dark/light contrast are consistent.

---

## Where to look next in the codebase

- `lib/src/pages/missions/` — mission list, create/edit views and controllers
- `lib/src/pages/profile/` — hunter/employer profile pages and proposal controllers (see `HunterProfileController`)
- `lib/src/infrastructure/commons/status.dart` — Status enum and UI color mapping
- `lib/src/infrastructure/services/theme_service.dart` — theme persistence and toggling logic
- `lib/src/infrastructure/repositories/` — HTTP / data access layer

---

If you want, I can:

- Convert this README to include screenshots and example API JSON payloads for the server endpoints used by the app.
- Add an example local `db.json` for the JSON server that matches the repository expectations.
- Draft unit tests for `HunterProfileController._recomputeCategories` and the mission expiration logic.

Tell me which of the three you'd like next and I will implement it.

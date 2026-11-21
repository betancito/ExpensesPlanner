---
id: BP-002
status: done
owner: developer
reviewer_verdict: pass
---

# Feature: Initial Xcode project

## Goal and user value

Create a native iOS application foundation in the repository root so later finance features can be built, tested in a simulator, and eventually deployed to the user's iPhone.

## Acceptance criteria

- [x] `ExpensesPlanner.xcodeproj` exists in the repository root and opens as a runnable iOS app.
- [x] The app uses Swift and SwiftUI, with `ExpensesPlanner` as its display name.
- [x] The app launches to a simple provisional screen without requiring a backend or network access.
- [x] The bundle identifier is `com.betancito.ExpensesPlanner`; the deployment target is iOS 17.0 unless the toolchain requires a documented adjustment.
- [x] Unit and UI test targets follow Xcode conventions and contain meaningful launch/smoke coverage.
- [x] The standard simulator build and tests pass.
- [x] README explains how to open, build, and test the project.
- [x] No finance model, persistence, or product UI is implemented beyond the provisional launch screen.

## Scope

### In scope

Native Xcode project, SwiftUI app entry point, provisional launch screen, unit/UI test targets, simulator verification, and basic developer instructions.

### Out of scope

Financial features, local persistence design, physical-device deployment, Apple Developer enrollment, signing credentials, App Store configuration, and third-party dependencies.

## Technical plan

Use the installed Xcode 27.2 toolchain and no external packages. Keep signing team unset for simulator builds. Physical-device signing will be configured with the user later. See [[project]] and [[decisions|D-001]].

## Test plan

- Build for an available iOS simulator using `xcodebuild`.
- Run unit and UI tests using `xcodebuild test`.
- Confirm the provisional screen appears through the UI smoke test.
- Review project structure and confirm no secrets, build output, or unrelated files are included.

## Implementation handoff

Resumed the existing implementation on 2026-11-21 without changing the Xcode project, app source, tests, README, or `.gitignore`. Xcode 27.2 (27B52) built and tested the shared `ExpensesPlanner` scheme on the iPhone 17 iOS 26.5 simulator.

Documented build command, run from the repository root:

```sh
xcodebuild -project ExpensesPlanner.xcodeproj \
  -scheme ExpensesPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

Result: exit 0, `** BUILD SUCCEEDED **`.

Documented test command:

```sh
xcodebuild -project ExpensesPlanner.xcodeproj \
  -scheme ExpensesPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Result: exit 0, `** TEST SUCCEEDED **`. The xcresult summary reports 2 total tests, 2 passed, 0 failed, and 0 skipped: `testProvisionalLaunchContentUsesExpectedCopy()` and `testLaunchDisplaysProvisionalScreen()`. The UI test launched `com.betancito.ExpensesPlanner`, confirmed foreground state, and found both provisional-screen accessibility identifiers.

`xcodebuild -list -project ExpensesPlanner.xcodeproj` lists the app, unit-test, and UI-test targets and the shared scheme. Project inspection confirms Swift 5, SwiftUI entry point, display name `ExpensesPlanner`, bundle identifier `com.betancito.ExpensesPlanner`, iOS 17.0 deployment target, and no signing team. Source inspection found only the provisional SwiftUI screen and its smoke tests; no finance model, persistence, network/backend code, or third-party dependency was added. `git diff --check` passed. Physical-device deployment remains unverified and out of scope.

## Review evidence

PASS — independent review on 2026-11-21. Reviewed the BP-002 working tree, project configuration, app source, tests, README, and `.gitignore`; no findings. With Xcode 27.2 (27B52), the documented iPhone 17 iOS 26.5 build exited 0 (`BUILD SUCCEEDED`) and test exited 0 (`TEST SUCCEEDED`). The independent xcresult summary reported 2 total, 2 passed, 0 failed, and 0 skipped. The UI smoke test launched `com.betancito.ExpensesPlanner` and verified the foreground provisional title and message. `xcodebuild -list` showed all three targets and the shared scheme; the built Info.plist confirmed display name `ExpensesPlanner`, bundle identifier `com.betancito.ExpensesPlanner`, and minimum iOS 17.0. `git diff --check` exited 0. Physical-device deployment remains untested and out of scope.

## Completion

Planner accepted the implementation and independent PASS. Git reference and push result are reported in the final planner handoff and repository history. Next: BP-001 product discovery and BP-003 first finance workflow.

# ExpensesPlanner

A personal iPhone expenses-planning app. Financial data is stored locally in the app; App Store publication is not currently a goal.

## Open, build, and test the iOS app

The project uses SwiftUI and XCTest without third-party dependencies. It currently contains only a provisional launch screen, a unit-test target, and a UI-test target. Xcode 27.2 is the verified toolchain; the app's deployment target is iOS 17.0.

Open the project in Xcode:

```sh
open ExpensesPlanner.xcodeproj
```

Select the **ExpensesPlanner** scheme and an iOS simulator, then use **Product > Run** to launch or **Product > Test** to run both test targets. Physical-device signing is not configured.

To build from the repository root with the verified simulator destination:

```sh
xcodebuild -project ExpensesPlanner.xcodeproj \
  -scheme ExpensesPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

To run the unit and UI tests on the same simulator:

```sh
xcodebuild -project ExpensesPlanner.xcodeproj \
  -scheme ExpensesPlanner \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

Use `xcrun simctl list devices available` to find another installed simulator and adjust the destination's name and OS if needed.

## Start the agent workflow

```sh
kimi --agent planner
```

The planner is the main point of contact. It delegates approved feature plans to the developer, the developer runs a fix-and-retest loop with the reviewer, and accepted work returns to the planner for final review and Git publishing.

Project agents are defined in `.kimi-code/agents/`. The `expenses-planner-brain` skill restores compact project context automatically.

## Obsidian project memory

Open the `.brain` folder as an Obsidian vault, then start at `home.md`. Durable status lives in `current-handoff.md`; feature plans, reviews, decisions, and the backlog use linked notes.

To resume an existing Kimi conversation instead, run `kimi --continue`; it restores the agent selected for that session.


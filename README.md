# ExpensesPlanner

A personal iPhone expenses-planning app. Financial data is stored locally in the app; App Store publication is not currently a goal.

## Open, build, and test the iOS app

The project uses SwiftUI, SwiftData, and XCTest without third-party dependencies. It currently contains a provisional launch screen, local finance models with a pure budget engine, a unit-test target, and a UI-test target. Xcode 27.2 is the verified toolchain; the app's deployment target is iOS 17.0.

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

## CNY/COP exchange rates

The exchange-rate service requests only `https://open.er-api.com/v6/latest/CNY`. This is the public [ExchangeRate-API](https://www.exchangerate-api.com) endpoint; no API key, credentials, account data, budget data, expenses, or other financial information are included in the request. Requests use an ephemeral `URLSession` and a 15-second timeout.

Successful responses are validated for a successful provider result, a CNY base currency, a positive finite Decimal COP-per-CNY rate, and the provider's update timestamp. Each successful refresh saves a local SwiftData snapshot containing the rate, timestamp, provider attribution, endpoint source, and network origin. If refresh fails, the service returns the newest locally saved snapshot and leaves the cache unchanged.

A positive finite manual COP-per-CNY rate can also be saved for offline use. Manual snapshots use the device's local timestamp and explicit manual-origin metadata. Results expose the rate timestamp, provider/source, network-versus-manual origin, and whether the value came from the network, cache, or manual entry so future UI can label it accurately. The provisional UI does not currently display or select exchange rates.

All exchange-rate tests use injected mocked transport and clocks; they do not access the real network.

## Start the agent workflow

```sh
kimi --agent planner
```

The planner is the main point of contact. It delegates approved feature plans to the developer, the developer runs a fix-and-retest loop with the reviewer, and accepted work returns to the planner for final review and Git publishing.

Project agents are defined in `.kimi-code/agents/`. The `expenses-planner-brain` skill restores compact project context automatically.

## Obsidian project memory

Open the `.brain` folder as an Obsidian vault, then start at `home.md`. Durable status lives in `current-handoff.md`; feature plans, reviews, decisions, and the backlog use linked notes.

To resume an existing Kimi conversation instead, run `kimi --continue`; it restores the agent selected for that session.


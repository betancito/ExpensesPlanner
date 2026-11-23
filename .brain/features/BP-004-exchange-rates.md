---
id: BP-004
status: done
owner: planner
reviewer_verdict: pass
---

# Feature: Public, cached, and manual CNY-COP exchange rates

## Goal and user value

Provide current CNY-to-COP conversion rates for future budget and expense workflows while keeping financial records local and preserving offline functionality.

## Acceptance criteria

- [x] Fetch `https://open.er-api.com/v6/latest/CNY` with no credentials and no financial data in the request.
- [x] Validate successful responses, CNY base, a positive finite COP-per-CNY rate, and provider timestamp.
- [x] Persist exchange-rate snapshots locally with rate, timestamp, source/provider, and manual-versus-network origin.
- [x] Add the model to the app's local SwiftData container without changing the provisional UI.
- [x] Return the newest locally cached rate when offline or when refresh fails; never delete the last valid cached rate on failure.
- [x] Allow a manual positive finite COP-per-CNY rate with a local timestamp for offline use.
- [x] Expose enough source and timestamp information for later UI to distinguish network, cached, and manual rates.
- [x] Use `Decimal` for money/rates and async Swift networking with explicit timeout/error handling.
- [x] Unit tests cover decoding, invalid responses/rates, network errors, cache fallback, manual rates, and in-memory persistence without real network access.
- [x] Document provider, attribution/source, request privacy, and service behavior in README and implementation handoff.
- [x] Existing build and full unit/UI test action pass; no production UI, third-party dependency, or financial-data request is added.

## Scope

### In scope

Exchange-rate model, transport and decoding, local cache/repository/service API, manual rate entry API, deterministic tests, and documentation. Follow [[decisions|D-004 and D-005]].

### Out of scope

Rate-selection UI, expense entry, budget integration, charts, accounts, backend, analytics, cloud sync, and physical deployment.

## Technical plan

Use the verified public ExchangeRate-API endpoint. The planner confirmed on 2026-11-23 that it returns `result: success`, `base_code: CNY`, and a COP rate. Store `https://www.exchangerate-api.com` as provider/attribution. Inject transport and clock in tests; never require live network in the test suite. Keep the last valid snapshot after all failures.

## Test plan

- Decode a representative successful response and preserve its COP rate and timestamp.
- Reject provider errors, wrong base currencies, missing/nonpositive/NaN rates, malformed responses, HTTP errors, and timeouts.
- Verify newest-rate selection, failed-refresh fallback, cache preservation, manual rate validation, and in-memory round trips.
- Run the documented iPhone 17 iOS 26.5 simulator build and full unit/UI tests.
- Independently review request privacy, persistence, errors, and scope.

## Implementation handoff

Implemented the exchange-rate service in `ExpensesPlanner/ExchangeRates.swift`, registered its SwiftData snapshot model in `ExpensesPlanner/FinanceModelContainer.swift`, added deterministic coverage in `ExpensesPlannerTests/ExchangeRateTests.swift`, and documented behavior in `README.md`.

The service sends a credential-free GET to `https://open.er-api.com/v6/latest/CNY` with no financial data and attributes rates to ExchangeRate-API (`https://www.exchangerate-api.com`). It validates HTTP/provider success, CNY base, a positive finite Decimal COP-per-CNY rate, and the provider timestamp. Successful refreshes persist timestamped snapshots with source/provider and network origin; failed refreshes return the newest cached snapshot without deleting it. Manual positive finite rates use an injected local timestamp and manual-origin metadata, and results distinguish network, cached, and manual values.

Tests use injected mocked transport and clocks with no real network access, covering decoding, invalid responses/rates, network failures, cache fallback/preservation, manual rates, and in-memory persistence. The provisional UI was not changed.

## Review evidence

2026-11-23 — **PASS**. The initial `CHANGES_REQUESTED` documentation finding was resolved and independently rechecked.

- Independent build passed: `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO build` → `** BUILD SUCCEEDED **`.
- Independent full test action passed with the same project, scheme, destination, and signing override plus `test` → `** TEST SUCCEEDED **`. The resulting `.xcresult` summary reports 30/30 passed, 0 failed, 0 skipped: 29 unit tests (14 exchange-rate service tests and 15 existing/persistence tests) and 1 UI test.
- Verified by diff, source inspection, and tests: one fixed public GET request with no body, credentials, or financial data; ephemeral networking and 15-second timeouts; HTTP/provider/base/positive-finite-Decimal-rate/provider-timestamp validation; SwiftData snapshot metadata and container registration; newest-cache fallback without cache deletion; manual offline rates with injected local timestamps; network/cache/manual result metadata; deterministic mocked transport with no live-network tests.
- No production UI file changed, the provisional-screen UI test passed, and no third-party package/dependency was added. README documents provider, attribution, privacy, caching, fallback, manual rates, and test behavior.
- The initial finding was only the unfinished implementation-handoff placeholder. The developer replaced it with the required provider, attribution/source, request-privacy, implementation, and service-behavior documentation. Follow-up independent review returned `PASS`, with no discrepancies between the handoff, implementation, tests, and README. No code changed during that documentation fix, so the successful build and test evidence remains applicable.
- Limitations: no live provider request was made during automated tests, as required for deterministic tests without real network access; the planner separately verified the public endpoint responds successfully. Online decoding/error paths, cache fallback, and manual offline behavior were exercised through injected mocks. There is intentionally no exchange-rate production UI to exercise.

## Completion

Planner accepted the implementation and independent PASS on 2026-11-23. Git publishing is recorded in repository history. Next: BP-005 income, period, obligation, and savings-goal management screens.

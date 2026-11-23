---
id: BP-003
status: done
owner: planner
reviewer_verdict: pass
---

# Feature: Local finance models and budget engine

## Goal and user value

Create a tested, local-only financial domain that later UI features can use without duplicating money, period, conversion, or budget logic.

## Acceptance criteria

- [x] Add SwiftData models for budget periods, confirmed COP income, user-named period obligations, savings goals, and CNY expenses.
- [x] Money uses `Decimal`; no floating-point money calculations.
- [x] Each expense model retains CNY amount, positive COP-per-CNY rate, COP snapshot, timestamp, and category/note information needed by the roadmap.
- [x] Savings goals support target COP, optional target date, saved COP, and planned per-period allocation.
- [x] A pure budget engine calculates flexible spending, remaining COP, and daily CNY allowance using the formula in [[features/BP-001-finance-mvp|BP-001]].
- [x] Only confirmed income contributes; expected income has no spendable representation.
- [x] Inclusive date boundaries, the final day, zero/negative remaining funds, and invalid exchange rates are handled deterministically.
- [x] Unit tests cover calculations and in-memory SwiftData persistence/relationships.
- [x] Existing app build, unit tests, and UI smoke test pass.
- [x] The provisional UI remains unchanged and no networking or third-party dependency is added.

## Scope

### In scope

SwiftData local model container, finance models, pure budget calculation API, and unit tests. Follow [[decisions|D-004 through D-006]] and [[features/BP-001-finance-mvp|BP-001]].

### Out of scope

Exchange-rate networking, production forms, home UI, charts, Shortcuts, debts, cloud sync, and physical-device deployment.

## Technical plan

Use SwiftData with an in-memory test container and the existing SwiftUI app lifecycle. Keep budget calculations independent of SwiftUI and network code. Use the device's calendar with explicit date injection in tests. Preserve COP-per-CNY direction and entry-time COP snapshots.

## Test plan

- Run deterministic budget-engine tests for confirmed income, obligations, savings, expenses, inclusive days, over-budget behavior, and invalid rates.
- Run in-memory SwiftData round-trip tests for every model and important relationship.
- Run the documented iPhone 17 iOS 26.5 simulator build and full unit/UI test action.
- Independently review scope, data integrity, calculations, and persistence.

## Implementation handoff

Implemented `FinanceModels.swift`, `FinanceModelContainer.swift`, and `BudgetEngine.swift`; attached the local SwiftData container in `ExpensesPlannerApp.swift`; added `BudgetEngineTests.swift` and `FinancePersistenceTests.swift`; and updated the Xcode project and README. The provisional `ContentView` and UI smoke test are unchanged.

## Review evidence

PASS — independent review on 2026-11-23. Inspected the complete tracked and untracked BP-003 diff against every acceptance criterion and D-004 through D-006; no findings. All monetary fields and calculations use `Decimal`. SwiftData models and period relationships round-trip in the in-memory container, and the app attaches a local model container. Expenses retain their CNY amount, COP-per-CNY rate, entry-time COP snapshot, timestamp, category, and optional note. The pure engine uses confirmed income only, subtracts obligations, savings allocations, and stored expense snapshots, handles inclusive/final-day and post-period dates, clamps zero/negative allowances, flags negative remaining funds, and rejects zero, negative, and NaN rates. The provisional `ContentView` and UI test are unchanged; no networking, debts, cloud sync, or third-party dependency was added.

Independent Xcode 27.2 (27B52) verification on iPhone 17 iOS 26.5: the README build command exited 0 with `** BUILD SUCCEEDED **`; the README full test command exited 0 with `** TEST SUCCEEDED **`. The xcresult summary reported 15 total, 15 passed, 0 failed, 0 skipped: 14 unit tests and 1 UI test. The UI smoke test launched the app and verified the unchanged provisional title and message. `git diff --check` exited 0. No production finance UI exists to exercise, as intended for BP-003. Physical-device deployment and disk relaunch persistence were not tested; in-memory SwiftData persistence is the BP-003 requirement and physical deployment is out of scope.

## Completion

Planner accepted the implementation and independent PASS on 2026-11-23. Git reference and push result are reported in the final planner handoff and repository history. Next: BP-004 exchange-rate service.

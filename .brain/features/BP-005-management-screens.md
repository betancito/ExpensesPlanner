---
id: BP-005
status: done
owner: planner
reviewer_verdict: pass
---

# Feature: Income, period, obligation, and savings-goal management screens

## Goal and user value

Replace the provisional launch screen with useful Spanish-language management flows so the user can record confirmed COP income, define flexible coverage periods, manage period-specific obligations, and maintain savings goals. This supplies the real local data required by the later home budget and quick-expense workflows.

## Acceptance criteria

- [x] Replace the provisional screen with a polished SwiftUI management interface in Spanish, with clear navigation to budget periods and savings goals and useful empty states.
- [x] Create, edit, list, and delete budget periods with user-selected start and end dates; reject an end date before the start date. Do not hardcode payday schedules.
- [x] Within a period, create, edit, list, and delete confirmed incomes with positive COP amounts and received dates. Multiple incomes contribute to the same period and its displayed confirmed-income total.
- [x] Within a period, create, edit, list, and delete user-named obligations with non-empty trimmed names and positive COP amounts. Display the period's obligation total.
- [x] Show each period's date range, confirmed income, obligations, and remaining flexible amount before savings and expenses (`confirmed income - obligations`) in COP.
- [x] Create, edit, list, and delete savings goals with non-empty trimmed names, positive target COP, optional target date, nonnegative saved COP, and nonnegative planned per-period allocation COP.
- [x] Display saved amount, target, planned allocation, and savings progress for each goal. Target dates are optional and do not create expected income or automatic transactions.
- [x] Validate all form input using locale-aware decimal parsing and `Decimal` for money; invalid input must show a useful Spanish error and must not save partial data.
- [x] Confirm destructive deletes. Deleting a period must warn that its incomes, obligations, and any associated expenses are also deleted.
- [x] Persist changes through the existing local SwiftData container. No account, backend, analytics, cloud sync, or financial-data network request.
- [x] Add deterministic unit tests for new validation/calculation logic and SwiftData behavior as needed. Add UI tests that exercise real creation/editing, validation, navigation, and persistence across relaunch for the main management workflows.
- [x] Update the previous provisional-screen UI test to the new intended launch experience and preserve passing existing finance/exchange-rate tests.
- [x] Document the implemented workflows and exact verification in README, implementation handoff, and review evidence.

## Scope

### In scope

SwiftUI period/detail and savings management screens, reusable form/input validation, local CRUD using the existing models, COP summaries, accessibility identifiers needed by tests, and automated unit/UI coverage. Follow [[features/BP-001-finance-mvp|BP-001]], [[decisions|D-001, D-004, and D-006]], and the existing SwiftData/budget-engine conventions.

### Out of scope

Home daily/weekly allowance, CNY expense entry, exchange-rate selection or refresh UI, charts and metrics, Shortcuts, debts, automatic savings transactions, backend/cloud sync, and physical-device deployment. Do not change the entry-time exchange-rate semantics or add dependencies.

## Technical plan

Use native SwiftUI and the existing SwiftData models/container. A practical structure is a periods list with period-detail management and a separate savings-goal list, reachable from the app's root navigation. Keep form state and decimal parsing testable and independent where useful. Reuse or extend the pure finance calculations rather than duplicating money logic. Use locale-aware COP formatting and parsing, explicit accessibility identifiers, and Spanish validation/confirmation copy.

Preserve `BudgetPeriod` relationships and cascade behavior. Additional confirmed income remains associated with its user-selected coverage period; there is no expected-income representation. Savings allocations remain planned values, not transfers. Keep the public exchange-rate service dormant in this feature.

## Test plan

- Unit-test valid/invalid localized decimal and form input, date validation, trimming, period totals, and savings progress/clamping behavior if new pure logic is introduced.
- Retain all existing BP-003/BP-004 unit tests and verify in-memory persistence for any model/schema changes.
- UI-test launch and empty states; create a period; add multiple incomes and an obligation; edit values; verify COP totals; reject invalid input; create/edit a savings goal with and without optional target date; verify saved data remains after terminating and relaunching the app; exercise delete confirmation where practical.
- Run the documented iPhone 17 iOS 26.5 simulator build and complete unit/UI test action.
- Independently review actual UI flows, local persistence, calculations, validation, destructive behavior, accessibility/test reliability, privacy, and scope.

## Implementation handoff

Implemented the Spanish SwiftUI management UI and local SwiftData workflows without adding dependencies or changing the dormant exchange-rate service. `ContentView.swift` now provides periods and savings-goal tabs. `PeriodManagementView.swift` covers period CRUD, period detail, confirmed incomes, obligations, COP totals, validation, and destructive confirmations. `SavingsGoalsView.swift` covers goal CRUD, optional dates, planned allocations, and clamped progress. `ManagementSupport.swift` contains localized `Decimal` parsing, validation, formatting, totals, and savings math. `ExpensesPlannerApp.swift` adds a DEBUG-only UI-test data reset; `FinanceModelContainer.swift` supports that reset. Xcode project and README include the new sources and workflow documentation.

Resumed work fixed goal editing rather than recreating the feature: creation/editing now share one sheet presentation, and the goal row uses the normal `List` button behavior instead of `.plain`, which had left the sheet unopened. The goal form has a keyboard “Listo” action through `@FocusState`. The existing UI test remains intact in coverage and was strengthened to dismiss the keyboard explicitly, tap the switch control, assert its value, and confirm sheet dismissal before checking saved values.

Verification on iPhone 17, iOS 26.5, with `CODE_SIGNING_ALLOWED=NO`:

- `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO -resultBundlePath build/BP-005-goal-flow-pass.xcresult -only-testing:ExpensesPlannerUITests/ExpensesPlannerUITests/testSavingsGoalCreateEditValidationProgressOptionalDateAndRelaunch test`: **TEST SUCCEEDED**, 1/1 UI test, 0 failures, 70.911 s.
- `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO build`: **BUILD SUCCEEDED** (`build/BP-005-build.log`).
- `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO -resultBundlePath build/BP-005-full.xcresult test`: **TEST SUCCEEDED**, 41/41 tests, 0 failures, 0 skipped (`build/BP-005-full.log`). Breakdown: 38 unit tests (BudgetEngine 8, ExchangeRate 14, ExpensesPlanner 1, FinancePersistence 7, ManagementValidation 8) and 3 UI tests; UI elapsed 162.982 s. The result reports one nonfatal XCTest runtime warning, `Invalid frame dimension (negative or non-finite).`

No physical-device run, asset accounts, home/rollover, CNY expense-entry UI, or Git publishing is included.

## Review evidence

Independent reviewer **PASS** on 2026-11-24. Inspected the implementation, model cascade rules, project membership, UI tests, and scope. Independently ran `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO build`: **BUILD SUCCEEDED** (`build/BP-005-independent-review-build.log`). Ran the same command with `-resultBundlePath build/BP-005-independent-review.xcresult test`: **TEST SUCCEEDED**, 41/41 passed, 0 failed/skipped (`build/BP-005-independent-review-full.log`); `xcresulttool get test-results summary` confirmed the counts and one nonfatal `Invalid frame dimension (negative or non-finite).` runtime warning. The actual UI run covered goal editing, keyboard dismissal, optional-date switching, both relaunch flows, and destructive confirmations. No physical-device run; period date editing/reversed-date UI and individual income/obligation deletion remain inspection-backed rather than separately UI-driven.

## Completion

Planner accepted the implementation and independent PASS on 2026-11-24. Git publishing is recorded in repository history. Next: [[features/BP-006-asset-accounts|BP-006 local asset accounts]], then [[features/BP-007-home-quick-expenses|BP-007 home and quick expenses]].

---
id: BP-006
status: done
owner: planner
reviewer_verdict: pass
---

# Feature: Local checking and savings asset accounts

## Goal and user value

Add an Assets tab where the user can separate money held in different accounts, distinguish checking funds for daily use from accumulated savings, and see balances without connecting a bank or duplicating financial transactions.

## Acceptance criteria

- [x] Add a dedicated Spanish `Activos` tab and keep period/income/obligation/savings-goal management accessible in a `Planificación` tab.
- [x] Create, edit, list, and delete local asset accounts with non-empty trimmed custom names, checking/savings type, COP/CNY currency, and nonnegative `Decimal` current balance.
- [x] Use clear Spanish labels such as `Corriente` and `Ahorros`; explain that checking is for daily use and savings is accumulated money.
- [x] Show account balances, checking/savings subtotals, and total assets grouped separately by COP and CNY. Do not silently convert currencies with a stale or implicit rate.
- [x] Persist accounts and edits with SwiftData across relaunch and register the model in the existing local container.
- [x] Validate localized decimal input and show useful Spanish errors without saving invalid partial data. Confirm destructive account deletion.
- [x] Include useful empty states and accessibility identifiers for reliable UI automation.
- [x] Unit-test validation, totals, and in-memory persistence; UI-test create/edit/validation/type-currency totals and relaunch persistence.
- [x] Document that balances are manual tracking records and do not create income, expenses, savings-goal progress, or bank synchronization automatically.

## Scope

### In scope

Asset-account model, local CRUD, Assets tab, grouped totals, validation, tests, and documentation. Follow [[decisions|D-007]] and existing management-screen conventions.

### Out of scope

Bank connections, transactions/transfers between accounts, automatic expense/income deductions, debt or credit cards, consolidated CNY/COP net-worth conversion, home budget, charts, and physical deployment.

## Test plan

Run deterministic unit tests, real UI workflows including relaunch, the documented simulator build/full test action, and independent reviewer verification.

## Implementation handoff

Implemented the Spanish `Activos` tab and grouped periods and savings goals under `Planificación`. `AssetAccount` is registered in the existing SwiftData container and stores a custom name, checking/savings type, COP/CNY currency, and `Decimal` balance. `AssetAccountsView.swift` provides validated create/edit forms, account listing, confirmed deletion, empty states, accessibility identifiers, and separate checking/savings subtotals and totals for each currency. Balances are documented in the UI and README as manual records that do not create income, expenses, goal progress, transfers, conversion, or bank synchronization. No dependencies or out-of-scope finance workflows were added.

Tests retain the BP-005 coverage with navigation updated for `Planificación`, and add five asset validation/totals/formatting unit tests, one SwiftData asset round-trip/edit/delete test, and one end-to-end asset UI test including relaunch. Earlier test attempts exposed a stale launch-title assertion and one incorrect back-button path; both test paths were corrected without removing assertions. The isolated period flow then passed 1/1 in 94.737 s (`build/BP-006-period-flow.log`).

Verification on iPhone 17, iOS 26.5 (arm64, device 7FE53F42-2563-4F90-82D1-05B3F1A6FFC1), Xcode 27.2 (27B52), with `CODE_SIGNING_ALLOWED=NO`:

- `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO build`: **BUILD SUCCEEDED** (`build/BP-006-build-final.log`).
- `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO -resultBundlePath build/BP-006-full.xcresult test`: **TEST SUCCEEDED**, 48/48 tests, 0 failures, 0 skipped (`build/BP-006-full.log`). Breakdown: 44 unit tests (AssetAccount 5, BudgetEngine 8, ExchangeRate 14, ExpensesPlanner 1, FinancePersistence 8, ManagementValidation 8) and 4 UI tests. UI elapsed 366.200 s: Assets 180.813 s, launch 15.109 s, periods 93.070 s, goals 77.209 s. `xcresulttool get test-results summary` independently confirms 48 passed/0 failed/0 skipped and two nonfatal `Invalid frame dimension (negative or non-finite).` runtime warnings (`build/BP-006-test-summary.json`).

No physical-device run, home/rollover, expense-entry UI, currency conversion, transfers, debts, bank connections, dependencies, or Git publishing is included. Independent final review is **PASS**; see the evidence below.

## Review evidence

Independent reviewer **PASS** on 2026-11-24, with no changes required. Preliminary static inspection found no defects in navigation, model registration, CRUD, validation, totals, persistence, accessibility, documentation, scope, project membership, or retained BP-005 assertions. The reviewer then independently ran `xcodebuild -project ExpensesPlanner.xcodeproj -scheme ExpensesPlanner -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' CODE_SIGNING_ALLOWED=NO build`: exit 0, **BUILD SUCCEEDED** (`build/BP-006-independent-review-build.log`). The same command with `-resultBundlePath build/BP-006-independent-review.xcresult test`: exit 0, **TEST SUCCEEDED**, 48/48 passed, 0 failed/skipped/expected failures, total 417.517 s (`build/BP-006-independent-review-full.log`). An earlier reviewer attempt hit the executor's 300-second limit and was discarded before this complete rerun.

`xcresulttool get test-results summary` and the extracted `build/BP-006-independent-review-tests.json` confirmed 44 unit tests (AssetAccount 5, BudgetEngine 8, ExchangeRate 14, ExpensesPlanner 1, FinancePersistence 8, ManagementValidation 8) and 4 UI tests. Independent UI elapsed 369.410 s: Assets 183.829 s, launch 15.020 s, periods 95.008 s, goals 75.552 s. The result contains two nonfatal `Invalid frame dimension (negative or non-finite).` runtime warnings associated with asset/goal UI flows; their visual origin was not isolated.

Limitations: simulator only, no physical device or additional exploratory manual session; storage-save failures were not injected; network traffic was not monitored, although static inspection found no network path in Activos.

## Completion

Planner accepted the implementation and independent PASS on 2026-11-24. Git publishing is recorded in repository history. Next: [[features/BP-007-home-quick-expenses|BP-007 home metrics, rolling daily budget, and quick CNY expenses]].

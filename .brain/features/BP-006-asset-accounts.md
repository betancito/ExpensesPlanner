---
id: BP-006
status: planned
owner: planner
reviewer_verdict: not-started
---

# Feature: Local checking and savings asset accounts

## Goal and user value

Add an Assets tab where the user can separate money held in different accounts, distinguish checking funds for daily use from accumulated savings, and see balances without connecting a bank or duplicating financial transactions.

## Acceptance criteria

- [ ] Add a dedicated Spanish `Activos` tab and keep period/income/obligation/savings-goal management accessible in a `Planificación` tab.
- [ ] Create, edit, list, and delete local asset accounts with non-empty trimmed custom names, checking/savings type, COP/CNY currency, and nonnegative `Decimal` current balance.
- [ ] Use clear Spanish labels such as `Corriente` and `Ahorros`; explain that checking is for daily use and savings is accumulated money.
- [ ] Show account balances, checking/savings subtotals, and total assets grouped separately by COP and CNY. Do not silently convert currencies with a stale or implicit rate.
- [ ] Persist accounts and edits with SwiftData across relaunch and register the model in the existing local container.
- [ ] Validate localized decimal input and show useful Spanish errors without saving invalid partial data. Confirm destructive account deletion.
- [ ] Include useful empty states and accessibility identifiers for reliable UI automation.
- [ ] Unit-test validation, totals, and in-memory persistence; UI-test create/edit/validation/type-currency totals and relaunch persistence.
- [ ] Document that balances are manual tracking records and do not create income, expenses, savings-goal progress, or bank synchronization automatically.

## Scope

### In scope

Asset-account model, local CRUD, Assets tab, grouped totals, validation, tests, and documentation. Follow [[decisions|D-007]] and existing management-screen conventions.

### Out of scope

Bank connections, transactions/transfers between accounts, automatic expense/income deductions, debt or credit cards, consolidated CNY/COP net-worth conversion, home budget, charts, and physical deployment.

## Test plan

Run deterministic unit tests, real UI workflows including relaunch, the documented simulator build/full test action, and independent reviewer verification.

## Implementation handoff

Not started.

## Review evidence

Not started.

## Completion

Planned after BP-005; before BP-007 home and quick expenses.

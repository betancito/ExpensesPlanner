---
id: BP-007
status: planned
owner: planner
reviewer_verdict: not-started
---

# Feature: Home metrics, rolling daily budget, and quick CNY expenses

## Goal and user value

Make the main page immediately useful: show the current period's total and remaining budgets, essential spending metrics, and the actual CNY amount available today after rolling forward unused money or overspending. Let the user record a CNY expense quickly with an auditable COP conversion.

## Acceptance criteria

- [ ] Make `Inicio` the first tab, with `Planificación` and `Activos` still accessible, all in Spanish.
- [ ] Select and display the current user-defined period, with a clear empty state and navigation to create one. New periods default to a 15-day inclusive range while custom dates remain supported.
- [ ] Show total flexible period budget, recorded expenses, remaining budget, base daily budget, and actual available-today budget. Lead with CNY for daily spending and provide COP financial results.
- [ ] Extend the pure budget engine to calculate total inclusive period days, base daily CNY, remaining CNY, and available-today CNY using [[decisions|D-008]] and the exact formula in [[features/BP-001-finance-mvp|BP-001]].
- [ ] Unused allowance increases the next day's available amount; expenses above the prior day's allowance reduce the next day's amount. Never show a negative recommended allowance; retain an over-budget indication when total remaining funds are negative.
- [ ] Add a prominent `Registrar gasto` action and a short form for positive CNY amount, category, timestamp, and optional note. Persist each expense with its entry-time positive COP-per-CNY rate and immutable COP snapshot in its selected period.
- [ ] Integrate the BP-004 service to refresh a public rate, show rate timestamp/source and network/cache/manual state, fall back to cache on failure, and permit a validated manual offline rate. Never send financial data with a rate request.
- [ ] Show recent period expenses and update home metrics immediately after adding or deleting an expense. Confirm destructive deletion.
- [ ] Keep asset-account balances and savings-goal saved amounts unchanged by expense entry; no automatic account transactions.
- [ ] Unit-test base/available-today calculations across first day, unused-day rollover, overspending, multiple consecutive days, final day, before/after period, no income, invalid periods/rates, and historical COP snapshots.
- [ ] UI-test the real home, rate states with deterministic test doubles where practical, quick-expense validation/creation, metric updates, rollover-related display, and relaunch persistence without live-network dependence.

## Scope

### In scope

Home tab and summary metrics, rolling budget engine, current-rate presentation/selection, quick CNY expense creation and recent history, local persistence, and automated tests.

### Out of scope

Detailed charts and historical analytics, Shortcuts, automatic asset transactions, transfers, debts, backend/cloud sync, and physical deployment.

## Test plan

Run deterministic budget-engine and expense tests, real UI workflows, the documented simulator build/full test action, and independent reviewer verification of both math and end-to-end functionality.

## Implementation handoff

Not started.

## Review evidence

Not started.

## Completion

Planned after BP-006 asset accounts.

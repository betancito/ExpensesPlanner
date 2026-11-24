---
id: BP-001
status: done
owner: planner
reviewer_verdict: not-applicable
---

# Feature: Personal finance MVP definition

## Goal and user value

Help the user save and plan spending with weekly and daily budgets based on manually confirmed COP income, period-specific obligations, and savings goals. Daily spending happens in CNY; financial results and summaries are shown in COP.

## Accepted product scope

### Budget and home

- Calculate flexible spending from confirmed income, obligations, savings allocations, and recorded expenses.
- Show total period budget, base daily budget, actual available-today amount, remaining funds, and spending metrics on the home screen, with a prominent quick-expense action.
- Default new periods to 15 days. Carry unused daily allowance into the next day and subtract the previous day's overspending from the next day's allowance; never recommend a negative amount.
- Support weekly, biweekly/pay-period, monthly, and general financial metrics.
- Initial visualizations: spending by category, budget versus actual spending, and savings progress.

### Income and periods

- Record income manually in COP when received; never include expected future income in safe spending calculations.
- Support irregular pay dates such as 5th/20th or 15th/30th without hardcoding them.
- Each income covers a user-defined period ending at the next expected payday; additional confirmed income increases the current period's available funds.
- Rent, utilities, and other obligations have user-defined names and amounts that can change by period.

### Savings

- Savings goals have a target COP amount and optional target date.
- A planned per-period savings allocation reduces spendable funds. A target date can be used to suggest that allocation.
- Debt tracking, interest, and debt-payment schedules are out of scope.

### Assets

- A dedicated tab manages manually entered accounts with custom names, checking/savings type, COP/CNY currency, and current balance.
- Checking represents money for daily use; savings represents accumulated savings. Totals are grouped by currency.
- Accounts are local tracking records: they do not connect to banks or automatically create income, expenses, or savings-goal progress.

### Currency decisions

- Income and financial results: COP.
- Daily entry, remaining budget, and daily allowance: CNY.
- The app may fetch a public CNY/COP rate when online without sending financial data. It caches the rate locally, shows its timestamp, and permits manual/offline rates.
- Every expense stores its CNY amount, the COP-per-CNY rate used, and the resulting COP snapshot. Historical expenses do not change when rates change.

### Privacy and device

- Financial data is stored locally only; no account, backend, analytics, or cloud sync.
- Spanish interface.
- Target personal device: iPhone 16 Pro with iOS 26.6.2. Physical signing/deployment remains a separate task.

## Budget formula

`flexible spending = confirmed income - obligations - savings allocation`

`remaining flexible spending = flexible spending - COP value of recorded expenses`

`base daily allowance in CNY = flexible spending / inclusive total period days / COP-per-CNY planning rate`

`available today in CNY = remaining flexible spending / COP-per-CNY planning rate - base daily allowance × future days after today`

This available-today formula carries the previous day's unused allowance or overspending into the current day while preserving the base allocation for future days. Negative available funds produce a zero safe spending allowance and an over-budget indication rather than a negative recommendation.

## MVP acceptance criteria

- [ ] User can enter COP income and define its coverage period.
- [ ] User can manage period-specific obligations and savings goals.
- [ ] User can quickly enter a CNY expense and retain its historical COP conversion.
- [ ] Home shows total period and remaining budgets, spending metrics, and base/actual daily CNY allowances with previous-day rollover and overspend adjustment.
- [ ] User can manage local checking and savings asset accounts in COP or CNY and see totals by currency.
- [ ] Exchange rates work online and offline as decided above.
- [ ] Biweekly/pay-period, monthly, and general metrics and initial charts are available.
- [ ] Data persists locally across launches and the core calculations have automated tests.

## Implementation roadmap

1. [[features/BP-003-local-finance-core|BP-003 — Local finance models and budget engine]].
2. [[features/BP-004-exchange-rates|BP-004 — Public/cached/manual CNY-COP exchange-rate service]].
3. [[features/BP-005-management-screens|BP-005 — Income, period, obligation, and savings-goal management screens]].
4. BP-006 — Local checking and savings asset accounts.
5. BP-007 — Home metrics, rolling daily budget, and quick CNY expense workflow.
6. BP-008 — Detailed metrics, summaries, and charts.
7. BP-009 — iOS Shortcut quick entry.
8. BP-010 — Physical iPhone signing and deployment.

## Completion

Product discovery accepted on 2026-11-22. Implementation begins with BP-003; no finance code existed when this plan was approved.

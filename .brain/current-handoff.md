---
status: ready-for-bp-004
active_feature: none
updated: 2026-11-23
---

# Current handoff

## Where we are

[[features/BP-003-local-finance-core|BP-003]] is complete and planner-accepted. SwiftData finance models and the pure Decimal budget engine are implemented. Independent review found no issues; the simulator build passed and all 15 tests passed (14 unit, 1 UI).

## Active feature

None. [[features/BP-001-finance-mvp|BP-001]] contains the accepted MVP roadmap. The provisional UI remains unchanged.

## Next action

Start BP-004: public CNY/COP exchange-rate fetching without financial data, local timestamped caching, and manual offline rates. Then continue with BP-005 management screens and BP-006 home/quick expenses.

## Environment confirmed

- Repository branch: `main`; GitHub remote: `origin`.
- Xcode 27.2 (27B52) and the iPhone 17 iOS 26.5 simulator successfully built and tested the app.
- Target device: iPhone 16 Pro with iOS 26.6.2; physical signing and deployment remain pending.

## Product decisions

- Only manually confirmed income contributes to safe spending.
- Public rate fetches contain no financial data; cached and manual rates support offline use.
- Expenses retain their entry-time CNY amount, exchange rate, and COP value.
- Debts are outside the MVP.

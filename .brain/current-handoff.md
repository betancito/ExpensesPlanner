---
status: ready
active_feature: none
updated: 2026-11-23
---

# Current handoff

## Where we are

[[features/BP-004-exchange-rates|BP-004]] is complete and planner-accepted. The app now has a public CNY/COP exchange-rate service with validated responses, timestamped local SwiftData snapshots, offline cache fallback, manual rates, and explicit source metadata. Independent review passed; the simulator build succeeded and all 30 tests passed (29 unit, 1 UI). The provisional UI remains unchanged.

## Active feature

No active feature.

## Next action

Plan and implement BP-005 income, period, obligation, and savings-goal management screens, followed by BP-006 home and quick CNY expenses.

## Environment confirmed

- Repository branch: `main`; GitHub remote: `origin`.
- Xcode 27.2 (27B52) and the iPhone 17 iOS 26.5 simulator successfully built and tested the app.
- Target device: iPhone 16 Pro with iOS 26.6.2; physical signing and deployment remain pending.

## Product decisions

- Only manually confirmed income contributes to safe spending.
- Public rate fetches contain no financial data; cached and manual rates support offline use.
- Expenses retain their entry-time CNY amount, exchange rate, and COP value.
- Debts are outside the MVP.

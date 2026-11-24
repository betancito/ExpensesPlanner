---
status: ready
active_feature: none
updated: 2026-11-24
---

# Current handoff

## Where we are

[[features/BP-005-management-screens|BP-005]] is complete and planner-accepted. The Spanish SwiftUI management flows for flexible periods, confirmed COP incomes, obligations, and savings goals are implemented. Independent review is **PASS**: the reviewer simulator build succeeded and all 41 tests passed (38 unit, 3 UI) on iPhone 17 iOS 26.5. Goal-row editing, optional-date UI reliability, relaunch persistence, and destructive confirmations were exercised.

## Active feature

No active feature.

## Next action

Implement [[features/BP-006-asset-accounts|BP-006 local checking/savings accounts]], then [[features/BP-007-home-quick-expenses|BP-007 home metrics, rolling daily budget, and quick CNY expenses]].

## Environment confirmed

- Repository branch: `main`; GitHub remote: `origin`.
- Xcode 27.2 (27B52) and the iPhone 17 iOS 26.5 simulator successfully built and tested the app.
- Target device: iPhone 16 Pro with iOS 26.6.2; physical signing and deployment remain pending.

## Product decisions

- Only manually confirmed income contributes to safe spending.
- Public rate fetches contain no financial data; cached and manual rates support offline use.
- Expenses retain their entry-time CNY amount, exchange rate, and COP value.
- Debts are outside the MVP.
- Local asset accounts distinguish checking for daily use from accumulated savings; balances are manually tracked and grouped by COP/CNY.
- New periods default to 15 days. Unused daily allowance rolls into the next day and overspending reduces the next day's allowance.
- Physical installation is deferred at the user's request; development continues in the simulator.

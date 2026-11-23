# Decisions

Record only durable decisions. Newest entries go first; do not rewrite history without noting why.

## D-006 — Calculate safe budgets from confirmed income only

- Date: 2026-11-22
- Status: accepted
- Decision: Record variable COP income manually when received and assign it a flexible coverage period. Exclude expected income and debts from the MVP; subtract obligations and savings allocations before recommending CNY spending.
- Reason: The user's income varies, and recommendations must not rely on money not yet received.

## D-005 — Preserve entry-time currency conversions

- Date: 2026-11-22
- Status: accepted
- Decision: Store each expense's CNY amount, positive COP-per-CNY rate, and COP snapshot. Do not revalue historical expenses when rates change.
- Reason: Historical financial results must remain stable and auditable.

## D-004 — Permit public exchange-rate fetches with local privacy

- Date: 2026-11-22
- Status: accepted
- Decision: Fetch only public CNY/COP exchange rates when online, without financial data. Cache rates locally with timestamps and support manual offline rates.
- Reason: Current conversion rates require internet, while the user's financial records remain local-only.

## D-003 — Use .brain as durable project memory

- Date: 2026-11-21
- Status: accepted
- Decision: Store project context, feature plans, handoffs, review evidence, and session outcomes in an Obsidian-compatible `.brain` vault.
- Reason: New agent sessions can restore context from a few linked notes instead of repeating the full conversation.

## D-002 — Use three Kimi project agents

- Date: 2026-11-21
- Status: accepted
- Decision: Use planner, developer, and reviewer profiles. The planner delegates to the developer; the developer delegates verification to the reviewer; failures return to the developer; successful work returns to the planner.
- Reason: Separates planning, implementation, and independent quality checks while preserving a simple handoff chain.

## D-001 — Build a local-only personal iPhone app

- Date: 2026-11-21
- Status: accepted
- Decision: Use native iOS tooling and keep financial data on the device. App Store publication is out of scope.
- Reason: Matches the user's personal-use and privacy requirements.

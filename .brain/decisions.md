# Decisions

Record only durable decisions. Newest entries go first; do not rewrite history without noting why.

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

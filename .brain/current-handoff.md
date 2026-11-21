---
status: ready-for-mvp-planning
active_feature: none
updated: 2026-11-21
---

# Current handoff

## Where we are

The planner → developer → reviewer workflow and this Obsidian memory passed independent review and planner acceptance. There is no application code or Xcode project yet.

## Active feature

None. [[features/BP-000-agent-workflow|BP-000]] is complete; start future sessions with `kimi --agent planner`.

## Next action

Define the smallest useful finance MVP, its acceptance criteria, and the initial Xcode project scope in [[backlog|BP-001]].

## Environment confirmed

- Repository branch: `main`; GitHub remote: `origin`.
- Xcode 27.2 and iOS simulators are installed.
- Physical iPhone signing, deployment, and device testing have not been verified.

## Open product questions

- Which finance problem should the first version solve?
- What information must be entered, calculated, and shown?
- Which currency, date, privacy, and backup behavior is required?

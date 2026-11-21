---
name: expenses-planner-brain
description: Restore or update ExpensesPlanner's Obsidian .brain context efficiently for the planner, developer, or reviewer
whenToUse: At the start of any ExpensesPlanner agent session or handoff, and when durable project memory needs updating
type: prompt
arguments:
  - role
---

Restore context for the `$role` role. If no role is supplied, use `planner`.

1. Read `.brain/current-handoff.md` and the matching role note: `.brain/init-planner.md`, `.brain/init-dev.md`, or `.brain/init-reviewer.md`.
2. Read `.brain/home.md` for navigation on a new session.
3. Follow the active-feature link only if the handoff names one. Read `.brain/project.md`, `.brain/decisions.md`, or `.brain/backlog.md` only when the task needs them.
4. Do not read session history, templates, or the whole vault by default.
5. Follow the role's delegation and verification rules. Subagent tasks must include relevant note paths because subagents do not inherit conversation context.
6. Before finishing meaningful work, update the active feature and `.brain/current-handoff.md`. Update `.brain/backlog.md` or `.brain/decisions.md` only when their content changed. Use `.brain/sessions/session-template.md` only for durable outcomes not captured elsewhere.

Keep notes short and factual. Record exact verification evidence and limitations. Never add secrets or personal financial records.

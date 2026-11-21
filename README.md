# ExpensesPlanner

A personal iPhone expenses-planning app. Financial data is stored locally in the app; App Store publication is not currently a goal.

## Start the agent workflow

```sh
kimi --agent planner
```

The planner is the main point of contact. It delegates approved feature plans to the developer, the developer runs a fix-and-retest loop with the reviewer, and accepted work returns to the planner for final review and Git publishing.

Project agents are defined in `.kimi-code/agents/`. The `expenses-planner-brain` skill restores compact project context automatically.

## Obsidian project memory

Open the `.brain` folder as an Obsidian vault, then start at `home.md`. Durable status lives in `current-handoff.md`; feature plans, reviews, decisions, and the backlog use linked notes.

To resume an existing Kimi conversation instead, run `kimi --continue`; it restores the agent selected for that session.


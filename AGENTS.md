# ExpensesPlanner agent workflow

This repository uses three project agents defined in `.kimi-code/agents/`:

1. **Planner** — talks with the user, maintains `.brain`, plans features, delegates implementation, performs final review, and commits/pushes accepted work.
2. **Developer** — implements a planned feature, runs initial checks, delegates testing to the reviewer, and fixes findings.
3. **Reviewer** — independently verifies the diff, functionality, and code quality; returns `PASS`, `CHANGES_REQUESTED`, or `BLOCKED` to the developer.

Start a new main session with `kimi --agent planner`. Use the `expenses-planner-brain` skill at session and handoff boundaries. If the skill is unavailable, read `.brain/current-handoff.md`, the role's `.brain/init-*.md` note, and only the active feature it links.

The `.brain` directory is an Obsidian vault and the durable project memory. Do not bulk-read it. Keep durable status in `current-handoff.md`, feature details in `features/`, and decisions in `decisions.md`.

Only the planner commits or pushes. Never publish the app or add remote financial-data storage without an explicit user request. Do not store secrets or personal financial records in the repository.

---
id: BP-000
status: done
owner: planner
reviewer_verdict: PASS
---

# Feature: Agent workflow and Obsidian memory

## Goal and user value

Establish a reusable planner → developer → reviewer workflow with compact, persistent project context for future app development.

## Acceptance criteria

- [x] Kimi discovers project-scoped planner, developer, and reviewer profiles with the intended delegation boundaries.
- [x] `.brain` works as an Obsidian vault with role initialization, current handoff, backlog, decisions, and feature/review/session templates.
- [x] The `expenses-planner-brain` skill restores role context without reading the whole vault.
- [x] Startup and resume instructions are documented.
- [x] The developer can obtain an independent reviewer verdict and return it to the planner.

## Scope

### In scope

Agent profiles, the project context skill, `.brain` notes and templates, root agent instructions, and README startup instructions.

### Out of scope

Application code, an Xcode project, finance features, physical iPhone deployment, and App Store setup.

## Technical plan

Use Kimi project agents in `.kimi-code/agents/` and a project skill in `.kimi-code/skills/`. Follow [[decisions|D-002 and D-003]]. The reviewer returns to the developer through Kimi's normal caller handoff.

## Test plan

- Validate Kimi configuration and agent discovery.
- Confirm the skill is discovered and can be invoked.
- Run `git diff --check`.
- Exercise planner startup and the developer → reviewer handoff without changing application code.

## Implementation handoff

Created three agent profiles, the context-loading skill, root `AGENTS.md`, README instructions, and the initial `.brain` vault. No app code exists.

## Review evidence

[[reviews/BP-000-agent-workflow|Reviewer PASS]]: all acceptance criteria passed with no findings. Planner startup, the full planner → developer → reviewer → developer → planner handoff, skill invocation, static structure/link checks, and whitespace checks were verified.

## Completion

Planner accepted the review. Git commit and push are reported in the final planner handoff and repository history. Next: BP-001.

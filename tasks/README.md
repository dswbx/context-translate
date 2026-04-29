# Tasks

This directory is the operating board for LLM agents.

## Files

- `CURRENT.md`: active task, current checkpoint, blockers, and next step
- `TASKS.md`: backlog and task statuses
- `PROGRESS.md`: chronological work log
- `templates/task.md`: reusable task format

## Status Values

- `not-started`
- `active`
- `blocked`
- `review`
- `done`
- `superseded`

## Agent Rules

1. Read `CURRENT.md` before starting.
2. Work only on the active task unless instructed otherwise.
3. Update `PROGRESS.md` after meaningful work.
4. Update `CURRENT.md` before stopping.
5. Add product questions to `docs/QUESTIONS.md`.
6. Add prototype findings to `docs/DISCOVERY.md`.
7. Add durable decisions to `docs/DECISIONS.md`.

## Product Owner Review

The product owner reviews behavior, findings, mockups, and decisions. Agents should make progress legible without requiring code review.

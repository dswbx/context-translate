# AGENTS.md

## Mission

Build the Contextual Language Assistant MVP through a discovery-first workflow. The product owner steers product direction; agents handle code, planning, technical exploration, and documentation.

## Required Reading Before Any Work

Read these files before making changes:

1. `docs/IDEA.md`
2. `docs/MVP.md`
3. `docs/TERMINOLOGY.md`
4. `docs/DISCOVERY.md`
5. `tasks/CURRENT.md`
6. The relevant task in `tasks/TASKS.md`

If a file does not exist yet, create it only when the active task asks for it.

## Current Strategy

We will not start with the production app. First, iterate on the disposable Swift/SwiftUI proof of concept under `poc/`.

The prototype should teach us about:

- menu-bar app behavior
- global shortcut or practical trigger alternatives
- selected text capture and clipboard fallback
- floating window behavior
- macOS permissions
- the explanation and phrase selection loop
- composer interaction
- history and learning bucket feel

Prototype code may be rough. Findings must be polished.

## Discovery Rules

- Treat `experiments/` code as disposable unless a later decision says otherwise.
- Do not turn prototype structure into production architecture by inertia.
- Avoid secrets and paid provider dependence in experiments.
- Prefer fake, stubbed, or local sample responses until provider integration is explicitly planned.
- Record every important surprise in `docs/DISCOVERY.md`.
- Promote durable product or technical decisions to `docs/DECISIONS.md`.

## Product Input Rules

The product owner will steer product, not code. If product behavior is unclear:

1. Add a question to `docs/QUESTIONS.md`.
2. Mark the relevant task as blocked in `tasks/CURRENT.md`.
3. Stop rather than inventing product behavior.

## Task Workflow

1. Pick the active task from `tasks/CURRENT.md`.
2. Confirm the task exists in `tasks/TASKS.md`.
3. Keep changes scoped to that task.
4. Update `tasks/PROGRESS.md` after meaningful work.
5. Update `tasks/CURRENT.md` before stopping.
6. Record decisions in `docs/DECISIONS.md`.
7. Record discovery findings in `docs/DISCOVERY.md`.
8. Run relevant checks before marking work complete.

## Completion Standard

A task is complete only when:

- acceptance criteria are satisfied
- relevant docs are updated
- checks are run or the reason they were not run is recorded
- `tasks/PROGRESS.md` has a final entry
- `tasks/CURRENT.md` points to the next task or says there is no active task

## Git Hygiene

- Commit focused changes.
- Do not commit `.superpowers/`, `.DS_Store`, build products, secrets, or local scratch files.
- Do not rewrite history unless explicitly instructed.
- Never delete user work unless explicitly asked.

## Working Style

The product owner steers product direction. LLM agents do the coding, planning, and progress recording. Agents must update the task and progress files so another agent can resume without hidden context.


<claude-mem-context>
# Memory Context

# [context-translate] recent context, 2026-05-01 4:51pm GMT+2

No previous sessions found.
</claude-mem-context>

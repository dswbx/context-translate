# Decisions

Durable product and technical decisions go here. Use this file for choices that future agents should not reopen without a reason.

## Decision Format

```markdown
## YYYY-MM-DD - Title

**Status:** proposed, accepted, superseded
**Context:** Why this decision exists.
**Decision:** What we decided.
**Consequences:** What this changes.
```

## 2026-04-29 - Use A Discovery-First Workflow

**Status:** accepted
**Context:** A polished plan can fail when native macOS realities appear, especially around selected text capture, permissions, floating windows, and menu-bar app behavior.
**Decision:** Build a disposable Swift/SwiftUI discovery prototype before planning the production MVP.
**Consequences:** The repository will include `experiments/swift-discovery/` and `docs/DISCOVERY.md`. Prototype code is not the production foundation by default.

## 2026-04-29 - Product Owner Steers Product, Agents Handle Code

**Status:** accepted
**Context:** The product owner wants to steer from a product perspective rather than write or review code line by line.
**Decision:** Agents must keep task, progress, question, and decision docs current so product review can focus on behavior and direction.
**Consequences:** `tasks/CURRENT.md`, `tasks/PROGRESS.md`, `tasks/TASKS.md`, `docs/QUESTIONS.md`, and `docs/DECISIONS.md` are required operating files.

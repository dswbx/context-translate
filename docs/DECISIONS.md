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
**Consequences:** The repository will include `poc/` and `docs/DISCOVERY.md`. Prototype code is not the production foundation by default.

## 2026-04-29 - Product Owner Steers Product, Agents Handle Code

**Status:** accepted
**Context:** The product owner wants to steer from a product perspective rather than write or review code line by line.
**Decision:** Agents must keep task, progress, question, and decision docs current so product review can focus on behavior and direction.
**Consequences:** `tasks/CURRENT.md`, `tasks/PROGRESS.md`, `tasks/TASKS.md`, `docs/QUESTIONS.md`, and `docs/DECISIONS.md` are required operating files.

## 2026-05-07 - Selected-Term Details Start With Context Translations

**Status:** accepted
**Context:** The Explain flow already starts with a full-text translation, but selected-term details also need a direct native-language anchor before deeper explanation.
**Decision:** The Explanation pane shows 1-3 context-driven selected-term translations before Meaning, Contextual Meaning, Tone, and Example.
**Consequences:** Provider detail prompts should return selected-term translations as part of the structured explanation response. These should be natural renderings in the exact sentence context, not dictionary-style single-word glosses. The production MVP should preserve this ordering unless product testing changes it.

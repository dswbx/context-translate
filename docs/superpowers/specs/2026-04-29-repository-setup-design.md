# Repository Setup Design

## Goal

Create a mockup-first, LLM-operable repository scaffold for the Contextual Language Assistant MVP. The repository should let a product owner steer through product decisions, mockup approval, and acceptance criteria while LLM coding agents handle planning, implementation, progress recording, and technical tradeoffs.

## Context

The current workspace contains `docs/IDEA.md`, which describes a native macOS app for non-native English speakers. The app helps users understand selected English text in context, expand unfamiliar phrases, compose natural English from their native language, save phrases to a learning bucket, review saved items, and control privacy-sensitive behavior.

The workspace is not yet initialized as a git repository. The setup should therefore establish both the repository mechanics and the collaboration operating model before production code is added.

## Recommendation

Use a mockup-first repository setup.

This approach creates the agent operating structure, product documents, task queue, progress logs, and mockup workflow before creating the Swift or SwiftUI app skeleton. The main product risk is not whether a native macOS app can be scaffolded, but whether the first-run flow, selected-text explanation flow, phrase detail expansion, composer, learning bucket, review mode, and privacy settings feel fast, trustworthy, and clear.

Production app code should begin only after the relevant MVP slice has an approved mockup, acceptance criteria, and task entry.

## Repository Structure

The setup will create these top-level files and directories:

- `AGENTS.md`: the primary operating manual for all LLM agents working in the repository.
- `README.md`: a concise project overview for humans and agents.
- `.gitignore`: excludes local brainstorming state, build artifacts, macOS files, dependency folders, generated scratch files, and secrets.
- `docs/PRODUCT.md`: cleaned-up product brief derived from `docs/IDEA.md`.
- `docs/MVP.md`: MVP scope, non-goals, success criteria, and product guardrails.
- `docs/ROADMAP.md`: ordered delivery slices from mockups to coded MVP.
- `docs/DECISIONS.md`: decision log with initial decisions and a lightweight template.
- `docs/QUESTIONS.md`: open product questions that agents must surface rather than guess.
- `docs/mockups/README.md`: mockup workflow, approval states, and naming conventions.
- `tasks/README.md`: instructions for selecting, executing, and updating tasks.
- `tasks/TASKS.md`: initial backlog with mockup-first tasks and later implementation slices.
- `tasks/PROGRESS.md`: chronological progress log for agent work.
- `tasks/CURRENT.md`: single source of truth for the active task and current checkpoint.
- `tasks/templates/task.md`: reusable task format with context, scope, acceptance criteria, and progress notes.

No production app skeleton will be created in this setup pass.

## Agent Operating Model

Agents should follow this loop:

1. Read `AGENTS.md`, `docs/MVP.md`, `tasks/CURRENT.md`, and the active task before making changes.
2. Confirm the task has enough product context and acceptance criteria.
3. If the task involves UX, create or update mockups before production code.
4. If product behavior is unclear, update `docs/QUESTIONS.md` and stop for product input.
5. Keep implementation scoped to the active task.
6. Record meaningful choices in `docs/DECISIONS.md`.
7. Update `tasks/PROGRESS.md` after each meaningful step.
8. Update `tasks/CURRENT.md` when pausing, completing, or handing off work.
9. Run relevant checks before marking a task complete.

The repository should assume the product owner steers product direction but does not review code line by line. Therefore, task files and progress logs must be explicit enough for another LLM agent to resume work without hidden context.

## Mockup Workflow

The first product iteration should be mockups. Mockups should answer product and UX questions before app code hardens those decisions.

Initial mockup slices:

- Menu bar and global shortcut entry point.
- Selected text explanation window.
- Phrase selection and phrase detail expansion.
- Phrase composer with casual, neutral, and professional output variants.
- Learning bucket and review mode.
- Privacy and settings screen.

Each mockup slice should move through these states:

- `proposed`: created by an agent for review.
- `needs-product-input`: blocked on product decision.
- `approved`: ready to become an implementation task.
- `superseded`: replaced by a newer direction.

Approved mockups should be referenced from the related task entry before implementation begins.

## Product Guardrails

The MVP must preserve these product constraints:

- Native macOS app.
- Mostly menu-bar driven.
- Global shortcut for selected text.
- Fast floating window UI.
- Local SQLite history and learning data.
- LLM-based translation, explanation, and phrase composition.
- Privacy-conscious storage and provider settings.
- Architecture should not block future iOS sharing of learning, history, and review logic.

The MVP should avoid browser extensions, OCR, screenshots, team accounts, cloud sync, offline AI, App Store release work, pronunciation/audio, and advanced dictionary features.

## Progress Recording

Progress recording should be simple enough that every agent updates it consistently.

- `tasks/CURRENT.md` records the active task, current status, immediate next step, blockers, and handoff notes.
- `tasks/PROGRESS.md` records chronological work entries with date, task ID, summary, files changed, checks run, decisions made, and next step.
- `tasks/TASKS.md` records task IDs, status, owner type, scope, acceptance criteria, and links to mockups or decisions.
- `docs/DECISIONS.md` records durable product and technical choices.
- `docs/QUESTIONS.md` records open questions for the product owner.

Agents should update progress before ending a work session, even if the task is incomplete.

## Initial Backlog Shape

The initial backlog should start with setup and product clarification tasks:

1. Repository operating scaffold.
2. MVP product brief refinement.
3. Mockup style and native macOS interaction direction.
4. Selected text explanation flow mockup.
5. Phrase composer mockup.
6. Learning bucket and review mockup.
7. Privacy/settings mockup.
8. Technical architecture plan for the native app.
9. Swift/SwiftUI app skeleton.
10. Local persistence and domain model.

This order keeps product validation ahead of production implementation.

## Git Baseline

Because the workspace is not currently a git repository, the setup should initialize git and create an initial baseline commit. The design spec should be committed first so the repository records why the scaffold exists. The scaffold files can then be added in a follow-up commit after the implementation plan is approved and executed.

## Acceptance Criteria

The repository setup is complete when:

- Git is initialized.
- The setup design spec is committed.
- The scaffold files listed in this document exist.
- `AGENTS.md` gives clear instructions for LLM agents.
- Task, progress, decision, and question tracking files are present and internally consistent.
- The first active task points toward mockup creation rather than production app code.
- The setup does not create production macOS app code yet.

## Out of Scope

This setup will not:

- Create a Swift or SwiftUI project.
- Choose a final AI provider integration.
- Implement global shortcuts or accessibility permissions.
- Implement SQLite persistence.
- Produce final visual design.
- Create App Store packaging, signing, or distribution setup.

Those belong to later approved tasks.

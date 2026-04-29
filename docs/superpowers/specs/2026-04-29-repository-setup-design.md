# Repository Setup Design

## Goal

Create a discovery-first, LLM-operable repository scaffold for the Contextual Language Assistant MVP. The repository should let a product owner steer through product decisions, prototype findings, mockup approval, and acceptance criteria while LLM coding agents handle planning, implementation, progress recording, and technical tradeoffs.

## Context

The current workspace contains `docs/IDEA.md`, which describes a native macOS app for non-native English speakers. The app helps users understand selected English text in context, expand unfamiliar phrases, compose natural English from their native language, save phrases to a learning bucket, review saved items, and control privacy-sensitive behavior.

The workspace is now initialized as a git repository with a baseline commit containing `docs/IDEA.md` and this setup design. The setup should establish the collaboration operating model before production code is added.

## Recommendation

Use a discovery-first repository setup.

This approach creates the agent operating structure, product documents, task queue, progress logs, and discovery workflow before the formal production app is planned. The main product risk is not only whether the UX looks right in mockups, but how the selected-text workflow, global shortcut, menu-bar app behavior, floating window, macOS permissions, local persistence, and LLM loop feel when touched in a real native app.

The repository should therefore include a deliberately disposable Swift/SwiftUI discovery prototype before the real MVP build. The prototype is a learning artifact, not the production foundation. Production app code should begin only after prototype findings have been captured, product decisions have been updated, and the formal MVP implementation plan has been written from those findings.

## Repository Structure

The setup will create these top-level files and directories:

- `AGENTS.md`: the primary operating manual for all LLM agents working in the repository.
- `README.md`: a concise project overview for humans and agents.
- `.gitignore`: excludes local brainstorming state, build artifacts, macOS files, dependency folders, generated scratch files, and secrets.
- `docs/PRODUCT.md`: cleaned-up product brief derived from `docs/IDEA.md`.
- `docs/MVP.md`: MVP scope, non-goals, success criteria, and product guardrails.
- `docs/DISCOVERY.md`: discovery prototype goals, constraints, findings, and recommendations for the real build.
- `docs/ROADMAP.md`: ordered delivery slices from mockups to coded MVP.
- `docs/DECISIONS.md`: decision log with initial decisions and a lightweight template.
- `docs/QUESTIONS.md`: open product questions that agents must surface rather than guess.
- `docs/mockups/README.md`: mockup workflow, approval states, and naming conventions.
- `experiments/README.md`: rules for disposable experiments.
- `experiments/swift-discovery/README.md`: scope and handoff notes for the Swift discovery prototype.
- `tasks/README.md`: instructions for selecting, executing, and updating tasks.
- `tasks/TASKS.md`: initial backlog with discovery tasks, mockup tasks, and later implementation slices.
- `tasks/PROGRESS.md`: chronological progress log for agent work.
- `tasks/CURRENT.md`: single source of truth for the active task and current checkpoint.
- `tasks/templates/task.md`: reusable task format with context, scope, acceptance criteria, and progress notes.

No production app skeleton will be created in this setup pass. The setup will prepare an `experiments/` area where a later task can one-shot a native Swift discovery prototype without pretending that prototype is the final app.

## Agent Operating Model

Agents should follow this loop:

1. Read `AGENTS.md`, `docs/MVP.md`, `tasks/CURRENT.md`, and the active task before making changes.
2. Confirm the task has enough product context and acceptance criteria.
3. If the task involves native macOS uncertainty, prefer a contained discovery prototype before production code.
4. If the task involves UX, create or update mockups before production code unless the task is explicitly a discovery prototype.
5. If product behavior is unclear, update `docs/QUESTIONS.md` and stop for product input.
6. Keep implementation scoped to the active task.
7. Record meaningful choices in `docs/DECISIONS.md`.
8. Capture prototype friction, surprises, dead ends, and recommendations in `docs/DISCOVERY.md`.
9. Update `tasks/PROGRESS.md` after each meaningful step.
10. Update `tasks/CURRENT.md` when pausing, completing, or handing off work.
11. Run relevant checks before marking a task complete.

The repository should assume the product owner steers product direction but does not review code line by line. Therefore, task files and progress logs must be explicit enough for another LLM agent to resume work without hidden context.

## Discovery Prototype Workflow

The first technical product iteration should be a disposable Swift/SwiftUI discovery prototype. Its purpose is to learn quickly from real macOS constraints before writing the formal MVP plan.

The prototype should test:

- Menu-bar app shape and lifecycle.
- Global shortcut or equivalent trigger flow.
- Selected text capture, including clipboard fallback if direct capture is unreliable.
- Fast floating window behavior.
- Translation-first explanation flow.
- Phrase selection and detail expansion interaction.
- Phrase composer with multiple tone variants.
- Minimal local persistence sufficient to feel history and learning bucket behavior.
- Fake, stubbed, or minimal LLM integration that preserves the user loop without committing to provider architecture.

The prototype must follow these constraints:

- It lives under `experiments/swift-discovery/`.
- It is allowed to be rough, duplicated, and incomplete.
- It must not become the production app foundation by default.
- It should favor observable learning over architectural purity.
- It should avoid secrets, paid provider dependence, and long-lived data migrations.
- It must record findings in `docs/DISCOVERY.md`.

After the prototype, agents should extract:

- Product decisions that changed after touching the app.
- macOS permission and API constraints.
- UX interactions that felt too slow, confusing, or too hidden.
- Technical risks for the real app.
- Code or architecture ideas worth reusing.
- Code or architecture ideas that should be discarded.

Only after this extraction should agents write the formal MVP implementation plan.

## Mockup Workflow

Mockups remain part of the workflow, but they no longer need to be the only first step. The discovery prototype should be allowed to reveal interaction problems that static mockups miss. Mockups should then clarify the UX direction for the real build.

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

Approved mockups and discovery findings should be referenced from the related task entry before production implementation begins.

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

- `tasks/CURRENT.md` records the active task, current status, immediate next step, blockers, discovery notes, and handoff notes.
- `tasks/PROGRESS.md` records chronological work entries with date, task ID, summary, files changed, checks run, findings, decisions made, and next step.
- `tasks/TASKS.md` records task IDs, status, owner type, scope, acceptance criteria, and links to mockups or decisions.
- `docs/DISCOVERY.md` records prototype goals, experiment results, surprises, risks, recommendations, and items to carry into the real MVP plan.
- `docs/DECISIONS.md` records durable product and technical choices.
- `docs/QUESTIONS.md` records open questions for the product owner.

Agents should update progress before ending a work session, even if the task is incomplete.

## Initial Backlog Shape

The initial backlog should start with setup, discovery, and product clarification tasks:

1. Repository operating scaffold.
2. Discovery prototype brief.
3. One-shot Swift/SwiftUI discovery prototype.
4. Discovery findings extraction.
5. MVP product brief refinement based on discovery.
6. Mockup style and native macOS interaction direction.
7. Selected text explanation flow mockup.
8. Phrase composer mockup.
9. Learning bucket and review mockup.
10. Privacy/settings mockup.
11. Technical architecture plan for the real native app.
12. Swift/SwiftUI production app skeleton.
13. Local persistence and domain model.

This order lets reality reshape the plan before the durable app begins.

## Git Baseline

The workspace has an initial git baseline commit so the repository records why the scaffold exists. The scaffold files can be added in a follow-up commit after the implementation plan is approved and executed.

## Acceptance Criteria

The repository setup is complete when:

- Git is initialized.
- The setup design spec is committed, including the discovery-first revision.
- The scaffold files listed in this document exist.
- `AGENTS.md` gives clear instructions for LLM agents.
- Task, progress, decision, and question tracking files are present and internally consistent.
- Discovery tracking exists in `docs/DISCOVERY.md`.
- The first active task points toward the disposable Swift discovery prototype rather than production app code.
- The setup does not create production macOS app code yet.

## Out of Scope

This setup will not:

- Create the production Swift or SwiftUI project.
- Choose a final AI provider integration.
- Implement global shortcuts or accessibility permissions.
- Implement SQLite persistence.
- Produce final visual design.
- Create App Store packaging, signing, or distribution setup.

Those belong to later approved tasks.

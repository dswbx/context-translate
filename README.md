# Contextual Language Assistant

A native macOS language assistant for non-native English speakers. The app helps users understand selected English text in context, inspect confusing phrases, compose natural English from their own language, review English they wrote, and learn saved phrases over time.

## Current Phase

This repository is in the discovery phase.

Before building the durable MVP, we will create a disposable Swift/SwiftUI prototype under `experiments/swift-discovery/` to learn from real macOS behavior:

- menu-bar app lifecycle
- global shortcut or trigger flow
- selected text capture and clipboard fallback
- floating window behavior
- translation-first explanation flow
- phrase detail expansion
- phrase composer
- basic local persistence feel

The prototype is a learning artifact. It is not the production app foundation by default.

## How To Navigate

- `docs/IDEA.md`: original rough product idea
- `docs/PRODUCT.md`: cleaned product brief
- `docs/MVP.md`: MVP scope and guardrails
- `docs/TERMINOLOGY.md`: shared product language
- `docs/DISCOVERY.md`: discovery prototype goals and findings
- `docs/DECISIONS.md`: durable product and technical decisions
- `docs/QUESTIONS.md`: open product questions
- `docs/ROADMAP.md`: phase roadmap
- `tasks/TASKS.md`: backlog
- `tasks/CURRENT.md`: active task and checkpoint
- `tasks/PROGRESS.md`: chronological progress log
- `experiments/`: disposable prototypes and experiments

## Working Style

The product owner steers product direction. LLM agents do the coding, planning, and progress recording. Agents must update the task and progress files so another agent can resume without hidden context.

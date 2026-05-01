# Contextual Language Assistant

A native macOS language assistant for non-native English speakers. The app helps users understand selected English text in context, inspect confusing phrases, compose natural English from their own language, review English they wrote, and learn saved phrases over time.

## Current Phase

This repository is in the proof-of-concept phase.

Before building the durable MVP, we are iterating on a Swift/SwiftUI proof of concept under `poc/` to learn from real macOS behavior:

- menu-bar app lifecycle
- global shortcut or trigger flow
- selected text capture and clipboard fallback
- floating window behavior
- translation-first explanation flow
- phrase detail expansion
- phrase composer
- basic local persistence feel

The POC is a learning artifact. It is not the production app foundation by default, but it is runnable for product feedback.

## Run The POC

Requirements:

- macOS
- Xcode Command Line Tools or Xcode with Swift installed
- optional: Ollama running locally for local AI responses
- optional: OpenRouter API key for cloud model responses

Run:

```bash
cd poc
swift run
```

The app appears in the macOS menu bar as `Context`. Use `Open Assistant` from the menu bar, or press `Command+Option+E` to open the floating bubble from the current selection.

For restart-on-change while editing:

```bash
cd poc
bash scripts/dev-watch.sh
```

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
- `experiments/poc/`: runnable macOS proof of concept

## Working Style

The product owner steers product direction. LLM agents do the coding, planning, and progress recording. Agents must update the task and progress files so another agent can resume without hidden context.

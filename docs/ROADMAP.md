# Roadmap

## Phase 0: Repository Operating Scaffold

Create the documents, task files, and progress recording system that let LLM agents work safely with product-only steering.

Exit criteria:

- `AGENTS.md` exists.
- Product, MVP, discovery, decision, and task docs exist.
- The active task points to discovery, not production code.

## Phase 1: Discovery Prototype

Create a disposable Swift/SwiftUI macOS proof of concept under `experiments/poc/`.

Exit criteria:

- Prototype can be run locally.
- It demonstrates the core selected-text or clipboard-trigger loop.
- It demonstrates the floating explanation window.
- It demonstrates phrase detail and composer interactions with stubbed responses.
- Findings are recorded in `docs/DISCOVERY.md`.

## Phase 2: Findings And Product Refinement

Convert prototype lessons into product decisions and real MVP constraints.

Exit criteria:

- `docs/DISCOVERY.md` has an extraction summary.
- `docs/DECISIONS.md` records durable choices.
- `docs/MVP.md` is updated if discovery changes scope.
- Open questions are listed in `docs/QUESTIONS.md`.

## Phase 3: Mockups For The Real MVP

Create focused mockups for flows that need product approval before production implementation.

Exit criteria:

- Key flows have approved mockups or explicit notes saying a mockup is unnecessary.
- Production tasks reference relevant mockups and discovery findings.

## Phase 4: Real MVP Plan

Write the formal implementation plan for the production macOS app.

Exit criteria:

- Architecture choices account for discovery findings.
- Tasks are small enough for LLM agents to execute.
- Persistence, AI provider, privacy, and macOS permission strategies are explicit.

## Phase 5: Production MVP Build

Build the durable app from the real plan.

Exit criteria:

- MVP success criteria in `docs/MVP.md` are met.
- Checks pass.
- Product owner can use the app end to end.

# Tasks

## Backlog

### TASK-001: Repository Operating Scaffold

**Status:** done
**Owner type:** agent
**Goal:** Create the repository docs, task tracking, discovery lane, and agent instructions.
**Acceptance criteria:**

- `AGENTS.md` exists.
- `README.md` exists.
- Product, MVP, discovery, roadmap, decision, and question docs exist.
- Mockup and experiment lanes exist.
- Task tracking files exist.
- `tasks/CURRENT.md` points to TASK-002 when complete.

### TASK-002: Discovery Prototype Brief

**Status:** done
**Owner type:** agent with product review
**Goal:** Turn `docs/DISCOVERY.md` into a concrete prototype brief before coding the Swift experiment.
**Acceptance criteria:**

- Prototype must-have behaviors are listed.
- Stubbed data and responses are defined.
- Product review questions are listed.
- Build/run expectations are documented in `poc/README.md`.

### TASK-003: Swift POC

**Status:** active
**Owner type:** agent
**Goal:** Create a disposable Swift/SwiftUI macOS prototype under `poc/`.
**Acceptance criteria:**

- Prototype runs locally on macOS.
- Prototype demonstrates menu-bar or trigger entry.
- Prototype demonstrates selected text or clipboard input.
- Prototype demonstrates floating explanation UI.
- Prototype demonstrates phrase detail and composer flows with stubbed responses.
- Findings are recorded in `docs/DISCOVERY.md`.

### TASK-004: Discovery Findings Extraction

**Status:** not-started
**Owner type:** agent with product review
**Goal:** Convert prototype learnings into product decisions and real MVP planning inputs.
**Acceptance criteria:**

- `docs/DISCOVERY.md` has an extraction summary.
- `docs/DECISIONS.md` records accepted durable decisions.
- `docs/QUESTIONS.md` lists unresolved product questions.
- `docs/MVP.md` is updated if scope changed.

### TASK-005: Real MVP Mockup Pass

**Status:** not-started
**Owner type:** agent with product review
**Goal:** Produce focused mockups for flows that still need product approval after discovery.
**Acceptance criteria:**

- Mockup files exist under `docs/mockups/`.
- Each mockup has a state.
- Approved mockups are linked from future implementation tasks.

### TASK-006: Real MVP Implementation Plan

**Status:** not-started
**Owner type:** agent
**Goal:** Write the production MVP implementation plan after discovery and mockup review.
**Acceptance criteria:**

- Plan references discovery findings.
- Plan references approved mockups or explains why not needed.
- Plan separates production code from prototype code.
- Plan includes testing and verification strategy.

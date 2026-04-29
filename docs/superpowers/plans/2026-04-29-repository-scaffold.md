# Repository Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the discovery-first repository operating scaffold so LLM agents can create a disposable Swift prototype, record findings, and later plan the real MVP.

**Architecture:** This is a documentation and workflow scaffold, not production app code. The root docs define product intent and operating rules; `tasks/` tracks executable work and progress; `experiments/` contains disposable prototype lanes; `docs/DISCOVERY.md` captures what reality teaches before the durable app is planned.

**Tech Stack:** Markdown, Git, native macOS/Swift discovery preparation only. No production Swift project or dependencies are created in this plan.

---

## File Structure

- Create `.gitignore`: ignores local brainstorming state, macOS noise, build products, dependency folders, secrets, and generated scratch files.
- Create `README.md`: human-readable project overview, current phase, and navigation.
- Create `AGENTS.md`: mandatory instructions for LLM agents, including discovery-first workflow and progress recording.
- Create `docs/PRODUCT.md`: cleaned product brief derived from `docs/IDEA.md`.
- Create `docs/MVP.md`: MVP scope, non-goals, success criteria, and guardrails.
- Create `docs/DISCOVERY.md`: discovery prototype brief, findings log, and extraction checklist.
- Create `docs/ROADMAP.md`: phased roadmap from scaffold to discovery to real MVP.
- Create `docs/DECISIONS.md`: decision log with initial decisions.
- Create `docs/QUESTIONS.md`: open product questions and rules for agents.
- Create `docs/mockups/README.md`: mockup workflow and approval states.
- Create `experiments/README.md`: rules for disposable experiments.
- Create `experiments/swift-discovery/README.md`: scope for the one-shot Swift discovery prototype.
- Create `tasks/README.md`: how agents select, execute, and update tasks.
- Create `tasks/TASKS.md`: initial discovery-first backlog.
- Create `tasks/PROGRESS.md`: chronological progress log initialized with baseline entries.
- Create `tasks/CURRENT.md`: active task pointer, initially aimed at the Swift discovery brief.
- Create `tasks/templates/task.md`: reusable task format.

## Task 1: Ignore Local And Generated Files

**Files:**
- Create: `.gitignore`

- [ ] **Step 1: Create `.gitignore`**

Write this exact file:

```gitignore
# macOS
.DS_Store
.AppleDouble
.LSOverride

# Local agent and brainstorming state
.superpowers/
.codex/
.agents/tmp/

# Build products
.build/
Build/
DerivedData/
*.xcuserdata/
*.xcworkspace/xcuserdata/
*.xcodeproj/xcuserdata/
*.xcodeproj/project.xcworkspace/xcuserdata/

# Swift Package Manager
.swiftpm/
Package.resolved

# Dependencies
node_modules/
vendor/

# Secrets and local config
.env
.env.*
*.local
*.key
*.p8
*.mobileprovision

# Logs and scratch files
*.log
tmp/
scratch/
coverage/
```

- [ ] **Step 2: Verify ignored files no longer appear as untracked**

Run:

```bash
git status --short
```

Expected: `.DS_Store` and `.superpowers/` are not listed. New scaffold files created later may appear as untracked.

- [ ] **Step 3: Commit ignore rules**

Run:

```bash
git add .gitignore
git commit -m "chore: add repository ignore rules"
```

Expected: commit succeeds.

## Task 2: Create Human And Agent Entry Points

**Files:**
- Create: `README.md`
- Create: `AGENTS.md`

- [ ] **Step 1: Create `README.md`**

Write this exact file:

```markdown
# Contextual Language Assistant

A native macOS language assistant for non-native English speakers. The app helps users understand selected English text in context, inspect confusing phrases, compose natural English from their own language, and review saved phrases over time.

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
```

- [ ] **Step 2: Create `AGENTS.md`**

Write this exact file:

```markdown
# AGENTS.md

## Mission

Build the Contextual Language Assistant MVP through a discovery-first workflow. The product owner steers product direction; agents handle code, planning, technical exploration, and documentation.

## Required Reading Before Any Work

Read these files before making changes:

1. `docs/IDEA.md`
2. `docs/MVP.md`
3. `docs/DISCOVERY.md`
4. `tasks/CURRENT.md`
5. The relevant task in `tasks/TASKS.md`

If a file does not exist yet, create it only when the active task asks for it.

## Current Strategy

We will not start with the production app. First, create a disposable Swift/SwiftUI discovery prototype under `experiments/swift-discovery/`.

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
```

- [ ] **Step 3: Verify entry point files exist**

Run:

```bash
test -f README.md && test -f AGENTS.md
```

Expected: command exits with status 0.

- [ ] **Step 4: Commit entry point files**

Run:

```bash
git add README.md AGENTS.md
git commit -m "docs: add project and agent entry points"
```

Expected: commit succeeds.

## Task 3: Create Product And Discovery Docs

**Files:**
- Create: `docs/PRODUCT.md`
- Create: `docs/MVP.md`
- Create: `docs/DISCOVERY.md`

- [ ] **Step 1: Create `docs/PRODUCT.md`**

Write this exact file:

```markdown
# Product Brief

## Purpose

Contextual Language Assistant is a native macOS app that helps non-native English speakers understand and use English in real work contexts.

The app focuses on nuance: idioms, tone, phrases, sayings, slang, professional wording, and the difference between literal and natural English.

## Target User

The target user:

- works in English-speaking environments
- understands basic English
- struggles with unfamiliar phrases, idioms, tone, or subtle wording
- wants to express their own thoughts in natural English
- wants to remember useful phrases over time

## Core Experience

The user selects English text in any macOS app and triggers the assistant.

The app first shows a translation of the selected sentence or paragraph into the user's native language. Then the user can select one or more confusing words or phrases from the original text. The app explains each selected phrase in context, including meaning, tone, formality, and examples.

The user can save phrases to a learning bucket and revisit them later.

## Main Capabilities

### Explain Selected Text

- Trigger from selected text in another macOS app.
- Show translation first.
- Let the user choose confusing words or phrases.
- Explain meaning in isolation and in context.
- Explain tone, formality, idiomatic usage, and examples.

### Phrase Composer

- Let the user write a thought in their native language.
- Produce natural English rather than literal translation.
- Offer casual, neutral, and professional variants.

### Learning Bucket

- Save explained words and phrases.
- Keep original sentence, selected phrase, explanation, source app setting, lookup date, and learning status.

### Review Mode

- Revisit saved phrases.
- Show newer or still-learning items more often.
- Let learned items return after a longer interval.

### History

- Browse previous lookups and phrase compositions.
- Search, delete, edit, or mark items as learned.

## Privacy Position

The app should be clear about what is stored locally and what is sent to an AI provider. Users should be able to delete history, disable source app storage, exclude apps, choose whether raw text is stored, and configure the AI provider.
```

- [ ] **Step 2: Create `docs/MVP.md`**

Write this exact file:

```markdown
# MVP Scope

## MVP Goal

A user can select confusing English text in another macOS app, understand the sentence and specific phrases, save useful phrases, review them later, and compose natural English from their native language.

## In Scope

- Native macOS app.
- Mostly menu-bar driven.
- Global shortcut or practical trigger flow.
- Fast floating window UI.
- Selected text explanation.
- Translation-first response.
- Phrase-level explanation after the user chooses confusing phrases.
- Phrase composer with casual, neutral, and professional outputs.
- Local history.
- Learning bucket.
- Basic review mode.
- Settings for native language and AI provider.
- Privacy controls for local storage and source app names.

## Out Of Scope

- Browser extension.
- OCR.
- Screenshots.
- Team accounts.
- Cloud sync.
- Offline AI.
- App Store release.
- Pronunciation or audio.
- Advanced dictionary features.
- iOS app in the MVP.

## Success Criteria

The MVP is successful when a user can:

1. Select confusing English text in another app.
2. Trigger the assistant.
3. Understand the sentence translation.
4. Ask for phrase-level explanation.
5. Save a useful phrase.
6. Review saved phrases.
7. Write a thought in their native language and get natural English back.

## Guardrails

- Prefer speed and clarity over feature breadth.
- Do not hide privacy-sensitive behavior.
- Do not require cloud sync.
- Do not let the discovery prototype become production architecture by accident.
- Keep future iOS sharing possible by separating durable domain concepts from macOS-only behavior in the real plan.
```

- [ ] **Step 3: Create `docs/DISCOVERY.md`**

Write this exact file:

```markdown
# Discovery

## Purpose

Use a disposable Swift/SwiftUI prototype to learn from real macOS behavior before planning the production MVP.

The prototype should answer practical questions that static plans and mockups cannot answer well.

## Prototype Location

`experiments/swift-discovery/`

## Prototype Constraints

- Disposable by default.
- Rough UI is acceptable.
- Duplicate code is acceptable.
- Stubbed AI responses are acceptable.
- Local sample data is acceptable.
- No secrets.
- No paid provider dependency unless explicitly approved.
- No production migrations.

## Questions To Answer

### macOS App Shape

- Does a menu-bar-first app feel right for this workflow?
- How should the floating window open, focus, and dismiss?
- What lifecycle behavior is surprising?

### Trigger And Text Capture

- Can selected text be captured reliably?
- Is a clipboard fallback acceptable?
- What permission prompts appear?
- Which apps behave differently?

### Explanation Flow

- Does translation-first feel helpful or too slow?
- How should users choose confusing phrases?
- How much detail fits before the window feels heavy?

### Composer Flow

- Where should phrase composing live?
- Are casual, neutral, and professional variants enough?
- Should composer history be mixed with lookup history?

### Learning And Review

- What is the lightest useful learning bucket?
- What review interaction feels good enough for MVP?
- Which metadata matters?

## Findings Log

Add entries in this format:

```markdown
### YYYY-MM-DD - Finding Title

**Area:** Trigger, UI, persistence, privacy, AI, or review
**Observed:** What happened in the prototype.
**Why it matters:** Product or technical implication.
**Recommendation:** What the real MVP should do.
**Carry forward:** Yes or no.
```

## Extraction Checklist

Before writing the real MVP implementation plan, summarize:

- product decisions changed by the prototype
- macOS APIs and permissions that matter
- UX flows that should be kept
- UX flows that should be changed
- code ideas worth reusing
- code ideas to discard
- risks that need planned mitigation
```

- [ ] **Step 4: Verify product docs exist**

Run:

```bash
test -f docs/PRODUCT.md && test -f docs/MVP.md && test -f docs/DISCOVERY.md
```

Expected: command exits with status 0.

- [ ] **Step 5: Commit product and discovery docs**

Run:

```bash
git add docs/PRODUCT.md docs/MVP.md docs/DISCOVERY.md
git commit -m "docs: define product mvp and discovery goals"
```

Expected: commit succeeds.

## Task 4: Create Roadmap, Decision Log, And Questions Log

**Files:**
- Create: `docs/ROADMAP.md`
- Create: `docs/DECISIONS.md`
- Create: `docs/QUESTIONS.md`

- [ ] **Step 1: Create `docs/ROADMAP.md`**

Write this exact file:

```markdown
# Roadmap

## Phase 0: Repository Operating Scaffold

Create the documents, task files, and progress recording system that let LLM agents work safely with product-only steering.

Exit criteria:

- `AGENTS.md` exists.
- Product, MVP, discovery, decision, and task docs exist.
- The active task points to discovery, not production code.

## Phase 1: Discovery Prototype

Create a disposable Swift/SwiftUI macOS prototype under `experiments/swift-discovery/`.

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
```

- [ ] **Step 2: Create `docs/DECISIONS.md`**

Write this exact file:

```markdown
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
```

- [ ] **Step 3: Create `docs/QUESTIONS.md`**

Write this exact file:

```markdown
# Product Questions

Agents should add questions here when product behavior is unclear. Do not invent product direction when a question would change user experience, privacy, or MVP scope.

## Open Questions

No open questions yet.

## Answered Questions

### 2026-04-29 - Should We Start With Mockups Or A Prototype?

**Answer:** Start with a disposable Swift/SwiftUI discovery prototype, then use the findings to shape mockups and the real MVP plan.

### 2026-04-29 - Should Prototype Code Become The Real App?

**Answer:** No. The prototype is disposable by default. Reuse ideas only after discovery findings are extracted and accepted.
```

- [ ] **Step 4: Verify roadmap and governance docs exist**

Run:

```bash
test -f docs/ROADMAP.md && test -f docs/DECISIONS.md && test -f docs/QUESTIONS.md
```

Expected: command exits with status 0.

- [ ] **Step 5: Commit roadmap and governance docs**

Run:

```bash
git add docs/ROADMAP.md docs/DECISIONS.md docs/QUESTIONS.md
git commit -m "docs: add roadmap decisions and product questions"
```

Expected: commit succeeds.

## Task 5: Create Mockup And Experiment Lanes

**Files:**
- Create: `docs/mockups/README.md`
- Create: `experiments/README.md`
- Create: `experiments/swift-discovery/README.md`

- [ ] **Step 1: Create `docs/mockups/README.md`**

Write this exact file:

```markdown
# Mockups

Mockups clarify product direction before production implementation. They can be created before or after the discovery prototype depending on what needs visual approval.

## States

- `proposed`: ready for product review
- `needs-product-input`: blocked on a product decision
- `approved`: accepted for implementation planning
- `superseded`: replaced by another direction

## Naming

Use descriptive names:

- `selected-text-explanation.md`
- `phrase-composer.md`
- `learning-bucket-review.md`
- `privacy-settings.md`

If mockups are images or interactive files, include a short Markdown companion explaining:

- goal
- status
- what changed
- open questions
- related task

## Initial Mockup Targets

- Menu bar and trigger entry point
- Selected text explanation window
- Phrase selection and detail expansion
- Phrase composer
- Learning bucket and review mode
- Privacy and settings

## Approval Rule

Production tasks should reference an approved mockup or a discovery finding that explains why a separate mockup is unnecessary.
```

- [ ] **Step 2: Create `experiments/README.md`**

Write this exact file:

```markdown
# Experiments

This directory contains disposable prototypes and technical spikes.

## Rules

- Experiments are not production code by default.
- Experiments should optimize for learning speed.
- Experiments may duplicate code.
- Experiments should avoid secrets and paid services unless explicitly approved.
- Findings must be recorded in `docs/DISCOVERY.md`.
- Durable decisions must be promoted to `docs/DECISIONS.md`.

## Current Experiments

- `swift-discovery/`: native macOS discovery prototype.
```

- [ ] **Step 3: Create `experiments/swift-discovery/README.md`**

Write this exact file:

```markdown
# Swift Discovery Prototype

This directory is reserved for the disposable native macOS prototype.

## Goal

Learn what the real app must account for before we plan and build the production MVP.

## Prototype Scope

The prototype should attempt:

- menu-bar app shell
- global shortcut or practical trigger alternative
- selected text capture or clipboard fallback
- fast floating window
- translation-first selected text view
- phrase detail expansion
- phrase composer with tone variants
- lightweight local sample history or learning bucket
- stubbed LLM responses

## Non-Goals

- production architecture
- final visual design
- real AI provider integration
- durable database migrations
- App Store packaging
- iOS sharing

## Required Handoff

After prototype work, update:

- `docs/DISCOVERY.md`
- `tasks/PROGRESS.md`
- `tasks/CURRENT.md`

Record what worked, what failed, what surprised you, and what the real MVP should do differently.
```

- [ ] **Step 4: Verify mockup and experiment docs exist**

Run:

```bash
test -f docs/mockups/README.md && test -f experiments/README.md && test -f experiments/swift-discovery/README.md
```

Expected: command exits with status 0.

- [ ] **Step 5: Commit mockup and experiment lanes**

Run:

```bash
git add docs/mockups/README.md experiments/README.md experiments/swift-discovery/README.md
git commit -m "docs: add mockup and experiment lanes"
```

Expected: commit succeeds.

## Task 6: Create Task Tracking System

**Files:**
- Create: `tasks/README.md`
- Create: `tasks/TASKS.md`
- Create: `tasks/PROGRESS.md`
- Create: `tasks/CURRENT.md`
- Create: `tasks/templates/task.md`

- [ ] **Step 1: Create `tasks/README.md`**

Write this exact file:

```markdown
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
```

- [ ] **Step 2: Create `tasks/TASKS.md`**

Write this exact file:

```markdown
# Tasks

## Backlog

### TASK-001: Repository Operating Scaffold

**Status:** active
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

**Status:** not-started
**Owner type:** agent with product review
**Goal:** Turn `docs/DISCOVERY.md` into a concrete prototype brief before coding the Swift experiment.
**Acceptance criteria:**

- Prototype must-have behaviors are listed.
- Stubbed data and responses are defined.
- Product review questions are listed.
- Build/run expectations are documented in `experiments/swift-discovery/README.md`.

### TASK-003: One-Shot Swift Discovery Prototype

**Status:** not-started
**Owner type:** agent
**Goal:** Create a disposable Swift/SwiftUI macOS prototype under `experiments/swift-discovery/`.
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
```

- [ ] **Step 3: Create `tasks/PROGRESS.md`**

Write this exact file:

```markdown
# Progress

Chronological log of meaningful work. Agents must update this before ending a session.

## 2026-04-29 - Repository Initialized

**Task:** setup
**Summary:** Initialized git and committed the original idea plus repository setup design.
**Files changed:** `docs/IDEA.md`, `docs/superpowers/specs/2026-04-29-repository-setup-design.md`
**Checks run:** `git status --short`, spec consistency scan
**Decisions made:** Use a discovery-first workflow with a disposable Swift prototype before the real MVP plan.
**Next step:** Complete TASK-001 by creating the repository operating scaffold.
```

- [ ] **Step 4: Create `tasks/CURRENT.md`**

Write this exact file:

```markdown
# Current Task

## Active Task

**Task ID:** TASK-001
**Status:** active
**Title:** Repository Operating Scaffold

## Current Checkpoint

Create the repository scaffold files listed in `docs/superpowers/specs/2026-04-29-repository-setup-design.md`.

## Immediate Next Step

Finish TASK-001, then update this file so TASK-002, Discovery Prototype Brief, becomes active.

## Blockers

None.

## Discovery Notes

The first technical build should be a disposable Swift/SwiftUI prototype in `experiments/swift-discovery/`, not the production app.

## Handoff Notes

The product owner approved the discovery-first direction. Keep prototype findings in `docs/DISCOVERY.md`.
```

- [ ] **Step 5: Create `tasks/templates/task.md`**

Write this exact file:

```markdown
# TASK-ID: Task Title

**Status:** not-started
**Owner type:** agent
**Related docs:** `docs/MVP.md`, `docs/DISCOVERY.md`

## Goal

One sentence describing the outcome.

## Context

What the agent needs to know before starting.

## Scope

In scope:

- Specific item

Out of scope:

- Specific item

## Acceptance Criteria

- Observable completion criterion

## Steps

- [ ] Step 1
- [ ] Step 2
- [ ] Step 3

## Checks

Commands or manual checks required before completion.

## Progress Notes

Add dated notes or link to `tasks/PROGRESS.md`.
```

- [ ] **Step 6: Verify task files exist**

Run:

```bash
test -f tasks/README.md && test -f tasks/TASKS.md && test -f tasks/PROGRESS.md && test -f tasks/CURRENT.md && test -f tasks/templates/task.md
```

Expected: command exits with status 0.

- [ ] **Step 7: Commit task tracking system**

Run:

```bash
git add tasks/README.md tasks/TASKS.md tasks/PROGRESS.md tasks/CURRENT.md tasks/templates/task.md
git commit -m "docs: add task tracking system"
```

Expected: commit succeeds.

## Task 7: Final Consistency Check And Completion Update

**Files:**
- Modify: `tasks/TASKS.md`
- Modify: `tasks/CURRENT.md`
- Modify: `tasks/PROGRESS.md`

- [ ] **Step 1: Verify required scaffold files**

Run:

```bash
test -f AGENTS.md && test -f README.md && test -f .gitignore && test -f docs/PRODUCT.md && test -f docs/MVP.md && test -f docs/DISCOVERY.md && test -f docs/ROADMAP.md && test -f docs/DECISIONS.md && test -f docs/QUESTIONS.md && test -f docs/mockups/README.md && test -f experiments/README.md && test -f experiments/swift-discovery/README.md && test -f tasks/README.md && test -f tasks/TASKS.md && test -f tasks/PROGRESS.md && test -f tasks/CURRENT.md && test -f tasks/templates/task.md
```

Expected: command exits with status 0.

- [ ] **Step 2: Check for unfinished marker terms**

Run:

```bash
rg -n "UNFINISHED|INCOMPLETE|REPLACE_ME|COMING_SOON" README.md AGENTS.md docs/PRODUCT.md docs/MVP.md docs/DISCOVERY.md docs/ROADMAP.md docs/DECISIONS.md docs/QUESTIONS.md docs/mockups tasks experiments
```

Expected: no matches. If matches appear only inside the committed setup spec as historical examples, do not change them unless they are in newly created scaffold files.

- [ ] **Step 3: Update `tasks/TASKS.md` status**

Change TASK-001 status to `done` and TASK-002 status to `active`.

- [ ] **Step 4: Replace `tasks/CURRENT.md` with TASK-002**

Write this exact file:

```markdown
# Current Task

## Active Task

**Task ID:** TASK-002
**Status:** active
**Title:** Discovery Prototype Brief

## Current Checkpoint

Prepare a concrete brief for the one-shot Swift/SwiftUI discovery prototype.

## Immediate Next Step

Define the prototype's must-have behaviors, stubbed data, run expectations, and product review questions.

## Blockers

None.

## Discovery Notes

The prototype should test real macOS behavior before the production MVP is planned. It should be disposable by default.

## Handoff Notes

Use `docs/DISCOVERY.md` and `experiments/swift-discovery/README.md` as the source of truth for the prototype brief.
```

- [ ] **Step 5: Append completion entry to `tasks/PROGRESS.md`**

Append this exact entry:

```markdown

## 2026-04-29 - Repository Scaffold Completed

**Task:** TASK-001
**Summary:** Created the discovery-first repository operating scaffold for product-led, LLM-coded iteration.
**Files changed:** `.gitignore`, `README.md`, `AGENTS.md`, `docs/PRODUCT.md`, `docs/MVP.md`, `docs/DISCOVERY.md`, `docs/ROADMAP.md`, `docs/DECISIONS.md`, `docs/QUESTIONS.md`, `docs/mockups/README.md`, `experiments/README.md`, `experiments/swift-discovery/README.md`, `tasks/README.md`, `tasks/TASKS.md`, `tasks/PROGRESS.md`, `tasks/CURRENT.md`, `tasks/templates/task.md`
**Checks run:** Required file existence checks; unfinished-marker scan.
**Decisions made:** TASK-002 is now active and will brief the disposable Swift discovery prototype.
**Next step:** Execute TASK-002.
```

- [ ] **Step 6: Review git status**

Run:

```bash
git status --short
```

Expected: only intentional scaffold changes are listed. `.DS_Store` and `.superpowers/` are ignored.

- [ ] **Step 7: Commit final scaffold updates**

Run:

```bash
git add tasks/TASKS.md tasks/CURRENT.md tasks/PROGRESS.md
git commit -m "docs: complete repository scaffold task"
```

Expected: commit succeeds.

- [ ] **Step 8: Confirm clean status**

Run:

```bash
git status --short
```

Expected: no tracked changes. Ignored local files do not appear.

## Self-Review Checklist

- Spec coverage: Tasks create every scaffold file named in the discovery-first setup spec.
- Discovery coverage: `docs/DISCOVERY.md`, `experiments/README.md`, and `experiments/swift-discovery/README.md` make the prototype phase explicit.
- Agent workflow coverage: `AGENTS.md`, `tasks/README.md`, `tasks/TASKS.md`, `tasks/CURRENT.md`, and `tasks/PROGRESS.md` define how agents work and record progress.
- Product-owner workflow coverage: `docs/QUESTIONS.md`, `docs/DECISIONS.md`, and `docs/mockups/README.md` keep product steering separate from code review.
- Production boundary: The plan creates no production Swift project and no real AI provider integration.

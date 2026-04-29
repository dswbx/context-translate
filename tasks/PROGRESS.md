# Progress

Chronological log of meaningful work. Agents must update this before ending a session.

## 2026-04-29 - Repository Initialized

**Task:** setup
**Summary:** Initialized git and committed the original idea plus repository setup design.
**Files changed:** `docs/IDEA.md`, `docs/superpowers/specs/2026-04-29-repository-setup-design.md`
**Checks run:** `git status --short`, spec consistency scan
**Decisions made:** Use a discovery-first workflow with a disposable Swift prototype before the real MVP plan.
**Next step:** Complete TASK-001 by creating the repository operating scaffold.

## 2026-04-29 - Repository Scaffold Completed

**Task:** TASK-001
**Summary:** Created the discovery-first repository operating scaffold for product-led, LLM-coded iteration.
**Files changed:** `.gitignore`, `README.md`, `AGENTS.md`, `docs/PRODUCT.md`, `docs/MVP.md`, `docs/DISCOVERY.md`, `docs/ROADMAP.md`, `docs/DECISIONS.md`, `docs/QUESTIONS.md`, `docs/mockups/README.md`, `experiments/README.md`, `experiments/swift-discovery/README.md`, `tasks/README.md`, `tasks/TASKS.md`, `tasks/PROGRESS.md`, `tasks/CURRENT.md`, `tasks/templates/task.md`
**Checks run:** Required file existence checks; unfinished-marker scan.
**Decisions made:** TASK-002 is now active and will brief the disposable Swift discovery prototype.
**Next step:** Execute TASK-002.

## 2026-04-29 - Swift Discovery Prototype Started

**Task:** TASK-002, TASK-003
**Summary:** Added the discovery prototype brief and created a runnable SwiftPM macOS accessory app prototype with menu bar entry, floating panel, clipboard fallback, phrase explanation, composer, and review screens.
**Files changed:** `experiments/swift-discovery/README.md`, `experiments/swift-discovery/Package.swift`, `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/TASKS.md`, `tasks/CURRENT.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`, `swift run`
**Decisions made:** Continue discovery with SwiftPM for now; full Xcode is not required until the prototype needs Xcode-specific app project behavior.
**Next step:** Product owner tests the running prototype and reports what feels useful, awkward, or missing.

## 2026-04-29 - Prototype Interaction Feedback Applied

**Task:** TASK-003
**Summary:** Updated the prototype so the assistant window stays visible until explicitly closed and the explanation flow starts empty with individual clickable words from the captured text.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** The discovery flow should not preselect an explanation. The floating window should stay visible across focus changes and close through the window control or Esc.
**Next step:** Relaunch the prototype and product-test word clicking, Esc close, and window persistence.

## 2026-04-29 - Inline Word Selection And Dev Watch Added

**Task:** TASK-003
**Summary:** Replaced the separate word-button grid with clickable words inside the original text area and added a lightweight SwiftPM restart-on-change watcher.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `experiments/swift-discovery/scripts/dev-watch.sh`, `experiments/swift-discovery/README.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Word selection belongs in the original text surface. SwiftPM needs a helper script for watch-like iteration.
**Next step:** Test `bash scripts/dev-watch.sh` during prototype iteration if manual restarts become annoying.

## 2026-04-29 - Fixed Inline Word Wrapping

**Task:** TASK-003
**Summary:** Replaced the adaptive grid word layout with a custom intrinsic wrapping layout so clickable words keep sentence-like flow and wrap between words.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** The original text interaction needs inline-block style behavior, not equal-width adaptive grid cells.
**Next step:** Relaunch the prototype and verify the original sentence reads naturally while individual words remain clickable.

## 2026-04-29 - Added Word States And Ollama Settings

**Task:** TASK-003
**Summary:** Polished the empty explanation pane, added stable hover and selected styles for clickable words, and added an Ollama settings tab with model discovery, persisted model selection, and non-streaming local generation.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use Ollama first for private local AI discovery. Use macOS accent color for selected word styling and reserve word padding in every state to avoid layout shifts.
**Next step:** Run the prototype with and without Ollama running to compare local AI behavior and fallback status messaging.

## 2026-04-29 - Split Ollama Translation And Detail Prompts

**Task:** TASK-003
**Summary:** Reworked the AI flow so German translation and selected-word details are generated by separate Ollama prompts, added Regenerate and Stop controls, and mapped model detail JSON into the detail pane fields.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep model selection in Settings for now. Generate translation and details through separate, cancellable local model requests.
**Next step:** Test with Ollama running and at least one local model available.

## 2026-04-29 - Added Product Terminology

**Task:** TASK-003
**Summary:** Added a shared terminology document for core product, AI, privacy, UI pane, and development language.
**Files changed:** `docs/TERMINOLOGY.md`, `README.md`, `AGENTS.md`, `tasks/PROGRESS.md`
**Checks run:** Documentation-only change.
**Decisions made:** Use "original text", "selected term", "explanation", "text pane", "explanation pane", "learning bucket", "discovery prototype", and related terms consistently.
**Next step:** Use the terminology doc when naming UI elements, tasks, and future implementation types.

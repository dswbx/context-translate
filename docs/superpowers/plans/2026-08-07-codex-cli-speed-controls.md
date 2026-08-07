# Codex CLI Speed Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Codex CLI latency controls adjustable in Settings and make model discovery feel immediate without hard-coded model capabilities.

**Architecture:** Extend the decoded CLI catalog with its advertised reasoning levels and service tiers, persist a selected reasoning effort and Fast toggle, and translate those settings into `codex exec` config arguments. Load the CLI-bundled catalog immediately, then replace it with the live catalog when Refresh completes; keep generation isolated in fresh ephemeral CLI runs rather than adopting the experimental app-server protocol.

**Tech Stack:** Swift 5.9, SwiftUI, Foundation `Process`, Swift Concurrency, SwiftPM Swift Testing, Codex CLI 0.142.x catalog JSON.

## Global Constraints

- Keep Ollama, OpenRouter, Apple Intelligence, and existing Codex behavior available.
- Discover models, reasoning efforts, and Fast capability from the installed CLI; do not hard-code model identifiers.
- Default Codex reasoning to `low` for language-assistance requests.
- Send `service_tier="priority"` only when Fast is enabled and the selected model advertises that tier.
- Keep CLI Default valid even when the catalog is unavailable.
- Preserve ephemeral read-only subprocess execution, cancellation, timeouts, and sanitized errors.

---

### Task 1: Decode Dynamic Speed Capabilities

**Files:**
- Modify: `poc/Sources/ContextTranslateDiscovery/CodexCLIRunner.swift`
- Test: `poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift`

**Interfaces:**
- Produces: `CodexCLIReasoningLevel`, `CodexCLIServiceTier`, enriched `CodexCLIModel`, and capability helpers.
- Produces: `CodexCLIRunner.fetchBundledModels() async throws -> [CodexCLIModel]` using `codex debug models --bundled`.

- [ ] **Step 1: Write failing catalog tests**

Add fixtures asserting snake-case decoding for `default_reasoning_level`, `supported_reasoning_levels`, and `service_tiers`, including a model with `priority` and a model without it.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --filter CodexCLIRunnerTests`

Expected: compilation fails because the capability fields and bundled-catalog method do not exist.

- [ ] **Step 3: Implement catalog capability decoding**

Decode these CLI-owned fields without model-name conditionals:

```swift
struct CodexCLIReasoningLevel: Decodable, Equatable, Identifiable {
    let effort: String
    let description: String
    var id: String { effort }
}

struct CodexCLIServiceTier: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String
}
```

Add `defaultReasoningLevel`, `supportedReasoningLevels`, and `serviceTiers` to `CodexCLIModel`, with missing arrays decoded as empty for compatibility with older CLIs. Add helpers for supported efforts and the `priority` tier.

- [ ] **Step 4: Implement bundled model discovery**

Refactor model fetching through one private method and call it with `debug models --bundled` for the instant catalog, retaining `debug models` for authoritative live refresh.

- [ ] **Step 5: Run focused tests**

Expected: all runner tests pass.

### Task 2: Persist And Apply Adjustable Speed Settings

**Files:**
- Modify: `poc/Sources/ContextTranslateDiscovery/CodexCLIRunner.swift`
- Modify: `poc/Sources/ContextTranslateDiscovery/main.swift`
- Test: `poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift`

**Interfaces:**
- Produces: `CodexCLIExecutionOptions(reasoningEffort:serviceTier:)`.
- Changes: `CodexCLIRunner.generate(prompt:modelSlug:options:)`.
- Produces store state/actions for `selectedCodexReasoningEffort` and `isCodexFastModeEnabled`.

- [ ] **Step 1: Write failing CLI argument tests**

Update the fake executable fixture to record arguments and assert generation includes:

```text
-c model_reasoning_effort="low"
-c service_tier="priority"
```

Also assert `service_tier` is absent when Fast is disabled.

- [ ] **Step 2: Implement execution options**

Insert argument-safe `-c` pairs into `codex exec`; never concatenate shell commands. Keep the existing model argument and stdin prompt path unchanged.

- [ ] **Step 3: Add persisted store settings**

Persist reasoning under `ContextDiscovery.CodexReasoningEffort`, defaulting to `low`, and Fast under `ContextDiscovery.CodexFastMode`. When the selected model changes or a catalog refresh removes a capability, resolve reasoning to `low` when supported or the model default/first advertised effort, and automatically turn Fast off when `priority` is unavailable.

- [ ] **Step 4: Pass resolved options to every Codex generation**

Use the same adjustable options for Test Connection, Explain, selected-term detail, Composer, and Review.

- [ ] **Step 5: Run tests and build**

Run the complete Swift test suite and debug build with the full Xcode toolchain.

### Task 3: Settings UI And Immediate Catalog Loading

**Files:**
- Modify: `poc/Sources/ContextTranslateDiscovery/main.swift`
- Modify: `poc/scripts/reset-settings.sh`

**Interfaces:**
- Consumes the dynamic capability and persisted store APIs from Tasks 1 and 2.
- Produces adjustable Reasoning and Fast controls in the Codex Settings section.

- [ ] **Step 1: Add capability-driven controls**

Add a Reasoning picker populated from the selected model's advertised levels. Add a Fast toggle only when the selected model advertises service tier id `priority`; show its catalog description as secondary text.

- [ ] **Step 2: Load the bundled catalog immediately**

When Codex Settings first appears or Codex is selected, load `--bundled` models without a network refresh, resolve persisted settings, and retain the explicit Refresh Models button for the live catalog.

- [ ] **Step 3: Reset new preferences**

Add both UserDefaults keys to `poc/scripts/reset-settings.sh`.

- [ ] **Step 4: Verify UI compilation and scripts**

Run the Swift tests, Swift build, `bash -n poc/scripts/reset-settings.sh`, and `git diff --check`.

### Task 4: Discovery Handoff

**Files:**
- Modify: `poc/README.md`
- Modify: `docs/DISCOVERY.md`
- Modify: `tasks/PROGRESS.md`
- Modify: `tasks/CURRENT.md`

**Interfaces:**
- Records the measured live-versus-bundled catalog latency and explains Low/Fast tradeoffs.

- [ ] **Step 1: Document behavior and caveats**

Document that Low reduces reasoning work, Fast uses increased subscription usage where advertised, bundled discovery is immediate but live Refresh remains authoritative, and persistent app-server integration remains deferred.

- [ ] **Step 2: Run final verification and review**

Run all checks, request an independent code review, fix all Critical/Important findings, and confirm the only unrelated working-tree change remains `poc/scripts/dev-watch.sh`.

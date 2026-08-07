# Codex CLI Provider Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an experimental Codex CLI provider with CLI-owned authentication, discovered models, structured subprocess execution, Settings controls, and discovery documentation.

**Architecture:** A new `CodexCLIRunner.swift` file owns executable resolution, catalog decoding, login checks, subprocess execution, cancellation, temporary workspace cleanup, and sanitized errors. `DiscoveryStore` retains the existing shared prompts and adds Codex-specific state, while `SettingsView` exposes readiness and dynamic model selection without reading Codex credential or cache files.

**Tech Stack:** Swift 5.9, SwiftUI, Foundation `Process`, Swift Concurrency, SwiftPM XCTest, Codex CLI.

## Global Constraints

- Keep the implementation inside the disposable `poc/` lane.
- Preserve Ollama, OpenRouter, and Apple Intelligence behavior.
- Do not bundle Codex CLI or read its credentials, config, or model cache.
- Do not hard-code Codex model identifiers.
- Run generation ephemerally in a temporary directory with a read-only sandbox.
- Keep provider failures explicit; never silently fall back to another provider.

---

### Task 1: Codex CLI Runner And Unit Tests

**Files:**
- Create: `poc/Sources/ContextTranslateDiscovery/CodexCLIRunner.swift`
- Create: `poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift`
- Modify: `poc/Package.swift`

**Interfaces:**
- Produces: `CodexCLIModel`, `CodexCLIModelCatalog`, `CodexCLIReadiness`, `CodexCLIError`, and `CodexCLIRunner`.
- Produces: `CodexCLIRunner.resolveExecutable(environment:homeDirectory:fileExists:) -> URL?`.
- Produces: `CodexCLIRunner.checkReadiness() async -> CodexCLIReadiness`.
- Produces: `CodexCLIRunner.fetchModels() async throws -> [CodexCLIModel]`.
- Produces: `CodexCLIRunner.generate(prompt:modelSlug:) async throws -> String`.

- [ ] **Step 1: Add the SwiftPM test target**

Update `poc/Package.swift` so `targets` contains the executable and:

```swift
.testTarget(
    name: "ContextTranslateDiscoveryTests",
    dependencies: ["ContextTranslateDiscovery"]
)
```

- [ ] **Step 2: Write failing catalog and executable-resolution tests**

Create tests covering snake-case JSON, visibility filtering, inherited `PATH`, conventional GUI paths, and missing binaries:

```swift
@testable import ContextTranslateDiscovery
import XCTest

final class CodexCLIRunnerTests: XCTestCase {
    func testCatalogReturnsOnlyVisibleModels() throws {
        let data = Data(#"{"models":[{"slug":"gpt-a","display_name":"GPT A","visibility":"list"},{"slug":"hidden","display_name":"Hidden","visibility":"hide"}]}"#.utf8)
        let models = try CodexCLIRunner.decodeVisibleModels(from: data)
        XCTAssertEqual(models, [CodexCLIModel(slug: "gpt-a", displayName: "GPT A", visibility: "list")])
    }

    func testResolveExecutableUsesPathBeforeFallbacks() {
        let existing = Set(["/custom/bin/codex", "/Users/test/.local/bin/codex"])
        let result = CodexCLIRunner.resolveExecutable(
            environment: ["PATH": "/custom/bin:/usr/bin"],
            homeDirectory: URL(fileURLWithPath: "/Users/test"),
            fileExists: existing.contains
        )
        XCTAssertEqual(result?.path, "/custom/bin/codex")
    }

    func testResolveExecutableReturnsNilWhenCodexIsMissing() {
        XCTAssertNil(CodexCLIRunner.resolveExecutable(
            environment: [:],
            homeDirectory: URL(fileURLWithPath: "/Users/test"),
            fileExists: { _ in false }
        ))
    }
}
```

- [ ] **Step 3: Run tests and verify they fail**

Run: `swift test`

Expected: compilation fails because the Codex runner types do not exist.

- [ ] **Step 4: Implement catalog decoding and executable discovery**

Add:

```swift
struct CodexCLIModel: Decodable, Equatable, Identifiable {
    let slug: String
    let displayName: String
    let visibility: String
    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug
        case displayName = "display_name"
        case visibility
    }
}

struct CodexCLIModelCatalog: Decodable {
    let models: [CodexCLIModel]
}
```

Implement `decodeVisibleModels(from:)` by decoding the catalog, filtering `visibility == "list"`, and sorting by input order. Implement executable discovery from `PATH`, then `~/.local/bin/codex`, `/opt/homebrew/bin/codex`, and `/usr/local/bin/codex`.

- [ ] **Step 5: Add failing subprocess tests using a fake executable**

Create a temporary executable shell fixture per test that handles `login status`, `debug models`, and `exec`, then verify:

```swift
func testFetchModelsUsesCLIJSON() async throws
func testGenerateReturnsOutputLastMessage() async throws
func testNonzeroExitBecomesSanitizedError() async throws
func testCancellationStopsInFlightProcess() async throws
```

The fake `exec` branch must locate the `--output-last-message` argument and write `fixture response` to that file. The failing branch writes `fixture failure` to stderr and exits `17`; assert the public error contains the exit code but not arbitrary raw stderr.

- [ ] **Step 6: Run focused tests and verify they fail**

Run: `swift test --filter CodexCLIRunnerTests`

Expected: subprocess tests fail because readiness, model fetching, generation, and cancellation are not implemented.

- [ ] **Step 7: Implement subprocess execution**

Implement `CodexCLIRunner` with an injected executable URL and these commands:

```swift
["login", "status"]
["debug", "models"]
["exec", "--ephemeral", "--sandbox", "read-only", "--skip-git-repo-check", "--color", "never", "--output-last-message", outputURL.path, optionalModelArguments..., "-"]
```

Write prompts to stdin, drain stdout and stderr without blocking, enforce a 120-second generation timeout, terminate the child on task cancellation, and remove the unique temporary directory with `defer`. Return only trimmed `--output-last-message` content. Map missing executable, unauthenticated status, timeout, cancellation, empty output, malformed catalog, and nonzero exit to `CodexCLIError`.

- [ ] **Step 8: Run runner tests**

Run: `swift test --filter CodexCLIRunnerTests`

Expected: all runner tests pass.

- [ ] **Step 9: Commit the runner**

```bash
git add poc/Package.swift poc/Sources/ContextTranslateDiscovery/CodexCLIRunner.swift poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift
git commit -m "Add tested Codex CLI runner"
```

### Task 2: Provider State And Generation Routing

**Files:**
- Modify: `poc/Sources/ContextTranslateDiscovery/main.swift`
- Test: `poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift`

**Interfaces:**
- Consumes: `CodexCLIRunner`, `CodexCLIModel`, and `CodexCLIReadiness` from Task 1.
- Produces: Codex state and actions on `DiscoveryStore`: `codexModels`, `selectedCodexModel`, `codexReadiness`, `codexStatusMessage`, `isCheckingCodex`, `refreshCodexStatusAndModels()`, `selectCodexModel(_:)`, and `testCodexConnection()`.

- [ ] **Step 1: Add selection fallback tests**

Add pure helper tests:

```swift
func testResolveSelectedModelKeepsAvailableSavedSlug() {
    XCTAssertEqual(CodexModelSelection.resolve(saved: "b", available: ["a", "b"]), "b")
}

func testResolveSelectedModelFallsBackToCLIDefault() {
    XCTAssertNil(CodexModelSelection.resolve(saved: "missing", available: ["a"]))
}
```

- [ ] **Step 2: Run tests and verify they fail**

Run: `swift test --filter CodexCLIRunnerTests`

Expected: compilation fails because `CodexModelSelection` does not exist.

- [ ] **Step 3: Implement Codex provider state**

Add `.codexCLI` to `AIProvider` with display name `Codex CLI`. Initialize persisted model selection from `ContextDiscovery.SelectedCodexModel`, readiness as unknown, status as `Check Codex CLI before turning it on.`, and the runner from executable discovery.

Implement `CodexModelSelection.resolve(saved:available:)` so an unavailable saved slug becomes `nil`, meaning CLI Default. Persist an empty value for CLI Default.

- [ ] **Step 4: Implement readiness, refresh, and connection test actions**

`refreshCodexStatusAndModels()` checks `codex login status`, fetches the live catalog when authenticated, updates visible models, resolves the saved selection, and publishes actionable status. `testCodexConnection()` sends `Reply with OK only.` using the selected model and marks the provider ready only when a nonempty response returns.

- [ ] **Step 5: Route shared prompts through Codex**

Extend `activeModelDisplayName`, `providerRequestFailureMessage`, `isProviderConfigured`, `providerReadyMessage`, `providerMissingConfigurationMessage`, and `askActiveProvider(prompt:)`. Codex calls `runner.generate(prompt:modelSlug:)`; it must not change the translation, detail, Composer, or Review prompt contents.

- [ ] **Step 6: Preserve cancellation semantics**

Confirm existing `translationTask`, `detailTask`, `composerTask`, and `reviewTask` cancellation propagates into `CodexCLIRunner.generate`, terminates the subprocess, and produces the existing stopped-state messages rather than generic provider failures.

- [ ] **Step 7: Run tests and build**

Run: `swift test`

Expected: all tests pass.

Run: `swift build`

Expected: build succeeds.

- [ ] **Step 8: Commit provider routing**

```bash
git add poc/Sources/ContextTranslateDiscovery/main.swift poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift
git commit -m "Route POC prompts through Codex CLI"
```

### Task 3: Codex Settings UI

**Files:**
- Modify: `poc/Sources/ContextTranslateDiscovery/main.swift`

**Interfaces:**
- Consumes: Codex `DiscoveryStore` state and actions from Task 2.
- Produces: Codex provider configuration UI within `SettingsView.aiProviderSection`.

- [ ] **Step 1: Add the Codex Settings branch**

Extend the provider switch with `.codexCLI`. Show the disclosure `Codex CLI sends selected text to OpenAI using your authenticated Codex account.` and the resolved executable path when present.

- [ ] **Step 2: Add dynamic model selection**

Add a Picker containing `CLI Default` with an empty selection plus one option per `codexModels` entry using `displayName` and `slug`. Persist changes through `selectCodexModel(_:)`.

- [ ] **Step 3: Add status and actions**

Display `codexStatusMessage`. Add `Refresh Models` calling `refreshCodexStatusAndModels()` and `Test Codex CLI` calling `testCodexConnection()`. Disable actions while `isCheckingCodex` is true and show a progress indicator consistent with the Ollama/OpenRouter/Apple sections.

- [ ] **Step 4: Update setup warning copy**

Use a Codex-specific warning title when the provider is selected but unavailable. Missing installation instructs the user to install Codex CLI; missing authentication instructs them to run `codex login` in Terminal.

- [ ] **Step 5: Build and inspect the diff**

Run: `swift build`

Expected: build succeeds.

Run: `git diff --check`

Expected: no whitespace errors.

- [ ] **Step 6: Commit Settings UI**

```bash
git add poc/Sources/ContextTranslateDiscovery/main.swift
git commit -m "Add Codex CLI provider settings"
```

### Task 4: Documentation And End-To-End Verification

**Files:**
- Modify: `poc/README.md`
- Modify: `docs/TERMINOLOGY.md`
- Modify: `docs/DISCOVERY.md`
- Modify: `tasks/PROGRESS.md`
- Modify: `tasks/CURRENT.md`

**Interfaces:**
- Consumes: completed Codex provider behavior.
- Produces: resumable discovery findings and manual verification instructions.

- [ ] **Step 1: Update POC documentation**

Add Codex CLI to POC scope, optional requirements, provider descriptions, privacy disclosure, and setup steps: install Codex, run `codex login`, select Codex CLI, refresh models, choose CLI Default or a discovered model, and run the connection test.

- [ ] **Step 2: Update terminology and discovery findings**

Define Codex CLI as an experimental local command-line bridge to OpenAI-hosted models, not a local model. Add a dated finding covering dynamic model discovery via `codex debug models`, GUI executable-path discovery, CLI-owned authentication, process latency, and the experimental status of model discovery.

- [ ] **Step 3: Update task handoff files**

Append a final TASK-003 progress entry with files, checks, decisions, and manual follow-up. Keep TASK-003 active and set the immediate next step to manually verify Codex Explain, selected-term detail, Composer, Review, Stop, and model refresh in the running POC.

- [ ] **Step 4: Run automated verification**

Run: `swift test`

Expected: all tests pass.

Run: `swift build`

Expected: build succeeds.

Run: `git diff --check`

Expected: no whitespace errors.

- [ ] **Step 5: Run local CLI smoke checks**

Run: `codex login status`

Expected: exit zero with authenticated status.

Run a small test through the runner or POC using the selected discovered model.

Expected: nonempty response and no retained Codex session files in the temporary workspace.

- [ ] **Step 6: Request code review and fix findings**

Review the complete implementation against `docs/superpowers/specs/2026-08-07-codex-cli-provider-design.md`. Fix all critical and important findings, then rerun `swift test`, `swift build`, and `git diff --check`.

- [ ] **Step 7: Commit documentation and final fixes**

```bash
git add poc/README.md docs/TERMINOLOGY.md docs/DISCOVERY.md tasks/PROGRESS.md tasks/CURRENT.md poc/Package.swift poc/Sources/ContextTranslateDiscovery/CodexCLIRunner.swift poc/Sources/ContextTranslateDiscovery/main.swift poc/Tests/ContextTranslateDiscoveryTests/CodexCLIRunnerTests.swift
git commit -m "Document Codex CLI provider discovery"
```

# Codex CLI Provider Design

## Goal

Add Codex CLI as an experimental AI provider in the disposable Swift/SwiftUI POC while preserving Ollama, OpenRouter, and Apple Intelligence. The user installs and authenticates Codex independently; the POC invokes the CLI without reading or storing its credentials.

## Scope

The Codex CLI provider supports the existing Explain translation, selected-term explanation, Composer, and Review flows. Settings exposes CLI readiness, model discovery, model selection, refresh, and a connection test.

This discovery change does not establish Codex CLI as a production dependency, bundle the CLI, implement authentication inside the app, or remove any existing provider.

## Architecture

Keep the POC's existing shared prompts and provider switch. Add a focused Codex CLI runner responsible for locating the executable, running subprocesses, collecting output, enforcing timeouts and cancellation, and mapping process failures into user-facing errors.

The provider never reads Codex configuration, model-cache, or authentication files. Authentication remains owned by the installed CLI.

## Executable Discovery

The POC searches a small set of conventional executable locations appropriate to a GUI-launched macOS app, including the inherited `PATH`, `~/.local/bin/codex`, `/opt/homebrew/bin/codex`, and `/usr/local/bin/codex`. Settings reports the resolved executable path for discovery transparency.

If no executable is found, Codex remains unavailable and Settings instructs the user to install Codex CLI.

## Authentication And Readiness

Readiness is checked by running `codex login status`. The POC uses the exit status and sanitized command output to distinguish:

- CLI not installed
- CLI installed but not authenticated
- CLI authenticated and ready
- command execution failure

The app does not start an interactive login flow. It tells the user to run `codex login` in Terminal when authentication is missing.

## Model Discovery

The POC runs `codex debug models`, decodes its JSON response, and displays entries whose `visibility` is `list`. Each model uses its `slug` as the stable command value and `display_name` as the user-facing label. A Refresh action reruns discovery.

The selected slug is stored in `UserDefaults`. If the saved slug disappears from the refreshed catalog, the POC selects the first visible model. If model discovery fails or returns no visible models, the provider can still use the CLI-configured default by leaving the model argument unset.

The POC does not parse `~/.codex/models_cache.json` and does not hard-code model identifiers. `codex app-server` and its `model/list` protocol remain out of scope because they add a long-lived experimental protocol dependency for no current benefit.

## Generation

Each request launches a fresh non-interactive process in an empty temporary directory. The command uses:

- `codex exec`
- `--ephemeral`
- `--sandbox read-only`
- `--skip-git-repo-check`
- `--color never`
- `--model <slug>` only when a model is selected
- `-` to read the prompt from standard input

Existing prompts continue asking for plain translation text or JSON structures. The runner captures the assistant's final response without exposing raw event logs to the UI.

The temporary directory is removed after the process exits. Cancellation terminates the child process and maps to the POC's existing Stop behavior.

## User Interface

Add Codex CLI to the provider picker. Its Settings section includes:

- installation and authentication status
- resolved CLI path
- model picker with a CLI Default option
- Refresh Models action
- Test Codex CLI action
- concise disclosure that selected text is sent to OpenAI under the user's Codex account

Selecting Codex is allowed only after readiness succeeds. Existing loading, Regenerate, Stop, and provider status behavior remains unchanged.

## Errors

Errors should be actionable and provider-specific. The POC distinguishes missing executable, missing authentication, model discovery failure, unsupported saved model, timeout, cancellation, malformed or empty output, and nonzero CLI exit. Raw credential material or unrestricted stderr must never be shown or persisted.

## Verification

Extract pure model-catalog decoding and executable-resolution behavior into testable units where practical. Verify:

- catalog JSON decodes visible models and ignores hidden entries
- saved model selection survives refresh and falls back safely
- executable discovery handles installed and missing CLI states
- subprocess output and nonzero exits map correctly
- cancellation terminates an in-flight process
- the Swift package builds
- a manual smoke test discovers the locally installed Codex CLI, confirms authentication, lists models, and generates one response

## Discovery Outcome

Record latency, output reliability, model-list stability, cancellation behavior, macOS subprocess surprises, and any mismatch between CLI-oriented agents and language-assistance prompts in `docs/DISCOVERY.md`. Update `poc/README.md`, `tasks/PROGRESS.md`, and `tasks/CURRENT.md` before stopping.

# Context Translate POC

This directory contains the runnable native macOS proof of concept.

## Goal

Learn what the real app must account for before we plan and build the production MVP.

## POC Scope

The POC currently includes:

- menu-bar app shell
- global shortcut or practical trigger alternative
- selected text capture with clipboard fallback
- normal and floating bubble windows
- translation-first selected text view
- clickable original words with detail explanations
- composer with tone variants
- writing review mode
- local Ollama provider
- optional OpenRouter provider with Keychain-backed API key storage
- experimental Codex CLI provider using the user's existing CLI authentication

## Run

Requirements:

- macOS
- Xcode Command Line Tools or Xcode with Swift installed
- optional: Ollama running locally at `localhost:11434`
- optional: OpenRouter API key
- optional: Codex CLI installed and authenticated with `codex login`

From this directory:

```bash
swift run
```

Expected behavior:

- On first launch, the app opens Settings.
- The app appears in the macOS menu bar as `T`, unless disabled in Settings.
- Choosing `Open Assistant` opens a floating assistant panel.
- Pressing `Command+Option+E` opens a floating bubble near the current selection when possible.
- The app tries Accessibility selection first, then temporary copy-restore, then clipboard fallback.
- Settings are available from the app menu, the status menu, and `Command+,`.
- Settings can record a different popover shortcut for this POC.

## Build Interim App Bundle

To create a local `.app` bundle that is easier to share or drag into Applications:

```bash
bash scripts/package-app.sh
open "dist/Context Translate POC.app"
```

The script builds the release executable, wraps it in `dist/Context Translate POC.app`, and ad-hoc signs the bundle when `codesign` is available. This is only an interim local bundle; it is not notarized and is not a production distribution flow.

The app bundle version comes from `VERSION`. During the POC, versions use a simple incrementing format like `poc-1`, `poc-2`, and so on.

## GitHub Release

The manual `Release POC App` GitHub Action increments `VERSION`, commits the bump, builds the `.app`, zips it, and attaches the zip to a GitHub Release tagged with the same version.

## AI Providers

The POC supports:

- **Ollama:** default, local provider. Install/run a model in Ollama, then refresh models in Settings.
- **OpenRouter:** optional cloud provider. Add an API key in Settings. The key is stored in macOS Keychain.
- **Codex CLI:** experimental cloud provider. The POC finds an installed Codex executable, checks `codex login status`, discovers selectable models with `codex debug models`, and uses the CLI's existing authentication.
- **Apple Intelligence:** optional on-device provider. Select it in Settings, run **Test Apple Intelligence**, and use it only after the readiness test passes.

OpenRouter sends selected text and prompts to OpenRouter and the selected upstream model provider. Codex CLI sends selected text and prompts to OpenAI under the user's authenticated Codex account. Ollama keeps model calls local. Apple Intelligence uses Apple on-device generation when this Mac is eligible, Apple Intelligence is enabled, local models are ready, and the selected translation language pair is installed.

To try Codex CLI:

1. Install Codex CLI separately.
2. Run `codex login` in Terminal and complete the browser flow.
3. Open POC Settings and select **Codex CLI**.
4. Choose a model from the installed CLI's bundled catalog, which loads without a network refresh.
5. Choose a **Reasoning** level. **Low** is the default for faster language-assistance requests.
6. Enable **Fast mode** when the selected model advertises it. Fast uses the CLI's priority service tier and increased subscription usage.
7. Click **Refresh Models** to verify the current live catalog and account availability.
8. Click **Test Codex CLI** before using Explain, Composer, or Review.

The POC does not read or store Codex credentials, configuration, or model-cache files. Reasoning choices and Fast availability come from the installed CLI catalog rather than model-name checks. Codex CLI is a coding agent and carries substantially more prompt overhead than a direct model API, so this provider remains a discovery experiment rather than the recommended default.

Apple Intelligence readiness checks both Foundation Models generation and Apple Translation with the current Mine/Theirs languages. If Apple Intelligence later becomes unavailable while selected, the POC shows the Apple-specific failure reason and does not silently fall back to Ollama or OpenRouter.

If the readiness test says a language pair is supported but not installed, install both languages in macOS:

1. Open **System Settings**.
2. Go to **General > Language & Region**.
3. Click **Translation Languages**.
4. Click **Download** for both the source language and target language, for example English and German.
5. Turn on **On-Device Mode** if you want macOS to process translations locally.
6. Return to the POC and run **Test Apple Intelligence** again.

## Development Watch

For a lightweight restart-on-change loop, run:

```bash
bash scripts/dev-watch.sh
```

The watcher polls `Package.swift` and `Sources/**/*.swift`, stops the running prototype, and starts `swift run` again when files change.

## Reset Settings

To simulate a first launch, quit the POC and run:

```bash
bash scripts/reset-settings.sh
```

This clears the POC's known `UserDefaults` keys and removes the OpenRouter API key from macOS Keychain.
It also resets first-launch onboarding, menu-bar visibility, and the recorded shortcut back to the default.

### Product Review Questions

- Does clipboard fallback feel acceptable for discovery?
- Does the floating panel feel like the right surface?
- Is translation-first helpful before phrase details?
- Are phrase chips a good way to ask for deeper explanation?
- Should composer live beside explanation, or as a separate mode?

## Non-Goals

- production architecture
- final visual design
- durable database migrations
- App Store packaging
- iOS sharing

## Required Handoff

After prototype work, update:

- `docs/DISCOVERY.md`
- `tasks/PROGRESS.md`
- `tasks/CURRENT.md`

Record what worked, what failed, what surprised you, and what the real MVP should do differently.

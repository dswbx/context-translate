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

## Run

Requirements:

- macOS
- Xcode Command Line Tools or Xcode with Swift installed
- optional: Ollama running locally at `localhost:11434`
- optional: OpenRouter API key

From this directory:

```bash
swift run
```

Expected behavior:

- The app appears in the macOS menu bar.
- Choosing `Open Assistant` opens a floating assistant panel.
- Pressing `Command+Option+E` opens a floating bubble near the current selection when possible.
- The app tries Accessibility selection first, then temporary copy-restore, then clipboard fallback.
- Settings are available from the app menu, the status menu, and `Command+,`.

## AI Providers

The POC supports:

- **Ollama:** default, local provider. Install/run a model in Ollama, then refresh models in Settings.
- **OpenRouter:** optional cloud provider. Add an API key in Settings. The key is stored in macOS Keychain.

OpenRouter sends selected text and prompts to OpenRouter and the selected upstream model provider. Ollama keeps model calls local.

## Development Watch

For a lightweight restart-on-change loop, run:

```bash
bash scripts/dev-watch.sh
```

The watcher polls `Package.swift` and `Sources/**/*.swift`, stops the running prototype, and starts `swift run` again when files change.

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

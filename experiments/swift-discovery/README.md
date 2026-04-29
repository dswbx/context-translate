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

## Prototype Brief

Build a small Swift Package executable that launches a native macOS accessory app.

### Must-Have Behaviors

- Show a menu bar item named `Context`.
- Provide a menu action for opening the assistant.
- Register a best-effort global shortcut: `Command+Option+E`.
- Read text from the clipboard as the selected-text fallback.
- Open a fast floating panel with the captured text.
- Show a translation-first explanation screen with selectable phrase chips.
- Show phrase details with meaning, contextual meaning, tone, examples, and a save action.
- Include a composer screen with casual, neutral, and professional stub outputs.
- Include a lightweight history/review screen backed by in-memory sample data.

### Stubbed Data

- German is the default native language for the prototype.
- AI responses are deterministic local stubs.
- Phrase examples should use workplace English.
- History and learning bucket data can reset when the app quits.

### Run Expectation

Run from this directory:

```bash
swift run
```

Expected behavior:

- The app appears in the macOS menu bar.
- Choosing `Open Assistant` opens a floating assistant panel.
- Copying English text to the clipboard before opening the assistant populates the explanation flow.
- Pressing `Command+Option+E` opens the same panel when the hotkey registration works.

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

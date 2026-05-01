# Contextual Language Assistant

A native macOS language assistant for non-native English speakers. The app helps users understand selected English text in context, inspect confusing phrases, compose natural English from their own language, review English they wrote, and learn saved phrases over time.

https://github.com/user-attachments/assets/71912beb-aaac-4c8c-aee8-d8e5a23e5bbf

## Current Phase

This repository is in the proof-of-concept phase.

Before building the durable MVP, we are iterating on a Swift/SwiftUI proof of concept under `poc/` to learn from real macOS behavior:

- menu-bar app lifecycle
- global shortcut or trigger flow
- selected text capture and clipboard fallback
- floating window behavior
- translation-first explanation flow
- phrase detail expansion
- phrase composer
- basic local persistence feel

The POC is a learning artifact. It is not the production app foundation by default, but it is runnable for product feedback.

## Run The POC

Requirements:

- macOS
- Xcode Command Line Tools or Xcode with Swift installed
- optional: Ollama running locally for local AI responses
- optional: OpenRouter API key for cloud model responses

Run:

```bash
cd poc
swift run
```

The app appears in the macOS menu bar as `Context`. Use `Open Assistant` from the menu bar, or press `Command+Option+E` to open the floating bubble from the current selection.

For restart-on-change while editing:

```bash
cd poc
bash scripts/dev-watch.sh
```

To create an interim local `.app` bundle:

```bash
cd poc
bash scripts/package-app.sh
open "dist/Context Translate POC.app"
```

## Setup The POC App

If you downloaded or copied the `.app`, macOS may block it because this POC is ad-hoc signed and not notarized yet. Clear quarantine attributes before opening it:

```bash
xattr -cr "Context Translate POC.app"
```

If you are inside the app bundle while troubleshooting, running this from the bundle contents also clears the parent app bundle:

```bash
xattr -cr ..
```

The app needs Accessibility permission for selected-text capture and selection-position popovers. Open **System Settings -> Privacy & Security -> Accessibility** and enable `Context Translate POC`. If it does not appear automatically, add the app manually from that settings screen.

On first launch, open Settings and choose an AI provider:

- **Ollama:** start Ollama locally, refresh models, then select a model.
- **OpenRouter:** add an API key, enter a model ID, then test the connection.

## Troubleshooting

- **App does not start:** clear quarantine with `xattr -cr "Context Translate POC.app"` and try again.
- **Shortcut opens but text capture is poor:** grant Accessibility permission. You may need to manually locate and add the app in System Settings.
- **No translation or explanations appear:** configure an AI provider and model in Settings.

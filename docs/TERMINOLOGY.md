# Terminology

Shared product language for the Contextual Language Assistant. Use these terms in product docs, tasks, UI copy, and implementation notes unless a later decision changes them.

## Core Concepts

### Contextual Language Assistant

The product as a whole: a native macOS assistant for understanding and producing natural English in context.

Avoid calling the product a dictionary or translator. It may translate text, but its purpose is contextual language understanding.

### Assistant

The user-facing helper surface. In the prototype this is the floating window opened from the menu bar or shortcut.

### Source App

The app where the user encountered text, such as a browser, Slack, email, document editor, or AI tool.

### Original Text

The English text the user wants help with. This can be a sentence, paragraph, or short phrase captured from another app or pasted through the clipboard fallback.

### Native Language

The user's preferred language for explanations and translation. German is the discovery prototype default, not a product limitation.

### Translation

A direct rendering of the original text into the user's native language.

For the MVP flow, translation appears before word or phrase details. Translation should not include extra explanation unless the prompt or UI explicitly asks for it.

### Word

A single selectable token in the original text.

In the prototype, words are clickable inline. In the real product, word selection may become richer, but the user should still feel that the original text itself is interactive.

### Phrase

One or more words that carry meaning together. Examples include idioms, collocations, workplace expressions, or short sayings.

### Selected Term

The word or phrase the user chooses for deeper explanation.

Use this term when the behavior can apply to either a single word or a multi-word phrase.

### Explanation

The detailed answer for a selected term. It should include meaning, meaning in this exact context, tone or formality, and example usage.

### Meaning

What a selected term means in isolation.

### Contextual Meaning

What the selected term means in the original text.

### Tone

How the selected term feels to a native or fluent speaker. Examples: casual, neutral, professional, formal, informal, slang, sarcastic, technical, corporate, or direct.

### Example

A natural English sentence showing how the user could use the selected term themselves.

### Text Pane

The left pane in the explain view. It contains the original text and its translation.

Avoid calling this the source pane because source app already means the external app where the text came from.

### Explanation Pane

The right pane in the explain view. It shows details for the selected term, including meaning, contextual meaning, tone, and examples.

## Product Areas

### Explain Flow

The workflow where a user captures original text, sees a translation, then selects terms for deeper explanation.

### Phrase Composer

The workflow where a user writes a thought in their native language and receives natural English versions.

### Composer Variant

One tone-specific version from the phrase composer. Initial variants are casual, neutral, and professional.

### Learning Bucket

The saved collection of selected terms the user wants to remember and review later.

Avoid calling this "flashcards" unless the product explicitly becomes card-based.

### Learn Mode

The workflow where the user revisits items from the learning bucket.

This was called review mode in earlier discovery notes. Use learn mode going forward so review can mean writing feedback.

### Review Mode

The workflow where a user enters an English sentence they wrote and optionally explains, in their native language, what they tried to express.

Review mode rates the sentence, suggests a better version when useful, and explains concrete improvements in structured sections.

### History

The record of previous explain-flow lookups and phrase composer outputs.

History is broader than the learning bucket. Not every history item is something the user wants to learn.

### Settings

The place where the user controls native language, AI provider, local storage behavior, privacy choices, and model selection.

In the discovery prototype, model and language settings live in the mode bar rather than a separate Settings pane.

## AI And Privacy

### AI Provider

The system used to generate translations, explanations, and composed English. Examples include Ollama for local models or a cloud LLM provider later.

### Local Model

An AI model running on the user's machine. In discovery, this means an Ollama model.

### Ollama

The first discovery-phase local AI provider. The prototype checks `http://localhost:11434/api/tags` for local models and uses `POST /api/generate` for responses.

### Stub Response

A deterministic fake response used when no real AI provider is configured or reachable.

Stub responses are acceptable in discovery but should be clearly marked as such.

### Clipboard Fallback

The discovery-phase fallback where the app reads the macOS clipboard instead of directly capturing selected text from the source app.

### Raw Text

The original text exactly as captured or pasted. Raw text can be privacy-sensitive.

### Capture Method

How the assistant obtained the original text. Discovery methods are Accessibility selection, temporary copy-restore, clipboard fallback, and sample text.

The prototype should signal the active capture method so the user knows whether text came from a direct selection path or a fallback.

## Development Terms

### Proof Of Concept

The disposable Swift/SwiftUI prototype under `experiments/poc/`.

Its job is to reveal product, UX, and macOS constraints before the real MVP plan. It is not the production app foundation by default.

### Production MVP

The durable app built after discovery findings are extracted and a proper implementation plan exists.

### Finding

A documented discovery observation in `docs/DISCOVERY.md` with product or technical implications.

### Decision

A durable product or technical choice recorded in `docs/DECISIONS.md`.

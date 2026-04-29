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

### 2026-04-29 - SwiftPM Can Launch A Native Menu Bar Prototype

**Area:** macOS app shape
**Observed:** A Swift Package executable can build and launch an AppKit/SwiftUI accessory app with a menu bar item, floating panel, clipboard fallback, and stubbed explanation/composer/review flows.
**Why it matters:** The discovery prototype does not require a full Xcode project yet. This keeps iteration lightweight while still testing real macOS window and menu behavior.
**Recommendation:** Continue discovery in `experiments/swift-discovery/` with SwiftPM until signing, previews, asset catalogs, or Xcode-specific project behavior becomes necessary.
**Carry forward:** Yes.

### 2026-04-29 - SwiftPM Needs Normal User Cache Access

**Area:** build tooling
**Observed:** The first sandboxed build could not write SwiftPM and Clang module caches. Running `swift build` with normal user cache access succeeded.
**Why it matters:** Future agents should expect SwiftPM builds to use user cache directories outside the repository.
**Recommendation:** Use normal local execution for SwiftPM build/run commands. If full Xcode is needed later, ask the product owner before switching.
**Carry forward:** Yes.

### 2026-04-29 - Word-Level Selection Feels Closer To The Product Intent

**Area:** UI
**Observed:** The prototype originally used fixed phrase chips and preselected the first phrase. Product feedback requested clickable individual words and no preselection.
**Why it matters:** Users should decide what confused them after seeing the translation. Preselection makes the app feel like it is guessing too early.
**Recommendation:** The real MVP should render the original text as selectable words or phrases, start with an empty detail state, and explain only after the user chooses text.
**Carry forward:** Yes.

### 2026-04-29 - Floating Window Should Not Auto-Disappear

**Area:** UI
**Observed:** Product feedback requested that the floating assistant stay visible until the user closes it with the window close control or Esc.
**Why it matters:** Users may compare the assistant with the source app, copy text, or pause mid-reading. Auto-hiding would make the flow feel fragile.
**Recommendation:** The real MVP should keep the assistant visible across app focus changes and provide explicit close behavior.
**Carry forward:** Yes.

### 2026-04-29 - Inline Original Text Is Better Than A Separate Word Grid

**Area:** UI
**Observed:** Product feedback clarified that words should be clickable in the original text itself, not repeated in a separate selection area. The first implementation used an adaptive grid, which broke word layout by forcing words into narrow columns.
**Why it matters:** Keeping interaction inside the original sentence preserves reading flow and makes the product feel less like a form.
**Recommendation:** The real MVP should make the original text itself interactive, with word and phrase selection in-place. Clickable words must keep intrinsic width and wrap only between words, like CSS `inline-flex`.
**Carry forward:** Yes.

### 2026-04-29 - SwiftPM Needs A Small Watch Wrapper

**Area:** build tooling
**Observed:** SwiftPM has `swift run` and `swift build`, but no built-in watch mode.
**Why it matters:** Manual restarts slow discovery iteration.
**Recommendation:** Use a lightweight local watcher script during discovery. Revisit full Xcode or a richer dev runner only if the prototype grows beyond SwiftPM ergonomics.
**Carry forward:** Yes.

### 2026-04-29 - Word Hover And Selection Need Reserved Space

**Area:** UI
**Observed:** Product feedback requested subtle hover styling and blue selected styling without moving the sentence layout.
**Why it matters:** If hover or selection changes word size, the original sentence shifts while the user is reading it.
**Recommendation:** Reserve padding and background bounds in every word state. Use transparent background normally, a subtle accent tint on hover, and accent blue with white text for selected words.
**Carry forward:** Yes.

### 2026-04-29 - Ollama Is A Good First Real AI Provider

**Area:** AI
**Observed:** Product direction favors starting with Ollama for privacy. The prototype can check `http://localhost:11434/api/tags`, list local models, persist the selected model, and call `POST /api/generate` with `stream: false`.
**Why it matters:** Local AI lets us test real explanation latency and quality without sending user text to a cloud provider during discovery.
**Recommendation:** Keep Ollama as the first provider path. If Ollama is unavailable, show a clear local status message instead of failing silently.
**Carry forward:** Yes.

## Extraction Checklist

Before writing the real MVP implementation plan, summarize:

- product decisions changed by the prototype
- macOS APIs and permissions that matter
- UX flows that should be kept
- UX flows that should be changed
- code ideas worth reusing
- code ideas to discard
- risks that need planned mitigation

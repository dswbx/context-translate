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

## Extraction Checklist

Before writing the real MVP implementation plan, summarize:

- product decisions changed by the prototype
- macOS APIs and permissions that matter
- UX flows that should be kept
- UX flows that should be changed
- code ideas worth reusing
- code ideas to discard
- risks that need planned mitigation

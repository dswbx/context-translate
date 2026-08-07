# Discovery

## Purpose

Use a disposable Swift/SwiftUI prototype to learn from real macOS behavior before planning the production MVP.

The prototype should answer practical questions that static plans and mockups cannot answer well.

## Prototype Location

`poc/`

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

### Learning And Learn Mode

- What is the lightest useful learning bucket?
- What learn interaction feels good enough for MVP?
- Which metadata matters?

### Writing Review

- How much native-language intent does the model need to judge whether a user-written English sentence expresses the right idea?
- Which structured feedback sections are clearest for the user?

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
**Recommendation:** Continue discovery in `poc/` with SwiftPM until signing, previews, asset catalogs, or Xcode-specific project behavior becomes necessary.
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

### 2026-04-29 - Translation And Word Details Need Separate Prompts

**Area:** AI
**Observed:** Product feedback clarified that German translation and word details should both come from the selected model, not local placeholder data.
**Why it matters:** Translation wants a narrow prompt with no extra output, while word details need structured fields for meaning, context, tone, and example. Treating them as separate prompt cases keeps the UI predictable.
**Recommendation:** Use dedicated prompts per response type. For translation: ask for only the German sentence. For word details: ask for structured JSON and map those fields directly into the details pane.
**Carry forward:** Yes.

### 2026-04-29 - In-Flight AI Needs Manual Control

**Area:** AI
**Observed:** Regenerate and Stop controls are needed once local generation can be slow.
**Why it matters:** Users need control when a model is too slow, stuck, or answering with the wrong model.
**Recommendation:** Keep generation tasks cancellable and expose explicit Regenerate and Stop actions near the generated content.
**Carry forward:** Yes.

### 2026-04-29 - Capture Method Should Be Visible

**Area:** text capture
**Observed:** macOS text capture needs multiple strategies. Accessibility selection is the cleanest path when available, temporary copy-restore works across more apps, and clipboard remains the fallback.
**Why it matters:** Users may otherwise be confused about why the assistant used stale clipboard text or why a selection failed.
**Recommendation:** Keep signaling the capture method in the assistant header during discovery and preserve this as a production UX requirement.
**Carry forward:** Yes.

### 2026-04-29 - Hotkey Bubble Needs Position Fallbacks

**Area:** windowing
**Observed:** The menu-bar path wants a normal persistent window, while the global shortcut wants a compact floating bubble near the current selection. Accessibility can sometimes provide selected-text bounds, but not every app exposes them.
**Why it matters:** A bubble that appears near the user's selection feels contextual. A bubble that cannot find selection bounds still needs a predictable fallback.
**Recommendation:** Keep separate normal and bubble panel modes. Position the bubble from Accessibility selection bounds when available, otherwise near the current mouse location. Treat the shortcut bubble as transient: remove visible title chrome and close it when focus moves outside the bubble.
**Carry forward:** Yes.

### 2026-04-29 - Hidden Titlebars Still Affect Bubble Layout

**Area:** windowing
**Observed:** Hiding the shortcut bubble titlebar removed the visible chrome, but SwiftUI still respected the titlebar safe area, leaving a large empty band above the mode switcher.
**Why it matters:** The bubble should feel compact and contextual. Hidden chrome that still reserves layout space makes it look broken and wastes the limited floating-window area.
**Recommendation:** When a panel hides its titlebar, explicitly let the SwiftUI root ignore the top container safe area. Persist the bubble size separately from the normal window so users can tune the floating surface without losing contextual placement.
**Carry forward:** Yes.

### 2026-04-29 - Bubble Should Feel Like A Native Floating Surface

**Area:** windowing
**Observed:** The shortcut bubble benefits from a subtle translucent material because it appears on top of arbitrary user content. The Explain view also needs an adjustable divider because the useful balance between original text and detail changes by task.
**Why it matters:** A floating assistant needs to feel lightweight without sacrificing legibility. Users also need control over whether they are reading more context or more explanation.
**Recommendation:** Use native vibrancy/translucency only for the bubble window, keep the normal window opaque, and use a native split view for adjustable text and detail panes.
**Carry forward:** Yes.

### 2026-04-29 - Floating Does Not Mean All Spaces

**Area:** windowing
**Observed:** Keeping the assistant above other windows is useful, but `canJoinAllSpaces` makes it follow the user across Desktop Spaces.
**Why it matters:** The normal menu-bar window should feel persistent within the current work context, not globally attached to every Desktop.
**Recommendation:** Keep the panel floating, but remove `canJoinAllSpaces`. Use `moveToActiveSpace` so opening the assistant from the menu bar or shortcut presents it on the active Space without making it visible everywhere.
**Carry forward:** Yes.

### 2026-04-30 - Settings Belong In Their Own Screen

**Area:** navigation
**Observed:** Keeping language and model controls in the mode bar makes the primary workflow header resize poorly and mixes configuration with task navigation.
**Why it matters:** The user should be able to steer language/model choices deliberately without those controls competing with Explain, Composer, and Review.
**Recommendation:** Keep the header focused on modes. Restore Settings as a dedicated screen, expose it from the menu-bar dropdown and standard `Cmd+,` app shortcut, and route shortcut capture to Explain so the contextual path stays quick.
**Carry forward:** Yes.

### 2026-04-30 - Providers Need A Shared Boundary

**Area:** model providers
**Observed:** Ollama-specific state and request code had spread across translation, detail, composer, review, and Settings. Adding OpenRouter is much easier when prompts stay shared and only the transport/provider configuration differs.
**Why it matters:** The real app will likely support multiple providers. Without a shared provider boundary, every new provider would duplicate readiness checks, error messages, and UI logic.
**Recommendation:** Keep Ollama as the default privacy-first provider, add OpenRouter as an optional cloud provider, store cloud API keys in Keychain, and preserve the provider abstraction so OpenAI API can be added later.
**Carry forward:** Yes.

### 2026-04-30 - Keychain Prompts Need Stable App Identity

**Area:** credentials
**Observed:** A SwiftPM debug executable launched with `swift run` can repeatedly trigger Keychain permission prompts even after choosing "Always Allow", especially after rebuilds.
**Why it matters:** Keychain trust is tied to app/code identity. The real app needs a stable signed bundle identity, while the discovery prototype should avoid unnecessary Keychain reads.
**Recommendation:** Do not read Keychain on startup just to populate UI. Cache credentials in memory after first successful read/save during a run. For the real app, use a signed `.app` bundle with a stable bundle identifier.
**Carry forward:** Yes.

### 2026-05-01 - Interim App Bundle Makes POC Easier To Share

**Area:** build tooling
**Observed:** The POC can be wrapped from SwiftPM output into a minimal local `.app` bundle with a stable bundle identifier and ad-hoc signature.
**Why it matters:** People can try the POC without running `swift run`, and the bundle shape is closer to how macOS treats a real app.
**Recommendation:** Use `poc/scripts/package-app.sh` for lightweight sharing during discovery. Treat it as an interim local bundle, not a notarized distribution path.
**Carry forward:** Yes.

### 2026-05-01 - Setup Belongs In Settings First

**Area:** onboarding
**Observed:** First launch needs to expose missing Accessibility permission, missing model setup, menu-bar visibility, and the global shortcut before the user tries the capture flow.
**Why it matters:** The assistant depends on macOS permissions and model/provider configuration. If those are invisible, the first run feels broken rather than merely unconfigured.
**Recommendation:** Open Settings on first launch, show yellow setup warnings for missing Accessibility and model configuration, and keep trigger preferences visible there.
**Carry forward:** Yes.

### 2026-05-01 - POC Releases Can Use Simple Incrementing Versions

**Area:** build tooling
**Observed:** The POC does not need semantic versioning yet. A plain `poc-N` version file is enough to identify downloadable builds.
**Why it matters:** Testers need a clear artifact version, but production release discipline would be premature during discovery.
**Recommendation:** Use `poc/VERSION` as the source of truth, stamp it into the interim app bundle, and let the manual GitHub release workflow increment it before publishing.
**Carry forward:** Yes.

### 2026-05-07 - Selected Terms Need Context Translations Before Meaning

**Area:** UI
**Observed:** Product feedback requested target-language renderings at the top of the selected-term detail pane, before the existing meaning and contextual meaning fields. A single dictionary-like word is not enough; the rendering must fit the exact sentence and can include 1-3 alternatives when that makes the term easier to understand.
**Why it matters:** A selected word or phrase often needs an immediate native-language anchor before deeper explanation, but literal one-word glosses can mislead users about idioms, tone, or context.
**Recommendation:** Ask the provider for 1-3 context-driven selected-term translations in the same structured detail response and show them before Meaning in the Explanation pane.
**Carry forward:** Yes.

### 2026-05-07 - Close Shortcut Should Close Windows, Not Quit

**Area:** windowing
**Observed:** Product feedback requested `Command+W` as an explicit close-window shortcut for the assistant surface.
**Why it matters:** A menu-bar assistant should behave like a normal macOS window: closing hides the current surface while the app stays available from the menu bar and global trigger.
**Recommendation:** Keep `Command+Q` as quit and use `Command+W` only to close the active assistant window or currently visible assistant surface.
**Carry forward:** Yes.

### 2026-05-07 - Apple Intelligence Needs A Readiness Gate

**Area:** AI
**Observed:** Apple Intelligence can be exposed as a third POC provider beside Ollama and OpenRouter, but it has runtime prerequisites that are different from both: eligible Mac, enabled Apple Intelligence, ready local Foundation Models assets, supported languages, and installed Apple Translation language pairs. The installed SDK exposes Foundation Models and Translation, but does not expose the documented `TranslationSession.Strategy.highFidelity` API.
**Why it matters:** Apple Intelligence is attractive as a privacy-first provider, but it cannot be treated like a saved API key or a manually selected Ollama model. The app must prove readiness before routing user text through it, and it must explain setup failures clearly.
**Recommendation:** Keep Apple Intelligence as an optional discovery provider. Gate it behind a Settings test that performs a small Foundation Models JSON generation and a small Apple Translation request for the selected language pair. If Apple later fails at request time, show the Apple-specific reason and do not silently fall back to another provider. When the language pair is supported but not installed, point the user to System Settings > General > Language & Region > Translation Languages.
**Carry forward:** Yes.

### 2026-05-07 - Apple Foundation Models Need Explicit Language Boundaries

**Area:** AI
**Observed:** Apple Intelligence could return selected-term context translations that mixed English and German when the prompt only implied that `contextTranslations` should be in the user's native language.
**Why it matters:** The Explain detail pane needs a dependable target-language anchor before meaning details. Mixed-language selected-term translations make the app feel unreliable for the core use case.
**Recommendation:** Provider prompts should state field-level language rules explicitly: context translations in the user's native language only; meaning, contextual meaning, tone, and examples in the source language only; no mixed-language fields.
**Carry forward:** Yes.

### 2026-08-07 - Codex CLI Can Bridge User Authentication But Has Agent Overhead

**Area:** model providers
**Observed:** The POC can locate a GUI-invisible Codex executable through conventional macOS paths, confirm the user's existing ChatGPT-backed login with `codex login status`, discover the installed CLI's visible model catalog through `codex debug models`, and execute cancellable read-only prompts without reading credential or model-cache files. On this Mac the live catalog returned five visible models. A minimal live generation succeeded, but the CLI loaded substantial agent context and reported roughly 8,950 tokens for an exact `OK` response. Trying `--ignore-user-config` did not remove all plugin and skill loading in the installed CLI build and reported even higher token use.
**Why it matters:** Subscription-backed CLI access is technically viable and removes API-key setup, but Codex is a full coding agent rather than a lightweight inference transport. Startup latency, large hidden context, CLI version drift, and the experimental model-catalog command can make it expensive and fragile for frequent translation calls.
**Recommendation:** Keep Codex CLI as an explicitly experimental POC provider beside Ollama and OpenRouter. Discover models dynamically, preserve CLI Default when discovery fails, isolate each call in an ephemeral temporary directory with a read-only sandbox, and do not make Codex the production default without latency and usage evaluation plus confirmation that third-party subscription-backed use is supported.
**Carry forward:** Yes, as a provider experiment and risk input rather than a production commitment.

## Extraction Checklist

Before writing the real MVP implementation plan, summarize:

- product decisions changed by the prototype
- macOS APIs and permissions that matter
- UX flows that should be kept
- UX flows that should be changed
- code ideas worth reusing
- code ideas to discard
- risks that need planned mitigation

# Progress

Chronological log of meaningful work. Agents must update this before ending a session.

## 2026-04-29 - Repository Initialized

**Task:** setup
**Summary:** Initialized git and committed the original idea plus repository setup design.
**Files changed:** `docs/IDEA.md`, `docs/superpowers/specs/2026-04-29-repository-setup-design.md`
**Checks run:** `git status --short`, spec consistency scan
**Decisions made:** Use a discovery-first workflow with a disposable Swift prototype before the real MVP plan.
**Next step:** Complete TASK-001 by creating the repository operating scaffold.

## 2026-04-29 - Repository Scaffold Completed

**Task:** TASK-001
**Summary:** Created the discovery-first repository operating scaffold for product-led, LLM-coded iteration.
**Files changed:** `.gitignore`, `README.md`, `AGENTS.md`, `docs/PRODUCT.md`, `docs/MVP.md`, `docs/DISCOVERY.md`, `docs/ROADMAP.md`, `docs/DECISIONS.md`, `docs/QUESTIONS.md`, `docs/mockups/README.md`, `experiments/README.md`, `experiments/swift-discovery/README.md`, `tasks/README.md`, `tasks/TASKS.md`, `tasks/PROGRESS.md`, `tasks/CURRENT.md`, `tasks/templates/task.md`
**Checks run:** Required file existence checks; unfinished-marker scan.
**Decisions made:** TASK-002 is now active and will brief the disposable Swift discovery prototype.
**Next step:** Execute TASK-002.

## 2026-04-29 - Swift Discovery Prototype Started

**Task:** TASK-002, TASK-003
**Summary:** Added the discovery prototype brief and created a runnable SwiftPM macOS accessory app prototype with menu bar entry, floating panel, clipboard fallback, phrase explanation, composer, and review screens.
**Files changed:** `experiments/swift-discovery/README.md`, `experiments/swift-discovery/Package.swift`, `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/TASKS.md`, `tasks/CURRENT.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`, `swift run`
**Decisions made:** Continue discovery with SwiftPM for now; full Xcode is not required until the prototype needs Xcode-specific app project behavior.
**Next step:** Product owner tests the running prototype and reports what feels useful, awkward, or missing.

## 2026-04-29 - Prototype Interaction Feedback Applied

**Task:** TASK-003
**Summary:** Updated the prototype so the assistant window stays visible until explicitly closed and the explanation flow starts empty with individual clickable words from the captured text.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** The discovery flow should not preselect an explanation. The floating window should stay visible across focus changes and close through the window control or Esc.
**Next step:** Relaunch the prototype and product-test word clicking, Esc close, and window persistence.

## 2026-04-29 - Inline Word Selection And Dev Watch Added

**Task:** TASK-003
**Summary:** Replaced the separate word-button grid with clickable words inside the original text area and added a lightweight SwiftPM restart-on-change watcher.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `experiments/swift-discovery/scripts/dev-watch.sh`, `experiments/swift-discovery/README.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Word selection belongs in the original text surface. SwiftPM needs a helper script for watch-like iteration.
**Next step:** Test `bash scripts/dev-watch.sh` during prototype iteration if manual restarts become annoying.

## 2026-04-29 - Fixed Inline Word Wrapping

**Task:** TASK-003
**Summary:** Replaced the adaptive grid word layout with a custom intrinsic wrapping layout so clickable words keep sentence-like flow and wrap between words.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** The original text interaction needs inline-block style behavior, not equal-width adaptive grid cells.
**Next step:** Relaunch the prototype and verify the original sentence reads naturally while individual words remain clickable.

## 2026-04-29 - Added Word States And Ollama Settings

**Task:** TASK-003
**Summary:** Polished the empty explanation pane, added stable hover and selected styles for clickable words, and added an Ollama settings tab with model discovery, persisted model selection, and non-streaming local generation.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use Ollama first for private local AI discovery. Use macOS accent color for selected word styling and reserve word padding in every state to avoid layout shifts.
**Next step:** Run the prototype with and without Ollama running to compare local AI behavior and fallback status messaging.

## 2026-04-29 - Split Ollama Translation And Detail Prompts

**Task:** TASK-003
**Summary:** Reworked the AI flow so German translation and selected-word details are generated by separate Ollama prompts, added Regenerate and Stop controls, and mapped model detail JSON into the detail pane fields.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep model selection in Settings for now. Generate translation and details through separate, cancellable local model requests.
**Next step:** Test with Ollama running and at least one local model available.

## 2026-04-29 - Added Product Terminology

**Task:** TASK-003
**Summary:** Added a shared terminology document for core product, AI, privacy, UI pane, and development language.
**Files changed:** `docs/TERMINOLOGY.md`, `README.md`, `AGENTS.md`, `tasks/PROGRESS.md`
**Checks run:** Documentation-only change.
**Decisions made:** Use "original text", "selected term", "explanation", "text pane", "explanation pane", "learning bucket", "discovery prototype", and related terms consistently.
**Next step:** Use the terminology doc when naming UI elements, tasks, and future implementation types.

## 2026-04-29 - Refined Explain Pane AI Controls

**Task:** TASK-003
**Summary:** Removed stub translation output, moved translation refresh/stop controls into the translation heading, and added explanation-pane refresh/stop controls with stable loading placeholders for known fields.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Translation and explanation controls act independently. Detail generation remains one Ollama request that returns all fields together, while the UI keeps the selected word and field headings visible during loading.
**Next step:** Run the prototype with Ollama available and verify refresh/stop behavior in both panes.

## 2026-04-29 - Connected Composer To Ollama

**Task:** TASK-003
**Summary:** Hid the review tab and learning-bucket save button, removed Composer starter content, shortened the Composer text area, and connected Composer output generation to Ollama.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep review and learning-bucket code hidden rather than deleted. Generate casual, neutral, and professional Composer variants with one Ollama JSON request.
**Next step:** Test Composer with a local Ollama model and capture any prompt or parsing findings.

## 2026-04-29 - Improved Composer Copy And Submit

**Task:** TASK-003
**Summary:** Added a minimal native Edit menu so Command+C reaches selectable text, changed Composer input from multiline text area to single-line Enter-submit input, and added quick-copy buttons to Composer results.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use the native AppKit Edit menu for standard text commands instead of custom copy handling on selectable text. Keep explicit copy buttons for Composer outputs because those are primary user actions.
**Next step:** Run the app and manually verify Command+C against selected translation/explanation/output text.

## 2026-04-29 - Refined Composer Input Actions

**Task:** TASK-003
**Summary:** Moved the Composer action into the single-line input row, removed the sparkle icon, placed result copy buttons directly beside result text, and added Regenerate labeling when the current input has already produced outputs.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** The Composer action remains disabled only for empty input. Once output exists for the unchanged input, the action label becomes "Regenerate" and remains available.
**Next step:** Manually check the Composer row layout with short and long generated outputs.

## 2026-04-29 - Added Writing Review Mode

**Task:** TASK-003
**Summary:** Added a visible Review tab for reviewing user-written English, renamed the hidden learning-bucket review surface to Learn, and wired Review to a structured Ollama JSON response.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/TERMINOLOGY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Reserve "Review" for writing feedback. Use "Learn" for the future saved-items practice workflow. Review mode asks for rating, suggested sentence, what works, concrete improvements, and alternatives in one model call.
**Next step:** Test Review with and without the optional native-language explanation to see whether the prompt produces useful structured feedback.

## 2026-04-29 - Added Capture Method Signaling

**Task:** TASK-003
**Summary:** Replaced direct clipboard-only capture with a hybrid capture flow and showed the capture method in the assistant header.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/TERMINOLOGY.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Try Accessibility selected text first, temporary copy-restore second, clipboard fallback third, and sample text only when no text is available.
**Next step:** Manually test capture from several apps and note which ones support Accessibility selection versus copy-restore.

## 2026-04-29 - Moved Capture Controls Into Text Pane

**Task:** TASK-003
**Summary:** Removed the top app header, moved Recapture into the Original text heading, and moved the capture method signal into the text pane footer beside translation status.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep capture controls and capture metadata local to the text pane because they describe the current original text, not the whole app.
**Next step:** Manually inspect the reduced header layout in the running prototype.

## 2026-04-29 - Moved Settings Into Mode Bar

**Task:** TASK-003
**Summary:** Made the assistant window resizable with persisted size constraints, moved model selection into a nested Ollama menu in the mode bar, and added persisted Mine/Theirs language pickers.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/TERMINOLOGY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep Settings hidden as a mode for now and expose active discovery settings in the mode bar. Use Mine as the user's language and Theirs as the target/source English-language side of the workflow.
**Next step:** Manually resize the window and verify frame persistence after closing and reopening the app.

## 2026-04-29 - Removed Visible Mode Label

**Task:** TASK-003
**Summary:** Removed the visible "Mode" label from the segmented mode picker while keeping an accessibility label.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep the header bar compact so it responds better to window resizing.
**Next step:** Manually inspect the mode bar at narrow window sizes.

## 2026-04-29 - Added Normal And Bubble Window Modes

**Task:** TASK-003
**Summary:** Split the assistant into a persistent normal menu-bar window and a compact hotkey bubble window that keeps all tabs but hides language/model controls.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Menu bar opens normal mode. Cmd+Option+E opens bubble mode. Bubble placement uses Accessibility selection bounds when available and mouse location as fallback.
**Next step:** Manually test bubble placement in apps that do and do not expose selected-text bounds.

## 2026-04-29 - Made Shortcut Bubble Transient

**Task:** TASK-003
**Summary:** Removed visible title-bar chrome from the shortcut bubble and made it close when the app loses focus or the user clicks outside the bubble.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep the normal menu-bar window persistent and titled. Apply transient behavior only to the shortcut bubble.
**Next step:** Manually verify that clicking inside the bubble keeps it open, clicking outside closes it, and the menu-bar window remains persistent.

## 2026-04-29 - Tightened Bubble Chrome And Persisted Size

**Task:** TASK-003
**Summary:** Removed the hidden-titlebar top safe-area gap from the shortcut bubble, increased its default size, expanded resize limits, and persisted the user's bubble size.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Recalculate bubble position on each shortcut open, but preserve the user's chosen bubble width and height.
**Next step:** Manually resize the bubble, close it by clicking outside, reopen with Cmd+Option+E, and confirm the size is retained near the new selection.

## 2026-04-29 - Added Bubble Translucency And Split Panes

**Task:** TASK-003
**Summary:** Made the shortcut bubble use a subtle translucent native material and changed the Explain view's text/detail layout to a draggable split view.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep translucency scoped to the shortcut bubble. Keep the normal assistant window opaque. Let users resize the text and detail panes with the native split divider.
**Next step:** Manually verify bubble legibility over light and dark backgrounds, then test dragging the Explain divider at compact and expanded bubble sizes.

## 2026-04-29 - Matched Explain Divider Color

**Task:** TASK-003
**Summary:** Replaced the native split-view divider with a custom draggable separator using the system separator color so it matches the header divider.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep a narrow visible divider with a wider invisible drag target, and persist the text pane width.
**Next step:** Manually verify the divider color in light and dark appearance and confirm dragging still feels easy.

## 2026-04-29 - Restored Native Split Interaction

**Task:** TASK-003
**Summary:** Replaced the custom SwiftUI drag divider with an AppKit split view bridge that keeps native resize cursor behavior and smooth pane resizing while preserving the gray divider color.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use AppKit for the split interaction because native cursor and resize behavior are part of the expected macOS feel. Keep pane width persistence in the split view delegate.
**Next step:** Manually verify the cursor changes over the divider and that live dragging no longer distorts pane content.

## 2026-04-29 - Scoped Floating Windows To Active Space

**Task:** TASK-003
**Summary:** Removed all-Spaces behavior from assistant panels while keeping them floating above other windows.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use `moveToActiveSpace` and `fullScreenAuxiliary` instead of `canJoinAllSpaces` so menu-bar and shortcut opens appear in the current Space without following the user across Spaces.
**Next step:** Manually open the assistant from one Desktop, switch to another Desktop, and confirm the window does not follow.

## 2026-04-29 - Adjusted Original Text Surface

**Task:** TASK-003
**Summary:** Changed the Explain view Original text box from the system gray control background to a 50% transparent black fill.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Apply the translucent dark surface only to the Original text box for now because it sits directly on the bubble material.
**Next step:** Manually inspect the Original text box over light and dark page backgrounds in bubble mode.

## 2026-04-29 - Unified Translucent Surface Styling

**Task:** TASK-003
**Summary:** Applied the same 10% transparent black surface to translation, composer, review, and settings boxes and inputs.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Preserve the user-adjusted `0.1` opacity and centralize the color as `PrototypeSurface.background`.
**Next step:** Manually inspect text legibility for every mode in the translucent bubble.

## 2026-04-30 - Restored Dedicated Settings Screen

**Task:** TASK-003
**Summary:** Added Settings back to the mode switcher, moved Mine/Theirs/model controls into Settings, and added Settings entry points from the menu bar and `Cmd+,`.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep the header focused on navigation only. Menu-bar Settings opens the normal window without recapturing text. The global selection shortcut still opens Explain directly.
**Next step:** Manually verify Settings opens from the status menu and with `Cmd+,`, and that language/model changes persist.

## 2026-04-30 - Added OpenRouter Provider

**Task:** TASK-003
**Summary:** Added provider selection with Ollama as the default and OpenRouter as an optional cloud provider using manual model IDs and Keychain-backed API key storage.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep prompts and parsing shared across providers. Use non-streaming OpenRouter chat completions for the first integration. Store only non-secret provider/model preferences in UserDefaults.
**Next step:** Manually test OpenRouter with a real API key and model ID, then check Ollama regression paths.

## 2026-04-30 - Simplified Provider Settings

**Task:** TASK-003
**Summary:** Moved the AI provider selector into the AI Provider section and made the provider options dynamic so only Ollama or OpenRouter settings are visible at a time.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep Languages separate, and group provider selection with the active provider's concrete configuration.
**Next step:** Manually switch providers in Settings and confirm only the relevant controls are shown.

## 2026-04-30 - Reduced Keychain Prompt Frequency

**Task:** TASK-003
**Summary:** Stopped reading the OpenRouter API key from Keychain on app startup and cached the key in memory after the first successful read or save.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Use a non-secret UserDefaults flag to show whether an OpenRouter key is expected, and only touch Keychain when saving, forgetting, testing, or making OpenRouter requests.
**Next step:** Manually verify the prompt appears only when OpenRouter actually needs the key, not every app launch.

## 2026-04-30 - Removed Duplicate Provider Picker Label

**Task:** TASK-003
**Summary:** Removed the visible "AI Provider" label from the provider segmented picker because the section title already provides that context.
**Files changed:** `experiments/swift-discovery/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep an accessibility label on the picker while avoiding duplicate visible text.
**Next step:** Manually inspect Settings for cleaner spacing around the provider picker.

## 2026-05-01 - Renamed Prototype To POC

**Task:** TASK-003
**Summary:** Renamed the runnable Swift experiment from `experiments/swift-discovery/` to `experiments/poc/` and added public run instructions.
**Files changed:** `README.md`, `experiments/README.md`, `experiments/poc/README.md`, `experiments/poc/Package.swift`, `docs/DISCOVERY.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/TERMINOLOGY.md`, `tasks/CURRENT.md`, `tasks/TASKS.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep the app as a SwiftPM POC for now, but make it easy for others to run locally.
**Next step:** Merge the POC branch into `main` so collaborators can pull and run it.

## 2026-05-01 - Added POC Settings Reset Script

**Task:** TASK-003
**Summary:** Added a script to clear known POC UserDefaults keys and remove the OpenRouter Keychain item for first-launch testing.
**Files changed:** `experiments/poc/scripts/reset-settings.sh`, `experiments/poc/README.md`, `tasks/PROGRESS.md`
**Checks run:** `bash experiments/poc/scripts/reset-settings.sh`
**Decisions made:** Delete only known POC keys across likely SwiftPM defaults domains instead of wiping entire domains.
**Next step:** Use the reset script before product demos when first-launch behavior needs to be checked.

## 2026-05-01 - Moved POC To Top Level And Added App Bundle Script

**Task:** TASK-003
**Summary:** Moved the runnable Swift proof of concept to top-level `poc/` and added an interim script that packages it as a local `.app` bundle.
**Files changed:** `.gitignore`, `README.md`, `AGENTS.md`, `experiments/README.md`, `poc/README.md`, `poc/scripts/package-app.sh`, `docs/DISCOVERY.md`, `docs/DECISIONS.md`, `docs/ROADMAP.md`, `docs/TERMINOLOGY.md`, `tasks/CURRENT.md`, `tasks/TASKS.md`, `tasks/PROGRESS.md`
**Checks run:** `swift package clean`; `swift build`; `bash scripts/package-app.sh`; `test -x "poc/dist/Context Translate POC.app/Contents/MacOS/context-translate-poc"`; `plutil -lint "poc/dist/Context Translate POC.app/Contents/Info.plist"`; `codesign --verify --deep --strict "poc/dist/Context Translate POC.app"`
**Decisions made:** Keep SwiftPM as the POC build source and use an ad-hoc signed local `.app` only as a convenience for sharing during discovery.
**Next step:** Share the top-level `poc/` run instructions and the generated interim app bundle path with testers.

## 2026-05-01 - Added Setup And Trigger Settings

**Task:** TASK-003
**Summary:** Renamed the app surfaces, opened Settings on first launch, added setup warnings, added menu-bar visibility control, and made the popover shortcut recordable.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `poc/scripts/reset-settings.sh`, `poc/README.md`, `docs/DISCOVERY.md`, `tasks/CURRENT.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`; `bash scripts/package-app.sh`
**Decisions made:** Keep setup concerns in Settings for the POC and default the global popover shortcut to `Command+Option+E`.
**Next step:** Manually verify the first-launch Settings state after running `bash poc/scripts/reset-settings.sh`.

## 2026-05-01 - Added POC Version And Release Workflow

**Task:** TASK-003
**Summary:** Added a `poc/VERSION` source of truth, stamped it into the interim app bundle, and added a manual GitHub Action that increments the version, builds the app, and attaches it to a release.
**Files changed:** `.github/workflows/release-poc.yml`, `poc/VERSION`, `poc/scripts/package-app.sh`, `poc/README.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `bash -n poc/scripts/package-app.sh`; `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/release-poc.yml"); puts "workflow yaml ok"'`; `swift build`; `bash scripts/package-app.sh`; `plutil -extract CFBundleShortVersionString raw "poc/dist/Context Translate POC.app/Contents/Info.plist"`; `plutil -extract CFBundleVersion raw "poc/dist/Context Translate POC.app/Contents/Info.plist"`; `plutil -lint "poc/dist/Context Translate POC.app/Contents/Info.plist"`; `codesign --verify --deep --strict "poc/dist/Context Translate POC.app"`; `test -x "poc/dist/Context Translate POC.app/Contents/MacOS/context-translate-poc"`
**Decisions made:** Use simple incrementing POC versions like `poc-1`, `poc-2` instead of semantic versioning during discovery.
**Next step:** Run the workflow manually when a shareable POC build should be published.

## 2026-05-07 - Added Close Shortcut And Term Translation

**Task:** TASK-003
**Summary:** Added a `Command+W` Close Window command that closes the active assistant surface without quitting the app, and added a direct selected-term translation above Meaning in the Explain detail pane.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/CURRENT.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Keep `Command+Q` as quit. Treat selected-term translation as part of the provider-backed explanation response so idioms and phrases can be translated in context.
**Next step:** Manually run the POC and verify `Command+W` from normal and bubble windows plus provider output for the new Translation field.

## 2026-05-07 - Made Term Translation Context-Driven

**Task:** TASK-003
**Summary:** Changed the selected-term detail prompt and UI from one direct translation to 1-3 context-driven translation alternatives shown before Meaning.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `docs/DECISIONS.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`
**Decisions made:** Selected-term translations should be natural renderings in the exact sentence context, with alternatives when useful, rather than dictionary-style single-word glosses.
**Next step:** Manually test selected words and idiomatic phrases with a configured provider to judge whether the alternatives are understandable.

## 2026-05-07 - Compacted Context Translation Display

**Task:** TASK-003
**Summary:** Changed selected-term context translation alternatives from stacked lines to comma-separated inline text to reduce detail-pane height.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `tasks/PROGRESS.md`
**Checks run:** `swift build`; `git diff --check`
**Decisions made:** Keep the provider response as structured alternatives, but render them inline for a denser detail pane.
**Next step:** Manually check that long alternatives wrap cleanly in the Explain detail pane.

## 2026-05-07 - Added Apple Intelligence Provider Spike

**Task:** TASK-003
**Summary:** Added Apple Intelligence as a third POC provider beside Ollama and OpenRouter, with Settings readiness testing for Foundation Models generation and Apple Translation before responses can be generated.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `poc/README.md`, `docs/TERMINOLOGY.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`, `tasks/CURRENT.md`
**Checks run:** `swift build`
**Decisions made:** Apple Intelligence remains optional and readiness-gated. If it fails at request time, the POC shows the Apple-specific failure and does not silently fall back to Ollama or OpenRouter. The installed SDK does not expose `TranslationSession.Strategy.highFidelity`, so the spike uses the available Translation API and records that as a discovery finding.
**Next step:** Run the POC, select Apple Intelligence in Settings, click Test Apple Intelligence, and manually verify Explain, selected-term detail, Composer, and Review if the readiness test passes.

## 2026-05-07 - Clarified Apple Translation Language Installation

**Task:** TASK-003
**Summary:** Added explicit instructions for installing supported-but-missing Apple Translation languages in macOS System Settings.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `poc/README.md`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`; `git diff --check`
**Decisions made:** Keep the readiness behavior unchanged, but make the setup path visible in both the Apple provider status message and POC README.
**Next step:** Re-run Test Apple Intelligence after downloading both translation languages from System Settings > General > Language & Region > Translation Languages.

## 2026-05-07 - Tightened Apple Detail Prompt Language Boundaries

**Task:** TASK-003
**Summary:** Added explicit field-level language rules to the selected-term detail prompt so context translations stay in the user's native language and examples stay in the source language.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`; `git diff --check`
**Decisions made:** Treat mixed-language Apple detail output as a prompt-boundary issue. Use precise per-field language constraints rather than post-processing generated text.
**Next step:** Re-test Apple Intelligence selected-term detail with Mine set to German and Theirs set to English; confirm Context translate contains German only.

## 2026-05-07 - Corrected Explain Detail Language Contract

**Task:** TASK-003
**Summary:** Corrected the selected-term detail prompt so only Context translate uses the user's native language; Meaning, In this context, Tone, and Example stay in the source language.
**Files changed:** `poc/Sources/ContextTranslateDiscovery/main.swift`, `docs/DISCOVERY.md`, `tasks/PROGRESS.md`
**Checks run:** `swift build`; `git diff --check`
**Decisions made:** Context translate is the native-language anchor. The rest of the explanation should remain in the source language so the user learns how the English term works.
**Next step:** Re-test Apple Intelligence selected-term detail with Mine set to German and Theirs set to English; confirm only Context translate is German.

# Current Task

## Active Task

**Task ID:** TASK-003
**Status:** active
**Title:** Swift POC

## Current Checkpoint

Test the runnable Swift/SwiftUI discovery prototype and record what feels right or wrong, including the experimental Codex CLI provider.

## Immediate Next Step

Package and run the POC, open Settings, select Codex CLI, verify that bundled models appear immediately, refresh the live catalog, and compare Low/Medium reasoning plus Fast on/off where advertised. Manually verify Explain, selected-term detail, Composer, Review, and Stop, then continue the pending Apple Intelligence verification.

## Blockers

None.

## Discovery Notes

The POC builds and runs via `swift run` in `poc/`, but permission-dependent capture should be tested from the packaged app bundle. It should stay disposable by default. Codex CLI is an experimental readiness-gated provider beside Ollama, OpenRouter, and Apple Intelligence; bundled models load immediately and adjustable Low/Fast settings can improve latency, but the provider still carries high coding-agent context overhead.

## Handoff Notes

Verify the first-launch Settings flow, compact `T` menu-bar label and visibility toggle, Accessibility/model warnings, recorded shortcut behavior, `Command+W` close behavior, selected-term context translations, Codex CLI readiness/model/generation behavior, and Apple Intelligence readiness/generation behavior in the running POC.

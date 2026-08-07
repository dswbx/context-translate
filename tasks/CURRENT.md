# Current Task

## Active Task

**Task ID:** TASK-003
**Status:** active
**Title:** Swift POC

## Current Checkpoint

Test the runnable Swift/SwiftUI discovery prototype and record what feels right or wrong, including the experimental Codex CLI provider.

## Immediate Next Step

Run the POC, open Settings, select Codex CLI, refresh its discovered models, test the connection, and manually verify Explain translation, selected-term detail, Composer, Review, and Stop. Then continue the pending Apple Intelligence manual verification.

## Blockers

None.

## Discovery Notes

The POC builds and runs via `swift run` in `poc/`. It should stay disposable by default. Codex CLI is an experimental readiness-gated provider beside Ollama, OpenRouter, and Apple Intelligence; live smoke testing confirmed it works but carries high coding-agent context overhead.

## Handoff Notes

Verify the first-launch Settings flow, menu-bar visibility toggle, Accessibility/model warnings, recorded shortcut behavior, `Command+W` close behavior, selected-term context translations, Codex CLI readiness/model/generation behavior, and Apple Intelligence readiness/generation behavior in the running POC.

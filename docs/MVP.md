# MVP Scope

## MVP Goal

A user can select confusing English text in another macOS app, understand the sentence and specific phrases, save useful phrases, review them later, and compose natural English from their native language.

## In Scope

- Native macOS app.
- Mostly menu-bar driven.
- Global shortcut or practical trigger flow.
- Fast floating window UI.
- Selected text explanation.
- Translation-first response.
- Phrase-level explanation after the user chooses confusing phrases.
- Phrase composer with casual, neutral, and professional outputs.
- Local history.
- Learning bucket.
- Basic review mode.
- Settings for native language and AI provider.
- Privacy controls for local storage and source app names.

## Out Of Scope

- Browser extension.
- OCR.
- Screenshots.
- Team accounts.
- Cloud sync.
- Offline AI.
- App Store release.
- Pronunciation or audio.
- Advanced dictionary features.
- iOS app in the MVP.

## Success Criteria

The MVP is successful when a user can:

1. Select confusing English text in another app.
2. Trigger the assistant.
3. Understand the sentence translation.
4. Ask for phrase-level explanation.
5. Save a useful phrase.
6. Review saved phrases.
7. Write a thought in their native language and get natural English back.

## Guardrails

- Prefer speed and clarity over feature breadth.
- Do not hide privacy-sensitive behavior.
- Do not require cloud sync.
- Do not let the discovery prototype become production architecture by accident.
- Keep future iOS sharing possible by separating durable domain concepts from macOS-only behavior in the real plan.

# Contextual Language Assistant, Rough Requirements

## Purpose

A native macOS app that helps non-native speakers understand English words, phrases, idioms, and sayings in the exact context where they appear.

The app should work across different apps such as browsers, Slack, email, documents, and AI tools.

The app should also help users express their own thoughts in natural English instead of literal translations from their native language.

## Target User

Non-native English speakers who:

* work in English-speaking environments
* often see unfamiliar phrases, sayings, or subtle wording
* understand basic English, but struggle with context, idioms, tone, and nuance
* want to remember and learn phrases over time

## Core Idea

The user selects text anywhere on macOS, triggers the app, and first receives only a translation of the selected sentence or paragraph into their native language.

After that, the user can select one or multiple words or phrases from the original text that they did not understand.

The app then expands only on those selected words or phrases by explaining:

* what they mean in isolation
* what they mean in this exact context
* examples of how they are normally used
* tone and formality guidance

The app saves unknown words and phrases into a learning bucket for later review.

## Main Features

### 1. Explain selected text

The user can select a sentence or paragraph in any app and trigger the assistant.

The app first translates only the full selected sentence or paragraph into the user’s native language.

After seeing the translation, the user can select one or multiple words or phrases from the original text that they did not understand.

For each selected word or phrase, the app explains:

* what it means in isolation
* what it means in this exact context
* whether it is idiomatic, slang, formal, informal, sarcastic, technical, etc.
* how the user could use it themselves

### 2. Phrase composer

The user can write what they want to say in their native language.

The app turns it into natural English.

It should avoid literal translations.

Example:

German input:

> damit wir uns später keine Steine in den Weg legen

Natural English:

> so we don’t create problems for ourselves later

The app should optionally provide different versions:

* casual
* neutral
* professional

### 3. Learning bucket

Every explained word or phrase can be saved.

The app tracks:

* the original sentence
* the selected word or phrase
* the explanation
* when it was looked up
* which app it came from
* whether the user is still learning it or has learned it

### 4. Review mode

The app should help the user revisit saved words and phrases.

Items should come back more often while they are new, and less often once the user knows them.

Learned items should only reappear after a few weeks.

### 5. History

The user can browse previous lookups and phrase translations.

They should be able to search, delete, edit, or mark items as learned.

## Privacy Requirements

The app should be privacy-conscious.

The user should be able to:

* delete history
* disable storing source app names
* exclude specific apps
* choose whether raw text is stored
* understand clearly when text is sent to an AI provider

## Platform Requirements

Initial version:

* native macOS app
* local SQLite database
* works mostly from the menu bar
* global keyboard shortcuts
* fast floating window UI

Future version:

* iOS app should be possible later
* architecture should not block sharing learning data, history, and review logic with iOS later

## AI Requirements

The translation and explanations should use an LLM, not only a classic translation API.

The AI must understand:

* context
* idioms
* tone
* slang
* professional wording
* literal vs natural translations

## MVP Scope

The MVP should include:

* native macOS app
* select text and explain it
* phrase composer
* local history
* learning bucket
* basic review mode
* settings for language and AI provider

## Out of Scope for MVP

Not needed initially:

* browser extension
* OCR
* screenshots
* team accounts
* cloud sync
* offline AI
* App Store release
* pronunciation/audio
* advanced dictionary features

## Success Criteria

The MVP is successful if a user can:

1. Select confusing English text in another app.
2. Understand the sentence and the confusing phrase.
3. Save the phrase for later.
4. Review saved phrases.
5. Write a thought in their own language and get natural English back.

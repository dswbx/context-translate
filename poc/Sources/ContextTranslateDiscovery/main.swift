import AppKit
import ApplicationServices
import Carbon
import Foundation
import Security
import SwiftUI
#if canImport(FoundationModels)
import FoundationModels
#endif
#if canImport(Translation)
import Translation
#endif

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var capturedText: String
    @Published var captureStatusMessage: String
    @Published var selectedPhrase: PhraseExplanation?
    @Published var selectedTokenID: Int?
    @Published var selectedWordText: String?
    @Published var savedPhrases: [PhraseExplanation]
    @Published var composerInput: String
    @Published var composerOutputs: ComposerOutputs
    @Published var composerStatusMessage: String
    @Published var reviewSentence: String
    @Published var reviewIntent: String
    @Published var reviewFeedback: ReviewFeedback?
    @Published var reviewStatusMessage: String
    @Published var germanTranslation: String
    @Published var translationStatusMessage: String
    @Published var selectedProvider: AIProvider
    @Published var ollamaModels: [String]
    @Published var selectedOllamaModel: String
    @Published var selectedOpenRouterModel: String
    @Published var openRouterAPIKeyInput: String
    @Published var myLanguage: LanguageOption
    @Published var theirLanguage: LanguageOption
    @Published var ollamaStatusMessage: String
    @Published var openRouterStatusMessage: String
    @Published var appleIntelligenceStatusMessage: String
    @Published var hasOpenRouterAPIKey: Bool
    @Published var isCheckingOllama: Bool
    @Published var isTestingOpenRouter: Bool
    @Published var isTestingAppleIntelligence: Bool
    @Published var appleIntelligenceReadiness: AppleIntelligenceReadiness
    @Published var isGeneratingTranslation: Bool
    @Published var isGeneratingDetail: Bool
    @Published var isGeneratingComposer: Bool
    @Published var isGeneratingReview: Bool
    @Published var detailStatusMessage: String
    @Published var selectedTab: PrototypeTab
    @Published var showsMenuBarItem: Bool
    @Published var globalShortcut: GlobalShortcut
    @Published var isRecordingShortcut: Bool

    private let selectedModelKey = "ContextDiscovery.SelectedOllamaModel"
    private let selectedProviderKey = "ContextDiscovery.SelectedProvider"
    private let selectedOpenRouterModelKey = "ContextDiscovery.SelectedOpenRouterModel"
    private let myLanguageKey = "ContextDiscovery.MyLanguage"
    private let theirLanguageKey = "ContextDiscovery.TheirLanguage"
    private let showsMenuBarItemKey = "ContextDiscovery.ShowsMenuBarItem"
    private let shortcutKeyCodeKey = "ContextDiscovery.Shortcut.KeyCode"
    private let shortcutModifiersKey = "ContextDiscovery.Shortcut.Modifiers"
    private let openRouterKeychainService = "ContextTranslateDiscovery.OpenRouter"
    private let openRouterKeychainAccount = "apiKey"
    private let openRouterHasAPIKeyKey = "ContextDiscovery.OpenRouter.HasAPIKey"
    private var selectedToken: WordToken?
    private var translationTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?
    private var composerTask: Task<Void, Never>?
    private var reviewTask: Task<Void, Never>?
    private var lastGeneratedComposerInput: String?
    private var lastReviewedSentence: String?
    private var cachedOpenRouterAPIKey: String?
    private var shortcutRecordingMonitor: Any?
    var menuBarVisibilityDidChange: ((Bool) -> Void)?
    var shortcutDidChange: ((GlobalShortcut) -> Void)?

    init(capture: TextCaptureResult) {
        let savedMyLanguage = LanguageOption.savedValue(forKey: myLanguageKey, fallback: .german)
        let savedTheirLanguage = LanguageOption.savedValue(forKey: theirLanguageKey, fallback: .english)
        let savedProvider = AIProvider.savedValue(forKey: selectedProviderKey, fallback: .ollama)
        let initialProvider = savedProvider
        let hasOpenRouterKey = UserDefaults.standard.bool(forKey: openRouterHasAPIKeyKey)
        let savedShowsMenuBarItem = UserDefaults.standard.object(forKey: showsMenuBarItemKey) as? Bool ?? true
        let savedShortcut = GlobalShortcut.savedValue(
            keyCodeKey: shortcutKeyCodeKey,
            modifiersKey: shortcutModifiersKey,
            fallback: .defaultShortcut
        )

        self.capturedText = capture.text
        self.captureStatusMessage = capture.statusMessage
        self.selectedPhrase = nil
        self.selectedTokenID = nil
        self.selectedWordText = nil
        self.savedPhrases = [PhraseExplanation.sampleLearningItem]
        self.composerInput = ""
        self.composerOutputs = .empty
        self.composerStatusMessage = "Write a thought, then compose it with a local model."
        self.reviewSentence = ""
        self.reviewIntent = ""
        self.reviewFeedback = nil
        self.myLanguage = savedMyLanguage
        self.theirLanguage = savedTheirLanguage
        self.reviewStatusMessage = "Write a \(savedTheirLanguage.name) sentence to review."
        self.germanTranslation = ""
        self.translationStatusMessage = "Choose a local Ollama model to translate."
        self.selectedProvider = initialProvider
        self.ollamaModels = []
        self.selectedOllamaModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? ""
        self.selectedOpenRouterModel = UserDefaults.standard.string(forKey: selectedOpenRouterModelKey) ?? "openrouter/auto"
        self.openRouterAPIKeyInput = ""
        self.ollamaStatusMessage = "Ollama has not been checked yet."
        self.openRouterStatusMessage = hasOpenRouterKey ? "OpenRouter API key is stored in Keychain." : "Add an OpenRouter API key to use cloud models."
        self.appleIntelligenceStatusMessage = "Test Apple Intelligence before turning it on."
        self.hasOpenRouterAPIKey = hasOpenRouterKey
        self.isCheckingOllama = false
        self.isTestingOpenRouter = false
        self.isTestingAppleIntelligence = false
        self.appleIntelligenceReadiness = .unknown
        self.isGeneratingTranslation = false
        self.isGeneratingDetail = false
        self.isGeneratingComposer = false
        self.isGeneratingReview = false
        self.detailStatusMessage = "Click a word to explain it."
        self.selectedTab = .explain
        self.showsMenuBarItem = savedShowsMenuBarItem
        self.globalShortcut = savedShortcut
        self.isRecordingShortcut = false
        self.translationStatusMessage = providerReadyMessage(for: initialProvider)
    }

    var translatedText: String {
        germanTranslation
    }

    var composerInputText: String {
        composerInput.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var composerActionTitle: String {
        if composerOutputs.hasContent && composerInputText == lastGeneratedComposerInput {
            return "Regenerate"
        }

        return "Compose"
    }

    var reviewSentenceText: String {
        reviewSentence.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var reviewActionTitle: String {
        if reviewFeedback != nil && reviewSentenceText == lastReviewedSentence {
            return "Regenerate"
        }

        return "Review"
    }

    var isActiveProviderConfigured: Bool {
        isProviderConfigured(selectedProvider)
    }

    var selectedOpenRouterModelText: String {
        selectedOpenRouterModel.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isAccessibilityGranted: Bool {
        AXIsProcessTrusted()
    }

    var activeProviderConfigurationWarning: String? {
        guard !isActiveProviderConfigured else {
            return nil
        }

        return providerMissingConfigurationMessage(for: selectedProvider, action: "generate responses")
    }

    var shortcutRecordingStatus: String {
        isRecordingShortcut ? "Press the shortcut you want to use." : "Current shortcut: \(globalShortcut.displayName)"
    }

    func replaceCapturedText(_ capture: TextCaptureResult) {
        stopAIResponses()
        capturedText = capture.text.isEmpty ? SampleText.defaultSourceText : capture.text
        captureStatusMessage = capture.statusMessage
        selectedPhrase = nil
        selectedTokenID = nil
        selectedWordText = nil
        selectedToken = nil
        germanTranslation = ""
        translationStatusMessage = providerReadyMessage(for: selectedProvider)
        detailStatusMessage = "Click a word to explain it."
        if isActiveProviderConfigured {
            regenerateAIResponses()
        }
    }

    var wordTokens: [WordToken] {
        WordToken.tokenize(capturedText)
    }

    func selectWord(_ token: WordToken) {
        detailTask?.cancel()
        detailTask = nil
        selectedTokenID = token.id
        selectedWordText = token.text
        selectedToken = token

        if !isActiveProviderConfigured {
            selectedPhrase = nil
            detailStatusMessage = providerMissingConfigurationMessage(for: selectedProvider, action: "explain this word")
        } else {
            selectedPhrase = nil
            generateAIDetail(for: token)
        }
    }

    func saveSelectedPhrase() {
        guard let selectedPhrase else {
            return
        }
        guard !savedPhrases.contains(where: { $0.phrase == selectedPhrase.phrase }) else {
            return
        }
        savedPhrases.insert(selectedPhrase, at: 0)
    }

    func compose() {
        stopComposer()

        let input = composerInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else {
            composerOutputs = .empty
            composerStatusMessage = "Write a thought first."
            return
        }

        guard isActiveProviderConfigured else {
            composerOutputs = .empty
            composerStatusMessage = providerMissingConfigurationMessage(for: selectedProvider, action: "compose")
            return
        }

        generateAIComposerOutput(for: input)
    }

    func reviewWriting() {
        stopReview()

        let sentence = reviewSentence.trimmingCharacters(in: .whitespacesAndNewlines)
        let intent = reviewIntent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !sentence.isEmpty else {
            reviewFeedback = nil
            reviewStatusMessage = "Write a \(theirLanguage.name) sentence first."
            return
        }

        guard isActiveProviderConfigured else {
            reviewFeedback = nil
            reviewStatusMessage = providerMissingConfigurationMessage(for: selectedProvider, action: "review your sentence")
            return
        }

        generateAIReview(sentence: sentence, intent: intent)
    }

    func selectOllamaModel(_ model: String) {
        selectedOllamaModel = model
        UserDefaults.standard.set(model, forKey: selectedModelKey)
        translationStatusMessage = "Selected \(model)."
        if selectedProvider == .ollama {
            regenerateAIResponses()
        }
    }

    func selectProvider(_ provider: AIProvider) {
        selectedProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: selectedProviderKey)
        translationStatusMessage = providerReadyMessage(for: provider)
        if isProviderConfigured(provider) {
            regenerateAIResponses()
        } else {
            stopAIResponses()
            if provider == .appleIntelligence {
                germanTranslation = ""
                selectedPhrase = nil
                detailStatusMessage = selectedWordText == nil ? "Click a word to explain it." : providerMissingConfigurationMessage(for: provider, action: "explain this word")
            }
        }
    }

    func setShowsMenuBarItem(_ isVisible: Bool) {
        showsMenuBarItem = isVisible
        UserDefaults.standard.set(isVisible, forKey: showsMenuBarItemKey)
        menuBarVisibilityDidChange?(isVisible)
    }

    func beginShortcutRecording() {
        stopShortcutRecording()
        isRecordingShortcut = true
        shortcutRecordingMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }

            Task { @MainActor in
                self.handleShortcutRecordingEvent(event)
            }
            return nil
        }
    }

    func cancelShortcutRecording() {
        stopShortcutRecording()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func selectOpenRouterModel(_ model: String) {
        selectedOpenRouterModel = model
        UserDefaults.standard.set(model, forKey: selectedOpenRouterModelKey)
        openRouterStatusMessage = hasOpenRouterAPIKey ? "OpenRouter model set to \(selectedOpenRouterModelText)." : "Add an OpenRouter API key to use \(selectedOpenRouterModelText)."
        if selectedProvider == .openRouter {
            translationStatusMessage = providerReadyMessage(for: .openRouter)
        }
    }

    func applyOpenRouterModelSelection() {
        selectOpenRouterModel(selectedOpenRouterModel)
        if selectedProvider == .openRouter, isActiveProviderConfigured {
            regenerateAIResponses()
        }
    }

    func saveOpenRouterAPIKey() {
        let apiKey = openRouterAPIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            openRouterStatusMessage = "Enter an OpenRouter API key before saving."
            return
        }

        do {
            try KeychainPasswordStore.save(
                apiKey,
                service: openRouterKeychainService,
                account: openRouterKeychainAccount
            )
            openRouterAPIKeyInput = ""
            cachedOpenRouterAPIKey = apiKey
            hasOpenRouterAPIKey = true
            UserDefaults.standard.set(true, forKey: openRouterHasAPIKeyKey)
            openRouterStatusMessage = "OpenRouter API key saved in Keychain."
            if selectedProvider == .openRouter {
                translationStatusMessage = providerReadyMessage(for: .openRouter)
                regenerateAIResponses()
            }
        } catch {
            openRouterStatusMessage = "Could not save OpenRouter API key."
        }
    }

    func forgetOpenRouterAPIKey() {
        KeychainPasswordStore.delete(
            service: openRouterKeychainService,
            account: openRouterKeychainAccount
        )
        openRouterAPIKeyInput = ""
        cachedOpenRouterAPIKey = nil
        hasOpenRouterAPIKey = false
        UserDefaults.standard.set(false, forKey: openRouterHasAPIKeyKey)
        openRouterStatusMessage = "OpenRouter API key removed."
        if selectedProvider == .openRouter {
            stopAIResponses()
            germanTranslation = ""
            translationStatusMessage = providerReadyMessage(for: .openRouter)
            detailStatusMessage = selectedWordText == nil ? "Click a word to explain it." : providerMissingConfigurationMessage(for: .openRouter, action: "explain this word")
        }
    }

    func testOpenRouterConnection() async {
        guard hasOpenRouterAPIKey else {
            openRouterStatusMessage = "Add an OpenRouter API key before testing."
            return
        }
        guard !selectedOpenRouterModelText.isEmpty else {
            openRouterStatusMessage = "Enter an OpenRouter model ID before testing."
            return
        }

        isTestingOpenRouter = true
        openRouterStatusMessage = "Testing OpenRouter with \(selectedOpenRouterModelText)..."
        defer { isTestingOpenRouter = false }

        do {
            _ = try await askOpenRouter(prompt: "Reply with OK.")
            openRouterStatusMessage = "OpenRouter connection works with \(selectedOpenRouterModelText)."
        } catch {
            openRouterStatusMessage = "OpenRouter test failed. Check the API key, model ID, and account credits."
        }
    }

    func testAppleIntelligence() async {
        isTestingAppleIntelligence = true
        appleIntelligenceReadiness = .checking
        appleIntelligenceStatusMessage = appleIntelligenceReadiness.message
        defer { isTestingAppleIntelligence = false }

        do {
            try await checkAppleIntelligenceReadiness()
            appleIntelligenceReadiness = .ready
            appleIntelligenceStatusMessage = appleIntelligenceReadiness.message
            if selectedProvider == .appleIntelligence {
                translationStatusMessage = providerReadyMessage(for: .appleIntelligence)
                regenerateAIResponses()
            }
        } catch {
            let message = appleIntelligenceFailureMessage(from: error)
            appleIntelligenceReadiness = .unavailable(message)
            appleIntelligenceStatusMessage = message
            if selectedProvider == .appleIntelligence {
                stopAIResponses()
                germanTranslation = ""
                translationStatusMessage = providerReadyMessage(for: .appleIntelligence)
                detailStatusMessage = selectedWordText == nil ? "Click a word to explain it." : providerMissingConfigurationMessage(for: .appleIntelligence, action: "explain this word")
            }
        }
    }

    func selectMyLanguage(_ language: LanguageOption) {
        myLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: myLanguageKey)
        resetAppleIntelligenceReadinessForLanguageChange()
        translationStatusMessage = providerReadyMessage(for: selectedProvider)
        if isActiveProviderConfigured {
            regenerateAIResponses()
        }
    }

    func selectTheirLanguage(_ language: LanguageOption) {
        theirLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: theirLanguageKey)
        resetAppleIntelligenceReadinessForLanguageChange()
        reviewStatusMessage = "Write a \(language.name) sentence to review."
        translationStatusMessage = providerReadyMessage(for: selectedProvider)
        if isActiveProviderConfigured {
            regenerateAIResponses()
        }
    }

    func refreshOllamaModels() async {
        isCheckingOllama = true
        defer { isCheckingOllama = false }

        guard let url = URL(string: "http://localhost:11434/api/tags") else {
            ollamaStatusMessage = "Ollama URL is invalid."
            return
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                ollamaModels = []
                ollamaStatusMessage = "Ollama responded unexpectedly. Check that the local server is healthy."
                return
            }

            let tags = try JSONDecoder().decode(OllamaTagsResponse.self, from: data)
            let models = tags.models.map(\.name).sorted()
            ollamaModels = models

            if models.isEmpty {
                selectedOllamaModel = ""
                ollamaStatusMessage = "Ollama is running, but no local models were found."
            } else {
                if !models.contains(selectedOllamaModel) {
                    selectOllamaModel(models[0])
                }
                ollamaStatusMessage = "Ollama is running. \(models.count) local model\(models.count == 1 ? "" : "s") available."
            }
        } catch {
            ollamaModels = []
            ollamaStatusMessage = "Ollama is not running at localhost:11434."
        }
    }

    func regenerateAIResponses() {
        stopAIResponses()
        regenerateTranslation()
        regenerateSelectedDetail()
    }

    func regenerateTranslation() {
        stopTranslation()
        guard isActiveProviderConfigured else {
            germanTranslation = ""
            translationStatusMessage = providerMissingConfigurationMessage(for: selectedProvider, action: "use real AI responses")
            return
        }

        generateAITranslation()
    }

    func regenerateSelectedDetail() {
        stopDetail()
        if let selectedToken {
            selectedPhrase = nil
            guard isActiveProviderConfigured else {
                detailStatusMessage = providerMissingConfigurationMessage(for: selectedProvider, action: "explain this word")
                return
            }
            generateAIDetail(for: selectedToken)
        }
    }

    func stopAIResponses() {
        stopTranslation()
        stopDetail()
        stopComposer()
        stopReview()
    }

    func stopTranslation() {
        translationTask?.cancel()
        translationTask = nil
        isGeneratingTranslation = false
        if isActiveProviderConfigured {
            translationStatusMessage = "Stopped."
        }
    }

    func stopDetail() {
        detailTask?.cancel()
        detailTask = nil
        isGeneratingDetail = false
        if isActiveProviderConfigured {
            detailStatusMessage = selectedWordText == nil ? "Click a word to explain it." : "Stopped."
        }
    }

    func stopComposer() {
        composerTask?.cancel()
        composerTask = nil
        isGeneratingComposer = false
        if isActiveProviderConfigured {
            composerStatusMessage = "Stopped."
        }
    }

    func stopReview() {
        reviewTask?.cancel()
        reviewTask = nil
        isGeneratingReview = false
        if isActiveProviderConfigured {
            reviewStatusMessage = "Stopped."
        }
    }

    private func generateAITranslation() {
        translationTask?.cancel()
        isGeneratingTranslation = true
        translationStatusMessage = "Translating with \(activeModelDisplayName)..."

        let prompt = """
        Translate this \(theirLanguage.name) sentence into natural \(myLanguage.name).
        Output only the \(myLanguage.name) translation. No notes, no alternatives, no markdown.

        \(theirLanguage.name) sentence:
        \(capturedText)
        """

        translationTask = Task {
            do {
                let response: String
                if selectedProvider == .appleIntelligence {
                    response = try await translateWithAppleIntelligence(capturedText)
                } else {
                    response = try await askActiveProvider(prompt: prompt)
                }
                guard !Task.isCancelled else { return }
                germanTranslation = response
                translationStatusMessage = "Translated with \(activeModelDisplayName)."
            } catch is CancellationError {
                translationStatusMessage = "Translation stopped."
            } catch {
                germanTranslation = ""
                translationStatusMessage = providerRequestFailureMessage
            }
            isGeneratingTranslation = false
            translationTask = nil
        }
    }

    private func generateAIDetail(for token: WordToken) {
        detailTask?.cancel()
        isGeneratingDetail = true
        detailStatusMessage = "Asking \(activeModelDisplayName)..."

        let prompt = """
        You are helping a \(myLanguage.speakerDescription) professional understand \(theirLanguage.name).
        Explain the selected word in the exact sentence context.
        Return valid JSON only. No markdown. No code fences.

        Required JSON shape:
        {
          "contextTranslations": [
            "natural \(myLanguage.name) rendering of the selected word or phrase in this sentence",
            "optional second alternative when it helps understanding",
            "optional third alternative when it helps understanding"
          ],
          "meaning": "short meaning in isolation",
          "contextualMeaning": "meaning in this exact sentence",
          "tone": "tone and formality guidance",
          "example": "one natural \(theirLanguage.name) example sentence"
        }

        Original sentence:
        \(capturedText)

        Selected word:
        \(token.text)
        """

        detailTask = Task {
            do {
                let response = try await askActiveProvider(prompt: prompt)
                guard !Task.isCancelled else { return }
                selectedPhrase = PhraseExplanation.fromModelResponse(response, fallbackWord: token.text)
                detailStatusMessage = "Generated with \(activeModelDisplayName)."
            } catch is CancellationError {
                detailStatusMessage = "Explanation stopped."
            } catch {
                selectedPhrase = nil
                detailStatusMessage = providerRequestFailureMessage
            }
            isGeneratingDetail = false
            detailTask = nil
        }
    }

    private func generateAIComposerOutput(for input: String) {
        composerTask?.cancel()
        composerOutputs = .empty
        isGeneratingComposer = true
        composerStatusMessage = "Composing with \(activeModelDisplayName)..."

        let prompt = """
        You are helping a \(myLanguage.speakerDescription) professional write natural \(theirLanguage.name).
        Rewrite the user's thought into three natural \(theirLanguage.name) variants.
        Return valid JSON only. No markdown. No code fences.

        Required JSON shape:
        {
          "casual": "natural casual \(theirLanguage.name)",
          "neutral": "natural neutral \(theirLanguage.name)",
          "professional": "natural professional \(theirLanguage.name)"
        }

        User thought:
        \(input)
        """

        composerTask = Task {
            do {
                let response = try await askActiveProvider(prompt: prompt)
                guard !Task.isCancelled else { return }
                composerOutputs = ComposerOutputs.fromModelResponse(response)
                lastGeneratedComposerInput = input
                composerStatusMessage = "Composed with \(activeModelDisplayName)."
            } catch is CancellationError {
                composerStatusMessage = "Composition stopped."
            } catch {
                composerOutputs = .empty
                composerStatusMessage = providerRequestFailureMessage
            }
            isGeneratingComposer = false
            composerTask = nil
        }
    }

    private func generateAIReview(sentence: String, intent: String) {
        reviewTask?.cancel()
        reviewFeedback = nil
        isGeneratingReview = true
        reviewStatusMessage = "Reviewing with \(activeModelDisplayName)..."

        let intentBlock = intent.isEmpty ? "No native-language explanation was provided." : intent
        let prompt = """
        You are helping a \(myLanguage.speakerDescription) professional improve a \(theirLanguage.name) sentence they wrote.
        Review the \(theirLanguage.name) sentence for naturalness, correctness, tone, and whether it expresses the intended meaning.
        Keep every field concise and concrete. Do not write one big prose paragraph.
        Return valid JSON only. No markdown. No code fences.

        Required JSON shape:
        {
          "rating": "Good | Understandable | Needs work",
          "score": "1-5",
          "correctedSentence": "best improved version of the sentence",
          "whatWorks": "short note about what is already good",
          "improvements": [
            {
              "issue": "specific issue",
              "suggestion": "specific improvement",
              "why": "short explanation"
            }
          ],
          "naturalAlternatives": [
            "first natural alternative",
            "second natural alternative"
          ]
        }

        \(theirLanguage.name) sentence:
        \(sentence)

        What the user tried to express in \(myLanguage.name):
        \(intentBlock)
        """

        reviewTask = Task {
            do {
                let response = try await askActiveProvider(prompt: prompt)
                guard !Task.isCancelled else { return }
                reviewFeedback = ReviewFeedback.fromModelResponse(response)
                lastReviewedSentence = sentence
                reviewStatusMessage = "Reviewed with \(activeModelDisplayName)."
            } catch is CancellationError {
                reviewStatusMessage = "Review stopped."
            } catch {
                reviewFeedback = nil
                reviewStatusMessage = providerRequestFailureMessage
            }
            isGeneratingReview = false
            reviewTask = nil
        }
    }

    private var activeModelDisplayName: String {
        switch selectedProvider {
        case .ollama:
            return selectedOllamaModel
        case .openRouter:
            return "OpenRouter: \(selectedOpenRouterModelText)"
        case .appleIntelligence:
            return "Apple Intelligence"
        }
    }

    private var providerRequestFailureMessage: String {
        switch selectedProvider {
        case .ollama:
            return "Could not reach Ollama. Check that the local server is running."
        case .openRouter:
            return "OpenRouter request failed. Check the API key, model ID, and account credits."
        case .appleIntelligence:
            return appleIntelligenceStatusMessage
        }
    }

    private func isProviderConfigured(_ provider: AIProvider) -> Bool {
        switch provider {
        case .ollama:
            return !selectedOllamaModel.isEmpty
        case .openRouter:
            return hasOpenRouterAPIKey && !selectedOpenRouterModelText.isEmpty
        case .appleIntelligence:
            return appleIntelligenceReadiness.isReady
        }
    }

    private func providerReadyMessage(for provider: AIProvider) -> String {
        guard isProviderConfigured(provider) else {
            return providerMissingConfigurationMessage(for: provider, action: "translate")
        }

        switch provider {
        case .ollama:
            return "Ready to translate with \(selectedOllamaModel)."
        case .openRouter:
            return "Ready to translate with OpenRouter: \(selectedOpenRouterModelText)."
        case .appleIntelligence:
            return "Ready to translate with Apple Intelligence."
        }
    }

    private func providerMissingConfigurationMessage(for provider: AIProvider, action: String) -> String {
        switch provider {
        case .ollama:
            return "Choose a local Ollama model to \(action)."
        case .openRouter:
            if !hasOpenRouterAPIKey {
                return "Add an OpenRouter API key to \(action)."
            }
            return "Enter an OpenRouter model ID to \(action)."
        case .appleIntelligence:
            return appleIntelligenceReadiness.isReady ? "Apple Intelligence is ready to \(action)." : appleIntelligenceReadiness.message
        }
    }

    private func askActiveProvider(prompt: String) async throws -> String {
        switch selectedProvider {
        case .ollama:
            return try await askOllama(prompt: prompt)
        case .openRouter:
            return try await askOpenRouter(prompt: prompt)
        case .appleIntelligence:
            return try await askAppleFoundationModel(prompt: prompt)
        }
    }

    private func askOllama(prompt: String) async throws -> String {
        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            throw URLError(.badURL)
        }

        try Task.checkCancellation()

        let requestBody = OllamaGenerateRequest(
            model: selectedOllamaModel,
            prompt: prompt,
            stream: false
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
        return result.response.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func askOpenRouter(prompt: String) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }
        guard let apiKey = openRouterAPIKey() else {
            throw URLError(.userAuthenticationRequired)
        }

        try Task.checkCancellation()

        let requestBody = OpenRouterChatCompletionRequest(
            model: selectedOpenRouterModelText,
            messages: [
                OpenRouterChatMessage(role: "user", content: prompt)
            ],
            temperature: 0.2
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Task.checkCancellation()

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode(OpenRouterChatCompletionResponse.self, from: data)
        guard let content = result.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines),
              !content.isEmpty else {
            throw URLError(.zeroByteResource)
        }

        return content
    }

    private func checkAppleIntelligenceReadiness() async throws {
        try Task.checkCancellation()
        try await verifyAppleFoundationModelReady()
        try Task.checkCancellation()
        let generationProbe = try await askAppleFoundationModel(prompt: """
        Return valid JSON only. No markdown.
        Required JSON shape:
        {"status":"OK"}
        """)
        guard AppleReadinessProbe.fromModelResponse(generationProbe)?.status.uppercased() == "OK" else {
            throw AppleIntelligenceProviderError("Apple Intelligence responded, but the readiness JSON test did not parse.")
        }
        try Task.checkCancellation()
        _ = try await translateWithAppleIntelligence("Hello.")
    }

    private func askAppleFoundationModel(prompt: String) async throws -> String {
#if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AppleIntelligenceProviderError("Apple Intelligence generation requires macOS 26 or later in this POC.")
        }

        try await verifyAppleFoundationModelReady()
        try Task.checkCancellation()

        let session = LanguageModelSession(instructions: """
        You are the on-device Apple Intelligence provider for a language assistant prototype.
        Follow the user's requested output format exactly.
        """)
        let response = try await session.respond(
            to: prompt,
            options: GenerationOptions(temperature: 0.2, maximumResponseTokens: 700)
        )
        try Task.checkCancellation()
        let content = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            throw AppleIntelligenceProviderError("Apple Intelligence returned an empty response.")
        }

        return content
#else
        throw AppleIntelligenceProviderError("Apple Intelligence generation APIs are not available in this SDK.")
#endif
    }

    private func translateWithAppleIntelligence(_ text: String) async throws -> String {
#if canImport(Translation)
        guard #available(macOS 26.0, *) else {
            throw AppleIntelligenceProviderError("Apple translation requires macOS 26 or later in this POC.")
        }

        try Task.checkCancellation()
        let source = theirLanguage.localeLanguage
        let target = myLanguage.localeLanguage
        let languageAvailability = LanguageAvailability()
        let status = await languageAvailability.status(from: source, to: target)
        guard status == .installed else {
            throw AppleIntelligenceProviderError(appleTranslationStatusMessage(status, source: theirLanguage, target: myLanguage))
        }

        let session = TranslationSession(installedSource: source, target: target)
        let response = try await session.translate(text)
        try Task.checkCancellation()
        let translated = response.targetText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translated.isEmpty else {
            throw AppleIntelligenceProviderError("Apple translation returned an empty response.")
        }

        return translated
#else
        throw AppleIntelligenceProviderError("Apple translation APIs are not available in this SDK.")
#endif
    }

    private func verifyAppleFoundationModelReady() async throws {
#if canImport(FoundationModels)
        guard #available(macOS 26.0, *) else {
            throw AppleIntelligenceProviderError("Apple Intelligence generation requires macOS 26 or later in this POC.")
        }

        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(let reason):
            throw AppleIntelligenceProviderError(appleFoundationModelUnavailableMessage(reason))
        @unknown default:
            throw AppleIntelligenceProviderError("Apple Intelligence availability is unknown on this Mac.")
        }

        guard model.supportsLocale(Locale(identifier: myLanguage.localeIdentifier)),
              model.supportsLocale(Locale(identifier: theirLanguage.localeIdentifier)) else {
            throw AppleIntelligenceProviderError("Apple Intelligence does not support \(myLanguage.name) and \(theirLanguage.name) on this Mac.")
        }
#else
        throw AppleIntelligenceProviderError("Apple Intelligence generation APIs are not available in this SDK.")
#endif
    }

    private func resetAppleIntelligenceReadinessForLanguageChange() {
        guard appleIntelligenceReadiness.isReady else {
            return
        }

        appleIntelligenceReadiness = .unknown
        appleIntelligenceStatusMessage = "Language changed. Test Apple Intelligence again before using it."
        if selectedProvider == .appleIntelligence {
            stopAIResponses()
            selectedProvider = .ollama
            UserDefaults.standard.set(AIProvider.ollama.rawValue, forKey: selectedProviderKey)
        }
    }

    private func appleIntelligenceFailureMessage(from error: Error) -> String {
        if let providerError = error as? AppleIntelligenceProviderError {
            return providerError.message
        }

        return "Apple Intelligence test failed: \(error.localizedDescription)"
    }

#if canImport(Translation)
    @available(macOS 15.0, *)
    private func appleTranslationStatusMessage(_ status: LanguageAvailability.Status, source: LanguageOption, target: LanguageOption) -> String {
        switch status {
        case .installed:
            return "Apple translation is installed for \(source.name) to \(target.name)."
        case .supported:
            return "Apple translation supports \(source.name) to \(target.name), but the language pair is not installed yet. Open System Settings > General > Language & Region > Translation Languages, download \(source.name) and \(target.name), then test again. Turn on On-Device Mode there if you want macOS to process translations locally."
        case .unsupported:
            return "Apple translation does not support \(source.name) to \(target.name) on this Mac."
        @unknown default:
            return "Apple translation availability is unknown for \(source.name) to \(target.name)."
        }
    }
#endif

#if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func appleFoundationModelUnavailableMessage(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "This Mac is not eligible for Apple Intelligence."
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled in System Settings."
        case .modelNotReady:
            return "Apple Intelligence is not ready yet. The local model may still be downloading."
        @unknown default:
            return "Apple Intelligence is unavailable for an unknown reason."
        }
    }
#endif

    private func openRouterAPIKey() -> String? {
        if let cachedOpenRouterAPIKey {
            return cachedOpenRouterAPIKey
        }

        guard let apiKey = KeychainPasswordStore.read(
            service: openRouterKeychainService,
            account: openRouterKeychainAccount
        ), !apiKey.isEmpty else {
            hasOpenRouterAPIKey = false
            UserDefaults.standard.set(false, forKey: openRouterHasAPIKeyKey)
            openRouterStatusMessage = "OpenRouter API key was not found in Keychain."
            return nil
        }

        cachedOpenRouterAPIKey = apiKey
        hasOpenRouterAPIKey = true
        UserDefaults.standard.set(true, forKey: openRouterHasAPIKeyKey)
        return apiKey
    }

    private func handleShortcutRecordingEvent(_ event: NSEvent) {
        if event.keyCode == UInt16(kVK_Escape) {
            stopShortcutRecording()
            return
        }

        guard let shortcut = GlobalShortcut(event: event) else {
            return
        }

        globalShortcut = shortcut
        UserDefaults.standard.set(Int(shortcut.keyCode), forKey: shortcutKeyCodeKey)
        UserDefaults.standard.set(Int(shortcut.modifiers), forKey: shortcutModifiersKey)
        shortcutDidChange?(shortcut)
        stopShortcutRecording()
    }

    private func stopShortcutRecording() {
        if let shortcutRecordingMonitor {
            NSEvent.removeMonitor(shortcutRecordingMonitor)
            self.shortcutRecordingMonitor = nil
        }
        isRecordingShortcut = false
    }
}

struct WordToken: Identifiable {
    let id: Int
    let text: String
    let normalized: String

    static func tokenize(_ text: String) -> [WordToken] {
        text.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .enumerated()
            .compactMap { index, raw in
                let normalized = raw
                    .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    .lowercased()

                guard !normalized.isEmpty else {
                    return nil
                }

                return WordToken(id: index, text: raw, normalized: normalized)
            }
    }
}

enum LanguageOption: String, CaseIterable, Identifiable {
    case english
    case german
    case french
    case spanish
    case italian
    case portuguese
    case dutch

    var id: String { rawValue }

    var name: String {
        switch self {
        case .english: return "English"
        case .german: return "German"
        case .french: return "French"
        case .spanish: return "Spanish"
        case .italian: return "Italian"
        case .portuguese: return "Portuguese"
        case .dutch: return "Dutch"
        }
    }

    var speakerDescription: String {
        switch self {
        case .english: return "English-speaking"
        case .german: return "German-speaking"
        case .french: return "French-speaking"
        case .spanish: return "Spanish-speaking"
        case .italian: return "Italian-speaking"
        case .portuguese: return "Portuguese-speaking"
        case .dutch: return "Dutch-speaking"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .english: return "en"
        case .german: return "de"
        case .french: return "fr"
        case .spanish: return "es"
        case .italian: return "it"
        case .portuguese: return "pt"
        case .dutch: return "nl"
        }
    }

    var localeLanguage: Locale.Language {
        Locale.Language(identifier: localeIdentifier)
    }

    static func savedValue(forKey key: String, fallback: LanguageOption) -> LanguageOption {
        guard let rawValue = UserDefaults.standard.string(forKey: key),
              let language = LanguageOption(rawValue: rawValue) else {
            return fallback
        }

        return language
    }
}

struct GlobalShortcut: Equatable {
    let keyCode: UInt32
    let modifiers: UInt32

    static let defaultShortcut = GlobalShortcut(
        keyCode: UInt32(kVK_ANSI_E),
        modifiers: UInt32(cmdKey | optionKey)
    )

    init(keyCode: UInt32, modifiers: UInt32) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init?(event: NSEvent) {
        let carbonModifiers = GlobalShortcut.carbonModifiers(from: event.modifierFlags)
        guard carbonModifiers != 0,
              event.keyCode != UInt16(kVK_Escape),
              event.charactersIgnoringModifiers?.isEmpty == false else {
            return nil
        }

        self.keyCode = UInt32(event.keyCode)
        self.modifiers = carbonModifiers
    }

    var displayName: String {
        "\(modifierDisplayName)\(keyDisplayName)"
    }

    static func savedValue(keyCodeKey: String, modifiersKey: String, fallback: GlobalShortcut) -> GlobalShortcut {
        guard UserDefaults.standard.object(forKey: keyCodeKey) != nil,
              UserDefaults.standard.object(forKey: modifiersKey) != nil else {
            return fallback
        }

        let keyCode = UserDefaults.standard.integer(forKey: keyCodeKey)
        let modifiers = UserDefaults.standard.integer(forKey: modifiersKey)
        guard modifiers > 0 else {
            return fallback
        }

        return GlobalShortcut(keyCode: UInt32(keyCode), modifiers: UInt32(modifiers))
    }

    private var modifierDisplayName: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("Control") }
        if modifiers & UInt32(optionKey) != 0 { parts.append("Option") }
        if modifiers & UInt32(shiftKey) != 0 { parts.append("Shift") }
        if modifiers & UInt32(cmdKey) != 0 { parts.append("Command") }
        return parts.isEmpty ? "" : parts.joined(separator: "+") + "+"
    }

    private var keyDisplayName: String {
        GlobalShortcut.keyNames[keyCode] ?? "Key \(keyCode)"
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_ForwardDelete): "Forward Delete",
        UInt32(kVK_Home): "Home",
        UInt32(kVK_End): "End",
        UInt32(kVK_PageUp): "Page Up",
        UInt32(kVK_PageDown): "Page Down",
        UInt32(kVK_LeftArrow): "Left Arrow",
        UInt32(kVK_RightArrow): "Right Arrow",
        UInt32(kVK_UpArrow): "Up Arrow",
        UInt32(kVK_DownArrow): "Down Arrow",
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12"
    ]
}

enum AIProvider: String, CaseIterable, Identifiable {
    case ollama
    case openRouter
    case appleIntelligence

    var id: String { rawValue }

    var name: String {
        switch self {
        case .ollama:
            return "Ollama"
        case .openRouter:
            return "OpenRouter"
        case .appleIntelligence:
            return "Apple Intelligence"
        }
    }

    static func savedValue(forKey key: String, fallback: AIProvider) -> AIProvider {
        guard let rawValue = UserDefaults.standard.string(forKey: key),
              let provider = AIProvider(rawValue: rawValue) else {
            return fallback
        }

        return provider
    }
}

enum AppleIntelligenceReadiness: Equatable {
    case unknown
    case checking
    case ready
    case unavailable(String)

    var isReady: Bool {
        if case .ready = self {
            return true
        }

        return false
    }

    var message: String {
        switch self {
        case .unknown:
            return "Test Apple Intelligence before turning it on."
        case .checking:
            return "Testing Apple Intelligence..."
        case .ready:
            return "Apple Intelligence is ready for this language pair."
        case .unavailable(let reason):
            return reason
        }
    }
}

struct AppleIntelligenceProviderError: LocalizedError {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var errorDescription: String? {
        message
    }
}

struct AppleReadinessProbe: Decodable {
    let status: String

    static func fromModelResponse(_ response: String) -> AppleReadinessProbe? {
        let jsonText = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonText.data(using: .utf8) else {
            return nil
        }

        return try? JSONDecoder().decode(AppleReadinessProbe.self, from: data)
    }
}

struct OllamaTagsResponse: Decodable {
    let models: [OllamaModelInfo]
}

struct OllamaModelInfo: Decodable {
    let name: String
}

struct OllamaGenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

struct OllamaGenerateResponse: Decodable {
    let response: String
}

struct OpenRouterChatCompletionRequest: Encodable {
    let model: String
    let messages: [OpenRouterChatMessage]
    let temperature: Double
}

struct OpenRouterChatMessage: Codable {
    let role: String
    let content: String
}

struct OpenRouterChatCompletionResponse: Decodable {
    let choices: [OpenRouterChoice]
}

struct OpenRouterChoice: Decodable {
    let message: OpenRouterChatMessage
}

enum KeychainPasswordStore {
    static func read(service: String, account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    static func save(_ password: String, service: String, account: String) throws {
        let data = Data(password.utf8)
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attributes: [CFString: Any] = [
            kSecValueData: data,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        guard updateStatus == errSecItemNotFound else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(updateStatus),
                userInfo: nil
            )
        }

        var addQuery = query
        addQuery[kSecValueData] = data
        addQuery[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(addStatus),
                userInfo: nil
            )
        }
    }

    static func delete(service: String, account: String) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct AIWordExplanation: Decodable {
    let contextTranslations: [String]
    let meaning: String
    let contextualMeaning: String
    let tone: String
    let example: String

    enum CodingKeys: String, CodingKey {
        case contextTranslations
        case translation
        case meaning
        case contextualMeaning
        case tone
        case example
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let translations = try? container.decode([String].self, forKey: .contextTranslations) {
            self.contextTranslations = translations.cleanedContextTranslations
        } else if let legacyTranslation = try? container.decode(String.self, forKey: .translation) {
            self.contextTranslations = [legacyTranslation].cleanedContextTranslations
        } else {
            self.contextTranslations = []
        }

        self.meaning = try container.decode(String.self, forKey: .meaning)
        self.contextualMeaning = try container.decode(String.self, forKey: .contextualMeaning)
        self.tone = try container.decode(String.self, forKey: .tone)
        self.example = try container.decode(String.self, forKey: .example)
    }
}

struct AIComposerOutput: Decodable {
    let casual: String
    let neutral: String
    let professional: String
}

struct AIReviewImprovement: Decodable {
    let issue: String
    let suggestion: String
    let why: String

    enum CodingKeys: String, CodingKey {
        case issue
        case suggestion
        case why
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.issue = (try? container.decode(String.self, forKey: .issue)) ?? "Improvement"
        self.suggestion = (try? container.decode(String.self, forKey: .suggestion)) ?? ""
        self.why = (try? container.decode(String.self, forKey: .why)) ?? ""
    }
}

struct AIReviewFeedback: Decodable {
    let rating: String
    let score: String
    let correctedSentence: String
    let whatWorks: String
    let improvements: [AIReviewImprovement]
    let naturalAlternatives: [String]

    enum CodingKeys: String, CodingKey {
        case rating
        case score
        case correctedSentence
        case whatWorks
        case improvements
        case naturalAlternatives
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.rating = (try? container.decode(String.self, forKey: .rating)) ?? "Understandable"

        if let scoreText = try? container.decode(String.self, forKey: .score) {
            self.score = scoreText
        } else if let scoreNumber = try? container.decode(Int.self, forKey: .score) {
            self.score = String(scoreNumber)
        } else if let scoreNumber = try? container.decode(Double.self, forKey: .score) {
            self.score = String(format: "%.1f", scoreNumber)
        } else {
            self.score = "?"
        }

        self.correctedSentence = (try? container.decode(String.self, forKey: .correctedSentence)) ?? ""
        self.whatWorks = (try? container.decode(String.self, forKey: .whatWorks)) ?? ""
        self.improvements = (try? container.decode([AIReviewImprovement].self, forKey: .improvements)) ?? []
        self.naturalAlternatives = (try? container.decode([String].self, forKey: .naturalAlternatives)) ?? []
    }
}

struct ReviewImprovement: Identifiable, Equatable {
    let id = UUID()
    let issue: String
    let suggestion: String
    let why: String
}

struct ReviewFeedback: Equatable {
    let rating: String
    let score: String
    let correctedSentence: String
    let whatWorks: String
    let improvements: [ReviewImprovement]
    let naturalAlternatives: [String]

    static func fromModelResponse(_ response: String) -> ReviewFeedback {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = jsonText.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(AIReviewFeedback.self, from: data) {
            return ReviewFeedback(
                rating: decoded.rating,
                score: decoded.score,
                correctedSentence: decoded.correctedSentence,
                whatWorks: decoded.whatWorks,
                improvements: decoded.improvements.map {
                    ReviewImprovement(issue: $0.issue, suggestion: $0.suggestion, why: $0.why)
                },
                naturalAlternatives: decoded.naturalAlternatives
            )
        }

        return ReviewFeedback(
            rating: "Needs review",
            score: "?",
            correctedSentence: trimmed,
            whatWorks: "The local model returned an unstructured response.",
            improvements: [
                ReviewImprovement(
                    issue: "Response format",
                    suggestion: "Try again or use a stronger local model.",
                    why: "The review mode expects structured JSON so it can show separate sections."
                )
            ],
            naturalAlternatives: []
        )
    }
}

struct PhraseExplanation: Identifiable, Equatable {
    let id = UUID()
    let phrase: String
    let contextTranslations: [String]
    let meaning: String
    let contextualMeaning: String
    let tone: String
    let example: String

    static let sampleLearningItem =
        PhraseExplanation(
            phrase: "on the same page",
            contextTranslations: [
                "auf dem gleichen Stand sein",
                "dasselbe Verständnis haben"
            ],
            meaning: "Sharing the same understanding.",
            contextualMeaning: "The speaker wants alignment before moving forward.",
            tone: "Friendly and professional.",
            example: "I want to make sure we're on the same page before I send the proposal."
        )

    static let samplePhrases = [
        PhraseExplanation(
            phrase: "blocker",
            contextTranslations: [
                "etwas, das uns aufhält",
                "ein Problem, das erst gelöst werden muss",
                "Hindernis"
            ],
            meaning: "Something that prevents progress.",
            contextualMeaning: "The issue needs attention before work can continue.",
            tone: "Direct, common in technical teams.",
            example: "The missing API key is the only blocker right now."
        )
    ]

    static func fromModelResponse(_ response: String, fallbackWord: String) -> PhraseExplanation {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = jsonText.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(AIWordExplanation.self, from: data) {
            return PhraseExplanation(
                phrase: fallbackWord,
                contextTranslations: decoded.contextTranslations,
                meaning: decoded.meaning,
                contextualMeaning: decoded.contextualMeaning,
                tone: decoded.tone,
                example: decoded.example
            )
        }

        return PhraseExplanation(
            phrase: fallbackWord,
            contextTranslations: [],
            meaning: trimmed,
            contextualMeaning: "The local model returned an unstructured response.",
            tone: "Ask again or try a stronger local model for cleaner structure.",
            example: "The generated response above is preserved as-is."
        )
    }
}

struct ComposerOutputs {
    let casual: String
    let neutral: String
    let professional: String

    static let empty = ComposerOutputs(casual: "", neutral: "", professional: "")

    var hasContent: Bool {
        !casual.isEmpty || !neutral.isEmpty || !professional.isEmpty
    }

    static func fromModelResponse(_ response: String) -> ComposerOutputs {
        let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonText = trimmed
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let data = jsonText.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(AIComposerOutput.self, from: data) {
            return ComposerOutputs(
                casual: decoded.casual,
                neutral: decoded.neutral,
                professional: decoded.professional
            )
        }

        return ComposerOutputs(
            casual: trimmed,
            neutral: "The local model returned an unstructured response.",
            professional: "Ask again or try a stronger local model for cleaner structure."
        )
    }
}

private extension Array where Element == String {
    var cleanedContextTranslations: [String] {
        Array(
            self
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)
        )
    }
}

enum SampleText {
    static let defaultSourceText = "Let's circle back tomorrow so we are on the same page and can remove any blockers."
}

struct AssistantView: View {
    @ObservedObject var store: DiscoveryStore
    let mode: AssistantWindowMode

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("", selection: $store.selectedTab) {
                    ForEach(PrototypeTab.visibleCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .accessibilityLabel("Mode")
                .pickerStyle(.segmented)
                .frame(maxWidth: 360)
            }
            .padding(12)

            Divider()

            switch store.selectedTab {
            case .explain:
                ExplanationView(store: store)
            case .composer:
                ComposerView(store: store)
            case .review:
                WritingReviewView(store: store)
            case .learn:
                LearnView(store: store)
            case .settings:
                SettingsView(store: store)
            }
        }
        .frame(minWidth: mode.minSize.width, minHeight: mode.minSize.height)
        .assistantBackground(mode)
        .bubbleChromeAdjustment(mode)
        .task {
            await store.refreshOllamaModels()
        }
    }
}

enum PrototypeTab: String, CaseIterable, Identifiable {
    case explain
    case composer
    case review
    case learn
    case settings

    static let visibleCases: [PrototypeTab] = [.explain, .composer, .review, .settings]

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .composer: return "Composer"
        case .review: return "Review"
        case .learn: return "Learn"
        case .settings: return "Settings"
        }
    }
}

extension View {
    @ViewBuilder
    func assistantBackground(_ mode: AssistantWindowMode) -> some View {
        if mode.usesTranslucentBackground {
            self.background {
                VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            }
        } else {
            self.background(Color(nsColor: .windowBackgroundColor))
        }
    }

    @ViewBuilder
    func bubbleChromeAdjustment(_ mode: AssistantWindowMode) -> some View {
        if mode.hidesTitleBar {
            self.ignoresSafeArea(.container, edges: .top)
        } else {
            self
        }
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
    }
}

enum PrototypeSurface {
    static let background = Color.black.opacity(0.1)
}

enum AssistantWindowMode {
    case normal
    case bubble

    var initialSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 760, height: 560)
        case .bubble:
            return NSSize(width: 680, height: 500)
        }
    }

    var minSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 700, height: 440)
        case .bubble:
            return NSSize(width: 560, height: 420)
        }
    }

    var maxSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 1200, height: 900)
        case .bubble:
            return NSSize(width: 920, height: 760)
        }
    }

    var title: String {
        switch self {
        case .normal:
            return "Context Translate POC"
        case .bubble:
            return "Context Translate POC"
        }
    }

    var autosaveName: String? {
        switch self {
        case .normal:
            return "ContextDiscovery.AssistantPanel"
        case .bubble:
            return nil
        }
    }

    var styleMask: NSWindow.StyleMask {
        switch self {
        case .normal:
            return [.titled, .closable, .resizable, .fullSizeContentView]
        case .bubble:
            return [.titled, .resizable, .fullSizeContentView]
        }
    }

    var hidesTitleBar: Bool {
        switch self {
        case .normal:
            return false
        case .bubble:
            return true
        }
    }

    var persistedSizeKey: String? {
        switch self {
        case .normal:
            return nil
        case .bubble:
            return "ContextDiscovery.BubblePanel.size"
        }
    }

    var usesTranslucentBackground: Bool {
        switch self {
        case .normal:
            return false
        case .bubble:
            return true
        }
    }

    var collectionBehavior: NSWindow.CollectionBehavior {
        [.moveToActiveSpace, .fullScreenAuxiliary]
    }
}

struct ExplanationView: View {
    @ObservedObject var store: DiscoveryStore

    private let textPaneWidthKey = "ContextDiscovery.ExplainTextPaneWidth"

    var body: some View {
        AppKitSplitView(
            minLeadingWidth: 280,
            minTrailingWidth: 240,
            defaultLeadingWidth: 360,
            persistedLeadingWidthKey: textPaneWidthKey
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ClickableOriginalText(store: store)
                    TranslationSectionView(store: store)
                }
                .padding(18)
            }
        } trailing: {
            PhraseDetailView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct AppKitSplitView<Leading: View, Trailing: View>: NSViewRepresentable {
    let minLeadingWidth: CGFloat
    let minTrailingWidth: CGFloat
    let defaultLeadingWidth: CGFloat
    let persistedLeadingWidthKey: String
    let leading: Leading
    let trailing: Trailing

    init(
        minLeadingWidth: CGFloat,
        minTrailingWidth: CGFloat,
        defaultLeadingWidth: CGFloat,
        persistedLeadingWidthKey: String,
        @ViewBuilder leading: () -> Leading,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.minLeadingWidth = minLeadingWidth
        self.minTrailingWidth = minTrailingWidth
        self.defaultLeadingWidth = defaultLeadingWidth
        self.persistedLeadingWidthKey = persistedLeadingWidthKey
        self.leading = leading()
        self.trailing = trailing()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            minLeadingWidth: minLeadingWidth,
            minTrailingWidth: minTrailingWidth,
            defaultLeadingWidth: defaultLeadingWidth,
            persistedLeadingWidthKey: persistedLeadingWidthKey
        )
    }

    func makeNSView(context: Context) -> SeparatorSplitView {
        let splitView = SeparatorSplitView()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.delegate = context.coordinator

        let leadingView = NSHostingView(rootView: leading)
        let trailingView = NSHostingView(rootView: trailing)
        leadingView.translatesAutoresizingMaskIntoConstraints = false
        trailingView.translatesAutoresizingMaskIntoConstraints = false

        splitView.addArrangedSubview(leadingView)
        splitView.addArrangedSubview(trailingView)
        context.coordinator.leadingView = leadingView
        context.coordinator.trailingView = trailingView

        DispatchQueue.main.async {
            context.coordinator.applyInitialPositionIfPossible(to: splitView)
        }

        return splitView
    }

    func updateNSView(_ splitView: SeparatorSplitView, context: Context) {
        context.coordinator.leadingView?.rootView = leading
        context.coordinator.trailingView?.rootView = trailing
        context.coordinator.applyInitialPositionIfPossible(to: splitView)
    }

    final class Coordinator: NSObject, NSSplitViewDelegate {
        let minLeadingWidth: CGFloat
        let minTrailingWidth: CGFloat
        let defaultLeadingWidth: CGFloat
        let persistedLeadingWidthKey: String
        var didApplyInitialPosition = false
        var leadingView: NSHostingView<Leading>?
        var trailingView: NSHostingView<Trailing>?

        init(
            minLeadingWidth: CGFloat,
            minTrailingWidth: CGFloat,
            defaultLeadingWidth: CGFloat,
            persistedLeadingWidthKey: String
        ) {
            self.minLeadingWidth = minLeadingWidth
            self.minTrailingWidth = minTrailingWidth
            self.defaultLeadingWidth = defaultLeadingWidth
            self.persistedLeadingWidthKey = persistedLeadingWidthKey
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMinCoordinate proposedMinimumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int
        ) -> CGFloat {
            minLeadingWidth
        }

        func splitView(
            _ splitView: NSSplitView,
            constrainMaxCoordinate proposedMaximumPosition: CGFloat,
            ofSubviewAt dividerIndex: Int
        ) -> CGFloat {
            max(minLeadingWidth, splitView.bounds.width - minTrailingWidth - splitView.dividerThickness)
        }

        func splitViewDidResizeSubviews(_ notification: Notification) {
            guard let splitView = notification.object as? NSSplitView else {
                return
            }

            if !didApplyInitialPosition {
                applyInitialPositionIfPossible(to: splitView)
                return
            }

            saveLeadingWidth(from: splitView)
        }

        func applyInitialPositionIfPossible(to splitView: NSSplitView) {
            guard !didApplyInitialPosition,
                  splitView.bounds.width > minLeadingWidth + minTrailingWidth + splitView.dividerThickness else {
                return
            }

            didApplyInitialPosition = true
            splitView.setPosition(constrainedLeadingWidth(for: splitView), ofDividerAt: 0)
            saveLeadingWidth(from: splitView)
        }

        private func constrainedLeadingWidth(for splitView: NSSplitView) -> CGFloat {
            let savedWidth = UserDefaults.standard.double(forKey: persistedLeadingWidthKey)
            let preferredWidth = savedWidth > 0 ? CGFloat(savedWidth) : defaultLeadingWidth
            let maxLeadingWidth = splitView.bounds.width - minTrailingWidth - splitView.dividerThickness
            return min(max(preferredWidth, minLeadingWidth), maxLeadingWidth)
        }

        private func saveLeadingWidth(from splitView: NSSplitView) {
            guard let leadingView = splitView.arrangedSubviews.first else {
                return
            }

            UserDefaults.standard.set(Double(leadingView.frame.width), forKey: persistedLeadingWidthKey)
        }
    }
}

final class SeparatorSplitView: NSSplitView {
    override var dividerColor: NSColor {
        .separatorColor
    }

    override var dividerThickness: CGFloat {
        1
    }
}

struct TranslationSectionView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("\(store.myLanguage.name) Translation")
                    .font(.headline)
                Spacer()
                if store.isGeneratingTranslation {
                    Button {
                        store.stopTranslation()
                    } label: {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Stop translation")
                } else {
                    Button {
                        store.regenerateTranslation()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .disabled(!store.isActiveProviderConfigured)
                    .help("Refresh translation")
                }
            }

            Text(translationText)
                .font(.body)
                .foregroundStyle(store.translatedText.isEmpty ? Color.secondary.opacity(0.65) : Color.primary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrototypeSurface.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(store.translationStatusMessage)
                Text(store.captureStatusMessage)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var translationText: String {
        if store.isGeneratingTranslation && store.translatedText.isEmpty {
            return "Loading..."
        }

        if store.translatedText.isEmpty {
            return store.translationStatusMessage
        }

        return store.translatedText
    }
}

struct ClickableOriginalText: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text("Original")
                    .font(.headline)
                Spacer()
                Button("Recapture") {
                    store.replaceCapturedText(TextCaptureService.captureText())
                }
                .buttonStyle(.borderless)
            }
            WrappingWords(
                tokens: store.wordTokens,
                selectedTokenID: store.selectedTokenID
            ) { token in
                store.selectWord(token)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrototypeSurface.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct WrappingWords: View {
    let tokens: [WordToken]
    let selectedTokenID: Int?
    let onSelect: (WordToken) -> Void

    var body: some View {
        WordWrapLayout(horizontalSpacing: 0, verticalSpacing: 3) {
            ForEach(tokens) { token in
                WordButton(
                    token: token,
                    isSelected: token.id == selectedTokenID
                ) {
                    onSelect(token)
                }
            }
        }
    }
}

struct WordButton: View {
    let token: WordToken
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onSelect) {
            Text(token.text)
                .font(.body)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .fixedSize()
        }
        .buttonStyle(.plain)
        .help("Explain \(token.normalized)")
        .onHover { isHovered = $0 }
    }

    private var background: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(Color.accentColor)
        }
        if isHovered {
            return AnyShapeStyle(Color.accentColor.opacity(0.14))
        }
        return AnyShapeStyle(Color.clear)
    }
}

struct WordWrapLayout: Layout {
    var horizontalSpacing: CGFloat
    var verticalSpacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let width = proposal.width ?? rows.map(\.width).max() ?? 0
        let height = rows.reduce(CGFloat.zero) { partial, row in
            partial + row.height
        } + CGFloat(max(rows.count - 1, 0)) * verticalSpacing

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY

        for row in rows {
            var x = bounds.minX

            for item in row.items {
                item.subview.place(
                    at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + horizontalSpacing
            }

            y += row.height + verticalSpacing
        }
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [WordWrapRow] {
        var rows: [WordWrapRow] = []
        var currentItems: [WordWrapItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            let spacing = currentItems.isEmpty ? 0 : horizontalSpacing
            let proposedWidth = currentWidth + spacing + size.width

            if !currentItems.isEmpty && proposedWidth > maxWidth {
                rows.append(WordWrapRow(items: currentItems, width: currentWidth, height: currentHeight))
                currentItems = [WordWrapItem(subview: subview, size: size)]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentItems.append(WordWrapItem(subview: subview, size: size))
                currentWidth = proposedWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        if !currentItems.isEmpty {
            rows.append(WordWrapRow(items: currentItems, width: currentWidth, height: currentHeight))
        }

        return rows
    }
}

private struct WordWrapItem {
    let subview: LayoutSubviews.Element
    let size: CGSize
}

private struct WordWrapRow {
    let items: [WordWrapItem]
    let width: CGFloat
    let height: CGFloat
}

struct PhraseDetailView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        Group {
            if let selectedWordText = store.selectedWordText {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .center) {
                        Text(selectedWordText)
                            .font(.system(size: 24, weight: .semibold))

                        Spacer()

                        if store.isGeneratingDetail {
                            Button {
                                store.stopDetail()
                            } label: {
                                Image(systemName: "stop.fill")
                            }
                            .buttonStyle(.borderless)
                            .help("Stop explanation")
                        } else {
                            Button {
                                store.regenerateSelectedDetail()
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                            .buttonStyle(.borderless)
                            .disabled(!store.isActiveProviderConfigured)
                            .help("Refresh explanation")
                        }
                    }

                    contextTranslationsDetail(
                        store.selectedPhrase?.contextTranslations ?? [],
                        isPlaceholder: store.selectedPhrase == nil
                    )
                    detail("Meaning", store.selectedPhrase?.meaning ?? placeholderText, isPlaceholder: store.selectedPhrase == nil)
                    detail("In this context", store.selectedPhrase?.contextualMeaning ?? placeholderText, isPlaceholder: store.selectedPhrase == nil)
                    detail("Tone", store.selectedPhrase?.tone ?? placeholderText, isPlaceholder: store.selectedPhrase == nil)
                    detail("Example", store.selectedPhrase?.example ?? placeholderText, isPlaceholder: store.selectedPhrase == nil)

                    if !store.detailStatusMessage.isEmpty {
                        Text(store.detailStatusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Spacer()
                    Text("Click a word to explain it")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text("No explanation is preselected. This is closer to the desired interaction: the user chooses what confused them after seeing the translation.")
                        .font(.system(size: 11))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .opacity(0.6)
                        .frame(maxWidth: 260)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(18)
    }

    private var placeholderText: String {
        store.isGeneratingDetail ? "Loading..." : store.detailStatusMessage
    }

    private func detail(_ title: String, _ value: String, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .foregroundStyle(isPlaceholder ? Color.secondary.opacity(0.65) : Color.primary)
                .textSelection(.enabled)
        }
    }

    private func contextTranslationsDetail(_ translations: [String], isPlaceholder: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Context translation")
                .font(.caption)
                .foregroundStyle(.secondary)

            if isPlaceholder {
                Text(placeholderText)
                    .foregroundStyle(Color.secondary.opacity(0.65))
                    .textSelection(.enabled)
            } else if translations.isEmpty {
                Text("No context translation returned.")
                    .foregroundStyle(Color.secondary.opacity(0.65))
                    .textSelection(.enabled)
            } else {
                Text(translations.prefix(3).joined(separator: ", "))
                    .textSelection(.enabled)
            }
        }
    }
}

struct ComposerView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Write a thought in \(store.myLanguage.name)")
                .font(.headline)

            composerInputRow

            Text(store.composerStatusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            if store.composerOutputs.hasContent || store.isGeneratingComposer {
                output("Casual", outputText(store.composerOutputs.casual), isPlaceholder: !store.composerOutputs.hasContent)
                output("Neutral", outputText(store.composerOutputs.neutral), isPlaceholder: !store.composerOutputs.hasContent)
                output("Professional", outputText(store.composerOutputs.professional), isPlaceholder: !store.composerOutputs.hasContent)
            }

            Spacer()
        }
        .padding(18)
    }

    private var composerInputRow: some View {
        HStack(spacing: 8) {
            TextField("", text: $store.composerInput)
                .font(.body)
                .textFieldStyle(.plain)
                .onSubmit {
                    if !store.composerInputText.isEmpty {
                        store.compose()
                    }
                }

            if store.isGeneratingComposer {
                Button("Stop") {
                    store.stopComposer()
                }
                .buttonStyle(.borderless)
            } else {
                Button(store.composerActionTitle) {
                    store.compose()
                }
                .buttonStyle(.borderless)
                .disabled(store.composerInputText.isEmpty)
            }
        }
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .frame(height: 34)
        .background(PrototypeSurface.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor))
        )
    }

    private func outputText(_ text: String) -> String {
        if store.isGeneratingComposer && text.isEmpty {
            return "Loading..."
        }

        return text
    }

    private func output(_ title: String, _ text: String, isPlaceholder: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .top, spacing: 6) {
                Text(text)
                    .foregroundStyle(isPlaceholder ? Color.secondary.opacity(0.65) : Color.primary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    ClipboardWriter.copy(text)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .disabled(isPlaceholder || text.isEmpty)
                .help("Copy \(title.lowercased()) variant")
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrototypeSurface.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct WritingReviewView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Review your \(store.theirLanguage.name)")
                    .font(.headline)

                input("\(store.theirLanguage.name) sentence", text: $store.reviewSentence, height: 42)
                input("What you meant (optional)", text: $store.reviewIntent, height: 72)

                HStack {
                    Text(store.reviewStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if store.isGeneratingReview {
                        Button("Stop") {
                            store.stopReview()
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button(store.reviewActionTitle) {
                            store.reviewWriting()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.reviewSentenceText.isEmpty)
                    }
                }

                if store.reviewFeedback != nil || store.isGeneratingReview {
                    ReviewFeedbackView(
                        feedback: store.reviewFeedback,
                        isLoading: store.isGeneratingReview
                    )
                }

                Spacer(minLength: 0)
            }
            .padding(18)
        }
    }

    private func input(_ title: String, text: Binding<String>, height: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextEditor(text: text)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(height: height)
                .background(PrototypeSurface.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor))
                )
        }
    }
}

struct ReviewFeedbackView: View {
    let feedback: ReviewFeedback?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                reviewBlock("Rating", feedback?.rating ?? placeholder)
                reviewBlock("Score", feedback?.score ?? placeholder)
            }

            reviewBlock(
                "Suggested version",
                feedback?.correctedSentence ?? placeholder,
                canCopy: feedback?.correctedSentence.isEmpty == false
            )

            reviewBlock("What works", feedback?.whatWorks ?? placeholder)

            improvementsSection
            alternativesSection
        }
    }

    private var placeholder: String {
        isLoading ? "Loading..." : ""
    }

    private var improvementsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Improvements")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let improvements = feedback?.improvements, !improvements.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(improvements) { improvement in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(improvement.issue)
                                .font(.body.weight(.semibold))
                            Text(improvement.suggestion)
                            Text(improvement.why)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrototypeSurface.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                reviewCard(placeholder)
            }
        }
    }

    private var alternativesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Alternatives")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let alternatives = feedback?.naturalAlternatives, !alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(alternatives.enumerated()), id: \.offset) { _, alternative in
                        HStack(alignment: .top, spacing: 6) {
                            Text(alternative)
                                .textSelection(.enabled)
                            Button {
                                ClipboardWriter.copy(alternative)
                            } label: {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.borderless)
                            .help("Copy alternative")
                        }
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrototypeSurface.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                reviewCard(placeholder)
            }
        }
    }

    private func reviewBlock(_ title: String, _ value: String, canCopy: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            reviewCard(value, canCopy: canCopy)
        }
    }

    private func reviewCard(_ value: String, canCopy: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(value)
                .foregroundStyle(feedback == nil ? Color.secondary.opacity(0.65) : Color.primary)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
            if canCopy {
                Button {
                    ClipboardWriter.copy(value)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("Copy suggested version")
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PrototypeSurface.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                warnings

                settingsSection("App") {
                    Toggle(
                        "Show Translator in menu bar",
                        isOn: Binding(
                            get: { store.showsMenuBarItem },
                            set: { store.setShowsMenuBarItem($0) }
                        )
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(store.shortcutRecordingStatus)
                                .foregroundStyle(store.isRecordingShortcut ? .primary : .secondary)
                            Spacer()
                            if store.isRecordingShortcut {
                                Button("Cancel") {
                                    store.cancelShortcutRecording()
                                }
                            } else {
                                Button("Record Shortcut") {
                                    store.beginShortcutRecording()
                                }
                            }
                        }

                        Text("This shortcut opens the floating popover from the current selection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(PrototypeSurface.background)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                settingsSection("Languages") {
                    Picker(
                        "Mine",
                        selection: Binding(
                            get: { store.myLanguage },
                            set: { store.selectMyLanguage($0) }
                        )
                    ) {
                        ForEach(LanguageOption.allCases) { language in
                            Text(language.name).tag(language)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Theirs",
                        selection: Binding(
                            get: { store.theirLanguage },
                            set: { store.selectTheirLanguage($0) }
                        )
                    ) {
                        ForEach(LanguageOption.allCases) { language in
                            Text(language.name).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }

                aiProviderSection
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var warnings: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !store.isAccessibilityGranted {
                warningBox(
                    title: "Accessibility is not granted",
                    message: "Direct selected-text capture and selection-position popovers need Accessibility permission.",
                    actionTitle: "Open Settings",
                    action: store.openAccessibilitySettings
                )
            }

            if let modelWarning = store.activeProviderConfigurationWarning {
                warningBox(
                    title: store.selectedProvider == .appleIntelligence ? "Apple Intelligence is not ready" : "No model configured",
                    message: modelWarning,
                    actionTitle: nil,
                    action: nil
                )
            }
        }
    }

    private var aiProviderSection: some View {
        settingsSection("AI Provider") {
            Picker(
                "",
                selection: Binding(
                    get: { store.selectedProvider },
                    set: { store.selectProvider($0) }
                )
            ) {
                ForEach(AIProvider.allCases) { provider in
                    Text(provider.name).tag(provider)
                }
            }
            .accessibilityLabel("AI Provider")
            .pickerStyle(.segmented)

            Text(providerPrivacyMessage)
                .font(.caption)
                .foregroundStyle(.secondary)

            switch store.selectedProvider {
            case .ollama:
                ollamaSettings
            case .openRouter:
                openRouterSettings
            case .appleIntelligence:
                appleIntelligenceSettings
            }
        }
    }

    private var ollamaSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ollama keeps prototype AI calls local for privacy.")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Refresh Models") {
                    Task {
                        await store.refreshOllamaModels()
                    }
                }
            }

            Text(store.ollamaStatusMessage)
                .font(.callout)
                .foregroundStyle(store.ollamaModels.isEmpty ? .secondary : .primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(PrototypeSurface.background)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if store.isCheckingOllama {
                ProgressView("Checking Ollama...")
            } else if !store.ollamaModels.isEmpty {
                Picker(
                    "Model",
                    selection: Binding(
                        get: { store.selectedOllamaModel },
                        set: { store.selectOllamaModel($0) }
                    )
                ) {
                    ForEach(store.ollamaModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)

                Text("Selected model is persisted with UserDefaults for this prototype.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Start Ollama, then refresh models.")
                    Text("Example: `ollama run llama3.2`")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var openRouterSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("OpenRouter sends selected text to OpenRouter and the upstream model provider you choose.")
                .foregroundStyle(.secondary)

            SecureField("OpenRouter API key", text: $store.openRouterAPIKeyInput)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("Save Key") {
                    store.saveOpenRouterAPIKey()
                }
                .disabled(store.openRouterAPIKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button("Forget Key") {
                    store.forgetOpenRouterAPIKey()
                }
                .disabled(!store.hasOpenRouterAPIKey)

                Spacer()

                Text(store.hasOpenRouterAPIKey ? "Key stored in Keychain" : "No key stored")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                TextField(
                    "Model ID",
                    text: Binding(
                        get: { store.selectedOpenRouterModel },
                        set: { store.selectOpenRouterModel($0) }
                    )
                )
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    store.applyOpenRouterModelSelection()
                }

                Button("Use Model") {
                    store.applyOpenRouterModelSelection()
                }
                .disabled(store.selectedOpenRouterModelText.isEmpty)
            }

            HStack {
                Text(store.openRouterStatusMessage)
                    .font(.callout)
                    .foregroundStyle(store.hasOpenRouterAPIKey ? .primary : .secondary)
                Spacer()
                if store.isTestingOpenRouter {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Test Connection") {
                        Task {
                            await store.testOpenRouterConnection()
                        }
                    }
                    .disabled(!store.hasOpenRouterAPIKey || store.selectedOpenRouterModelText.isEmpty)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrototypeSurface.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var appleIntelligenceSettings: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apple Intelligence runs on this Mac when available. It needs supported hardware, enabled system settings, ready local models, and installed translation languages. To install languages, open System Settings > General > Language & Region > Translation Languages, then download both Mine and Theirs.")
                .foregroundStyle(.secondary)

            HStack {
                Text(store.appleIntelligenceStatusMessage)
                    .font(.callout)
                    .foregroundStyle(store.appleIntelligenceReadiness.isReady ? .primary : .secondary)
                Spacer()
                if store.isTestingAppleIntelligence {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button("Test Apple Intelligence") {
                        Task {
                            await store.testAppleIntelligence()
                        }
                    }
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PrototypeSurface.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if store.appleIntelligenceReadiness.isReady {
                Text("Apple Intelligence can now be used for Explain, Composer, and Review.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Apple Intelligence cannot generate responses until this test passes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }


    private func settingsSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
    }

    private func warningBox(
        title: String,
        message: String,
        actionTitle: String?,
        action: (() -> Void)?
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yellow.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var providerPrivacyMessage: String {
        switch store.selectedProvider {
        case .ollama:
            return "Ollama keeps model calls local on this Mac."
        case .openRouter:
            return "OpenRouter uses cloud models. Selected text and prompts leave this Mac."
        case .appleIntelligence:
            return "Apple Intelligence uses Apple on-device features when this Mac is eligible and ready."
        }
    }
}

struct LearnView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Learning Bucket")
                .font(.headline)
            Text("In-memory only. This is here to feel the review surface, not to design persistence yet.")
                .foregroundStyle(.secondary)

            List(store.savedPhrases) { phrase in
                VStack(alignment: .leading, spacing: 5) {
                    Text(phrase.phrase)
                        .font(.headline)
                    Text(phrase.contextualMeaning)
                        .foregroundStyle(.secondary)
                    Text("Practice again: soon")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
    }
}

struct FlowLayout<Item: Identifiable, Content: View>: View {
    let items: [Item]
    let content: (Item) -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

final class AssistantPanel: NSPanel {
    override func cancelOperation(_ sender: Any?) {
        close()
    }
}

enum ClipboardWriter {
    static func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

enum TextCaptureSource {
    case accessibility
    case temporaryCopyRestore
    case clipboard
    case sample

    var statusMessage: String {
        switch self {
        case .accessibility:
            return "Captured from selection via Accessibility."
        case .temporaryCopyRestore:
            return "Captured from selection via temporary copy-restore."
        case .clipboard:
            return "Captured from clipboard fallback."
        case .sample:
            return "Showing sample text."
        }
    }
}

struct TextCaptureResult {
    let text: String
    let source: TextCaptureSource

    var statusMessage: String {
        source.statusMessage
    }
}

enum TextCaptureService {
    static func captureText() -> TextCaptureResult {
        if let text = accessibilitySelectedText() {
            return TextCaptureResult(text: text, source: .accessibility)
        }

        if let text = temporaryCopyRestoreSelectedText() {
            return TextCaptureResult(text: text, source: .temporaryCopyRestore)
        }

        if let text = clipboardText() {
            return TextCaptureResult(text: text, source: .clipboard)
        }

        return TextCaptureResult(text: SampleText.defaultSourceText, source: .sample)
    }

    private static func accessibilitySelectedText() -> String? {
        guard AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        var focusedValue: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard focusedStatus == .success,
              let focusedElement = focusedValue,
              CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return nil
        }

        var selectedValue: CFTypeRef?
        let selectedStatus = AXUIElementCopyAttributeValue(
            (focusedElement as! AXUIElement),
            kAXSelectedTextAttribute as CFString,
            &selectedValue
        )

        guard selectedStatus == .success,
              let selectedText = selectedValue as? String else {
            return nil
        }

        return nonEmpty(selectedText)
    }

    private static func temporaryCopyRestoreSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let previousItems = clonePasteboardItems(pasteboard.pasteboardItems ?? [])
        let previousChangeCount = pasteboard.changeCount

        sendCopyShortcut()

        let deadline = Date().addingTimeInterval(0.35)
        while Date() < deadline && pasteboard.changeCount == previousChangeCount {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.03))
        }

        let didCopySelection = pasteboard.changeCount != previousChangeCount
        let copiedText = didCopySelection ? nonEmpty(pasteboard.string(forType: .string)) : nil

        pasteboard.clearContents()
        if !previousItems.isEmpty {
            pasteboard.writeObjects(previousItems)
        }

        return copiedText
    }

    private static func clipboardText() -> String? {
        nonEmpty(NSPasteboard.general.string(forType: .string))
    }

    private static func nonEmpty(_ text: String?) -> String? {
        guard let text else {
            return nil
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : text
    }

    private static func sendCopyShortcut() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            return
        }

        let keyCode = CGKeyCode(kVK_ANSI_C)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private static func clonePasteboardItems(_ items: [NSPasteboardItem]) -> [NSPasteboardItem] {
        items.map { item in
            let clone = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    clone.setData(data, forType: type)
                } else if let string = item.string(forType: type) {
                    clone.setString(string, forType: type)
                }
            }
            return clone
        }
    }
}

enum SelectionGeometryReader {
    static func selectedTextAnchor() -> NSPoint? {
        guard AXIsProcessTrusted(),
              let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        guard let focusedElement = focusedElement(in: appElement),
              let selectedRange = selectedTextRange(in: focusedElement),
              let bounds = bounds(for: selectedRange, in: focusedElement) else {
            return nil
        }

        return NSPoint(x: bounds.maxX, y: bounds.minY)
    }

    private static func focusedElement(in appElement: AXUIElement) -> AXUIElement? {
        var focusedValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard status == .success,
              let focusedValue,
              CFGetTypeID(focusedValue) == AXUIElementGetTypeID() else {
            return nil
        }

        return (focusedValue as! AXUIElement)
    }

    private static func selectedTextRange(in element: AXUIElement) -> AXValue? {
        var rangeValue: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &rangeValue
        )

        guard status == .success,
              let rangeValue,
              CFGetTypeID(rangeValue) == AXValueGetTypeID() else {
            return nil
        }

        return (rangeValue as! AXValue)
    }

    private static func bounds(for range: AXValue, in element: AXUIElement) -> CGRect? {
        var parameterizedValue: CFTypeRef?
        let status = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            range,
            &parameterizedValue
        )

        guard status == .success,
              let parameterizedValue,
              CFGetTypeID(parameterizedValue) == AXValueGetTypeID() else {
            return nil
        }

        var rect = CGRect.zero
        let value = parameterizedValue as! AXValue
        guard AXValueGetType(value) == .cgRect,
              AXValueGetValue(value, .cgRect, &rect),
              !rect.isEmpty else {
            return nil
        }

        return rect
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var normalPanel: NSPanel?
    private var bubblePanel: NSPanel?
    private var store: DiscoveryStore!
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?
    private var bubbleLocalEventMonitor: Any?
    private let firstLaunchCompletedKey = "ContextDiscovery.FirstLaunchCompleted"

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: firstLaunchCompletedKey)
        store = DiscoveryStore(capture: TextCaptureService.captureText())
        store.menuBarVisibilityDidChange = { [weak self] isVisible in
            Task { @MainActor in
                self?.setMenuBarVisible(isVisible)
            }
        }
        store.shortcutDidChange = { [weak self] _ in
            self?.registerHotKey()
        }
        setupApplicationMenu()
        NSApp.setActivationPolicy(.accessory)
        setMenuBarVisible(store.showsMenuBarItem)
        registerHotKey()
        if isFirstLaunch {
            UserDefaults.standard.set(true, forKey: firstLaunchCompletedKey)
            showAssistant(mode: .normal, recapture: false, selectedTab: .settings)
        } else {
            showAssistant(mode: .normal, recapture: false)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let hotKeyHandler {
            RemoveEventHandler(hotKeyHandler)
        }
        stopBubbleDismissMonitor()
    }

    @MainActor
    func applicationDidResignActive(_ notification: Notification) {
        closeBubblePanel()
    }

    @MainActor
    func windowWillClose(_ notification: Notification) {
        guard let closedPanel = notification.object as? NSPanel,
              closedPanel === bubblePanel else {
            return
        }

        stopBubbleDismissMonitor()
    }

    @MainActor
    func windowDidResize(_ notification: Notification) {
        guard let resizedPanel = notification.object as? NSPanel,
              resizedPanel === bubblePanel else {
            return
        }

        saveBubbleSize(resizedPanel.frame.size)
    }

    @MainActor
    private func setupApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Context Translate POC", action: #selector(quit), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        let closeWindowItem = NSMenuItem(title: "Close Window", action: #selector(closeActiveAssistantWindow), keyEquivalent: "w")
        closeWindowItem.target = self
        fileMenu.addItem(closeWindowItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(.separator())
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @MainActor
    private func setMenuBarVisible(_ isVisible: Bool) {
        if isVisible {
            setupMenuBar()
        } else if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    @MainActor
    private func setupMenuBar() {
        guard statusItem == nil else {
            statusItem?.button?.title = "Translator"
            return
        }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Translator"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Assistant", action: #selector(openAssistant), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Recapture Text", action: #selector(recaptureText), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    @MainActor
    @objc private func openAssistant() {
        showAssistant(mode: .normal)
    }

    @MainActor
    @objc private func openSettings() {
        showAssistant(mode: .normal, recapture: false, selectedTab: .settings)
    }

    @MainActor
    @objc private func recaptureText() {
        showAssistant(mode: .normal)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    @objc private func closeActiveAssistantWindow() {
        if let keyWindow = NSApp.keyWindow as? NSPanel,
           keyWindow === normalPanel || keyWindow === bubblePanel {
            keyWindow.close()
            return
        }

        if let normalPanel, normalPanel.isVisible {
            normalPanel.close()
            return
        }

        closeBubblePanel()
    }

    @MainActor
    private func showAssistant(
        mode: AssistantWindowMode,
        recapture: Bool = true,
        selectedTab: PrototypeTab? = nil
    ) {
        if let selectedTab {
            store.selectedTab = selectedTab
        }

        if recapture {
            store.replaceCapturedText(TextCaptureService.captureText())
        }

        let panel = panel(for: mode)
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        switch mode {
        case .normal:
            closeBubblePanel()
        case .bubble:
            startBubbleDismissMonitor(for: panel)
        }
    }

    @MainActor
    private func panel(for mode: AssistantWindowMode) -> NSPanel {
        switch mode {
        case .normal:
            if let normalPanel {
                return normalPanel
            }

            let panel = makePanel(mode: .normal)
            if UserDefaults.standard.string(forKey: "NSWindow Frame ContextDiscovery.AssistantPanel") == nil {
                panel.center()
            }
            normalPanel = panel
            return panel
        case .bubble:
            if let bubblePanel {
                positionBubblePanel(bubblePanel)
                return bubblePanel
            }

            let panel = makePanel(mode: .bubble)
            positionBubblePanel(panel)
            bubblePanel = panel
            return panel
        }
    }

    @MainActor
    private func makePanel(mode: AssistantWindowMode) -> NSPanel {
        let panel = AssistantPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: mode.initialSize.width,
                height: mode.initialSize.height
            ),
            styleMask: mode.styleMask,
            backing: .buffered,
            defer: false
        )

        panel.title = mode.title
        panel.delegate = self
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.level = .floating
        panel.minSize = mode.minSize
        panel.maxSize = mode.maxSize
        panel.isOpaque = !mode.usesTranslucentBackground
        panel.backgroundColor = mode.usesTranslucentBackground ? .clear : .windowBackgroundColor
        if let autosaveName = mode.autosaveName {
            panel.setFrameAutosaveName(autosaveName)
        }
        panel.collectionBehavior = mode.collectionBehavior
        if mode.hidesTitleBar {
            panel.titleVisibility = .hidden
            panel.titlebarAppearsTransparent = true
            panel.standardWindowButton(.closeButton)?.isHidden = true
            panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            panel.standardWindowButton(.zoomButton)?.isHidden = true
        }
        panel.contentView = NSHostingView(rootView: AssistantView(store: store, mode: mode))
        return panel
    }

    @MainActor
    private func positionBubblePanel(_ panel: NSPanel) {
        let size = savedBubbleSize()
        let anchor = SelectionGeometryReader.selectedTextAnchor() ?? NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.visibleFrame.contains(anchor) } ?? NSScreen.main
        let visibleFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 900)
        let proposedOrigin = NSPoint(x: anchor.x + 12, y: anchor.y - size.height - 12)
        let origin = NSPoint(
            x: min(max(proposedOrigin.x, visibleFrame.minX), visibleFrame.maxX - size.width),
            y: min(max(proposedOrigin.y, visibleFrame.minY), visibleFrame.maxY - size.height)
        )

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func savedBubbleSize() -> NSSize {
        guard let key = AssistantWindowMode.bubble.persistedSizeKey,
              let size = UserDefaults.standard.string(forKey: key) else {
            return AssistantWindowMode.bubble.initialSize
        }

        let storedSize = NSSizeFromString(size)
        return constrainedBubbleSize(storedSize)
    }

    private func saveBubbleSize(_ size: NSSize) {
        guard let key = AssistantWindowMode.bubble.persistedSizeKey else {
            return
        }

        UserDefaults.standard.set(NSStringFromSize(constrainedBubbleSize(size)), forKey: key)
    }

    private func constrainedBubbleSize(_ size: NSSize) -> NSSize {
        let mode = AssistantWindowMode.bubble
        return NSSize(
            width: min(max(size.width, mode.minSize.width), mode.maxSize.width),
            height: min(max(size.height, mode.minSize.height), mode.maxSize.height)
        )
    }

    @MainActor
    private func startBubbleDismissMonitor(for panel: NSPanel) {
        stopBubbleDismissMonitor()
        bubbleLocalEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
        ) { [weak self, weak panel] event in
            guard let self,
                  let panel,
                  panel.isVisible else {
                return event
            }

            if event.window !== panel {
                self.closeBubblePanel()
            }

            return event
        }
    }

    @MainActor
    private func closeBubblePanel() {
        guard let bubblePanel,
              bubblePanel.isVisible else {
            stopBubbleDismissMonitor()
            return
        }

        bubblePanel.close()
    }

    @MainActor
    private func stopBubbleDismissMonitor() {
        if let bubbleLocalEventMonitor {
            NSEvent.removeMonitor(bubbleLocalEventMonitor)
            self.bubbleLocalEventMonitor = nil
        }
    }

    @MainActor
    private func registerHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        installHotKeyHandlerIfNeeded()

        let hotKeyID = EventHotKeyID(signature: "CTXT".fourCharCode, id: 1)
        let shortcut = store.globalShortcut

        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            NSLog("Context discovery hotkey registration failed: \(status)")
            return
        }
    }

    @MainActor
    private func installHotKeyHandlerIfNeeded() {
        guard hotKeyHandler == nil else {
            return
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if hotKeyID.id == 1 {
                    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                    Task { @MainActor in
                        delegate.showAssistant(mode: .bubble, selectedTab: .explain)
                    }
                }

                return noErr
            },
            1,
            &eventSpec,
            selfPointer,
            &hotKeyHandler
        )
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }

    var fourCharCode: FourCharCode {
        var result: FourCharCode = 0
        for scalar in unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

import AppKit
import ApplicationServices
import Carbon
import Foundation
import SwiftUI

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
    @Published var ollamaModels: [String]
    @Published var selectedOllamaModel: String
    @Published var myLanguage: LanguageOption
    @Published var theirLanguage: LanguageOption
    @Published var ollamaStatusMessage: String
    @Published var isCheckingOllama: Bool
    @Published var isGeneratingTranslation: Bool
    @Published var isGeneratingDetail: Bool
    @Published var isGeneratingComposer: Bool
    @Published var isGeneratingReview: Bool
    @Published var detailStatusMessage: String

    private let selectedModelKey = "ContextDiscovery.SelectedOllamaModel"
    private let myLanguageKey = "ContextDiscovery.MyLanguage"
    private let theirLanguageKey = "ContextDiscovery.TheirLanguage"
    private var selectedToken: WordToken?
    private var translationTask: Task<Void, Never>?
    private var detailTask: Task<Void, Never>?
    private var composerTask: Task<Void, Never>?
    private var reviewTask: Task<Void, Never>?
    private var lastGeneratedComposerInput: String?
    private var lastReviewedSentence: String?

    init(capture: TextCaptureResult) {
        let savedMyLanguage = LanguageOption.savedValue(forKey: myLanguageKey, fallback: .german)
        let savedTheirLanguage = LanguageOption.savedValue(forKey: theirLanguageKey, fallback: .english)

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
        self.ollamaModels = []
        self.selectedOllamaModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? ""
        self.ollamaStatusMessage = "Ollama has not been checked yet."
        self.isCheckingOllama = false
        self.isGeneratingTranslation = false
        self.isGeneratingDetail = false
        self.isGeneratingComposer = false
        self.isGeneratingReview = false
        self.detailStatusMessage = "Click a word to explain it."
    }

    var translatedText: String {
        germanTranslation
    }

    var modelMenuTitle: String {
        selectedOllamaModel.isEmpty ? "Ollama: None" : "Ollama: \(selectedOllamaModel)"
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

    func replaceCapturedText(_ capture: TextCaptureResult) {
        stopAIResponses()
        capturedText = capture.text.isEmpty ? SampleText.defaultSourceText : capture.text
        captureStatusMessage = capture.statusMessage
        selectedPhrase = nil
        selectedTokenID = nil
        selectedWordText = nil
        selectedToken = nil
        germanTranslation = ""
        translationStatusMessage = selectedOllamaModel.isEmpty ? "Choose a local Ollama model to translate." : "Ready to translate with \(selectedOllamaModel)."
        detailStatusMessage = "Click a word to explain it."
        if !selectedOllamaModel.isEmpty {
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

        if selectedOllamaModel.isEmpty {
            selectedPhrase = nil
            detailStatusMessage = "Choose a local Ollama model to explain this word."
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

        guard !selectedOllamaModel.isEmpty else {
            composerOutputs = .empty
            composerStatusMessage = "Choose a local Ollama model to compose."
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

        guard !selectedOllamaModel.isEmpty else {
            reviewFeedback = nil
            reviewStatusMessage = "Choose a local Ollama model to review your sentence."
            return
        }

        generateAIReview(sentence: sentence, intent: intent)
    }

    func selectOllamaModel(_ model: String) {
        selectedOllamaModel = model
        UserDefaults.standard.set(model, forKey: selectedModelKey)
        translationStatusMessage = "Selected \(model)."
        regenerateAIResponses()
    }

    func selectMyLanguage(_ language: LanguageOption) {
        myLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: myLanguageKey)
        translationStatusMessage = selectedOllamaModel.isEmpty ? "Choose a local Ollama model to translate." : "Ready to translate with \(selectedOllamaModel)."
        if !selectedOllamaModel.isEmpty {
            regenerateAIResponses()
        }
    }

    func selectTheirLanguage(_ language: LanguageOption) {
        theirLanguage = language
        UserDefaults.standard.set(language.rawValue, forKey: theirLanguageKey)
        reviewStatusMessage = "Write a \(language.name) sentence to review."
        translationStatusMessage = selectedOllamaModel.isEmpty ? "Choose a local Ollama model to translate." : "Ready to translate with \(selectedOllamaModel)."
        if !selectedOllamaModel.isEmpty {
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
        guard !selectedOllamaModel.isEmpty else {
            germanTranslation = ""
            translationStatusMessage = "Choose a local Ollama model to use real AI responses."
            return
        }

        generateAITranslation()
    }

    func regenerateSelectedDetail() {
        stopDetail()
        if let selectedToken {
            selectedPhrase = nil
            guard !selectedOllamaModel.isEmpty else {
                detailStatusMessage = "Choose a local Ollama model to explain this word."
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
        if !selectedOllamaModel.isEmpty {
            translationStatusMessage = "Stopped."
        }
    }

    func stopDetail() {
        detailTask?.cancel()
        detailTask = nil
        isGeneratingDetail = false
        if !selectedOllamaModel.isEmpty {
            detailStatusMessage = selectedWordText == nil ? "Click a word to explain it." : "Stopped."
        }
    }

    func stopComposer() {
        composerTask?.cancel()
        composerTask = nil
        isGeneratingComposer = false
        if !selectedOllamaModel.isEmpty {
            composerStatusMessage = "Stopped."
        }
    }

    func stopReview() {
        reviewTask?.cancel()
        reviewTask = nil
        isGeneratingReview = false
        if !selectedOllamaModel.isEmpty {
            reviewStatusMessage = "Stopped."
        }
    }

    private func generateAITranslation() {
        translationTask?.cancel()
        isGeneratingTranslation = true
        translationStatusMessage = "Translating with \(selectedOllamaModel)..."

        let prompt = """
        Translate this \(theirLanguage.name) sentence into natural \(myLanguage.name).
        Output only the \(myLanguage.name) translation. No notes, no alternatives, no markdown.

        \(theirLanguage.name) sentence:
        \(capturedText)
        """

        translationTask = Task {
            do {
                let response = try await askOllama(prompt: prompt)
                guard !Task.isCancelled else { return }
                germanTranslation = response
                translationStatusMessage = "Translated with \(selectedOllamaModel)."
            } catch is CancellationError {
                translationStatusMessage = "Translation stopped."
            } catch {
                germanTranslation = ""
                translationStatusMessage = "Could not reach Ollama. Check that the local server is running."
            }
            isGeneratingTranslation = false
            translationTask = nil
        }
    }

    private func generateAIDetail(for token: WordToken) {
        detailTask?.cancel()
        isGeneratingDetail = true
        detailStatusMessage = "Asking \(selectedOllamaModel)..."

        let prompt = """
        You are helping a \(myLanguage.speakerDescription) professional understand \(theirLanguage.name).
        Explain the selected word in the exact sentence context.
        Return valid JSON only. No markdown. No code fences.

        Required JSON shape:
        {
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
                let response = try await askOllama(prompt: prompt)
                guard !Task.isCancelled else { return }
                selectedPhrase = PhraseExplanation.fromModelResponse(response, fallbackWord: token.text)
                detailStatusMessage = "Generated with \(selectedOllamaModel)."
            } catch is CancellationError {
                detailStatusMessage = "Explanation stopped."
            } catch {
                selectedPhrase = nil
                detailStatusMessage = "Could not reach Ollama. Check that the local server is running."
            }
            isGeneratingDetail = false
            detailTask = nil
        }
    }

    private func generateAIComposerOutput(for input: String) {
        composerTask?.cancel()
        composerOutputs = .empty
        isGeneratingComposer = true
        composerStatusMessage = "Composing with \(selectedOllamaModel)..."

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
                let response = try await askOllama(prompt: prompt)
                guard !Task.isCancelled else { return }
                composerOutputs = ComposerOutputs.fromModelResponse(response)
                lastGeneratedComposerInput = input
                composerStatusMessage = "Composed with \(selectedOllamaModel)."
            } catch is CancellationError {
                composerStatusMessage = "Composition stopped."
            } catch {
                composerOutputs = .empty
                composerStatusMessage = "Could not reach Ollama. Check that the local server is running."
            }
            isGeneratingComposer = false
            composerTask = nil
        }
    }

    private func generateAIReview(sentence: String, intent: String) {
        reviewTask?.cancel()
        reviewFeedback = nil
        isGeneratingReview = true
        reviewStatusMessage = "Reviewing with \(selectedOllamaModel)..."

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
                let response = try await askOllama(prompt: prompt)
                guard !Task.isCancelled else { return }
                reviewFeedback = ReviewFeedback.fromModelResponse(response)
                lastReviewedSentence = sentence
                reviewStatusMessage = "Reviewed with \(selectedOllamaModel)."
            } catch is CancellationError {
                reviewStatusMessage = "Review stopped."
            } catch {
                reviewFeedback = nil
                reviewStatusMessage = "Could not reach Ollama. Check that the local server is running."
            }
            isGeneratingReview = false
            reviewTask = nil
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

    static func savedValue(forKey key: String, fallback: LanguageOption) -> LanguageOption {
        guard let rawValue = UserDefaults.standard.string(forKey: key),
              let language = LanguageOption(rawValue: rawValue) else {
            return fallback
        }

        return language
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

struct AIWordExplanation: Decodable {
    let meaning: String
    let contextualMeaning: String
    let tone: String
    let example: String
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
    let meaning: String
    let contextualMeaning: String
    let tone: String
    let example: String

    static let sampleLearningItem =
        PhraseExplanation(
            phrase: "on the same page",
            meaning: "Sharing the same understanding.",
            contextualMeaning: "The speaker wants alignment before moving forward.",
            tone: "Friendly and professional.",
            example: "I want to make sure we're on the same page before I send the proposal."
        )

    static let samplePhrases = [
        PhraseExplanation(
            phrase: "blocker",
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
                meaning: decoded.meaning,
                contextualMeaning: decoded.contextualMeaning,
                tone: decoded.tone,
                example: decoded.example
            )
        }

        return PhraseExplanation(
            phrase: fallbackWord,
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

enum SampleText {
    static let defaultSourceText = "Let's circle back tomorrow so we are on the same page and can remove any blockers."
}

struct AssistantView: View {
    @ObservedObject var store: DiscoveryStore
    let mode: AssistantWindowMode
    @State private var tab = PrototypeTab.explain

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Picker("", selection: $tab) {
                    ForEach(PrototypeTab.visibleCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .accessibilityLabel("Mode")
                .pickerStyle(.segmented)
                .frame(maxWidth: 260)

                Spacer()

                if mode.showsSettingsControls {
                    languageMenu("Mine", selection: store.myLanguage) { language in
                        store.selectMyLanguage(language)
                    }

                    languageMenu("Theirs", selection: store.theirLanguage) { language in
                        store.selectTheirLanguage(language)
                    }

                    modelMenu
                }
            }
            .padding(12)

            Divider()

            switch tab {
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
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await store.refreshOllamaModels()
        }
    }

    private var modelMenu: some View {
        Menu {
            Menu("Ollama") {
                Button("Refresh Models") {
                    Task {
                        await store.refreshOllamaModels()
                    }
                }

                Divider()

                if store.ollamaModels.isEmpty {
                    Text(store.isCheckingOllama ? "Checking..." : "No models found")
                } else {
                    ForEach(store.ollamaModels, id: \.self) { model in
                        Button(model) {
                            store.selectOllamaModel(model)
                        }
                    }
                }
            }
        } label: {
            Text(store.modelMenuTitle)
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
        .frame(maxWidth: 180)
    }

    private func languageMenu(
        _ title: String,
        selection: LanguageOption,
        onSelect: @escaping (LanguageOption) -> Void
    ) -> some View {
        Menu {
            ForEach(LanguageOption.allCases) { language in
                Button(language.name) {
                    onSelect(language)
                }
            }
        } label: {
            Text("\(title): \(selection.name)")
                .lineLimit(1)
        }
        .menuStyle(.borderlessButton)
    }
}

enum PrototypeTab: String, CaseIterable, Identifiable {
    case explain
    case composer
    case review
    case learn
    case settings

    static let visibleCases: [PrototypeTab] = [.explain, .composer, .review]

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

enum AssistantWindowMode {
    case normal
    case bubble

    var initialSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 760, height: 560)
        case .bubble:
            return NSSize(width: 560, height: 430)
        }
    }

    var minSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 700, height: 440)
        case .bubble:
            return NSSize(width: 520, height: 380)
        }
    }

    var maxSize: NSSize {
        switch self {
        case .normal:
            return NSSize(width: 1200, height: 900)
        case .bubble:
            return NSSize(width: 760, height: 640)
        }
    }

    var showsSettingsControls: Bool {
        switch self {
        case .normal:
            return true
        case .bubble:
            return false
        }
    }

    var title: String {
        switch self {
        case .normal:
            return "Context Discovery"
        case .bubble:
            return "Context"
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
}

struct ExplanationView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        HStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ClickableOriginalText(store: store)
                    TranslationSectionView(store: store)
                }
                .padding(18)
            }
            .frame(width: 360)

            Divider()

            PhraseDetailView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
                    .disabled(store.selectedOllamaModel.isEmpty)
                    .help("Refresh translation")
                }
            }

            Text(translationText)
                .font(.body)
                .foregroundStyle(store.translatedText.isEmpty ? Color.secondary.opacity(0.65) : Color.primary)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
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
            .background(Color(nsColor: .controlBackgroundColor))
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
                            .disabled(store.selectedOllamaModel.isEmpty)
                            .help("Refresh explanation")
                        }
                    }

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
            .background(Color(nsColor: .controlBackgroundColor))
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
                .frame(height: height)
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
                .background(Color(nsColor: .controlBackgroundColor))
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
                .background(Color(nsColor: .controlBackgroundColor))
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
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SettingsView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local AI")
                        .font(.headline)
                    Text("Ollama keeps prototype AI calls local for privacy.")
                        .foregroundStyle(.secondary)
                }
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
                .background(Color(nsColor: .controlBackgroundColor))
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

            Spacer()
        }
        .padding(18)
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

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        store = DiscoveryStore(capture: TextCaptureService.captureText())
        setupApplicationMenu()
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        registerHotKey()
        showAssistant(mode: .normal, recapture: false)
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
    private func setupApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Quit Context", action: #selector(quit), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

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
    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Context"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Assistant", action: #selector(openAssistant), keyEquivalent: "e"))
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
    @objc private func recaptureText() {
        showAssistant(mode: .normal)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func showAssistant(mode: AssistantWindowMode, recapture: Bool = true) {
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
        if let autosaveName = mode.autosaveName {
            panel.setFrameAutosaveName(autosaveName)
        }
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
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
        let size = AssistantWindowMode.bubble.initialSize
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

    private func registerHotKey() {
        let hotKeyID = EventHotKeyID(signature: "CTXT".fourCharCode, id: 1)
        let modifiers = UInt32(cmdKey | optionKey)
        let keyCode = UInt32(kVK_ANSI_E)

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            NSLog("Context discovery hotkey registration failed: \(status)")
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
                        delegate.showAssistant(mode: .bubble)
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

import AppKit
import Carbon
import Foundation
import SwiftUI

@MainActor
final class DiscoveryStore: ObservableObject {
    @Published var capturedText: String
    @Published var selectedPhrase: PhraseExplanation?
    @Published var selectedTokenID: Int?
    @Published var savedPhrases: [PhraseExplanation]
    @Published var composerInput: String
    @Published var composerOutputs: ComposerOutputs
    @Published var ollamaModels: [String]
    @Published var selectedOllamaModel: String
    @Published var ollamaStatusMessage: String
    @Published var isCheckingOllama: Bool
    @Published var isGeneratingAI: Bool
    @Published var aiExplanation: String?

    private let selectedModelKey = "ContextDiscovery.SelectedOllamaModel"

    init(capturedText: String) {
        self.capturedText = capturedText
        self.selectedPhrase = nil
        self.selectedTokenID = nil
        self.savedPhrases = [PhraseExplanation.sampleLearningItem]
        self.composerInput = "damit wir uns spaeter keine Steine in den Weg legen"
        self.composerOutputs = ComposerOutputs.generate(
            from: "damit wir uns spaeter keine Steine in den Weg legen"
        )
        self.ollamaModels = []
        self.selectedOllamaModel = UserDefaults.standard.string(forKey: selectedModelKey) ?? ""
        self.ollamaStatusMessage = "Ollama has not been checked yet."
        self.isCheckingOllama = false
        self.isGeneratingAI = false
        self.aiExplanation = nil
    }

    var translatedText: String {
        StubTranslator.translate(capturedText)
    }

    func replaceCapturedText(_ text: String) {
        capturedText = text.isEmpty ? StubTranslator.defaultSourceText : text
        selectedPhrase = nil
        selectedTokenID = nil
        aiExplanation = nil
    }

    var wordTokens: [WordToken] {
        WordToken.tokenize(capturedText)
    }

    func selectWord(_ token: WordToken) {
        selectedTokenID = token.id
        aiExplanation = nil
        selectedPhrase = PhraseExplanation.explain(word: token.normalized, visibleWord: token.text, context: capturedText)

        if !selectedOllamaModel.isEmpty {
            Task {
                await generateAIExplanation(for: token)
            }
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
        composerOutputs = ComposerOutputs.generate(from: composerInput)
    }

    func selectOllamaModel(_ model: String) {
        selectedOllamaModel = model
        UserDefaults.standard.set(model, forKey: selectedModelKey)
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

    func generateAIExplanation(for token: WordToken) async {
        guard !selectedOllamaModel.isEmpty else {
            aiExplanation = "Choose a local Ollama model in Settings to use real AI responses."
            return
        }

        isGeneratingAI = true
        defer { isGeneratingAI = false }

        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            aiExplanation = "Ollama URL is invalid."
            return
        }

        let prompt = """
        You are helping a German-speaking professional understand English.
        Explain the selected word in concise, practical language.

        Original sentence:
        \(capturedText)

        Selected word:
        \(token.text)

        Return:
        - Meaning
        - Meaning in this exact context
        - Tone/formality
        - One natural example sentence
        """

        let requestBody = OllamaGenerateRequest(
            model: selectedOllamaModel,
            prompt: prompt,
            stream: false
        )

        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(requestBody)

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                aiExplanation = "Ollama did not return a usable response."
                return
            }

            let result = try JSONDecoder().decode(OllamaGenerateResponse.self, from: data)
            aiExplanation = result.response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            aiExplanation = "Could not reach Ollama. Start Ollama, then refresh models in Settings."
        }
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

    static func explain(word: String, visibleWord: String, context: String) -> PhraseExplanation {
        switch word {
        case "circle":
            return PhraseExplanation(
                phrase: visibleWord,
                meaning: "As a verb, it can mean to move around something. In workplace English it often appears in the phrase 'circle back'.",
                contextualMeaning: "Here it probably belongs to 'circle back', meaning return to the topic later.",
                tone: "Workplace-friendly; slightly corporate.",
                example: "Let's circle back after lunch."
            )
        case "back":
            return PhraseExplanation(
                phrase: visibleWord,
                meaning: "Return, reverse direction, or support someone depending on context.",
                contextualMeaning: "With 'circle', it forms 'circle back': return to a topic later.",
                tone: "Neutral. The phrase 'circle back' is common in meetings.",
                example: "I'll get the numbers and circle back tomorrow."
            )
        case "blocker", "blockers":
            return PhraseExplanation(
                phrase: visibleWord,
                meaning: "Something that prevents progress.",
                contextualMeaning: "The issue needs attention before work can continue.",
                tone: "Direct, common in technical and project teams.",
                example: "The missing API key is the only blocker right now."
            )
        case "same", "page":
            return PhraseExplanation(
                phrase: visibleWord,
                meaning: "Part of the phrase 'on the same page', meaning shared understanding.",
                contextualMeaning: "The speaker wants everyone aligned before moving forward.",
                tone: "Friendly and professional.",
                example: "I want to make sure we're on the same page before I send the proposal."
            )
        default:
            return PhraseExplanation(
                phrase: visibleWord,
                meaning: "Stub explanation for this word.",
                contextualMeaning: "In this sentence, '\(visibleWord)' contributes to the overall message: \(context)",
                tone: "Tone needs real AI analysis in the production version.",
                example: "Try this word in a short workplace sentence to test whether it feels natural."
            )
        }
    }

    static let samplePhrases = [
        PhraseExplanation(
            phrase: "blocker",
            meaning: "Something that prevents progress.",
            contextualMeaning: "The issue needs attention before work can continue.",
            tone: "Direct, common in technical teams.",
            example: "The missing API key is the only blocker right now."
        )
    ]
}

struct ComposerOutputs {
    let casual: String
    let neutral: String
    let professional: String

    static func generate(from input: String) -> ComposerOutputs {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ComposerOutputs(
                casual: "Let's avoid making things harder for ourselves later.",
                neutral: "So we do not create problems for ourselves later.",
                professional: "So we can avoid creating unnecessary obstacles later."
            )
        }

        return ComposerOutputs(
            casual: "Let's avoid making things harder for ourselves later.",
            neutral: "So we do not create problems for ourselves later.",
            professional: "So we can avoid creating unnecessary obstacles later."
        )
    }
}

enum StubTranslator {
    static let defaultSourceText = "Let's circle back tomorrow so we are on the same page and can remove any blockers."

    static func translate(_ text: String) -> String {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else {
            return "Lass uns morgen darauf zurueckkommen, damit wir alle das gleiche Verstaendnis haben und Hindernisse beseitigen koennen."
        }

        if source.localizedCaseInsensitiveContains("circle back") {
            return "Lass uns spaeter darauf zurueckkommen, damit wir alle das gleiche Verstaendnis haben."
        }

        return "Stub-Uebersetzung: \(source)"
    }
}

struct AssistantView: View {
    @ObservedObject var store: DiscoveryStore
    @State private var tab = PrototypeTab.explain

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            Picker("Mode", selection: $tab) {
                ForEach(PrototypeTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(14)

            Divider()

            switch tab {
            case .explain:
                ExplanationView(store: store)
            case .composer:
                ComposerView(store: store)
            case .review:
                ReviewView(store: store)
            case .settings:
                SettingsView(store: store)
            }
        }
        .frame(width: 680, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await store.refreshOllamaModels()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Context")
                    .font(.system(size: 18, weight: .semibold))
                Text("Discovery prototype - stubbed AI, clipboard fallback")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Refresh Clipboard") {
                store.replaceCapturedText(ClipboardReader.readText())
            }
        }
        .padding(16)
    }
}

enum PrototypeTab: String, CaseIterable, Identifiable {
    case explain
    case composer
    case review
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .composer: return "Composer"
        case .review: return "Review"
        case .settings: return "Settings"
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
                    section("German Translation", text: store.translatedText)
                }
                .padding(18)
            }
            .frame(width: 360)

            Divider()

            PhraseDetailView(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func section(_ title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.headline)
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ClickableOriginalText: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Original")
                .font(.headline)
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
        WordWrapLayout(horizontalSpacing: 3, verticalSpacing: 3) {
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
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
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
            if let phrase = store.selectedPhrase {
                VStack(alignment: .leading, spacing: 14) {
                    Text(phrase.phrase)
                        .font(.system(size: 24, weight: .semibold))

                    detail("Meaning", phrase.meaning)
                    detail("In this context", phrase.contextualMeaning)
                    detail("Tone", phrase.tone)
                    detail("Example", phrase.example)

                    if store.isGeneratingAI {
                        ProgressView("Asking \(store.selectedOllamaModel)...")
                    } else if let aiExplanation = store.aiExplanation, !aiExplanation.isEmpty {
                        detail("Ollama", aiExplanation)
                    } else if store.selectedOllamaModel.isEmpty {
                        detail("AI", "Using stubbed explanation. Choose a local Ollama model in Settings for real AI responses.")
                    }

                    Spacer()

                    Button("Save to Learning Bucket") {
                        store.saveSelectedPhrase()
                    }
                    .buttonStyle(.borderedProminent)
                }
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

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .textSelection(.enabled)
        }
    }
}

struct ComposerView: View {
    @ObservedObject var store: DiscoveryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Write a thought in your native language")
                .font(.headline)

            TextEditor(text: $store.composerInput)
                .font(.body)
                .frame(height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor))
                )

            Button("Compose Natural English") {
                store.compose()
            }
            .buttonStyle(.borderedProminent)

            output("Casual", store.composerOutputs.casual)
            output("Neutral", store.composerOutputs.neutral)
            output("Professional", store.composerOutputs.professional)

            Spacer()
        }
        .padding(18)
    }

    private func output(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(text)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
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

struct ReviewView: View {
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
                    Text("Review again: soon")
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

enum ClipboardReader {
    static func readText() -> String {
        NSPasteboard.general.string(forType: .string) ?? StubTranslator.defaultSourceText
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var panel: NSPanel?
    private var store: DiscoveryStore!
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        store = DiscoveryStore(capturedText: ClipboardReader.readText())
        NSApp.setActivationPolicy(.accessory)
        setupMenuBar()
        registerHotKey()
        showAssistant()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let hotKeyHandler {
            RemoveEventHandler(hotKeyHandler)
        }
    }

    @MainActor
    private func setupMenuBar() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = "Context"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Assistant", action: #selector(openAssistant), keyEquivalent: "e"))
        menu.addItem(NSMenuItem(title: "Refresh From Clipboard", action: #selector(refreshFromClipboard), keyEquivalent: "r"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
    }

    @MainActor
    @objc private func openAssistant() {
        showAssistant()
    }

    @MainActor
    @objc private func refreshFromClipboard() {
        store.replaceCapturedText(ClipboardReader.readText())
        showAssistant()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @MainActor
    private func showAssistant() {
        store.replaceCapturedText(ClipboardReader.readText())

        if panel == nil {
            let panel = AssistantPanel(
                contentRect: NSRect(x: 0, y: 0, width: 680, height: 560),
                styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.title = "Context Discovery"
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.isReleasedWhenClosed = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: AssistantView(store: store))
            panel.center()
            self.panel = panel
        }

        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
                        delegate.showAssistant()
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

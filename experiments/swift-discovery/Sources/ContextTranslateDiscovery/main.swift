import AppKit
import Carbon
import SwiftUI

final class DiscoveryStore: ObservableObject {
    @Published var capturedText: String
    @Published var selectedPhrase: PhraseExplanation?
    @Published var savedPhrases: [PhraseExplanation]
    @Published var composerInput: String
    @Published var composerOutputs: ComposerOutputs

    init(capturedText: String) {
        self.capturedText = capturedText
        self.selectedPhrase = nil
        self.savedPhrases = [PhraseExplanation.sampleLearningItem]
        self.composerInput = "damit wir uns spaeter keine Steine in den Weg legen"
        self.composerOutputs = ComposerOutputs.generate(
            from: "damit wir uns spaeter keine Steine in den Weg legen"
        )
    }

    var translatedText: String {
        StubTranslator.translate(capturedText)
    }

    func replaceCapturedText(_ text: String) {
        capturedText = text.isEmpty ? StubTranslator.defaultSourceText : text
        selectedPhrase = nil
    }

    var wordTokens: [WordToken] {
        WordToken.tokenize(capturedText)
    }

    func selectWord(_ token: WordToken) {
        selectedPhrase = PhraseExplanation.explain(word: token.normalized, visibleWord: token.text, context: capturedText)
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
}

struct WordToken: Identifiable {
    let id = UUID()
    let text: String
    let normalized: String

    static func tokenize(_ text: String) -> [WordToken] {
        text.split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .compactMap { raw in
                let normalized = raw
                    .trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
                    .lowercased()

                guard !normalized.isEmpty else {
                    return nil
                }

                return WordToken(text: raw, normalized: normalized)
            }
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
            }
        }
        .frame(width: 680, height: 560)
        .background(Color(nsColor: .windowBackgroundColor))
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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .composer: return "Composer"
        case .review: return "Review"
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
            WrappingWords(tokens: store.wordTokens) { token in
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
    let onSelect: (WordToken) -> Void

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 24), spacing: 4, alignment: .leading)],
            alignment: .leading,
            spacing: 4
        ) {
            ForEach(tokens) { token in
                Button {
                    onSelect(token)
                } label: {
                    Text(token.text)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 1)
                }
                .buttonStyle(.plain)
                .help("Explain \(token.normalized)")
            }
        }
    }
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

                    Spacer()

                    Button("Save to Learning Bucket") {
                        store.saveSelectedPhrase()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Click a word to explain it")
                        .font(.system(size: 22, weight: .semibold))
                    Text("No explanation is preselected. This is closer to the desired interaction: the user chooses what confused them after seeing the translation.")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
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
    private var store = DiscoveryStore(capturedText: ClipboardReader.readText())
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandler: EventHandlerRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
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

    @objc private func openAssistant() {
        showAssistant()
    }

    @objc private func refreshFromClipboard() {
        store.replaceCapturedText(ClipboardReader.readText())
        showAssistant()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

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
                    DispatchQueue.main.async {
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

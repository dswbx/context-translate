import Darwin
import Foundation

struct CodexCLIReasoningLevel: Decodable, Equatable, Identifiable {
    let effort: String
    let description: String

    var id: String { effort }
}

struct CodexCLIServiceTier: Decodable, Equatable, Identifiable {
    let id: String
    let name: String
    let description: String
}

struct CodexCLIModel: Decodable, Equatable, Identifiable {
    let slug: String
    let displayName: String
    let visibility: String
    let defaultReasoningLevel: String?
    let supportedReasoningLevels: [CodexCLIReasoningLevel]
    let serviceTiers: [CodexCLIServiceTier]

    var id: String { slug }
    var priorityServiceTier: CodexCLIServiceTier? {
        serviceTiers.first(where: { $0.id == "priority" })
    }
    var supportsFastMode: Bool {
        priorityServiceTier != nil
    }

    init(
        slug: String,
        displayName: String,
        visibility: String,
        defaultReasoningLevel: String? = nil,
        supportedReasoningLevels: [CodexCLIReasoningLevel] = [],
        serviceTiers: [CodexCLIServiceTier] = []
    ) {
        self.slug = slug
        self.displayName = displayName
        self.visibility = visibility
        self.defaultReasoningLevel = defaultReasoningLevel
        self.supportedReasoningLevels = supportedReasoningLevels
        self.serviceTiers = serviceTiers
    }

    enum CodingKeys: String, CodingKey {
        case slug
        case displayName = "display_name"
        case visibility
        case defaultReasoningLevel = "default_reasoning_level"
        case supportedReasoningLevels = "supported_reasoning_levels"
        case serviceTiers = "service_tiers"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        slug = try container.decode(String.self, forKey: .slug)
        displayName = try container.decode(String.self, forKey: .displayName)
        visibility = try container.decode(String.self, forKey: .visibility)
        defaultReasoningLevel = try container.decodeIfPresent(String.self, forKey: .defaultReasoningLevel)
        supportedReasoningLevels = try container.decodeIfPresent(
            [CodexCLIReasoningLevel].self,
            forKey: .supportedReasoningLevels
        ) ?? []
        serviceTiers = try container.decodeIfPresent(
            [CodexCLIServiceTier].self,
            forKey: .serviceTiers
        ) ?? []
    }
}

struct CodexCLIModelCatalog: Decodable {
    let models: [CodexCLIModel]
}

struct CodexCLIExecutionOptions: Equatable, Sendable {
    let reasoningEffort: String?
    let serviceTier: String?

    init(reasoningEffort: String? = nil, serviceTier: String? = nil) {
        self.reasoningEffort = reasoningEffort
        self.serviceTier = serviceTier
    }
}

struct CodexCLISpeedSelection: Equatable {
    let reasoningEffort: String?
    let fastEnabled: Bool

    static func resolve(
        reasoningEffort: String?,
        fastEnabled: Bool,
        model: CodexCLIModel?
    ) -> CodexCLISpeedSelection {
        guard let model else {
            return CodexCLISpeedSelection(reasoningEffort: nil, fastEnabled: false)
        }

        let supportedEfforts = model.supportedReasoningLevels.map(\.effort)
        let resolvedEffort: String?
        if let reasoningEffort, supportedEfforts.contains(reasoningEffort) {
            resolvedEffort = reasoningEffort
        } else if supportedEfforts.contains("low") {
            resolvedEffort = "low"
        } else if let defaultEffort = model.defaultReasoningLevel,
                  supportedEfforts.contains(defaultEffort) {
            resolvedEffort = defaultEffort
        } else {
            resolvedEffort = supportedEfforts.first
        }

        return CodexCLISpeedSelection(
            reasoningEffort: resolvedEffort,
            fastEnabled: fastEnabled && model.supportsFastMode
        )
    }
}

struct CodexCatalogLoadState: Equatable {
    private var generation = 0
    private var hasStartedBundledLoad = false
    private var hasStartedLiveRefresh = false

    mutating func beginBundledLoad() -> Int? {
        guard !hasStartedBundledLoad, !hasStartedLiveRefresh else { return nil }
        hasStartedBundledLoad = true
        generation += 1
        return generation
    }

    mutating func beginLiveRefresh() {
        hasStartedLiveRefresh = true
        generation += 1
    }

    func shouldApplyBundledResult(requestID: Int) -> Bool {
        !hasStartedLiveRefresh && requestID == generation
    }
}

enum CodexModelSelection {
    static func resolve(saved: String?, available: [String]) -> String? {
        if let saved, !saved.isEmpty, available.contains(saved) {
            return saved
        }
        return available.first
    }
}

enum CodexCLIUnavailableReason: Equatable {
    case notInstalled
    case notAuthenticated
    case commandFailed
}

enum CodexCLIReadiness: Equatable {
    case unknown
    case checking
    case ready
    case unavailable(CodexCLIUnavailableReason)

    var isReady: Bool {
        self == .ready
    }

    var message: String {
        switch self {
        case .unknown:
            return "Check Codex CLI before turning it on."
        case .checking:
            return "Checking Codex CLI..."
        case .ready:
            return "Codex CLI is installed and authenticated."
        case .unavailable(.notInstalled):
            return "Codex CLI was not found. Install it, then refresh."
        case .unavailable(.notAuthenticated):
            return "Codex CLI is not authenticated. Run `codex login` in Terminal, then refresh."
        case .unavailable(.commandFailed):
            return "Codex CLI could not be checked."
        }
    }
}

enum CodexCLIError: LocalizedError, Equatable {
    case notInstalled
    case nonzeroExit(Int32)
    case malformedModelCatalog
    case emptyOutput
    case timedOut
    case cancelled
    case launchFailed

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Codex CLI is not installed."
        case .nonzeroExit(let status):
            return "Codex CLI exited with status \(status)."
        case .malformedModelCatalog:
            return "Codex CLI returned an invalid model catalog."
        case .emptyOutput:
            return "Codex CLI returned an empty response."
        case .timedOut:
            return "Codex CLI timed out."
        case .cancelled:
            return "Codex CLI was stopped."
        case .launchFailed:
            return "Codex CLI could not be launched."
        }
    }
}

struct CodexCLIRunner {
    let executableURL: URL?
    let generationTimeout: TimeInterval

    init(
        executableURL: URL? = CodexCLIRunner.resolveExecutable(),
        generationTimeout: TimeInterval = 120
    ) {
        self.executableURL = executableURL
        self.generationTimeout = generationTimeout
    }

    var executablePath: String? {
        executableURL?.path
    }

    static func decodeVisibleModels(from data: Data) throws -> [CodexCLIModel] {
        try JSONDecoder()
            .decode(CodexCLIModelCatalog.self, from: data)
            .models
            .filter { $0.visibility == "list" }
    }

    static func resolveExecutable(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileExists: (String) -> Bool = FileManager.default.isExecutableFile(atPath:)
    ) -> URL? {
        var candidates = environment["PATH", default: ""]
            .split(separator: ":")
            .map { String($0) + "/codex" }

        candidates.append(contentsOf: [
            homeDirectory.appendingPathComponent(".local/bin/codex").path,
            "/opt/homebrew/bin/codex",
            "/usr/local/bin/codex"
        ])

        guard let path = candidates.first(where: fileExists) else {
            return nil
        }

        return URL(fileURLWithPath: path)
    }

    func checkReadiness() async -> CodexCLIReadiness {
        guard executableURL != nil else {
            return .unavailable(.notInstalled)
        }

        do {
            let result = try await run(
                arguments: ["login", "status"],
                standardInput: nil,
                currentDirectory: nil,
                timeout: 20
            )
            if result.status == 0 {
                return .ready
            }

            let statusText = String(decoding: result.standardOutput + result.standardError, as: UTF8.self)
                .lowercased()
            let authenticationMarkers = ["not logged in", "logged out", "unauthenticated"]
            return authenticationMarkers.contains(where: statusText.contains)
                ? .unavailable(.notAuthenticated)
                : .unavailable(.commandFailed)
        } catch is CancellationError {
            return .unknown
        } catch {
            return .unavailable(.commandFailed)
        }
    }

    func fetchModels() async throws -> [CodexCLIModel] {
        try await fetchModels(arguments: ["debug", "models"])
    }

    func fetchBundledModels() async throws -> [CodexCLIModel] {
        try await fetchModels(arguments: ["debug", "models", "--bundled"])
    }

    private func fetchModels(arguments: [String]) async throws -> [CodexCLIModel] {
        let result = try await run(
            arguments: arguments,
            standardInput: nil,
            currentDirectory: nil,
            timeout: 30
        )
        guard result.status == 0 else {
            throw CodexCLIError.nonzeroExit(result.status)
        }

        do {
            return try Self.decodeVisibleModels(from: result.standardOutput)
        } catch {
            throw CodexCLIError.malformedModelCatalog
        }
    }

    func generate(
        prompt: String,
        modelSlug: String?,
        options: CodexCLIExecutionOptions = CodexCLIExecutionOptions()
    ) async throws -> String {
        guard executableURL != nil else {
            throw CodexCLIError.notInstalled
        }

        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("context-translate-codex-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        defer { try? fileManager.removeItem(at: temporaryDirectory) }

        let outputURL = temporaryDirectory.appendingPathComponent("response.txt")
        var arguments = [
            "exec",
            "--ephemeral",
            "--sandbox", "read-only",
            "--skip-git-repo-check",
            "--color", "never",
            "--output-last-message", outputURL.path
        ]
        if let reasoningEffort = options.reasoningEffort, !reasoningEffort.isEmpty {
            arguments.append(contentsOf: [
                "-c",
                tomlStringAssignment(key: "model_reasoning_effort", value: reasoningEffort)
            ])
        }
        if let serviceTier = options.serviceTier, !serviceTier.isEmpty {
            arguments.append(contentsOf: [
                "-c",
                tomlStringAssignment(key: "service_tier", value: serviceTier)
            ])
        }
        if let modelSlug, !modelSlug.isEmpty {
            arguments.append(contentsOf: ["--model", modelSlug])
        }
        arguments.append("-")

        let result: CodexProcessResult
        do {
            result = try await run(
                arguments: arguments,
                standardInput: Data(prompt.utf8),
                currentDirectory: temporaryDirectory,
                timeout: generationTimeout
            )
        } catch is CancellationError {
            throw CancellationError()
        }

        guard result.status == 0 else {
            throw CodexCLIError.nonzeroExit(result.status)
        }
        guard let response = try? String(contentsOf: outputURL, encoding: .utf8)
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !response.isEmpty else {
            throw CodexCLIError.emptyOutput
        }
        return response
    }

    private func tomlStringAssignment(key: String, value: String) -> String {
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\(key)=\"\(escapedValue)\""
    }

    private func run(
        arguments: [String],
        standardInput: Data?,
        currentDirectory: URL?,
        timeout: TimeInterval
    ) async throws -> CodexProcessResult {
        try await withThrowingTaskGroup(of: CodexProcessResult.self) { group in
            group.addTask {
                try await runProcess(
                    arguments: arguments,
                    standardInput: standardInput,
                    currentDirectory: currentDirectory
                )
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw CodexCLIError.timedOut
            }

            guard let result = try await group.next() else {
                throw CodexCLIError.launchFailed
            }
            group.cancelAll()
            return result
        }
    }

    private func runProcess(
        arguments: [String],
        standardInput: Data?,
        currentDirectory: URL?
    ) async throws -> CodexProcessResult {
        guard let executableURL else {
            throw CodexCLIError.notInstalled
        }

        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let processControl = CodexProcessControl(
            process: process,
            outputHandles: [outputPipe.fileHandleForReading, errorPipe.fileHandleForReading]
        )
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let outputTask = Task.detached {
                outputPipe.fileHandleForReading.readDataToEndOfFile()
            }
            let errorTask = Task.detached {
                errorPipe.fileHandleForReading.readDataToEndOfFile()
            }

            let status = try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { finishedProcess in
                    continuation.resume(returning: finishedProcess.terminationStatus)
                }

                do {
                    try processControl.launch()
                    if let standardInput {
                        try inputPipe.fileHandleForWriting.write(contentsOf: standardInput)
                    }
                    try inputPipe.fileHandleForWriting.close()
                } catch is CancellationError {
                    process.terminationHandler = nil
                    try? inputPipe.fileHandleForWriting.close()
                    continuation.resume(throwing: CancellationError())
                } catch {
                    process.terminationHandler = nil
                    try? inputPipe.fileHandleForWriting.close()
                    continuation.resume(throwing: CodexCLIError.launchFailed)
                }
            }

            let standardOutput = await outputTask.value
            let standardError = await errorTask.value
            try Task.checkCancellation()
            return CodexProcessResult(
                status: status,
                standardOutput: standardOutput,
                standardError: standardError
            )
        } onCancel: {
            processControl.terminate()
        }
    }
}

private struct CodexProcessResult: Sendable {
    let status: Int32
    let standardOutput: Data
    let standardError: Data
}

private final class CodexProcessControl: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process
    private let outputHandles: [FileHandle]
    private var cancellationRequested = false

    init(process: Process, outputHandles: [FileHandle]) {
        self.process = process
        self.outputHandles = outputHandles
    }

    func launch() throws {
        lock.lock()
        defer { lock.unlock() }
        guard !cancellationRequested else {
            throw CancellationError()
        }
        try process.run()
    }

    func terminate() {
        lock.lock()
        cancellationRequested = true
        let shouldTerminate = process.isRunning
        let processIdentifier = process.processIdentifier
        let descendants = shouldTerminate ? descendantProcessIdentifiers(of: processIdentifier) : []
        if shouldTerminate {
            descendants.reversed().forEach { kill($0, SIGTERM) }
            process.terminate()
        }
        lock.unlock()

        guard shouldTerminate else { return }
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            descendants.reversed().forEach { kill($0, SIGKILL) }
            if self.process.isRunning {
                kill(processIdentifier, SIGKILL)
            }
            self.outputHandles.forEach { try? $0.close() }
        }
    }

    private func descendantProcessIdentifiers(of parent: pid_t) -> [pid_t] {
        let requiredCapacity = proc_listchildpids(parent, nil, 0)
        guard requiredCapacity > 0 else { return [] }

        var children = [pid_t](repeating: 0, count: Int(requiredCapacity))
        let returnedCount = children.withUnsafeMutableBytes { buffer in
            proc_listchildpids(parent, buffer.baseAddress, Int32(buffer.count))
        }
        guard returnedCount > 0 else { return [] }

        let count = min(Int(returnedCount), children.count)
        return children.prefix(count).filter { $0 > 0 }.flatMap { child in
            [child] + descendantProcessIdentifiers(of: child)
        }
    }
}

import Foundation

struct CodexCLIModel: Decodable, Equatable, Identifiable {
    let slug: String
    let displayName: String
    let visibility: String

    var id: String { slug }

    enum CodingKeys: String, CodingKey {
        case slug
        case displayName = "display_name"
        case visibility
    }
}

struct CodexCLIModelCatalog: Decodable {
    let models: [CodexCLIModel]
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
            return result.status == 0 ? .ready : .unavailable(.notAuthenticated)
        } catch is CancellationError {
            return .unknown
        } catch {
            return .unavailable(.commandFailed)
        }
    }

    func fetchModels() async throws -> [CodexCLIModel] {
        let result = try await run(
            arguments: ["debug", "models"],
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

    func generate(prompt: String, modelSlug: String?) async throws -> String {
        guard executableURL != nil else {
            throw CodexCLIError.notInstalled
        }

        let fileManager = FileManager.default
        let temporaryDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("context-translate-codex-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
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
            throw CodexCLIError.cancelled
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
        let processControl = CodexProcessControl(process: process)
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.executableURL = executableURL
        process.arguments = arguments
        process.currentDirectoryURL = currentDirectory
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        return try await withTaskCancellationHandler {
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
                    try process.run()
                    if let standardInput {
                        try inputPipe.fileHandleForWriting.write(contentsOf: standardInput)
                    }
                    try inputPipe.fileHandleForWriting.close()
                } catch {
                    process.terminationHandler = nil
                    try? inputPipe.fileHandleForWriting.close()
                    continuation.resume(throwing: CodexCLIError.launchFailed)
                }
            }

            let standardOutput = await outputTask.value
            _ = await errorTask.value
            try Task.checkCancellation()
            return CodexProcessResult(status: status, standardOutput: standardOutput)
        } onCancel: {
            processControl.terminate()
        }
    }
}

private struct CodexProcessResult: Sendable {
    let status: Int32
    let standardOutput: Data
}

private final class CodexProcessControl: @unchecked Sendable {
    private let lock = NSLock()
    private let process: Process

    init(process: Process) {
        self.process = process
    }

    func terminate() {
        lock.lock()
        defer { lock.unlock() }
        if process.isRunning {
            process.terminate()
        }
    }
}

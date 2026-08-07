@testable import ContextTranslateDiscovery
import Foundation
import Testing

struct CodexCLIRunnerTests {
    @Test func catalogReturnsOnlyVisibleModels() throws {
        let data = Data(#"{"models":[{"slug":"gpt-a","display_name":"GPT A","visibility":"list"},{"slug":"hidden","display_name":"Hidden","visibility":"hide"}]}"#.utf8)

        let models = try CodexCLIRunner.decodeVisibleModels(from: data)

        #expect(models == [CodexCLIModel(slug: "gpt-a", displayName: "GPT A", visibility: "list")])
    }

    @Test func resolveExecutableUsesPathBeforeFallbacks() {
        let existing = Set(["/custom/bin/codex", "/Users/test/.local/bin/codex"])

        let result = CodexCLIRunner.resolveExecutable(
            environment: ["PATH": "/custom/bin:/usr/bin"],
            homeDirectory: URL(fileURLWithPath: "/Users/test"),
            fileExists: existing.contains
        )

        #expect(result?.path == "/custom/bin/codex")
    }

    @Test func resolveExecutableUsesConventionalGUIPath() {
        let result = CodexCLIRunner.resolveExecutable(
            environment: [:],
            homeDirectory: URL(fileURLWithPath: "/Users/test"),
            fileExists: { $0 == "/Users/test/.local/bin/codex" }
        )

        #expect(result?.path == "/Users/test/.local/bin/codex")
    }

    @Test func resolveExecutableReturnsNilWhenCodexIsMissing() {
        let result = CodexCLIRunner.resolveExecutable(
            environment: [:],
            homeDirectory: URL(fileURLWithPath: "/Users/test"),
            fileExists: { _ in false }
        )

        #expect(result == nil)
    }

    @Test func readinessReportsAuthenticatedCLI() async throws {
        let fixture = try makeExecutableFixture(body: """
        if [ "$1" = "login" ] && [ "$2" = "status" ]; then
          echo "Logged in using ChatGPT"
          exit 0
        fi
        exit 2
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }

        let readiness = await CodexCLIRunner(executableURL: fixture).checkReadiness()

        #expect(readiness == .ready)
    }

    @Test func readinessDistinguishesLoggedOutFromCommandFailure() async throws {
        let loggedOutFixture = try makeExecutableFixture(body: """
        echo "Not logged in"
        exit 1
        """)
        defer { try? FileManager.default.removeItem(at: loggedOutFixture.deletingLastPathComponent()) }
        let failureFixture = try makeExecutableFixture(body: """
        echo "internal CLI failure" >&2
        exit 2
        """)
        defer { try? FileManager.default.removeItem(at: failureFixture.deletingLastPathComponent()) }

        let loggedOut = await CodexCLIRunner(executableURL: loggedOutFixture).checkReadiness()
        let failed = await CodexCLIRunner(executableURL: failureFixture).checkReadiness()

        #expect(loggedOut == .unavailable(.notAuthenticated))
        #expect(failed == .unavailable(.commandFailed))
    }

    @Test func fetchModelsUsesCLIJSON() async throws {
        let fixture = try makeExecutableFixture(body: """
        if [ "$1" = "debug" ] && [ "$2" = "models" ]; then
          printf '%s' '{"models":[{"slug":"gpt-a","display_name":"GPT A","visibility":"list"},{"slug":"internal","display_name":"Internal","visibility":"hide"}]}'
          exit 0
        fi
        exit 2
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }

        let models = try await CodexCLIRunner(executableURL: fixture).fetchModels()

        #expect(models.map(\.slug) == ["gpt-a"])
    }

    @Test func generateReturnsOutputLastMessage() async throws {
        let fixture = try makeExecutableFixture(body: """
        if [ "$1" = "exec" ]; then
          output=''
          while [ "$#" -gt 0 ]; do
            if [ "$1" = "--output-last-message" ]; then
              shift
              output="$1"
            fi
            shift
          done
          cat >/dev/null
          printf '%s' 'fixture response' > "$output"
          exit 0
        fi
        exit 2
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }

        let response = try await CodexCLIRunner(executableURL: fixture).generate(
            prompt: "fixture prompt",
            modelSlug: "gpt-a"
        )

        #expect(response == "fixture response")
    }

    @Test func nonzeroExitBecomesSanitizedError() async throws {
        let fixture = try makeExecutableFixture(body: """
        echo 'credential-shaped fixture failure' >&2
        exit 17
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }

        do {
            _ = try await CodexCLIRunner(executableURL: fixture).generate(
                prompt: "fixture prompt",
                modelSlug: nil
            )
            Issue.record("Expected a nonzero-exit error")
        } catch let error as CodexCLIError {
            #expect(error == .nonzeroExit(17))
            #expect(!error.localizedDescription.contains("credential-shaped"))
        }
    }

    @Test func cancellationStopsInFlightProcess() async throws {
        let fixture = try makeExecutableFixture(body: """
        exec sleep 30
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
        let runner = CodexCLIRunner(executableURL: fixture, generationTimeout: 60)
        let clock = ContinuousClock()
        let started = clock.now
        let task = Task {
            try await runner.generate(prompt: "fixture prompt", modelSlug: nil)
        }

        try await Task.sleep(for: .milliseconds(100))
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            #expect(started.duration(to: clock.now) < .seconds(3))
        } catch let error as CodexCLIError {
            #expect(error == .cancelled)
            #expect(started.duration(to: clock.now) < .seconds(3))
        }
    }

    @Test func timeoutForceKillsTermResistantProcess() async throws {
        let fixture = try makeExecutableFixture(body: """
        trap '' TERM
        sleep 30
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
        let runner = CodexCLIRunner(executableURL: fixture, generationTimeout: 0.1)
        let clock = ContinuousClock()
        let started = clock.now

        do {
            _ = try await runner.generate(prompt: "fixture prompt", modelSlug: nil)
            Issue.record("Expected timeout")
        } catch let error as CodexCLIError {
            #expect(error == .timedOut)
            #expect(started.duration(to: clock.now) < .seconds(3))
        }
    }

    @Test func cancellationBeforeLaunchReturnsPromptly() async throws {
        let fixture = try makeExecutableFixture(body: """
        exec sleep 30
        """)
        defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
        let runner = CodexCLIRunner(executableURL: fixture, generationTimeout: 60)
        let clock = ContinuousClock()
        let started = clock.now
        let task = Task {
            try await runner.generate(prompt: "fixture prompt", modelSlug: nil)
        }
        task.cancel()

        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
            #expect(started.duration(to: clock.now) < .seconds(3))
        }
    }

    @Test func selectedModelKeepsAvailableSavedSlug() {
        let selected = CodexModelSelection.resolve(saved: "b", available: ["a", "b"])

        #expect(selected == "b")
    }

    @Test func selectedModelFallsBackToFirstVisibleModel() {
        let selected = CodexModelSelection.resolve(saved: "missing", available: ["a"])

        #expect(selected == "a")
    }

    @Test func selectedModelFallsBackToCLIDefaultForEmptyCatalog() {
        let selected = CodexModelSelection.resolve(saved: "missing", available: [])

        #expect(selected == nil)
    }

    private func makeExecutableFixture(body: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appendingPathComponent("codex")
        try Data("#!/bin/sh\n\(body)\n".utf8).write(to: executable)
        try FileManager.default.setAttributes(
            [.posixPermissions: NSNumber(value: 0o755)],
            ofItemAtPath: executable.path
        )
        return executable
    }
}

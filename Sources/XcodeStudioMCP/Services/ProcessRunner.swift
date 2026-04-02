import Foundation

struct ProcessResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum ProcessRunnerError: Error, CustomStringConvertible {
    case executableNotFound(String)
    case timeout(command: String, seconds: Int)

    var description: String {
        switch self {
        case .executableNotFound(let name):
            return "Executable not found: \(name)"
        case .timeout(let command, let seconds):
            return "Command timed out after \(seconds)s: \(command)"
        }
    }
}

enum ProcessRunner {
    static func run(
        _ executable: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        workingDirectory: String? = nil,
        timeout: TimeInterval = 120
    ) async throws -> ProcessResult {
        let process = Process()

        if executable.hasPrefix("/") {
            process.executableURL = URL(fileURLWithPath: executable)
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [executable] + arguments
        }

        if process.executableURL?.lastPathComponent != "env" {
            process.arguments = arguments
        }

        if let env = environment {
            var currentEnv = ProcessInfo.processInfo.environment
            for (key, value) in env {
                currentEnv[key] = value
            }
            process.environment = currentEnv
        }

        if let cwd = workingDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: cwd)
        }

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { _ in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let result = ProcessResult(
                    stdout: String(data: stdoutData, encoding: .utf8) ?? "",
                    stderr: String(data: stderrData, encoding: .utf8) ?? "",
                    exitCode: process.terminationStatus
                )
                continuation.resume(returning: result)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

import Foundation

enum IDBError: Error, CustomStringConvertible {
    case notInstalled

    var description: String {
        switch self {
        case .notInstalled:
            return """
            idb CLI not found. Install it with:
              pip3 install fb-idb

            Also ensure idb_companion is installed:
              brew tap facebook/fb && brew install idb-companion
            """
        }
    }
}

actor IDBService {
    private var resolvedPath: String?
    private var searched = false

    func getIDBPath() async throws -> String {
        if let path = resolvedPath { return path }
        if searched { throw IDBError.notInstalled }

        searched = true

        // Check environment variable
        if let envPath = ProcessInfo.processInfo.environment["IDB_PATH"] {
            if FileManager.default.isExecutableFile(atPath: envPath) {
                resolvedPath = envPath
                return envPath
            }
        }

        // Check common pip install locations
        let candidates = [
            "\(NSHomeDirectory())/Library/Python/3.9/bin/idb",
            "\(NSHomeDirectory())/Library/Python/3.10/bin/idb",
            "\(NSHomeDirectory())/Library/Python/3.11/bin/idb",
            "\(NSHomeDirectory())/Library/Python/3.12/bin/idb",
            "\(NSHomeDirectory())/Library/Python/3.13/bin/idb",
            "/usr/local/bin/idb",
            "/opt/homebrew/bin/idb",
        ]

        for candidate in candidates {
            if FileManager.default.isExecutableFile(atPath: candidate) {
                resolvedPath = candidate
                return candidate
            }
        }

        // Try which
        let result = try? await ProcessRunner.run("/usr/bin/which", arguments: ["idb"])
        if let result = result, result.exitCode == 0 {
            let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            if !path.isEmpty && FileManager.default.isExecutableFile(atPath: path) {
                resolvedPath = path
                return path
            }
        }

        throw IDBError.notInstalled
    }

    func tap(udid: String, x: Double, y: Double, duration: Double? = nil) async throws -> String {
        let idb = try await getIDBPath()
        var args = ["ui", "tap", "--udid", udid]
        if let duration = duration {
            args += ["--duration", String(duration)]
        }
        args += ["--", String(Int(x)), String(Int(y))]

        let result = try await ProcessRunner.run(idb, arguments: args, timeout: 30)
        if result.exitCode != 0 {
            return "Tap failed: \(result.stderr)"
        }
        return "Tapped at (\(Int(x)), \(Int(y)))"
    }

    func typeText(udid: String, text: String) async throws -> String {
        let idb = try await getIDBPath()
        let args = ["ui", "text", "--udid", udid, "--", text]

        let result = try await ProcessRunner.run(idb, arguments: args, timeout: 30)
        if result.exitCode != 0 {
            return "Type failed: \(result.stderr)"
        }
        return "Typed: \(text)"
    }

    func describeAll(udid: String) async throws -> String {
        let idb = try await getIDBPath()
        let args = ["ui", "describe-all", "--udid", udid, "--json", "--nested"]

        let result = try await ProcessRunner.run(idb, arguments: args, timeout: 30)
        if result.exitCode != 0 {
            return "Describe failed: \(result.stderr)"
        }
        return result.stdout
    }
}

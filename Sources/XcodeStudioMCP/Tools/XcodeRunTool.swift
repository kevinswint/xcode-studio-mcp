import Foundation

enum XcodeRunTool {
    static func run(
        projectPath: String,
        scheme: String?,
        bundleIdentifier: String,
        configuration: String,
        simulatorUDID: String?
    ) async throws -> String {
        // Build first
        let udid = try await SimulatorService.resolveUDID(simulatorUDID)
        let destination = "platform=iOS Simulator,id=\(udid)"

        let buildResult = try await XcodeBuildTool.run(
            projectPath: projectPath,
            scheme: scheme,
            configuration: configuration,
            destination: destination,
            extraArgs: []
        )

        guard buildResult.succeeded else {
            return buildResult.toJSON()
        }

        // Launch in simulator
        let launchResult = try await ProcessRunner.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "launch", udid, bundleIdentifier],
            timeout: 30
        )

        if launchResult.exitCode != 0 {
            return "Build succeeded but launch failed: \(launchResult.stderr.trimmingCharacters(in: .whitespacesAndNewlines))"
        }

        let pid = launchResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        return "Build succeeded and app launched. \(pid)"
    }
}

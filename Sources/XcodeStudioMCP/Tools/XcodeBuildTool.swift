import Foundation

enum XcodeBuildTool {
    static func run(
        projectPath: String,
        scheme: String?,
        configuration: String,
        destination: String?,
        extraArgs: [String]
    ) async throws -> BuildResult {
        let resolvedPath = (projectPath as NSString).expandingTildeInPath
        let fm = FileManager.default

        // Find the project or workspace file
        var projectFile: String
        var isWorkspace = false

        if resolvedPath.hasSuffix(".xcworkspace") || resolvedPath.hasSuffix(".xcodeproj") {
            projectFile = resolvedPath
            isWorkspace = resolvedPath.hasSuffix(".xcworkspace")
        } else {
            // Scan directory
            let contents = (try? fm.contentsOfDirectory(atPath: resolvedPath)) ?? []
            if let ws = contents.first(where: { $0.hasSuffix(".xcworkspace") && !$0.hasPrefix(".")  }) {
                projectFile = "\(resolvedPath)/\(ws)"
                isWorkspace = true
            } else if let proj = contents.first(where: { $0.hasSuffix(".xcodeproj") }) {
                projectFile = "\(resolvedPath)/\(proj)"
                isWorkspace = false
            } else {
                return BuildResult(
                    succeeded: false,
                    diagnostics: [],
                    summary: "No .xcworkspace or .xcodeproj found at \(resolvedPath)",
                    rawOutput: nil
                )
            }
        }

        // Auto-detect scheme if not provided
        var resolvedScheme = scheme
        if resolvedScheme == nil {
            let flag = isWorkspace ? "-workspace" : "-project"
            let listResult = try await ProcessRunner.run(
                "/usr/bin/xcrun",
                arguments: ["xcodebuild", "-list", "-json", flag, projectFile],
                timeout: 30
            )
            if listResult.exitCode == 0,
               let data = listResult.stdout.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
            {
                if let projectInfo = (json["project"] ?? json["workspace"]) as? [String: Any],
                   let schemes = projectInfo["schemes"] as? [String],
                   let first = schemes.first
                {
                    resolvedScheme = first
                }
            }
        }

        guard let finalScheme = resolvedScheme else {
            return BuildResult(
                succeeded: false,
                diagnostics: [],
                summary: "Could not determine scheme. Specify one with the 'scheme' parameter.",
                rawOutput: nil
            )
        }

        // Resolve destination
        var resolvedDestination = destination
        if resolvedDestination == nil {
            if let sim = try? await SimulatorService.getBootedSimulator() {
                resolvedDestination = "platform=iOS Simulator,id=\(sim.udid)"
            }
        }

        // Build command
        let flag = isWorkspace ? "-workspace" : "-project"
        var args = ["xcodebuild", flag, projectFile, "-scheme", finalScheme, "-configuration", configuration]

        if let dest = resolvedDestination {
            args += ["-destination", dest]
        }

        args.append("build")
        args += extraArgs

        let result = try await ProcessRunner.run(
            "/usr/bin/xcrun",
            arguments: args,
            timeout: 300
        )

        return XcodeBuildParser.parse(
            stdout: result.stdout,
            stderr: result.stderr,
            exitCode: result.exitCode
        )
    }
}

import Foundation

enum SimulatorScreenshotTool {
    static func capture(simulatorUDID: String?) async throws -> (base64: String, mimeType: String) {
        let udid = try await SimulatorService.resolveUDID(simulatorUDID)
        let tempPath = "/tmp/xcode-studio-mcp-\(UUID().uuidString).png"

        defer {
            try? FileManager.default.removeItem(atPath: tempPath)
        }

        let result = try await ProcessRunner.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "io", udid, "screenshot", "--type=png", tempPath],
            timeout: 30
        )

        guard result.exitCode == 0 else {
            throw NSError(domain: "SimulatorScreenshot", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Screenshot failed: \(result.stderr)"])
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: tempPath))
        return (base64: data.base64EncodedString(), mimeType: "image/png")
    }
}

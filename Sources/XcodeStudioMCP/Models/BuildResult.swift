import Foundation

struct BuildResult: Codable, Sendable {
    let succeeded: Bool
    let diagnostics: [BuildDiagnostic]
    let summary: String
    let rawOutput: String?

    func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(self) else {
            return "{\"succeeded\": \(succeeded), \"summary\": \"\(summary)\"}"
        }
        return String(data: data, encoding: .utf8) ?? ""
    }
}

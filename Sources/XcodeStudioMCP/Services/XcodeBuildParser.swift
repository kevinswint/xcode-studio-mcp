import Foundation

enum XcodeBuildParser {
    private static let diagnosticPattern = try! NSRegularExpression(
        pattern: #"^(.+):(\d+):(\d+):\s+(error|warning|note):\s+(.+)$"#,
        options: .anchorsMatchLines
    )

    static func parse(stdout: String, stderr: String, exitCode: Int32) -> BuildResult {
        let combined = stdout + "\n" + stderr
        var diagnostics: [BuildDiagnostic] = []

        let range = NSRange(combined.startIndex..., in: combined)
        let matches = diagnosticPattern.matches(in: combined, range: range)

        for match in matches {
            guard match.numberOfRanges == 6 else { continue }

            let file = String(combined[Range(match.range(at: 1), in: combined)!])
            let line = Int(String(combined[Range(match.range(at: 2), in: combined)!])) ?? 0
            let column = Int(String(combined[Range(match.range(at: 3), in: combined)!])) ?? 0
            let severity = String(combined[Range(match.range(at: 4), in: combined)!])
            let message = String(combined[Range(match.range(at: 5), in: combined)!])

            diagnostics.append(BuildDiagnostic(
                file: file, line: line, column: column,
                severity: severity, message: message
            ))
        }

        let succeeded = exitCode == 0
        let errors = diagnostics.filter { $0.severity == "error" }.count
        let warnings = diagnostics.filter { $0.severity == "warning" }.count

        let summary: String
        if succeeded {
            summary = warnings > 0
                ? "Build succeeded with \(warnings) warning(s)"
                : "Build succeeded"
        } else {
            summary = "Build failed with \(errors) error(s) and \(warnings) warning(s)"
        }

        // If build failed but no diagnostics parsed, include raw output tail
        var rawOutput: String? = nil
        if !succeeded && diagnostics.isEmpty {
            let lines = combined.components(separatedBy: .newlines)
            let tail = lines.suffix(50).joined(separator: "\n")
            rawOutput = tail
        }

        return BuildResult(
            succeeded: succeeded,
            diagnostics: diagnostics,
            summary: summary,
            rawOutput: rawOutput
        )
    }
}

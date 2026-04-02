import Foundation

struct BuildDiagnostic: Codable, Sendable {
    let file: String
    let line: Int
    let column: Int
    let severity: String
    let message: String
}

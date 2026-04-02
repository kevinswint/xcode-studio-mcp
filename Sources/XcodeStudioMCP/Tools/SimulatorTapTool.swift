import Foundation

enum SimulatorTapTool {
    static func tap(x: Double, y: Double, duration: Double?, simulatorUDID: String?, idb: IDBService) async throws -> String {
        let udid = try await SimulatorService.resolveUDID(simulatorUDID)
        return try await idb.tap(udid: udid, x: x, y: y, duration: duration)
    }
}

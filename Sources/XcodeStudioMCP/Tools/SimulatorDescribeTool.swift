import Foundation

enum SimulatorDescribeTool {
    static func describe(simulatorUDID: String?, idb: IDBService) async throws -> String {
        let udid = try await SimulatorService.resolveUDID(simulatorUDID)
        return try await idb.describeAll(udid: udid)
    }
}

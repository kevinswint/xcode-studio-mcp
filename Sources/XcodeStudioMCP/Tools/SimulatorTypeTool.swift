import Foundation

enum SimulatorTypeTool {
    static func type(text: String, simulatorUDID: String?, idb: IDBService) async throws -> String {
        let udid = try await SimulatorService.resolveUDID(simulatorUDID)
        return try await idb.typeText(udid: udid, text: text)
    }
}

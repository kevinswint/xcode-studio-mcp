import Foundation

enum SimulatorServiceError: Error, CustomStringConvertible {
    case noBootedSimulator

    var description: String {
        switch self {
        case .noBootedSimulator:
            return "No booted simulator found. Boot one with: xcrun simctl boot <device_udid>. List available devices with: xcrun simctl list devices"
        }
    }
}

enum SimulatorService {
    static func getBootedSimulator() async throws -> SimulatorInfo {
        let result = try await ProcessRunner.run(
            "/usr/bin/xcrun",
            arguments: ["simctl", "list", "devices", "booted", "-j"]
        )

        guard result.exitCode == 0 else {
            throw SimulatorServiceError.noBootedSimulator
        }

        guard let data = result.stdout.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let devices = json["devices"] as? [String: [[String: Any]]]
        else {
            throw SimulatorServiceError.noBootedSimulator
        }

        for (runtime, deviceList) in devices {
            for device in deviceList {
                if let state = device["state"] as? String,
                   state == "Booted",
                   let udid = device["udid"] as? String,
                   let name = device["name"] as? String
                {
                    return SimulatorInfo(udid: udid, name: name, runtime: runtime)
                }
            }
        }

        throw SimulatorServiceError.noBootedSimulator
    }

    static func resolveUDID(_ udid: String?) async throws -> String {
        if let udid = udid, !udid.isEmpty {
            return udid
        }
        let sim = try await getBootedSimulator()
        return sim.udid
    }
}

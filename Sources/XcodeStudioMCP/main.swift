import Foundation
import MCP

let idbService = IDBService()

let server = Server(
    name: "xcode-studio-mcp",
    version: "0.1.0",
    capabilities: .init(tools: .init(listChanged: false))
)

// MARK: - Tool Definitions

let tools: [Tool] = [
    Tool(
        name: "xcode_build",
        description: "Build an Xcode project or workspace. Returns structured diagnostics with file, line, column, severity, and message for each error/warning.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "project_path": .object([
                    "type": "string",
                    "description": "Path to the Xcode project directory, .xcodeproj, or .xcworkspace"
                ]),
                "scheme": .object([
                    "type": "string",
                    "description": "Build scheme name. Auto-detected if omitted."
                ]),
                "configuration": .object([
                    "type": "string",
                    "description": "Build configuration (Debug or Release). Default: Debug"
                ]),
                "destination": .object([
                    "type": "string",
                    "description": "Build destination. Default: booted iOS Simulator"
                ]),
            ]),
            "required": .array([.string("project_path")])
        ])
    ),
    Tool(
        name: "xcode_run",
        description: "Build an Xcode project and launch the app in the iOS Simulator. Returns build errors if the build fails, or a success message with the launched process ID.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "project_path": .object([
                    "type": "string",
                    "description": "Path to the Xcode project directory, .xcodeproj, or .xcworkspace"
                ]),
                "bundle_identifier": .object([
                    "type": "string",
                    "description": "App bundle identifier to launch (e.g. com.example.MyApp)"
                ]),
                "scheme": .object([
                    "type": "string",
                    "description": "Build scheme name. Auto-detected if omitted."
                ]),
                "configuration": .object([
                    "type": "string",
                    "description": "Build configuration. Default: Debug"
                ]),
                "simulator_udid": .object([
                    "type": "string",
                    "description": "Simulator UDID. Default: first booted simulator"
                ]),
            ]),
            "required": .array([.string("project_path"), .string("bundle_identifier")])
        ])
    ),
    Tool(
        name: "simulator_screenshot",
        description: "Capture a screenshot of the iOS Simulator screen. Returns the image as base64-encoded PNG.",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "simulator_udid": .object([
                    "type": "string",
                    "description": "Simulator UDID. Default: first booted simulator"
                ]),
            ]),
        ])
    ),
    Tool(
        name: "simulator_tap",
        description: "Tap at specific coordinates on the iOS Simulator screen. Requires idb (pip3 install fb-idb).",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "x": .object([
                    "type": "number",
                    "description": "X coordinate to tap"
                ]),
                "y": .object([
                    "type": "number",
                    "description": "Y coordinate to tap"
                ]),
                "duration": .object([
                    "type": "number",
                    "description": "Tap duration in seconds (for long press)"
                ]),
                "simulator_udid": .object([
                    "type": "string",
                    "description": "Simulator UDID. Default: first booted simulator"
                ]),
            ]),
            "required": .array([.string("x"), .string("y")])
        ])
    ),
    Tool(
        name: "simulator_type",
        description: "Type text into the currently focused field on the iOS Simulator. Requires idb (pip3 install fb-idb).",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "text": .object([
                    "type": "string",
                    "description": "Text to type"
                ]),
                "simulator_udid": .object([
                    "type": "string",
                    "description": "Simulator UDID. Default: first booted simulator"
                ]),
            ]),
            "required": .array([.string("text")])
        ])
    ),
    Tool(
        name: "simulator_describe",
        description: "Get the accessibility tree of the current iOS Simulator screen as JSON. Useful for finding UI elements to interact with. Requires idb (pip3 install fb-idb).",
        inputSchema: .object([
            "type": "object",
            "properties": .object([
                "simulator_udid": .object([
                    "type": "string",
                    "description": "Simulator UDID. Default: first booted simulator"
                ]),
            ]),
        ])
    ),
]

// MARK: - Handler Registration

await server.withMethodHandler(ListTools.self) { _ in
    ListTools.Result(tools: tools)
}

await server.withMethodHandler(CallTool.self) { params in
    do {
        switch params.name {
        case "xcode_build":
            let projectPath = params.arguments?["project_path"]?.stringValue ?? ""
            let scheme = params.arguments?["scheme"]?.stringValue
            let configuration = params.arguments?["configuration"]?.stringValue ?? "Debug"
            let destination = params.arguments?["destination"]?.stringValue

            let result = try await XcodeBuildTool.run(
                projectPath: projectPath,
                scheme: scheme,
                configuration: configuration,
                destination: destination,
                extraArgs: []
            )
            return CallTool.Result(
                content: [.text(text: result.toJSON(), annotations: nil, _meta: nil)],
                isError: !result.succeeded
            )

        case "xcode_run":
            let projectPath = params.arguments?["project_path"]?.stringValue ?? ""
            let bundleId = params.arguments?["bundle_identifier"]?.stringValue ?? ""
            let scheme = params.arguments?["scheme"]?.stringValue
            let configuration = params.arguments?["configuration"]?.stringValue ?? "Debug"
            let simulatorUDID = params.arguments?["simulator_udid"]?.stringValue

            let result = try await XcodeRunTool.run(
                projectPath: projectPath,
                scheme: scheme,
                bundleIdentifier: bundleId,
                configuration: configuration,
                simulatorUDID: simulatorUDID
            )
            return CallTool.Result(content: [.text(text: result, annotations: nil, _meta: nil)])

        case "simulator_screenshot":
            let simulatorUDID = params.arguments?["simulator_udid"]?.stringValue
            let screenshot = try await SimulatorScreenshotTool.capture(simulatorUDID: simulatorUDID)
            return CallTool.Result(
                content: [.image(data: screenshot.base64, mimeType: screenshot.mimeType, annotations: nil, _meta: nil)]
            )

        case "simulator_tap":
            let x = params.arguments?["x"]?.doubleValue ?? 0
            let y = params.arguments?["y"]?.doubleValue ?? 0
            let duration = params.arguments?["duration"]?.doubleValue
            let simulatorUDID = params.arguments?["simulator_udid"]?.stringValue

            let result = try await SimulatorTapTool.tap(
                x: x, y: y, duration: duration,
                simulatorUDID: simulatorUDID, idb: idbService
            )
            return CallTool.Result(content: [.text(text: result, annotations: nil, _meta: nil)])

        case "simulator_type":
            let text = params.arguments?["text"]?.stringValue ?? ""
            let simulatorUDID = params.arguments?["simulator_udid"]?.stringValue

            let result = try await SimulatorTypeTool.type(
                text: text, simulatorUDID: simulatorUDID, idb: idbService
            )
            return CallTool.Result(content: [.text(text: result, annotations: nil, _meta: nil)])

        case "simulator_describe":
            let simulatorUDID = params.arguments?["simulator_udid"]?.stringValue

            let result = try await SimulatorDescribeTool.describe(
                simulatorUDID: simulatorUDID, idb: idbService
            )
            return CallTool.Result(content: [.text(text: result, annotations: nil, _meta: nil)])

        default:
            throw MCPError.invalidParams("Unknown tool: \(params.name)")
        }
    } catch {
        return CallTool.Result(
            content: [.text(text: "Error: \(error)", annotations: nil, _meta: nil)],
            isError: true
        )
    }
}

// MARK: - Start Server

let transport = StdioTransport()
try await server.start(transport: transport)
await server.waitUntilCompleted()

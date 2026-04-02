# xcode-studio-mcp

## Project Overview
Unified MCP server for iOS development lifecycle: build, deploy, screenshot, interact with iOS Simulator.

## Tech Stack
- Swift 6.3 with Swift Package Manager
- Official Swift MCP SDK (`modelcontextprotocol/swift-sdk` v0.11.0+)
- Stdio transport for MCP communication
- Wraps: `xcodebuild`, `xcrun simctl`, `idb` CLI

## Architecture
- `Sources/XcodeStudioMCP/main.swift` - MCP server setup, tool registration, request dispatch
- `Tools/` - One file per tool, each is a static enum with a `run`/`capture`/etc method
- `Services/` - Shared infrastructure (ProcessRunner, SimulatorService, IDBService, XcodeBuildParser)
- `Models/` - Codable data structures (BuildDiagnostic, BuildResult, SimulatorInfo)

## Build & Run
```bash
swift build           # debug build
swift build -c release  # release build
.build/release/XcodeStudioMCP  # runs on stdio (for MCP client)
```

## Key Patterns
- `ProcessRunner.run()` is the async wrapper for all subprocess calls
- `SimulatorService.resolveUDID()` auto-detects booted simulator when UDID not specified
- `XcodeBuildParser.parse()` extracts structured diagnostics from xcodebuild output
- `IDBService` is an actor that lazily resolves the `idb` binary path
- All tools return `CallTool.Result` with `.text()` or `.image()` content

## Dependencies
- `idb_companion` (brew) + `fb-idb` (pip3) required for tap/type/describe tools
- `xcrun simctl` and `xcodebuild` required (ships with Xcode)

# xcode-studio-mcp

**Unified MCP server for Xcode + iOS Simulator** — build, deploy, screenshot, and interact with your iOS app from [Claude Code](https://claude.ai/claude-code), [Codex](https://openai.com/codex/), [Cursor](https://cursor.sh), or any MCP client.

Built in Swift. Single binary. No Node/Python runtime required.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![MCP](https://img.shields.io/badge/MCP-compatible-green.svg)](https://modelcontextprotocol.io)

## Why This Exists

Today you need 2-3 separate tools to do the full iOS dev loop with an AI agent. **xcode-studio-mcp** combines them into one:

```
Write code → Build → Deploy to Simulator → Screenshot → Tap/Type → Verify
```

### Tools

| Tool | Description |
|------|-------------|
| `xcode_build` | Build an Xcode project with structured error output (file, line, column, severity, message) |
| `xcode_run` | Build and launch an app in the iOS Simulator |
| `simulator_screenshot` | Capture the Simulator screen as a PNG image |
| `simulator_tap` | Tap at x,y coordinates on the Simulator screen |
| `simulator_type` | Type text into the currently focused field |
| `simulator_describe` | Get the accessibility tree of the current screen (JSON) |

## Tool Parameters

### `xcode_build`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `project_path` | Yes | Path to Xcode project directory, `.xcodeproj`, or `.xcworkspace` |
| `scheme` | No | Build scheme (auto-detected if omitted) |
| `configuration` | No | `Debug` (default) or `Release` |
| `destination` | No | Build destination (defaults to booted simulator) |

### `xcode_run`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `project_path` | Yes | Path to Xcode project |
| `bundle_identifier` | Yes | App bundle ID (e.g. `com.example.MyApp`) |
| `scheme` | No | Build scheme (auto-detected) |
| `simulator_udid` | No | Target simulator (defaults to booted) |

### `simulator_screenshot`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `simulator_udid` | No | Target simulator (defaults to booted) |

### `simulator_tap`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `x` | Yes | X coordinate |
| `y` | Yes | Y coordinate |
| `duration` | No | Hold duration in seconds (for long press) |
| `simulator_udid` | No | Target simulator |

### `simulator_type`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `text` | Yes | Text to type |
| `simulator_udid` | No | Target simulator |

### `simulator_describe`
| Parameter | Required | Description |
|-----------|----------|-------------|
| `simulator_udid` | No | Target simulator |

## Quick Start

### Prerequisites

- macOS with Xcode installed
- For UI interaction tools (`tap`, `type`, `describe`):
  ```bash
  brew tap facebook/fb && brew install idb-companion
  pip3 install fb-idb
  ```

### Build

```bash
git clone https://github.com/kevinswint/xcode-studio-mcp.git
cd xcode-studio-mcp
swift build -c release
```

### Configure Claude Code

Add to your Claude Code MCP settings:

```json
{
  "mcpServers": {
    "xcode-studio-mcp": {
      "command": "/path/to/xcode-studio-mcp/.build/release/XcodeStudioMCP"
    }
  }
}
```

## Example Workflow

```
You: Build and run my app at ~/Projects/MyApp
Claude: [calls xcode_build] Build succeeded with 0 errors
        [calls xcode_run] App launched (PID 12345)
        [calls simulator_screenshot] Here's what the app looks like...
        [calls simulator_describe] I can see a "Sign In" button and email/password fields
        [calls simulator_tap] Tapped the email field
        [calls simulator_type] Typed "test@example.com"
        [calls simulator_screenshot] Here's the current state...
```

## Architecture

```
┌─────────────────────────────┐
│     MCP Protocol Layer      │  stdio transport (Swift MCP SDK)
├─────────────────────────────┤
│   Tool Implementations      │  6 tools, structured error output
├──────────┬──────────────────┤
│ xcodebuild│  simctl  │  idb │  native process calls
│  wrapper  │  wrapper │ CLI  │
└──────────┴──────────┴──────┘
```

Built in Swift with zero Node/Python runtime dependencies (idb CLI is only needed for UI interaction tools).

## Roadmap

- **v0.1** (current): Core build + simulator tools
- **v1.0**: Semantic UI navigation ("tap the Sign In button"), visual diff, Xcode project file manipulation, compound operations, SwiftUI preview capture

## Related Projects

| Project | What It Does | Difference |
|---------|-------------|------------|
| [XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP) | Build + test only | No simulator UI interaction |
| [mobile-mcp](https://github.com/mobile-next/mobile-mcp) | Cross-platform simulator UI | No Xcode build support |
| [ios-simulator-mcp](https://github.com/joshuayoes/ios-simulator-mcp) | Simulator via IDB | No build, depends on IDB for everything |

**xcode-studio-mcp** combines build _and_ interact into a single server.

## Contributing

PRs welcome. The codebase is ~750 lines of Swift organized into Tools, Services, and Models.

## License

MIT

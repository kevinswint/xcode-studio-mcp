# xcode-studio-mcp

A unified MCP server that gives AI coding agents full control over the iOS development lifecycle: **build, deploy, see, interact, and verify** — all from a single tool.

## What It Does

No more chaining multiple tools together. One MCP server handles the complete loop:

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

## License

MIT

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "xcode-studio-mcp",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "XcodeStudioMCP", targets: ["XcodeStudioMCP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.11.0"),
    ],
    targets: [
        .executableTarget(
            name: "XcodeStudioMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
            ]
        ),
    ]
)

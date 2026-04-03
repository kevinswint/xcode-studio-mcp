FROM swift:6.0-jammy AS builder

WORKDIR /app
COPY Package.swift Package.resolved* ./
COPY Sources/ Sources/

RUN swift build -c release

FROM swift:6.0-jammy-slim

COPY --from=builder /app/.build/release/XcodeStudioMCP /usr/local/bin/XcodeStudioMCP

ENTRYPOINT ["XcodeStudioMCP"]

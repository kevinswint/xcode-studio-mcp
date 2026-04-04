FROM swift:6.0-jammy AS builder

WORKDIR /app
COPY Package.swift Package.resolved* ./
COPY Sources/ Sources/

RUN swift build -c release

FROM ubuntu:22.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4 \
    libxml2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/lib/swift/linux/lib*.so /usr/lib/swift/linux/
COPY --from=builder /app/.build/release/XcodeStudioMCP /usr/local/bin/XcodeStudioMCP

ENV LD_LIBRARY_PATH=/usr/lib/swift/linux

ENTRYPOINT ["/usr/local/bin/XcodeStudioMCP"]

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/coucou-chat-parsing.XXXXXX")"
trap 'rm -rf "$TEST_DIR"' EXIT

swiftc \
    NotchBuddy/Sources/App/LocalChat.swift \
    NotchBuddy/Sources/App/ChatMarkdown.swift \
    tests/ChatParsingTests.swift \
    -o "$TEST_DIR/chat-parsing-tests"

"$TEST_DIR/chat-parsing-tests"

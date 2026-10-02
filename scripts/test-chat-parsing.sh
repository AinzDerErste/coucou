#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

TEST_DIR="$(mktemp -d "${TMPDIR:-/tmp}/coucou-chat-parsing.XXXXXX")"
trap 'rm -rf "$TEST_DIR"; kill "$SERVER_PID" 2>/dev/null || true' EXIT

# ── Start fake LLM server ────────────────────────────────────────────────────
PORT_FILE="$TEST_DIR/port.txt"
python3 tests/fake_local_llm.py "$PORT_FILE" &
SERVER_PID=$!

# Wait up to 3 s for the server to write its port
for i in $(seq 1 30); do
    [ -s "$PORT_FILE" ] && break
    sleep 0.1
done

if [ ! -s "$PORT_FILE" ]; then
    echo "ERROR: fake LLM server did not start in time" >&2
    exit 1
fi

PORT=$(cat "$PORT_FILE")
echo "Fake LLM server listening on port $PORT (PID $SERVER_PID)"

# ── Compile test binary ──────────────────────────────────────────────────────
swiftc \
    NotchBuddy/Sources/App/LocalChat.swift \
    NotchBuddy/Sources/App/ChatMarkdown.swift \
    tests/ChatParsingTests.swift \
    -o "$TEST_DIR/chat-parsing-tests"

# ── Run tests ────────────────────────────────────────────────────────────────
"$TEST_DIR/chat-parsing-tests" "$PORT"

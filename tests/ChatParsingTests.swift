import Foundation

// MARK: - Tests for LocalChat and ChatMarkdown

@main
enum ChatParsingTests {
    static var failures = 0

    static func check(_ label: String, _ got: String, _ expected: String) {
        if got == expected {
            print("  ✓ \(label)")
        } else {
            print("  ✗ \(label)")
            print("    got:      \(got.debugDescription)")
            print("    expected: \(expected.debugDescription)")
            failures += 1
        }
    }

    static func checkTrue(_ label: String, _ value: Bool) {
        if value {
            print("  ✓ \(label)")
        } else {
            print("  ✗ \(label)")
            failures += 1
        }
    }

    static func main() {
        // MARK: - LocalChat.normaliseURL

        print("LocalChat.normaliseURL")
        check("strips trailing slash", LocalChat.normaliseURL("http://localhost:11434/"), "http://localhost:11434")
        check("strips /api suffix",    LocalChat.normaliseURL("http://localhost:11434/api"), "http://localhost:11434")
        check("strips /v1 suffix",     LocalChat.normaliseURL("http://localhost:1234/v1"), "http://localhost:1234")
        check("no-op clean URL",       LocalChat.normaliseURL("http://localhost:11434"), "http://localhost:11434")
        check("trims whitespace",      LocalChat.normaliseURL("  http://localhost:11434  "), "http://localhost:11434")

        // MARK: - LocalChat.parseSSEDelta

        print("LocalChat.parseSSEDelta")
        let sseData = #"data: {"id":"1","choices":[{"delta":{"content":"hello"}}]}"#
        check("parses delta", LocalChat.parseSSEDelta(sseData) ?? "", "hello")
        checkTrue("ignores [DONE]", LocalChat.parseSSEDelta("data: [DONE]") == nil)
        checkTrue("ignores non-data", LocalChat.parseSSEDelta(": heartbeat") == nil)
        checkTrue("ignores empty content", LocalChat.parseSSEDelta(#"data: {"choices":[{"delta":{}}]}"#) == nil)

        // MARK: - LocalChat.filterThinkingBlocks

        print("LocalChat.filterThinkingBlocks")
        check("removes think block",       LocalChat.filterThinkingBlocks("<think>internal</think>answer"), "answer")
        check("no-op without think block", LocalChat.filterThinkingBlocks("hello"),                         "hello")
        check("multiline think block",     LocalChat.filterThinkingBlocks("<think>\nstep1\nstep2\n</think>result"), "result")

        // MARK: - ChatMarkdown.parse

        print("ChatMarkdown.parse")
        let blocks = ChatMarkdown.parse("## Hello\n\nThis is a paragraph.\n\n- item 1\n- item 2\n\n```swift\nlet x = 1\n```")
        checkTrue("heading count",     blocks.filter { if case .heading = $0 { return true }; return false }.count == 1)
        checkTrue("paragraph count",   blocks.filter { if case .paragraph = $0 { return true }; return false }.count == 1)
        checkTrue("list item count",   blocks.filter { if case .listItem = $0 { return true }; return false }.count == 2)
        checkTrue("code block count",  blocks.filter { if case .codeBlock = $0 { return true }; return false }.count == 1)

        // Check heading level
        if case .heading(let level, let text) = blocks.first(where: { if case .heading = $0 { return true }; return false })! {
            checkTrue("heading level 2", level == 2)
            checkTrue("heading text", text == "Hello")
        } else {
            print("  ✗ first heading not found"); failures += 1
        }

        // MARK: - Result

        if failures == 0 {
            print("\nAll tests passed.")
            exit(0)
        } else {
            print("\n\(failures) test(s) failed.")
            exit(1)
        }
    }
}

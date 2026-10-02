import Foundation

// MARK: - Local model helpers (Foundation only — importable by both app and test target)

enum LocalChat {

    /// Removes trailing slashes and known sub-paths (e.g. /api, /v1) that users
    /// sometimes copy from documentation. Returns a clean base URL string.
    static func normaliseURL(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        while s.hasSuffix("/") { s = String(s.dropLast()) }
        for suffix in ["/api", "/v1"] {
            if s.hasSuffix(suffix) { s = String(s.dropLast(suffix.count)) }
        }
        return s
    }

    /// Parses `delta.content` from a single SSE event line in the OpenAI streaming format.
    /// Returns nil for non-data lines, heartbeats, `[DONE]`, or absent content.
    static func parseSSEDelta(_ line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }
        let payload = String(line.dropFirst(6))
        guard payload != "[DONE]" else { return nil }
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else { return nil }
        return content
    }

    /// Strips `<think>…</think>` blocks (used by reasoning models like DeepSeek-R1).
    static func filterThinkingBlocks(_ text: String) -> String {
        let pattern = "<think>[\\s\\S]*?</think>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

import Foundation

// MARK: - Markdown block types

enum MDBlock {
    case heading(level: Int, text: String)
    case paragraph(text: String)
    case codeBlock(lang: String, code: String)
    case listItem(text: String)
    case rule
}

// MARK: - Parser (Foundation only — testable without SwiftUI)

enum ChatMarkdown {

    /// Splits a markdown string into top-level blocks.
    static func parse(_ input: String) -> [MDBlock] {
        var blocks: [MDBlock] = []
        let lines = input.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            let line = lines[i]

            // Fenced code block
            if line.hasPrefix("```") {
                let lang = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].hasPrefix("```") {
                    code.append(lines[i])
                    i += 1
                }
                blocks.append(.codeBlock(lang: lang, code: code.joined(separator: "\n")))
                i += 1
                continue
            }

            // ATX heading
            if line.hasPrefix("#") {
                var level = 0
                var rest = line
                while rest.hasPrefix("#") { level += 1; rest = String(rest.dropFirst()) }
                let text = rest.trimmingCharacters(in: .whitespaces)
                if !text.isEmpty { blocks.append(.heading(level: min(level, 6), text: text)) }
                i += 1
                continue
            }

            // Horizontal rule
            let stripped = line.trimmingCharacters(in: .whitespaces)
            if stripped == "---" || stripped == "***" || stripped == "___" {
                blocks.append(.rule)
                i += 1
                continue
            }

            // List item (-, *, +, or numbered)
            if stripped.hasPrefix("- ") || stripped.hasPrefix("* ") || stripped.hasPrefix("+ ") {
                let text = String(stripped.dropFirst(2))
                blocks.append(.listItem(text: text))
                i += 1
                continue
            }
            if let colonRange = stripped.range(of: "^\\d+\\.\\s+", options: .regularExpression) {
                let text = String(stripped[colonRange.upperBound...])
                blocks.append(.listItem(text: text))
                i += 1
                continue
            }

            // Blank line — skip
            if stripped.isEmpty {
                i += 1
                continue
            }

            // Paragraph: accumulate consecutive non-special lines
            var paragraphLines: [String] = [line]
            i += 1
            while i < lines.count {
                let next = lines[i]
                let nextStripped = next.trimmingCharacters(in: .whitespaces)
                if nextStripped.isEmpty { break }
                if next.hasPrefix("#") || next.hasPrefix("```") { break }
                if nextStripped.hasPrefix("- ") || nextStripped.hasPrefix("* ") || nextStripped.hasPrefix("+ ") { break }
                if nextStripped == "---" || nextStripped == "***" || nextStripped == "___" { break }
                paragraphLines.append(next)
                i += 1
            }
            blocks.append(.paragraph(text: paragraphLines.joined(separator: "\n")))
        }
        return blocks
    }
}

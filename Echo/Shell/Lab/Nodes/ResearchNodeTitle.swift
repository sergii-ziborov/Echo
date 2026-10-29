import UIKit

/// Keep whole words on two balanced lines. Measuring the actual font avoids
/// UIKit's fallback to splitting the last letter of a long Russian word.
@MainActor
enum ResearchNodeTitle {
    static func layout(_ title: String, width: CGFloat) -> (text: String, fontSize: CGFloat) {
        let words = title.split(whereSeparator: \.isWhitespace).map(String.init)
        let lines: [String]
        if words.count > 1 {
            let split = (1..<words.count).min { a, b in
                longestLine(at: a, words: words) < longestLine(at: b, words: words)
            } ?? 1
            lines = [words[..<split].joined(separator: " "), words[split...].joined(separator: " ")]
        } else {
            lines = [title]
        }
        let font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        let longest = lines.map { ($0 as NSString).size(withAttributes: [.font: font]).width }.max() ?? 1
        let fontSize = min(10, max(6.6, 10 * max(1, width - 4) / max(1, longest)))
        return (lines.joined(separator: "\n"), fontSize)
    }

    private static func longestLine(at split: Int, words: [String]) -> Int {
        max(words[..<split].joined(separator: " ").count,
            words[split...].joined(separator: " ").count)
    }

}

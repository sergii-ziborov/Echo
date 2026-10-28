import SwiftUI

/// Two balanced lines, each allowed to shrink as a whole. SwiftUI's normal
/// wrapping can otherwise strand the last letter of a long Russian word.
struct ResearchNodeTitle: View {
    let title: String

    private var lines: [String] {
        let words = title.split(whereSeparator: \.isWhitespace).map(String.init)
        guard words.count > 1 else { return [title] }
        let split = (1..<words.count).min { a, b in
            longestLine(at: a, words: words) < longestLine(at: b, words: words)
        } ?? 1
        return [words[..<split].joined(separator: " "), words[split...].joined(separator: " ")]
    }

    private func longestLine(at split: Int, words: [String]) -> Int {
        max(words[..<split].joined(separator: " ").count,
            words[split...].joined(separator: " ").count)
    }

    var body: some View {
        let lines = lines
        VStack(spacing: 0) {
            ForEach(lines.indices, id: \.self) { index in
                Text(lines[index])
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.system(size: 10, weight: .semibold))
        .multilineTextAlignment(.center)
        .frame(height: 26)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
    }
}

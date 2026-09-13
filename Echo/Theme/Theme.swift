import SwiftUI

enum EchoTheme {
    static let navy = Color(red: 0.051, green: 0.122, blue: 0.259)
    static let navyDeep = Color(red: 0.02, green: 0.05, blue: 0.12)
    static let panel = Color(red: 0.07, green: 0.14, blue: 0.28)
    static let panelStroke = Color.white.opacity(0.10)
    static let cyan = Color(red: 0.31, green: 0.78, blue: 1.0)
    static let cyanBright = Color(red: 0.72, green: 0.93, blue: 1.0)
    static let magenta = Color(red: 0.72, green: 0.38, blue: 1.0)
    static let violet = Color(red: 0.45, green: 0.28, blue: 0.92)
    static let gold = Color(red: 1.0, green: 0.84, blue: 0.32)
    static let goldDim = Color(red: 0.45, green: 0.48, blue: 0.62)
    static let danger = Color(red: 1.0, green: 0.32, blue: 0.42)
    static let primaryBlue = Color(red: 0.18, green: 0.48, blue: 1.0)
    static let primaryBlueHi = Color(red: 0.32, green: 0.62, blue: 1.0)
    static let muted = Color.white.opacity(0.55)
    static let text = Color.white

    static let titleFont: Font = .system(size: 56, weight: .ultraLight, design: .default)
    static let wordmarkTracking: CGFloat = 14
}

extension LinearGradient {
    static let primaryButton = LinearGradient(
        colors: [EchoTheme.primaryBlueHi, EchoTheme.primaryBlue],
        startPoint: .top,
        endPoint: .bottom
    )

    static let screenBackground = LinearGradient(
        colors: [EchoTheme.navyDeep, EchoTheme.navy, Color(red: 0.04, green: 0.08, blue: 0.18)],
        startPoint: .top,
        endPoint: .bottom
    )
}

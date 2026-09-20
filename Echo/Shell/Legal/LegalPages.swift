import SwiftUI

enum LegalDocument: String, Identifiable, CaseIterable {
    case about
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .about: "About"
        case .terms: "Terms of Use"
        case .privacy: "Privacy"
        }
    }

    var paragraphs: [String] {
        switch self {
        case .about:
            [
                "ECHO is a one-time iPhone and iPad puzzle. Steer a glowing orb, collect sparks, and outlive the route you just drew.",
                "The App Store build is a paid download. There are no ads, subscriptions, or in-app purchases. Progress stays on this device.",
                "Version \(LegalDocument.shortVersion) (\(LegalDocument.buildNumber)). © 2026 Sergii Ziborov.",
                "Support: sergii.ziborov@gmail.com",
            ]
        case .terms:
            [
                "A paid App Store download of ECHO grants a personal, non-transferable license to play the compiled app on devices associated with your Apple ID, subject to Apple’s Licensed Application End User License Agreement.",
                "The purchase is a one-time app download. The current build does not offer subscriptions, consumable items, or advertising. Features, maps, and balance may change in later updates.",
                "You may not copy, reverse engineer, redistribute, or reuse the app, source, artwork, or audio except as allowed by law or a separate written license from the copyright holder.",
                "Progress, settings, and records are stored on this device. Uninstalling the app or using Reset progress permanently removes that local data.",
                "ECHO is provided as-is. To the extent permitted by law, the developer is not liable for lost progress, device issues, or indirect damages. Your statutory consumer rights remain unchanged.",
                "Questions: sergii.ziborov@gmail.com",
            ]
        case .privacy:
            [
                "ECHO does not collect personal data and does not require an account.",
                "Stars, shards, inventory, research, last map, and audio or haptic preferences are stored only on this device with Apple’s standard UserDefaults.",
                "The app does not include analytics, advertising, tracking, or network calls required to play.",
                "If this policy changes, the App Store listing and the public PRIVACY.md file will be updated together.",
                "Contact: sergii.ziborov@gmail.com",
            ]
        }
    }

    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "17"
    }
}

struct LegalPageView: View {
    let document: LegalDocument
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 12) {
                HStack(spacing: 11) {
                    IconCircle(system: "chevron.left") {
                        onBack?()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(document.title.uppercased())
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .tracking(1.4)
                        Text("ECHO")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 4)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(document.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.white.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(EchoTheme.panel.opacity(0.94), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.bottom, 28)
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }
}

import SwiftUI
import UIKit

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
                "ECHO is a one-time puzzle for iPhone, iPad and Apple Watch. You are the Signal, the last light of the Lighthouse: carry it down the Fold Road through eleven regions of space, collect sparks, and outlive the route you just drew.",
                "Seventy-seven campaign maps, the endless Deep Time, a Daily Rift, and twelve clockwork rooms on the watch, which can also steer a run on the phone.",
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
                "With a paired Apple Watch, wrist clears and relics pass between your iPhone and the watch through Apple’s WatchConnectivity, and a run steered from the watch sends its controls the same way. That stays between your own devices.",
                "Report a bug opens your mail app with a message to the developer that already names the app version, device model and system version. Nothing is sent unless you send it, and the message is used only to answer you and fix the problem.",
                "If this policy changes, the App Store listing and the public PRIVACY.md file will be updated together.",
                "Contact: sergii.ziborov@gmail.com",
            ]
        }
    }

    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "18"
    }
}

/// A bug report is an email the player sends themselves, with the details
/// that help reproduce the problem filled in; GitHub Issues is the fallback
/// when no mail account is set up.
enum BugReport {
    static let address = "sergii.ziborov@gmail.com"
    static let issues = URL(string: "https://github.com/sergii-ziborov/Echo/issues")!

    static var mail: URL? {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = address
        parts.queryItems = [
            URLQueryItem(name: "subject", value: "ECHO bug report (\(LegalDocument.shortVersion) build \(LegalDocument.buildNumber))"),
            URLQueryItem(name: "body", value: "What happened:\n\n\nWhat you expected:\n\n\nMap or screen:\n\n—\nECHO \(LegalDocument.shortVersion) (\(LegalDocument.buildNumber)) · \(model) · iOS \(UIDevice.current.systemVersion)"),
        ]
        return parts.url
    }

    /// The hardware identifier, such as iPhone14,4, which names the exact model.
    static var model: String {
        var info = utsname()
        uname(&info)
        return withUnsafeBytes(of: &info.machine) { raw in
            String(decoding: raw.prefix { $0 != 0 }, as: UTF8.self)
        }
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

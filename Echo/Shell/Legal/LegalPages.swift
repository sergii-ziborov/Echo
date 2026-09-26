import SwiftUI
import UIKit

enum LegalDocument: String, Identifiable, CaseIterable {
    case about
    case terms
    case privacy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .about: Copy.text("legal.about")
        case .terms: Copy.text("legal.terms")
        case .privacy: Copy.text("legal.privacy")
        }
    }

    /// About tells what the game is and how far the story begins, never how
    /// it ends; Terms and Privacy stay plain facts in the app's language.
    var paragraphs: [String] {
        switch self {
        case .about:
            [
                Copy.text("about.game"),
                Copy.text("about.world"),
                Copy.format("about.features", LevelCatalog.playable.count, Act.allCases.count, WristCatalog.maps.count),
                Copy.text("about.science"),
                Copy.text("about.purchase"),
                Copy.text("about.data"),
                Copy.text("about.credits") + " " + Copy.format("about.version", LegalDocument.shortVersion, LegalDocument.buildNumber),
                Copy.format("legal.support", BugReport.address),
            ]
        case .terms:
            ["terms.license", "terms.purchase", "terms.limits", "terms.progress", "terms.disclaimer"].map { Copy.text($0) }
                + [Copy.format("legal.questions", BugReport.address)]
        case .privacy:
            ["privacy.none", "privacy.local", "privacy.network", "privacy.watch", "privacy.report", "privacy.changes"].map { Copy.text($0) }
                + [Copy.format("legal.contact", BugReport.address)]
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

    @MainActor
    static var mail: URL? {
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = address
        parts.queryItems = [
            URLQueryItem(name: "subject", value: Copy.format("support.subject", LegalDocument.shortVersion, LegalDocument.buildNumber)),
            URLQueryItem(name: "body", value: Copy.text("support.body") + "\n\n\n—\nECHO \(LegalDocument.shortVersion) (\(LegalDocument.buildNumber)) · \(model) · iOS \(UIDevice.current.systemVersion) · \(Bundle.main.preferredLocalizations.first ?? "en")"),
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

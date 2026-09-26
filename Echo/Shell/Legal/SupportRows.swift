import SwiftUI
import UIKit

/// A row in the Settings cards: an icon tile, a title, an optional second
/// line and a trailing glyph.
private struct SupportRowLabel: View {
    let icon: String
    let tint: Color
    let title: String
    var detail: String?
    let trailing: String

    var body: some View {
        HStack(spacing: 11) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                if let detail {
                    Text(detail)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(EchoTheme.muted)
                        .lineLimit(2)
                }
            }
            Spacer()
            Image(systemName: trailing)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(minHeight: 58)
    }
}

/// iOS keeps each app's language in its own Settings page; this row names
/// the current one and opens that page.
struct LanguageRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            model.audio.play(.select)
            if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
        } label: {
            SupportRowLabel(
                icon: "globe",
                tint: EchoTheme.gold,
                title: Copy.text("settings.language"),
                detail: Copy.format("settings.language.detail", Self.currentLanguage),
                trailing: "arrow.up.forward.app"
            )
        }
        .buttonStyle(PressStyle())
    }

    static var currentLanguage: String {
        let code = Bundle.main.preferredLocalizations.first ?? "en"
        return Locale(identifier: code).localizedString(forLanguageCode: code)?.capitalized ?? code
    }
}

/// Opens a prefilled email to the developer, or GitHub Issues when no mail
/// account is set up.
struct BugReportRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            model.audio.play(.select)
            guard let mail = BugReport.mail else { return openURL(BugReport.issues) }
            openURL(mail) { opened in
                if !opened { openURL(BugReport.issues) }
            }
        } label: {
            SupportRowLabel(icon: "ladybug.fill", tint: EchoTheme.gold, title: Copy.text("settings.report"), trailing: "envelope.fill")
        }
        .buttonStyle(PressStyle())
        .accessibilityHint(Copy.text("settings.report.hint"))
    }
}

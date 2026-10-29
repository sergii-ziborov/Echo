import SwiftUI

struct MonetizationSettingsRow: View {
    @Environment(AppModel.self) private var model
    @State private var presented = false
    var body: some View {
        Button {
            guard model.monetization.modal.acquire(.purchase) else { return }
            presented = true
        } label: {
            Label(Copy.text("monetization.title"), systemImage: "checkmark.shield")
                .font(.body.weight(.semibold)).frame(maxWidth: .infinity, alignment: .leading).padding()
                .foregroundStyle(EchoTheme.cyan)
                .background(EchoTheme.panel, in: RoundedRectangle(cornerRadius: 18))
        }
        .accessibilityIdentifier("settings.monetization")
        .sheet(isPresented: $presented, onDismiss: { model.monetization.modal.release(.purchase) }) {
            MonetizationSettingsView(coordinator: model.monetization)
        }
    }
}

struct MonetizationSettingsView: View {
    let coordinator: MonetizationCoordinator
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(spacing: 0) {
            RemoveAdsView(purchases: coordinator.purchases)
            VStack(alignment: .leading, spacing: 8) {
                // Remains reachable for a purchaser who previously used advertising.
                Button(Copy.text("privacy.options")) {
                    Task {
                        coordinator.modal.release(.purchase)
                        await coordinator.showPrivacyOptions()
                        _ = coordinator.modal.acquire(.purchase)
                    }
                }.frame(minHeight: 44)
                if let key = coordinator.privacy.messageKey { Text(Copy.text(key)).font(.footnote) }
                Button(Copy.text("ads.report")) { openURL(AdReport.mail(diagnosticID: coordinator.lastAdDiagnostic, date: coordinator.lastAdStartedAt)) }.frame(minHeight: 44)
            }.padding(.horizontal, 24).padding(.bottom, 12).frame(maxWidth: 620, alignment: .leading)
        }
    }
}

struct HomeMonetizationRow: View {
    @Environment(AppModel.self) private var model
    @AppStorage("echo.monetization.legacyNoticeShown.v1") private var legacyNoticeShown = false
    @State private var presented = false
    var body: some View {
        Group {
            if model.monetization.purchases.purchaseOffered {
                Button(Copy.text("monetization.playAdFree")) {
                    guard model.monetization.modal.acquire(.purchase) else { return }
                    presented = true
                }
                .font(.footnote).foregroundStyle(EchoTheme.muted).frame(minHeight: 44)
            } else if case .adFreeLegacy = model.monetization.purchases.entitlements.state, !legacyNoticeShown {
                HStack(alignment: .top) {
                    Text(Copy.text("monetization.legacyNotice")).font(.footnote).foregroundStyle(EchoTheme.muted)
                    Button { legacyNoticeShown = true } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel(Copy.text("monetization.close"))
                }
                .onDisappear { legacyNoticeShown = true }
            }
        }
        .sheet(isPresented: $presented, onDismiss: { model.monetization.modal.release(.purchase) }) {
            RemoveAdsView(purchases: model.monetization.purchases)
        }
    }
}

enum AdReport {
    // No automatic send, raw transaction, advertising ID, route or receipt.
    static func mail(diagnosticID: String?, date: Date?) -> URL {
        var url = URLComponents()
        url.scheme = "mailto"; url.path = BugReport.address
        url.queryItems = [URLQueryItem(name: "subject", value: "ECHO — ad report"),
            URLQueryItem(name: "body", value: "\(Copy.text("ads.reportPrompt"))\n\nECHO \(LegalDocument.shortVersion) (\(LegalDocument.buildNumber))\nPlacement: campaign_result_to_next\nLast ad UTC: \(date.map { ISO8601DateFormatter().string(from: $0) } ?? "not available")\nDiagnostic: \(diagnosticID ?? "not available")")]
        return url.url!
    }
}

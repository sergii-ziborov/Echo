import SwiftUI

struct RemoveAdsView: View {
    @Bindable var purchases: StoreKitPurchaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        GeometryReader { viewport in
            content.frame(width: viewport.size.width, height: viewport.size.height)
        }
        .task { await purchases.loadProduct() }
    }

    private var content: some View {
        ScreenBackground().overlay {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Image(systemName: "sparkles").font(.largeTitle).foregroundStyle(EchoTheme.gold)
                        Spacer()
                        Color.clear.frame(width: 44, height: 44)
                    }
                    Text(Copy.text(purchases.effectivePolicy.phase == .preFree ? "monetization.title" : "monetization.headline")).font(.largeTitle.bold())
                    status.accessibilityIdentifier("monetization.status")
                    if purchases.purchaseOffered {
                        Text(Copy.text("monetization.description")).foregroundStyle(EchoTheme.muted)
                    }
                    if purchases.purchaseOffered {
                        if let product = purchases.product {
                            Button {
                                Task { await purchases.buy() }
                            } label: {
                                Text(Copy.text("monetization.removeAds") + " — " + product.displayPrice)
                                    .font(.headline).foregroundStyle(.black).frame(maxWidth: .infinity).padding()
                            }
                            .buttonStyle(.borderedProminent).tint(EchoTheme.cyan)
                            .disabled(!purchases.canPurchase)
                            .accessibilityIdentifier("monetization.buy")
                        } else if purchases.operation == .loadingProduct {
                            ProgressView(Copy.text("monetization.loadingProduct"))
                        } else {
                            Text(Copy.text("monetization.productUnavailable"))
                        }
                    }
                    if let key = purchases.messageKey {
                        Text(Copy.text(key)).accessibilityAddTraits(.updatesFrequently)
                    }
                    Button(Copy.text("monetization.restore")) { Task { await purchases.restore() } }
                        .disabled(purchases.operation != .idle)
                        .frame(minHeight: 44)
                        .accessibilityIdentifier("monetization.restore")
                    Button(Copy.text(purchases.entitlements.state.isConclusiveFree ? "monetization.continueFree" : "monetization.close")) { dismiss() }
                        .frame(minHeight: 44)
                    Text(Copy.text("monetization.legacyHelp")).font(.footnote).foregroundStyle(EchoTheme.muted)
                    HStack {
                        Link(Copy.text("legal.privacy"), destination: legalURL("privacy"))
                        Text("·")
                        Link(Copy.text("legal.terms"), destination: legalURL("terms"))
                    }.font(.footnote)
                }
                .padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
        }.overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .bold))
                    .frame(width: 44, height: 44).background(.black.opacity(0.3), in: Circle())
            }
            .accessibilityLabel(Copy.text("monetization.close"))
            .accessibilityIdentifier("monetization.close")
            .padding(16)
        }
    }
    private func legalURL(_ page: String) -> URL {
        let prefix = LanguagePreference.shared.selection.resolvedCode() == "ru" ? "/ru" : ""
        return URL(string: "https://echo-survive-your-past.serhiiright.chatgpt.site\(prefix)/\(page)/")!
    }
    @ViewBuilder private var status: some View {
        if purchases.entitlements.state.isAdFree {
            Label(Copy.text(purchases.entitlements.state.statusKey), systemImage: "checkmark.shield")
        } else if purchases.effectivePolicy.phase == .preFree {
            Text(Copy.text("monetization.preFree"))
        } else {
            Label(Copy.text(purchases.entitlements.state.statusKey), systemImage: purchases.entitlements.state.isAdFree ? "checkmark.shield" : "info.circle")
        }
    }
}

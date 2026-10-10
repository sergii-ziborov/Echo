import SwiftUI

struct ArchiveRecoveryView: View {
    let finds: [ArchiveDiscovery]
    var onRead: (ArchiveDiscovery) -> Void
    var onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.68).ignoresSafeArea()
            GeometryReader { _ in
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 18) {
                        details
                        footer
                    }
                    VStack(spacing: 18) {
                        ScrollView { details }
                        footer
                    }
                }
                .padding(20)
                .background(
                    LinearGradient(colors: [EchoTheme.panel.opacity(0.98), EchoTheme.navyDeep.opacity(0.98)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(EchoTheme.gold.opacity(0.38), lineWidth: 1))
                .shadow(color: EchoTheme.gold.opacity(0.14), radius: 24, y: 10)
                .frame(maxWidth: 520)
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(.white)
        .accessibilityIdentifier("archive.recovery")
        .onAppear {
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.55)) { appeared = true }
        }
    }

    private var details: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().stroke(EchoTheme.gold.opacity(0.12), lineWidth: 1).frame(width: 104, height: 104)
                Circle().trim(from: 0.08, to: 0.78).stroke(EchoTheme.gold.opacity(0.55), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(appeared ? 20 : -50)).frame(width: 86, height: 86)
                Image(systemName: "waveform.path")
                    .font(.system(size: 33, weight: .light))
                    .foregroundStyle(EchoTheme.gold)
                    .shadow(color: EchoTheme.gold.opacity(0.45), radius: 12)
            }
            .scaleEffect(appeared ? 1 : 0.88)

            VStack(spacing: 7) {
                Text(Copy.text("archive.find.eyebrow")).font(.system(size: 9, weight: .black, design: .rounded)).tracking(2.6).foregroundStyle(EchoTheme.gold)
                Text(Copy.text("archive.find.title")).font(.system(size: 27, weight: .light)).multilineTextAlignment(.center)
                Text(Copy.format("archive.find.count", finds.count)).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(EchoTheme.muted)
            }

            VStack(spacing: 8) {
                ForEach(finds) { item in
                    Button { onRead(item) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.icon).font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(item.section.tint).frame(width: 39, height: 39)
                                .background(item.section.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.section.title.uppercased()).font(.system(size: 8, weight: .black, design: .rounded)).tracking(1).foregroundStyle(item.section.tint)
                                Text(item.title).font(.system(size: 14, weight: .bold, design: .rounded))
                                Text(item.requirement.recoveryReason).font(.system(size: 10, weight: .medium, design: .rounded)).foregroundStyle(EchoTheme.muted)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").font(.system(size: 10, weight: .bold)).foregroundStyle(EchoTheme.muted).padding(.top, 13)
                        }
                        .padding(13).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(item.section.tint.opacity(0.16), lineWidth: 1))
                    }
                    .buttonStyle(PressStyle())
                    .accessibilityHint(Copy.text("archive.find.read"))
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 14) {
            Text(Copy.text("archive.find.saved"))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(EchoTheme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: Copy.text("archive.find.continue"), systemImage: "checkmark", action: onContinue)
                .accessibilityIdentifier("archive.recovery.continue")
        }
    }
}

struct ArchiveSealedCard: View {
    let item: ArchiveDiscovery
    var body: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "lock.fill").font(.system(size: 15, weight: .bold)).foregroundStyle(EchoTheme.muted)
                .frame(width: 42, height: 42).background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 5) {
                Text(item.title).font(.system(size: 14, weight: .bold, design: .rounded))
                Text(item.requirement.instruction).font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(EchoTheme.muted)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(EchoTheme.panel.opacity(0.65), in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(EchoTheme.panelStroke, lineWidth: 1))
        .foregroundStyle(EchoTheme.muted)
    }
}

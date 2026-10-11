import SwiftUI

/// A collection opened from completed-run results, never a lesson over play.
struct ArchiveRecoveryView: View {
    let finds: [ArchiveDiscovery]
    var onRead: (ArchiveDiscovery) -> Void
    var onContinue: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72).ignoresSafeArea()
            GeometryReader { _ in
                VStack(spacing: 18) {
                    header
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 185), spacing: 10)], spacing: 10) {
                            ForEach(Array(finds.enumerated()), id: \.element.id) { index, item in
                                fragment(item)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 10)
                                    .animation(reduceMotion ? nil : .easeOut(duration: 0.35).delay(Double(index) * 0.045), value: appeared)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    VStack(spacing: 12) {
                        Text(Copy.text("archive.find.saved"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                            .multilineTextAlignment(.center)
                        PrimaryButton(title: Copy.text("archive.find.return"), systemImage: "checkmark", action: onContinue)
                            .accessibilityIdentifier("archive.recovery.continue")
                    }
                }
                .padding(22)
                .background(
                    LinearGradient(colors: [EchoTheme.panel.opacity(0.99), EchoTheme.navyDeep], startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                )
                .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(EchoTheme.gold.opacity(0.3), lineWidth: 1))
                .shadow(color: EchoTheme.gold.opacity(0.1), radius: 30, y: 12)
                .frame(maxWidth: 620, maxHeight: 780)
                .padding(.horizontal, 16).padding(.vertical, 22)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(.white)
        .accessibilityIdentifier("archive.recovery")
        .onAppear { appeared = true }
    }

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                ForEach(-1...1, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 10)
                        .fill(EchoTheme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(EchoTheme.gold.opacity(index == 0 ? 0.8 : 0.25), lineWidth: 1))
                        .frame(width: 45, height: 56)
                        .rotationEffect(.degrees(Double(index) * (appeared ? 17 : 0)))
                        .offset(x: CGFloat(index) * (appeared ? 26 : 0), y: CGFloat(abs(index)) * 6)
                }
                Image(systemName: "sparkle").font(.system(size: 25, weight: .light)).foregroundStyle(EchoTheme.gold)
            }
            .frame(height: 70)
            .shadow(color: EchoTheme.gold.opacity(0.25), radius: 15)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.5), value: appeared)
            Text(Copy.text("archive.find.eyebrow"))
                .font(.system(size: 9, weight: .black, design: .rounded)).tracking(2).foregroundStyle(EchoTheme.gold)
            Text(Copy.text("archive.find.title"))
                .font(.system(size: 26, weight: .light)).multilineTextAlignment(.center)
            Text(Copy.format("archive.find.count", finds.count))
                .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(EchoTheme.muted)
        }
    }

    private func fragment(_ item: ArchiveDiscovery) -> some View {
        Button { onRead(item) } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: item.icon).font(.system(size: 19, weight: .light))
                        .foregroundStyle(item.section.tint).frame(width: 38, height: 38)
                        .background(item.section.tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
                    Spacer()
                    Text(String(format: "%02d", item.fragmentNumber))
                        .font(.system(size: 21, weight: .light, design: .monospaced))
                        .foregroundStyle(EchoTheme.gold.opacity(0.6))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text(item.section.title.uppercased())
                        .font(.system(size: 8, weight: .black, design: .rounded)).tracking(1.2).foregroundStyle(item.section.tint)
                    Text(item.title).font(.system(size: 15, weight: .bold, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(item.excerpt).font(.system(size: 11, weight: .medium))
                        .foregroundStyle(EchoTheme.muted).lineLimit(2)
                }
                HStack {
                    Text(Copy.text("archive.find.open"))
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(EchoTheme.gold)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(item.section.tint.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .accessibilityHint(Copy.text("archive.find.read"))
    }
}

struct ArchiveRewardStrip: View {
    let finds: [ArchiveDiscovery]
    var onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8).stroke(EchoTheme.gold.opacity(0.25), lineWidth: 1)
                        .frame(width: 25, height: 32).rotationEffect(.degrees(-14)).offset(x: -5)
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 24, weight: .light)).foregroundStyle(EchoTheme.gold)
                }.frame(width: 38, height: 42)
                VStack(alignment: .leading, spacing: 3) {
                    Text(Copy.format("archive.find.count", finds.count))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text(Copy.text("archive.find.reward"))
                        .font(.system(size: 10, weight: .medium)).foregroundStyle(EchoTheme.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(EchoTheme.gold)
            }
            .padding(13).frame(maxWidth: .infinity, alignment: .leading)
            .background(EchoTheme.gold.opacity(0.065), in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).stroke(EchoTheme.gold.opacity(0.22), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
        .foregroundStyle(.white)
        .accessibilityIdentifier("results.archive.finds")
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

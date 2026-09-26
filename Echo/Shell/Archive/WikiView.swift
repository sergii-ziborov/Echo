import SwiftUI

struct WikiView: View {
    @Environment(AppModel.self) private var model
    @State var section: WikiSection

    init(section: WikiSection = .launch) {
        _section = State(initialValue: section)
    }

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                header

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        archiveHeader
                        sectionPicker
                        sectionContent
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 34)
                }
            }
        }
        .foregroundStyle(EchoTheme.text)
    }

    private var header: some View {
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") {
                model.audio.play(.tap)
                model.goHome()
            }
            .accessibilityLabel(Copy.text("archive.back"))

            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.text("archive.title"))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.2)
                Text(Copy.text("archive.revision"))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer()

            Image(systemName: "books.vertical.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(section.tint)
                .frame(width: 38, height: 38)
                .background(section.tint.opacity(0.13), in: Circle())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    private var archiveHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(EchoTheme.cyan.opacity(0.12))
                    .frame(width: 68, height: 68)
                Circle()
                    .stroke(EchoTheme.cyan.opacity(0.32), lineWidth: 1)
                    .frame(width: 53, height: 53)
                Image(systemName: "point.3.connected.trianglepath.dotted")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(EchoTheme.cyan)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(Copy.text("archive.header.title"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.1)
                Text(Copy.text("archive.header.subtitle"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [EchoTheme.cyan.opacity(0.14), EchoTheme.panel.opacity(0.93)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(EchoTheme.cyan.opacity(0.2), lineWidth: 1)
        )
    }

    private var sectionPicker: some View {
        HStack(spacing: 5) {
            ForEach(WikiSection.allCases) { item in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeOut(duration: 0.2)) {
                        section = item
                    }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.icon)
                            .font(.system(size: 11, weight: .bold))
                        Text(item.title.uppercased())
                            .font(.system(size: 7, weight: .black, design: .rounded))
                            .tracking(0.35)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .foregroundStyle(section == item ? EchoTheme.navyDeep : Color.white.opacity(0.68))
                    .frame(maxWidth: .infinity)
                    .frame(height: 47)
                    .background(
                        section == item ? AnyShapeStyle(item.tint) : AnyShapeStyle(EchoTheme.panel),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(section == item ? item.tint.opacity(0.7) : EchoTheme.panelStroke, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.title)
                .accessibilityAddTraits(section == item ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var sectionContent: some View {
        switch section {
        case .research:
            WikiResearchContent()
        case .acts:
            WikiRegionsContent()
        case .story:
            WikiStoryContent()
        case .basics, .threats, .abilities:
            VStack(spacing: 12) {
                ForEach(section == .basics ? WikiEntry.guide : section == .threats ? WikiEntry.hazards : WikiEntry.skills) { entry in
                    WikiEntryCard(entry: entry)
                }
            }
        }
    }
}

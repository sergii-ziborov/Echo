import SwiftUI

/// Two ratings, one per device: the campaign on iPhone and the chronometer
/// rooms on Apple Watch, each with the records it is built from.
struct RecordsView: View {
    enum Board: String, CaseIterable, Identifiable {
        case phone, watch

        var id: String { rawValue }
        var icon: String { self == .phone ? "iphone" : "applewatch" }
        var tint: Color { self == .phone ? EchoTheme.cyan : EchoTheme.gold }
    }

    @Environment(AppModel.self) private var model
    @State private var board: Board

    init(board: Board? = nil) {
        let shot: Board = ProcessInfo.processInfo.arguments.contains("-shot-records-watch") ? .watch : .phone
        _board = State(initialValue: board ?? shot)
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            VStack(spacing: 12) {
                header
                picker
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        switch board {
                        case .phone: phoneBoard
                        case .watch: watchBoard
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            IconCircle(system: "chevron.left") {
                model.audio.play(.tap)
                model.goHome()
            }
            .accessibilityLabel(Copy.text("records.back"))
            VStack(alignment: .leading, spacing: 2) {
                Text(Copy.text("records.title"))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(2.5)
                Text(Copy.text("records.subtitle"))
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(EchoTheme.gold)
                .frame(width: 38, height: 38)
                .background(EchoTheme.gold.opacity(0.10), in: Circle())
                .overlay(Circle().stroke(EchoTheme.gold.opacity(0.18), lineWidth: 1))
        }
    }

    private var picker: some View {
        HStack(spacing: 4) {
            ForEach(Board.allCases) { item in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeOut(duration: 0.18)) { board = item }
                } label: {
                    Label(Copy.text("records.tab.\(item.rawValue)"), systemImage: item.icon)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(board == item ? .white : EchoTheme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(board == item ? item.tint.opacity(0.32) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(board == item ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    // MARK: - iPhone

    private var phoneBoard: some View {
        VStack(spacing: 14) {
            ratingCard(Ratings.phone(model.progress), board: .phone, note: Copy.text("records.phone.note"))
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle(Copy.text("records.regions"))
                ForEach(Act.allCases, id: \.rawValue) { act in
                    regionRow(act)
                    if act != Act.allCases.last { divider }
                }
            }
            .padding(.vertical, 6)
            .background(EchoTheme.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private func regionRow(_ act: Act) -> some View {
        let maps = LevelCatalog.playable.filter { act.range.contains($0.number) }
        let stars = maps.map { model.progress.progress(for: $0.id).stars }
        return HStack(spacing: 11) {
            Image(systemName: act.atlasIcon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(act.atlasTint)
                .frame(width: 30, height: 30)
                .background(act.atlasTint.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(act.region)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(Copy.format("records.region.detail", stars.reduce(0, +), maps.count * 3, stars.filter { $0 > 0 }.count, maps.count))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
            Text("\(stars.reduce(0, +) * Ratings.sealPoints)")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(EchoTheme.cyan)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }

    // MARK: - Apple Watch

    private var watchBoard: some View {
        let wrist = model.progress.wrist
        return VStack(spacing: 14) {
            ratingCard(Ratings.watch(wrist), board: .watch, note: Copy.text("records.watch.note"))
            Text(Copy.format("records.watch.summary", wrist.cleared.count, WristCatalog.maps.count, wrist.relics.count, WristRelic.allCases.count))
                .font(.system(size: 10, weight: .black, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(EchoTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            if wrist.cleared.isEmpty {
                Text(Copy.text("records.watch.empty"))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(EchoTheme.gold.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            ForEach(WristCatalog.actTitles.indices, id: \.self) { act in
                VStack(alignment: .leading, spacing: 0) {
                    sectionTitle("\(["I", "II", "III"][act]) · \(WristCatalog.actTitles[act].uppercased())")
                    let rooms = WristCatalog.maps.filter { WristCatalog.act(of: $0) == act }
                    ForEach(rooms, id: \.id) { room in
                        roomRow(room, wrist: wrist)
                        if room.id != rooms.last?.id { divider }
                    }
                }
                .padding(.vertical, 6)
                .background(EchoTheme.panel.opacity(0.92), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func roomRow(_ room: LevelDefinition, wrist: WristProgress) -> some View {
        let best = wrist.bestTimes[room.id]
        let cleared = wrist.cleared.contains(room.id)
        return HStack(spacing: 10) {
            Text(String(format: "%02d", room.number))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(cleared ? EchoTheme.gold : EchoTheme.muted)
                .frame(width: 24, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(room.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(cleared ? .white : .white.opacity(0.55))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(Copy.format("records.room.par", Copy.seconds(room.parTime)))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
            Spacer(minLength: 0)
            if cleared, let best {
                Text(Copy.format("watch.best", Copy.seconds(best)))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(best <= room.parTime ? EchoTheme.gold : .white)
            } else {
                Text(Copy.text("records.room.open"))
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(EchoTheme.muted)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - Shared

    private func ratingCard(_ lines: [RatingLine], board: Board, note: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Label(Copy.text("records.tab.\(board.rawValue)"), systemImage: board.icon)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(board.tint)
                    Text(Copy.text("records.rating"))
                        .font(.system(size: 8, weight: .black, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(EchoTheme.muted)
                }
                Spacer()
                Text(Ratings.total(lines).formatted())
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            VStack(spacing: 7) {
                ForEach(lines) { line in
                    HStack(spacing: 8) {
                        Text(Copy.text(line.id))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 4)
                        Text(Copy.format("records.times", line.count.formatted(), line.weight.formatted()))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(EchoTheme.muted)
                        Text(line.points.formatted())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(board.tint)
                            .frame(minWidth: 52, alignment: .trailing)
                    }
                }
            }
            Text(note)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(EchoTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [EchoTheme.panel.opacity(0.97), board.tint.opacity(0.10)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(board.tint.opacity(0.22), lineWidth: 1)
        )
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .black, design: .rounded))
            .tracking(1.4)
            .foregroundStyle(EchoTheme.muted)
            .padding(.horizontal, 14)
            .padding(.top, 8)
            .padding(.bottom, 4)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 54)
    }
}

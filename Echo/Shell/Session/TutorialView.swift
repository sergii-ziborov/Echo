import SwiftUI

/// A small, disposable route. Training never spends charges or changes the archive.
@MainActor @Observable
final class TutorialPractice {
    struct Sample { let time: TimeInterval; let point: CGPoint }
    static let start = CGPoint(x: 0.18, y: 0.68)
    static let sparks = [CGPoint(x: 0.38, y: 0.35), CGPoint(x: 0.72, y: 0.58), CGPoint(x: 0.42, y: 0.78)]
    static let exit = CGPoint(x: 0.84, y: 0.22)
    static let delay: TimeInterval = 2.4
    var player = start
    var target: CGPoint?
    var collected: Set<Int> = []
    var trail: [Sample] = []
    var elapsed: TimeInterval = 0
    var hasMoved = false
    var hasSeenEcho = false
    var collisions = 0
    var completed = false
    var echo: CGPoint? {
        guard elapsed >= Self.delay else { return nil }
        return trail.last { $0.time <= elapsed - Self.delay }?.point
    }
    var exitOpen: Bool { collected.count == Self.sparks.count }

    func aim(at point: CGPoint?) {
        guard !completed else { return }
        target = point.map { CGPoint(x: min(0.94, max(0.06, $0.x)), y: min(0.94, max(0.06, $0.y))) }
    }

    func tick(_ dt: TimeInterval) {
        guard !completed, !trail.isEmpty || target != nil else { return }
        let dt = min(max(dt, 0), 0.05)
        if trail.isEmpty { trail = [Sample(time: 0, point: player)] }
        elapsed += dt
        if let target {
            let dx = target.x - player.x, dy = target.y - player.y
            let distance = hypot(dx, dy)
            let step = min(distance, 0.42 * dt)
            if distance > 0 {
                player.x += dx / distance * step
                player.y += dy / distance * step
                hasMoved = true
            }
        }
        trail.append(Sample(time: elapsed, point: player))
        for (index, spark) in Self.sparks.enumerated() where hypot(player.x - spark.x, player.y - spark.y) < 0.065 {
            collected.insert(index)
        }
        if exitOpen, hypot(player.x - Self.exit.x, player.y - Self.exit.y) < 0.07 {
            completed = true
            target = nil
            return
        }
        if let echo {
            hasSeenEcho = true
            if hypot(player.x - echo.x, player.y - echo.y) < 0.055 {
                // A gentle reset teaches the collision; recovered sparks stay recovered.
                collisions += 1
                player = Self.start
                elapsed = 0
                trail = []
                target = nil
            }
        }
        // Keep only what the delayed echo and its visible trail still need.
        trail.removeAll { $0.time < elapsed - Self.delay - 0.6 }
    }
}

struct TutorialView: View {
    var onDone: () -> Void
    @State var practice: TutorialPractice
    @State private var selectedLesson: Int?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(practice: TutorialPractice = TutorialPractice(), onDone: @escaping () -> Void) {
        self.onDone = onDone
        _practice = State(initialValue: practice)
    }

    var body: some View {
        GeometryReader { geo in
            let wide = geo.size.width >= 800
            ZStack {
                ScreenBackground()
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(Copy.text("tutorial.practice.eyebrow"))
                                .font(.system(size: 10, weight: .black, design: .rounded)).tracking(2)
                                .foregroundStyle(EchoTheme.cyan)
                            Text(Copy.text("tutorial.practice.title"))
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                        }
                        Spacer(minLength: 10)
                        Button(action: onDone) {
                            Text(Copy.text("tutorial.skip"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .padding(12).background(.white.opacity(0.06), in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Copy.text("tutorial.a11y.skip"))
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(Copy.text("tutorial.practice.subtitle"))
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(EchoTheme.muted)
                            if wide {
                                HStack(alignment: .top, spacing: 20) {
                                    arena.frame(height: 360)
                                    instructions.frame(width: 285)
                                }
                            } else {
                                arena.frame(height: min(290, max(190, geo.size.height * 0.30)))
                                instructions
                            }
                        }
                        .padding(.bottom, 4)
                    }.scrollBounceBehavior(.basedOnSize)
                    VStack(spacing: 8) {
                        Text(Copy.text(practice.completed ? "tutorial.practice.finished" : "tutorial.practice.optional"))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(practice.completed ? EchoTheme.gold : EchoTheme.muted)
                            .multilineTextAlignment(.center)
                        PrimaryButton(title: Copy.text("tutorial.start"), systemImage: "play.fill", action: onDone)
                            .accessibilityIdentifier("tutorial.start")
                    }
                }
                .padding(.horizontal, wide ? 28 : 18).padding(.vertical, 16)
                .frame(maxWidth: 980).frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .foregroundStyle(.white)
        }
        .task {
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(33)) } catch { break }
                practice.tick(0.033)
            }
        }
    }

    private var arena: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                EchoTheme.navyDeep
                Canvas { context, size in
                    func point(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * size.width, y: p.y * size.height) }
                    func circle(_ p: CGPoint, _ radius: CGFloat) -> Path {
                        Circle().path(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
                    }
                    var grid = Path()
                    for x in stride(from: CGFloat(0), through: size.width, by: 32) {
                        grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                    }
                    for y in stride(from: CGFloat(0), through: size.height, by: 32) {
                        grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                    }
                    context.stroke(grid, with: .color(.white.opacity(0.035)), lineWidth: 1)
                    let exit = point(TutorialPractice.exit)
                    context.stroke(circle(exit, 15), with: .color(practice.exitOpen ? EchoTheme.gold : .white.opacity(0.2)), style: StrokeStyle(lineWidth: 2, dash: practice.exitOpen ? [] : [3, 4]))
                    for (i, spark) in TutorialPractice.sparks.enumerated() where !practice.collected.contains(i) {
                        let p = point(spark)
                        context.fill(circle(p, 15), with: .color(EchoTheme.gold.opacity(0.08)))
                        context.stroke(circle(p, 10), with: .color(EchoTheme.gold.opacity(0.4)), lineWidth: 1)
                        context.fill(circle(p, 4), with: .color(EchoTheme.gold))
                    }
                    var route = Path()
                    for (i, sample) in practice.trail.enumerated() {
                        if i == 0 { route.move(to: point(sample.point)) } else { route.addLine(to: point(sample.point)) }
                    }
                    context.stroke(route, with: .color(EchoTheme.cyan.opacity(0.24)), lineWidth: 2)
                    if let echo = practice.echo {
                        let p = point(echo)
                        context.fill(circle(p, 18), with: .color(EchoTheme.violet.opacity(0.16)))
                        context.stroke(circle(p, 10), with: .color(EchoTheme.violet), lineWidth: 2)
                    }
                    let p = point(practice.player)
                    context.fill(circle(p, reduceMotion ? 16 : 18 + sin(practice.elapsed * 4) * 2), with: .color(EchoTheme.cyan.opacity(0.16)))
                    context.fill(circle(p, 9), with: .color(EchoTheme.cyan))
                    context.fill(circle(p, 4), with: .color(.white))
                }
                HStack(spacing: 6) {
                    Image(systemName: "hand.draw.fill")
                    Text(Copy.text("tutorial.practice.touch"))
                    Spacer(minLength: 0)
                    Image(systemName: "sparkle").foregroundStyle(EchoTheme.gold)
                    Text("\(practice.collected.count)/3").monospacedDigit()
                }
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(EchoTheme.muted).padding(14).allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { practice.aim(at: CGPoint(x: $0.location.x / geo.size.width, y: $0.location.y / geo.size.height)) }
                .onEnded { _ in practice.aim(at: nil) })
            .accessibilityLabel(Copy.text("tutorial.practice.a11y"))
            .accessibilityIdentifier("tutorial.practice.arena")
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(EchoTheme.cyan.opacity(0.26), lineWidth: 1))
    }

    private var currentLesson: Int {
        selectedLesson ?? (practice.hasSeenEcho ? 3 : practice.hasMoved ? 2 : 1)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                ForEach(1...3, id: \.self) { index in
                    Button { selectedLesson = index } label: {
                        Text(Copy.text("tutorial.practice.\(index).short"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(index == currentLesson ? EchoTheme.cyan : EchoTheme.muted)
                            .frame(maxWidth: .infinity).frame(height: 34)
                            .background(index == currentLesson ? EchoTheme.cyan.opacity(0.1) : .white.opacity(0.035), in: Capsule())
                    }.buttonStyle(.plain)
                        .accessibilityAddTraits(index == currentLesson ? .isSelected : [])
                }
            }
            let icons = ["hand.draw.fill", "sparkle", "clock.arrow.2.circlepath"]
            let tints = [EchoTheme.cyan, EchoTheme.gold, EchoTheme.violet]
            let met = [practice.hasMoved, practice.exitOpen, practice.hasSeenEcho]
            instruction(currentLesson, icon: icons[currentLesson - 1], tint: tints[currentLesson - 1], met: met[currentLesson - 1])
            if practice.collisions > 0 {
                Text(Copy.text("tutorial.practice.collision"))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(EchoTheme.violet).fixedSize(horizontal: false, vertical: true)
                    .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                    .background(EchoTheme.violet.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            }
        }
    }

    private func instruction(_ index: Int, icon: String, tint: Color, met: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: met ? "checkmark" : icon)
                .font(.system(size: 15, weight: .semibold)).foregroundStyle(tint)
                .frame(width: 36, height: 36).background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
            VStack(alignment: .leading, spacing: 4) {
                Text(Copy.text("tutorial.practice.\(index).title"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text(Copy.text("tutorial.practice.\(index).detail"))
                    .font(.system(size: 11, weight: .medium, design: .rounded)).foregroundStyle(EchoTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
    }
}

import SwiftUI

struct TutorialView: View {
    var onDone: () -> Void

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var stepIndex: Int

    init(stepIndex: Int = 0, onDone: @escaping () -> Void) {
        self.onDone = onDone
        _stepIndex = State(initialValue: stepIndex)
    }

    private let steps: [TutorialBeat] = [
        TutorialBeat(
            icon: "hand.draw.fill",
            title: "Drag the present",
            detail: "Drag anywhere to steer the white orb. Release to coast through a clear lane.",
            tip: "Try a smooth route. Your movement will matter again soon.",
            tint: EchoTheme.cyan
        ),
        TutorialBeat(
            icon: "clock.arrow.2.circlepath",
            title: "Your route returns",
            detail: "When the Echo clock reaches zero, a copy starts replaying the path you just drew.",
            tip: "The violet echo is your past, not a collectible.",
            tint: EchoTheme.violet
        ),
        TutorialBeat(
            icon: "point.topleft.down.to.point.bottomright.curvepath",
            title: "Leave room for yourself",
            detail: "Collect every spark, then enter the awakened exit. Avoid crossing the path your echo is about to follow.",
            tip: "A wide loop is safer than a tight knot.",
            tint: EchoTheme.gold
        ),
        TutorialBeat(
            icon: "clock.arrow.circlepath",
            title: "Rewind a bad turn",
            detail: "Double-tap the arena to dash. After a crash, use Rewind on the fracture screen to return along your recent route if you have a charge.",
            tip: "Rewind leaves the failed branch as an unstable echo.",
            tint: EchoTheme.magenta
        )
    ]

    private var current: TutorialBeat { steps[stepIndex] }

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 14) {
                header
                stepPicker

                TutorialScene(step: stepIndex, tint: current.tint, reduceMotion: reduceMotion)
                    .frame(height: 228)
                    .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 23, style: .continuous)
                            .stroke(current.tint.opacity(0.38), lineWidth: 1)
                    }

                lessonCard

                Spacer(minLength: 0)

                PrimaryButton(
                    title: stepIndex == steps.count - 1 ? "Start playing" : "Next lesson",
                    systemImage: stepIndex == steps.count - 1 ? "play.fill" : "arrow.right"
                ) {
                    if stepIndex == steps.count - 1 {
                        onDone()
                    } else {
                        model.audio.play(.select)
                        withAnimation(.easeInOut(duration: reduceMotion ? 0.01 : 0.24)) {
                            stepIndex += 1
                        }
                    }
                }
            }
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
    }

    private var header: some View {
        HStack(spacing: 11) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(EchoTheme.cyan)
                .frame(width: 46, height: 46)
                .background(EchoTheme.cyan.opacity(0.13), in: Circle())
                .overlay(Circle().stroke(EchoTheme.cyan.opacity(0.24), lineWidth: 1))

            VStack(alignment: .leading, spacing: 3) {
                Text("FIELD TRAINING")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1.8)
                Text("LEARN THE LOOP IN FOUR BEATS")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(EchoTheme.muted)
            }

            Spacer(minLength: 0)

            Button {
                onDone()
            } label: {
                Text("SKIP")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(EchoTheme.muted)
                    .frame(width: 52, height: 42)
                    .background(Color.white.opacity(0.06), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip tutorial and start playing")
        }
    }

    private var stepPicker: some View {
        HStack(spacing: 6) {
            ForEach(steps.indices, id: \.self) { index in
                Button {
                    model.audio.play(.select)
                    withAnimation(.easeInOut(duration: reduceMotion ? 0.01 : 0.20)) {
                        stepIndex = index
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 9, weight: .black, design: .rounded))
                        if index == stepIndex {
                            Image(systemName: steps[index].icon)
                                .font(.system(size: 9, weight: .bold))
                        }
                    }
                    .foregroundStyle(index == stepIndex ? EchoTheme.navyDeep : EchoTheme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(
                        index == stepIndex ? steps[index].tint : Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Lesson \(index + 1): \(steps[index].title)")
                .accessibilityAddTraits(index == stepIndex ? .isSelected : [])
            }
        }
    }

    private var lessonCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 11) {
                Image(systemName: current.icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(current.tint)
                    .frame(width: 45, height: 45)
                    .background(current.tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("LESSON \(stepIndex + 1) / \(steps.count)")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.3)
                        .foregroundStyle(current.tint)
                    Text(current.title)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            Text(current.detail)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 7) {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(EchoTheme.gold)
                Text(current.tip)
                    .foregroundStyle(EchoTheme.muted)
            }
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .fixedSize(horizontal: false, vertical: true)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(EchoTheme.panel.opacity(0.95), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(current.tint.opacity(0.20), lineWidth: 1)
        }
    }
}

private struct TutorialBeat {
    let icon: String
    let title: String
    let detail: String
    let tip: String
    let tint: Color
}

private struct TutorialScene: View {
    let step: Int
    let tint: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let phase = reduceMotion ? 0.55 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3.3) / 3.3

            ZStack(alignment: .topLeading) {
                EchoTheme.navyDeep
                Canvas { context, size in
                    drawGrid(context: &context, size: size)
                    drawRoute(context: &context, size: size, phase: phase)
                }

                HStack(spacing: 6) {
                    Circle()
                        .fill(tint)
                        .frame(width: 5, height: 5)
                    Text("LIVE FIELD DEMO")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(tint)
                    Spacer()
                    Text(String(format: "%02d / 04", step + 1))
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundStyle(EchoTheme.muted)
                }
                .padding(14)
            }
        }
        .accessibilityLabel("Animated illustration of \(step == 0 ? "dragging" : step == 1 ? "an echo replaying" : step == 2 ? "avoiding your echo" : "rewinding")")
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        for x in stride(from: CGFloat(0), through: size.width, by: 36) {
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(.white.opacity(0.045)), lineWidth: 1)
        }
        for y in stride(from: CGFloat(0), through: size.height, by: 36) {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(.white.opacity(0.045)), lineWidth: 1)
        }
    }

    private func drawRoute(context: inout GraphicsContext, size: CGSize, phase: Double) {
        let start = CGPoint(x: size.width * 0.16, y: size.height * 0.72)
        let bend = CGPoint(x: size.width * 0.45, y: size.height * 0.36)
        let finish = CGPoint(x: size.width * 0.82, y: size.height * 0.63)
        let firstControl = CGPoint(x: size.width * 0.21, y: size.height * 0.27)
        let secondControl = CGPoint(x: size.width * 0.78, y: size.height * 0.26)
        let position = routePoint(start: start, bend: bend, finish: finish, firstControl: firstControl, secondControl: secondControl, progress: phase)

        var fullPath = Path()
        fullPath.move(to: start)
        fullPath.addQuadCurve(to: bend, control: firstControl)
        fullPath.addQuadCurve(to: finish, control: secondControl)
        context.stroke(fullPath, with: .color(tint.opacity(0.42)), style: StrokeStyle(lineWidth: 2, dash: [5, 7]))

        if step == 2 {
            let danger = CGPoint(x: size.width * 0.61, y: size.height * 0.68)
            context.fill(Circle().path(in: CGRect(x: danger.x - 21, y: danger.y - 21, width: 42, height: 42)), with: .color(EchoTheme.danger.opacity(0.14)))
            context.stroke(Circle().path(in: CGRect(x: danger.x - 16, y: danger.y - 16, width: 32, height: 32)), with: .color(EchoTheme.danger), lineWidth: 2)
        }

        if step >= 1 {
            let delayed = max(0, phase - 0.26)
            let echo = routePoint(start: start, bend: bend, finish: finish, firstControl: firstControl, secondControl: secondControl, progress: delayed)
            context.fill(Circle().path(in: CGRect(x: echo.x - 12, y: echo.y - 12, width: 24, height: 24)), with: .color(EchoTheme.violet.opacity(0.19)))
            context.stroke(Circle().path(in: CGRect(x: echo.x - 9, y: echo.y - 9, width: 18, height: 18)), with: .color(EchoTheme.magenta.opacity(0.82)), lineWidth: 2)
        }

        if step == 3 {
            let reversed = routePoint(start: start, bend: bend, finish: finish, firstControl: firstControl, secondControl: secondControl, progress: 1 - phase)
            context.stroke(Circle().path(in: CGRect(x: reversed.x - 23, y: reversed.y - 23, width: 46, height: 46)), with: .color(EchoTheme.cyan.opacity(0.44)), lineWidth: 2)
            drawOrb(context: &context, at: reversed)
        } else {
            drawOrb(context: &context, at: position)
        }

        if step == 0 || step == 2 {
            let spark = CGPoint(x: size.width * 0.82, y: size.height * 0.63)
            context.fill(Circle().path(in: CGRect(x: spark.x - 3, y: spark.y - 3, width: 6, height: 6)), with: .color(EchoTheme.gold))
            context.stroke(Circle().path(in: CGRect(x: spark.x - 10, y: spark.y - 10, width: 20, height: 20)), with: .color(EchoTheme.gold.opacity(0.45)), lineWidth: 1)
        }
    }

    private func routePoint(
        start: CGPoint,
        bend: CGPoint,
        finish: CGPoint,
        firstControl: CGPoint,
        secondControl: CGPoint,
        progress: Double
    ) -> CGPoint {
        if progress < 0.5 {
            let t = CGFloat(progress * 2)
            return quadratic(from: start, control: firstControl, to: bend, t: t)
        }
        let t = CGFloat((progress - 0.5) * 2)
        return quadratic(from: bend, control: secondControl, to: finish, t: t)
    }

    private func quadratic(from start: CGPoint, control: CGPoint, to end: CGPoint, t: CGFloat) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * start.x + 2 * u * t * control.x + t * t * end.x,
            y: u * u * start.y + 2 * u * t * control.y + t * t * end.y
        )
    }

    private func drawOrb(context: inout GraphicsContext, at point: CGPoint) {
        context.fill(Circle().path(in: CGRect(x: point.x - 18, y: point.y - 18, width: 36, height: 36)), with: .color(EchoTheme.cyan.opacity(0.22)))
        context.fill(Circle().path(in: CGRect(x: point.x - 10, y: point.y - 10, width: 20, height: 20)), with: .color(.white))
    }
}

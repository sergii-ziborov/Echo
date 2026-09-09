import SwiftUI

struct ScreenBackground: View {
    var body: some View {
        LinearGradient.screenBackground
            .ignoresSafeArea()
            .overlay {
                EchoAmbientOrbs()
                    .allowsHitTesting(false)
            }
    }
}

struct EchoAmbientOrbs: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let t = timeline.date.timeIntervalSinceReferenceDate
                drawOrb(context: &context, size: size, t: t, x: 0.78, y: 0.08, r: 90, color: EchoTheme.cyan)
                drawOrb(context: &context, size: size, t: t * 0.7, x: 0.18, y: 0.16, r: 50, color: EchoTheme.magenta)
                drawOrb(context: &context, size: size, t: t * 1.1, x: 0.9, y: 0.42, r: 40, color: EchoTheme.violet)
            }
        }
        .blur(radius: 0.2)
    }

    private func drawOrb(context: inout GraphicsContext, size: CGSize, t: Double, x: Double, y: Double, r: CGFloat, color: Color) {
        let pulse = 1 + 0.06 * sin(t)
        let rect = CGRect(
            x: size.width * x - r * pulse,
            y: size.height * y - r * pulse,
            width: r * 2 * pulse,
            height: r * 2 * pulse
        )
        context.fill(Circle().path(in: rect), with: .color(color.opacity(0.12)))
    }
}

struct EchoMark: View {
    var size: CGFloat = 220
    var spinning = true

    var body: some View {
        TimelineView(.animation(minimumInterval: spinning ? 1 / 30 : 10, paused: !spinning)) { timeline in
            let t = spinning ? timeline.date.timeIntervalSinceReferenceDate : 0
            Canvas { context, canvasSize in
                let cx = canvasSize.width / 2
                let cy = canvasSize.height / 2
                let radius = min(canvasSize.width, canvasSize.height) * 0.30
                let count = 16
                var head = CGPoint(x: cx, y: cy)
                for i in 0..<count {
                    let u = Double(i) / Double(count - 1)
                    let angle = 0.85 * .pi + u * 1.55 * .pi + t * 0.22
                    let x = cx + cos(angle) * radius
                    let y = cy + sin(angle) * radius
                    let s = canvasSize.width * (0.10 + 0.06 * u)
                    let color = Color(
                        red: 0.62 + 0.12 * (1 - u),
                        green: 0.32 + 0.55 * u,
                        blue: 1.0
                    )
                    let rect = CGRect(x: x - s / 2, y: y - s / 2, width: s, height: s)
                    context.opacity = 0.22 + 0.55 * u
                    context.fill(Circle().path(in: rect), with: .color(color.opacity(0.42)))
                    context.stroke(Circle().path(in: rect.insetBy(dx: 1, dy: 1)), with: .color(color.opacity(0.85)), lineWidth: 1.2)
                    if i == count - 1 { head = CGPoint(x: x, y: y) }
                }
                let core = canvasSize.width * 0.155
                let coreRect = CGRect(x: head.x - core / 2, y: head.y - core / 2, width: core, height: core)
                context.opacity = 1
                context.fill(Circle().path(in: coreRect.insetBy(dx: -12, dy: -12)), with: .color(EchoTheme.cyan.opacity(0.28)))
                context.fill(Circle().path(in: coreRect), with: .color(.white))
            }
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }
}

struct PrimaryButton: View {
    var title: String
    var systemImage: String = "play.fill"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Capsule().fill(LinearGradient.primaryButton))
            .shadow(color: EchoTheme.primaryBlue.opacity(0.45), radius: 16, y: 6)
        }
        .buttonStyle(PressStyle())
    }
}

struct SecondaryButton: View {
    var title: String
    var systemImage: String?
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1))
        }
        .buttonStyle(PressStyle())
    }
}

struct GhostButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(EchoTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Capsule().fill(Color.white.opacity(0.04)))
        }
        .buttonStyle(PressStyle())
    }
}

struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct Wordmark: View {
    var subtitle: String = "YOU SURVIVE THE TIMELINE YOU CREATED"

    var body: some View {
        VStack(spacing: 10) {
            Text("ECHO")
                .font(.system(size: 54, weight: .ultraLight))
                .tracking(EchoTheme.wordmarkTracking)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 11, weight: .medium))
                .tracking(2.2)
                .foregroundStyle(EchoTheme.muted)
        }
    }
}

struct PanelCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(EchoTheme.panel.opacity(0.92))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(EchoTheme.panelStroke, lineWidth: 1)
            )
    }
}

struct StarRow: View {
    var filled: Int
    var size: CGFloat = 28

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < filled ? "star.fill" : "star.fill")
                    .font(.system(size: size))
                    .foregroundStyle(i < filled ? EchoTheme.gold : EchoTheme.goldDim.opacity(0.45))
                    .shadow(color: i < filled ? EchoTheme.gold.opacity(0.6) : .clear, radius: 8)
            }
        }
    }
}

struct IconCircle: View {
    var system: String
    var action: (() -> Void)?

    var body: some View {
        Button(action: { action?() }) {
            Image(systemName: system)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

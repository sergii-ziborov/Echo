import SwiftUI

/// A live, top-down miniature of the phone's arena.
struct RadarView: View {
    let frame: RadarFrame?
    let live: Bool

    var body: some View {
        Canvas { context, size in
            guard let frame, live else {
                idle(in: &context, size: size)
                return
            }
            let width = min(size.width, size.height / max(frame.aspect, 0.1))
            let height = width * frame.aspect
            let origin = CGPoint(x: (size.width - width) / 2, y: (size.height - height) / 2)
            func place(_ x: Double, _ y: Double) -> CGPoint {
                CGPoint(x: origin.x + x * width, y: origin.y + (frame.aspect - y) * width)
            }
            func dot(_ center: CGPoint, _ radius: CGFloat) -> Path {
                Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            }

            let arena = CGRect(origin: origin, size: CGSize(width: width, height: height))
            context.fill(Path(roundedRect: arena, cornerRadius: 10), with: .color(Color(red: 0.03, green: 0.05, blue: 0.1)))
            context.stroke(Path(roundedRect: arena, cornerRadius: 10), with: .color(.cyan.opacity(0.25)), lineWidth: 1)

            for wall in frame.walls where wall.count == 4 {
                let corner = place(wall[0], wall[1] + wall[3])
                let rect = CGRect(x: corner.x, y: corner.y, width: wall[2] * width, height: wall[3] * width)
                context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(.white.opacity(0.22)))
            }
            if frame.exit.count == 3 {
                let open = frame.exit[2] > 0.5
                context.stroke(dot(place(frame.exit[0], frame.exit[1]), 7), with: .color(open ? .cyan : .white.opacity(0.3)), lineWidth: open ? 2 : 1)
            }
            for spark in frame.sparks where spark.count == 3 {
                context.fill(dot(place(spark[0], spark[1]), 3), with: .color(spark[2] > 0.5 ? .yellow : .cyan))
            }
            for rock in frame.rocks where rock.count == 3 {
                context.fill(dot(place(rock[0], rock[1]), max(3, rock[2] * width)), with: .color(Color(red: 0.62, green: 0.56, blue: 0.5)))
            }
            for echo in frame.echoes where echo.count == 2 {
                let center = place(echo[0], echo[1])
                context.fill(dot(center, 7), with: .color(.purple.opacity(0.25)))
                context.fill(dot(center, 4), with: .color(Color(red: 0.85, green: 0.6, blue: 1)))
            }
            if frame.player.count == 2 {
                let center = place(frame.player[0], frame.player[1])
                context.fill(dot(center, 9), with: .color(.cyan.opacity(0.25)))
                context.fill(dot(center, 5), with: .color(.white))
            }

            let hud = Text("◆ \(frame.collected)/\(frame.total)  ◌ \(frame.echoCount)/\(frame.maxEchoes)")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            context.draw(hud, at: CGPoint(x: size.width / 2, y: origin.y + 9))
        }
    }

    private func idle(in context: inout GraphicsContext, size: CGSize) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        for step in 1...3 {
            let radius = CGFloat(step) * min(size.width, size.height) * 0.14
            let ring = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(ring, with: .color(.purple.opacity(0.35 - Double(step) * 0.08)), lineWidth: 1)
        }
    }
}

import SwiftUI

/// What the Atlas knows about one stop on a region's route.
struct AtlasStop: Equatable {
    var cleared: Bool
    var unlocked: Bool
}

/// The moving parts of a region's route, drawn in two passes around the
/// stop buttons: under them the lit road between stops, the halos and the
/// far side of the selected stop's loop; over them the near side of the
/// loop. The stops themselves are opaque, so no line shows through one.
struct AtlasRouteLayer: View {
    enum Pass { case under, over }

    let pass: Pass
    let points: [CGPoint]
    let stops: [AtlasStop]
    let selected: Int?
    let selectedAt: Date
    let tint: Color
    let reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let time = reduceMotion ? 0.8 : timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 3600)
            let appear = reduceMotion ? 1 : timeline.date.timeIntervalSince(selectedAt) / 0.45
            Canvas { context, _ in
                let loop = selected.flatMap { points.indices.contains($0) ? AtlasMobius(center: points[$0], tint: tint, time: time, appear: appear) : nil }
                switch pass {
                case .under:
                    AtlasRouteArt.drawRoad(points: points, stops: stops, tint: tint, time: time, in: context)
                    AtlasRouteArt.drawHalos(points: points, stops: stops, selected: selected, tint: tint, time: time, in: context)
                    loop?.draw(.behind, in: context)
                case .over:
                    loop?.draw(.inFront, in: context)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

enum AtlasRouteArt {
    /// A gentle arc from one stop's centre to the next.
    static func arc(from start: CGPoint, to end: CGPoint, bend: CGFloat) -> (path: Path, at: (CGFloat) -> CGPoint) {
        let dx = end.x - start.x, dy = end.y - start.y
        let length = max(1, hypot(dx, dy))
        let control = CGPoint(x: (start.x + end.x) / 2 - dy / length * bend, y: (start.y + end.y) / 2 + dx / length * bend)
        var path = Path()
        path.move(to: start)
        path.addQuadCurve(to: end, control: control)
        return (path, { u in
            let v = 1 - u
            return CGPoint(
                x: v * v * start.x + 2 * v * u * control.x + u * u * end.x,
                y: v * v * start.y + 2 * v * u * control.y + u * u * end.y
            )
        })
    }

    /// Travelled road glows and carries pulses of light forward; the road to
    /// the next open stop is drawn in marching light; the rest is faint.
    static func drawRoad(points: [CGPoint], stops: [AtlasStop], tint: Color, time: Double, in context: GraphicsContext) {
        guard points.count > 1, stops.count == points.count else { return }
        var glowing = context
        glowing.blendMode = .plusLighter
        for index in 0..<(points.count - 1) {
            let start = points[index], end = points[index + 1]
            let bend = hypot(end.x - start.x, end.y - start.y) * (index.isMultiple(of: 2) ? 0.1 : -0.1)
            let (path, at) = arc(from: start, to: end, bend: bend)
            let from = stops[index], to = stops[index + 1]
            if from.cleared && to.cleared {
                context.stroke(path, with: .color(tint.opacity(0.14)), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                context.stroke(path, with: .color(tint.opacity(0.85)), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                for pulse in 0..<2 {
                    let u = (time * 0.32 + Double(index) * 0.37 + Double(pulse) * 0.5).truncatingRemainder(dividingBy: 1)
                    for trail in 0..<5 {
                        let point = at(CGFloat(max(0, u - Double(trail) * 0.025)))
                        let radius = 2.6 - Double(trail) * 0.4
                        let fade = 1 - Double(trail) / 5
                        glowing.fill(
                            Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color((trail == 0 ? Color.white : tint).opacity(0.8 * fade))
                        )
                    }
                }
            } else if from.cleared || to.unlocked {
                context.stroke(path, with: .color(tint.opacity(0.08)), style: StrokeStyle(lineWidth: 7, lineCap: .round))
                context.stroke(
                    path,
                    with: .color(tint.opacity(0.75)),
                    style: StrokeStyle(lineWidth: 1.8, lineCap: .round, dash: [6, 7], dashPhase: CGFloat(-time * 16))
                )
            } else {
                context.stroke(path, with: .color(Color.white.opacity(0.2)), style: StrokeStyle(lineWidth: 1.3, lineCap: .round, dash: [0.5, 6]))
            }
        }
    }

    /// Cleared stops wear a slowly turning ring of ticks; the next stop to
    /// play sends out a ping; the selected stop sits in a pool of light.
    static func drawHalos(points: [CGPoint], stops: [AtlasStop], selected: Int?, tint: Color, time: Double, in context: GraphicsContext) {
        let next = stops.firstIndex { $0.unlocked && !$0.cleared }
        for (index, point) in points.enumerated() where stops.indices.contains(index) {
            func ring(_ radius: Double) -> Path {
                Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
            }
            if index == selected {
                context.fill(ring(44), with: .radialGradient(Gradient(colors: [tint.opacity(0.24), tint.opacity(0.07), .clear]), center: point, startRadius: 20, endRadius: 44))
            }
            if stops[index].cleared {
                context.stroke(
                    ring(30),
                    with: .color(tint.opacity(0.45)),
                    style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [2, 5], dashPhase: CGFloat(time * 5))
                )
            }
            // The selected stop already has the Signal's loop round it.
            if index == next, index != selected {
                for wave in 0..<2 {
                    let phase = (time / 2.2 + Double(wave) * 0.5).truncatingRemainder(dividingBy: 1)
                    context.stroke(ring(25 + phase * 22), with: .color(tint.opacity(0.6 * (1 - phase))), lineWidth: 1.5)
                }
            }
        }
    }
}

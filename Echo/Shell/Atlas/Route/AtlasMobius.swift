import SwiftUI

/// The Signal's loop around the selected stop: a ribbon with a half twist,
/// a Möbius band, seen from a little above. The orb rides it and comes back
/// on the other face after one lap, and two echoes replay its path a moment
/// later — the game's own rule in miniature.
struct AtlasMobius {
    enum Layer {
        /// Behind the stop's disc, drawn before it.
        case behind
        /// In front of the disc, drawn over it.
        case inFront
    }

    let center: CGPoint
    let tint: Color
    let time: Double
    /// 0...1 while the loop unfolds after a new selection.
    let appear: Double

    private let radius = 44.0
    private let halfWidth = 8.5
    /// How far above the ribbon's plane the view sits, in radians.
    private let elevation = 0.5
    /// The whole loop leans a little on screen.
    private let tilt = -0.2
    /// Seconds for the orb to go once round.
    private let lap = 3.8
    private let steps = 110

    private var eased: Double { 1 - pow(1 - min(1, max(0, appear)), 3) }
    private var scale: Double { 0.55 + 0.45 * eased }

    struct Sample {
        let point: CGPoint
        /// Towards the viewer is positive; the disc sits at zero.
        let depth: Double
        /// How squarely the face here looks at the viewer, from -1 to 1.
        let facing: Double
    }

    /// A point on the ribbon: `across` runs over its width from -1 to 1 and
    /// `lift` raises it off the face along the surface normal.
    func sample(_ s: Double, across: Double = 0, lift: Double = 0) -> Sample {
        let cosS = cos(s)
        let sinS = sin(s)
        let twist = s / 2
        let reach = radius * scale
        let width = halfWidth * scale * across
        // The width direction turns half a revolution per lap.
        let wx = cos(twist) * cosS, wy = cos(twist) * sinS, wz = sin(twist)
        let nx = sin(twist) * cosS, ny = sin(twist) * sinS, nz = -cos(twist)
        let x = reach * cosS + width * wx + lift * nx
        let y = reach * sinS + width * wy + lift * ny
        let z = width * wz + lift * nz
        let screenY = y * sin(elevation) - z * cos(elevation)
        return Sample(
            point: CGPoint(
                x: center.x + x * cos(tilt) - screenY * sin(tilt),
                y: center.y + x * sin(tilt) + screenY * cos(tilt)
            ),
            depth: y * cos(elevation) + z * sin(elevation),
            facing: ny * cos(elevation) + nz * sin(elevation)
        )
    }

    private struct Slice {
        let depth: Double
        let path: Path
        let edges: Path
        /// How squarely the slice faces the viewer.
        let light: Double
        /// Where a band of flowing light passes.
        let flow: Double
    }

    private enum Mark {
        case light(CGPoint, radius: Double, colors: [Color])
        case dot(CGPoint, radius: Double, color: Color)
    }

    func draw(_ layer: Layer, in context: GraphicsContext) {
        guard appear > 0 else { return }
        var slices: [Slice] = []
        var marks: [(depth: Double, mark: Mark)] = []
        func keep(_ depth: Double) -> Bool { (depth < 0) == (layer == .behind) }

        for index in 0..<steps {
            let s0 = Double(index) / Double(steps) * 2 * .pi
            // A hair of overlap hides the seams between slices.
            let s1 = Double(index + 1) / Double(steps) * 2 * .pi + 0.01
            let middle = sample((s0 + s1) / 2)
            guard keep(middle.depth) else { continue }
            let a = sample(s0, across: -1), b = sample(s0, across: 1)
            let c = sample(s1, across: 1), d = sample(s1, across: -1)
            var slice = Path()
            slice.move(to: a.point)
            slice.addLine(to: b.point)
            slice.addLine(to: c.point)
            slice.addLine(to: d.point)
            slice.closeSubpath()
            var edges = Path()
            edges.move(to: a.point)
            edges.addLine(to: d.point)
            edges.move(to: b.point)
            edges.addLine(to: c.point)
            // Bands of light run along the ribbon like time flowing through it.
            slices.append(Slice(depth: middle.depth, path: slice, edges: edges, light: abs(middle.facing), flow: 0.5 + 0.5 * sin(s0 * 6 - time * 2.4)))
        }

        let head = (time / lap).truncatingRemainder(dividingBy: 2) * 2 * .pi
        let lift = 4.2 * scale
        // Echoes replay the same path a little later, like in a run.
        for (delay, isEcho) in [(2.6, true), (1.3, true), (0, false)] {
            let at = head - delay
            let tail = isEcho ? 5 : 10
            for step in stride(from: tail, through: 1, by: -1) {
                let point = sample(at - Double(step) * 0.07, lift: lift)
                guard keep(point.depth) else { continue }
                let fade = 1 - Double(step) / Double(tail + 1)
                let color = isEcho ? EchoTheme.magenta : EchoTheme.cyanBright
                marks.append((point.depth, .dot(point.point, radius: (isEcho ? 0.5 + 1.6 * fade : 0.6 + 2.6 * fade) * scale, color: color.opacity((isEcho ? 0.4 : 0.55) * fade * eased))))
            }
            let body = sample(at, lift: lift)
            guard keep(body.depth) else { continue }
            let glow: [Color] = isEcho
                ? [EchoTheme.magenta.opacity(0.85 * eased), EchoTheme.violet.opacity(0.3 * eased), .clear]
                : [Color.white.opacity(0.95 * eased), EchoTheme.cyanBright.opacity(0.45 * eased), .clear]
            marks.append((body.depth + 0.01, .light(body.point, radius: (isEcho ? 8 : 11) * scale, colors: glow)))
            marks.append((body.depth + 0.02, .dot(body.point, radius: (isEcho ? 2.4 : 3.3) * scale, color: isEcho ? Color(red: 0.93, green: 0.8, blue: 1).opacity(eased) : Color.white.opacity(eased))))
        }

        // Each slice is one opaque colour painted far to near in its own
        // layer, and the layer is faded as a whole, so slices leave no seams.
        context.drawLayer { ribbon in
            ribbon.opacity = 0.78 * eased
            for slice in slices.sorted(by: { $0.depth < $1.depth }) {
                let shade = EchoTheme.navyDeep
                    .mix(with: tint, by: 0.28 + 0.55 * slice.light)
                    .mix(with: .white, by: 0.2 * slice.flow * slice.light)
                ribbon.fill(slice.path, with: .color(shade))
                ribbon.stroke(slice.edges, with: .color(tint.opacity(0.7 + 0.3 * slice.light)), lineWidth: 1)
            }
        }
        var glowing = context
        glowing.blendMode = .plusLighter
        for (_, mark) in marks.sorted(by: { $0.depth < $1.depth }) {
            switch mark {
            case let .light(point, radius, colors):
                let disc = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
                glowing.fill(disc, with: .radialGradient(Gradient(colors: colors), center: point, startRadius: 0, endRadius: radius))
            case let .dot(point, radius, color):
                glowing.fill(Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)), with: .color(color))
            }
        }
    }
}

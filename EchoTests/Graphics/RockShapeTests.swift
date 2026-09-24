import CoreGraphics
import SpriteKit
import XCTest
@testable import Echo

final class RockShapeTests: XCTestCase {
    private let seeds = (0..<160).map { UInt64($0) &* 0x9E37_79B9_7F4A_7C15 }

    func testOutlineHugsTheCollisionCircle() {
        let circle = CGFloat.pi * 40 * 40
        for material in AsteroidMaterial.allCases {
            for seed in seeds {
                let shape = RockShape(material: material, radius: 40, seed: seed)
                XCTAssertGreaterThanOrEqual(shape.outline.count, 6)
                for point in shape.outline {
                    let reach = hypot(point.x, point.y) / 40
                    XCTAssertGreaterThanOrEqual(reach, 0.8399)
                    XCTAssertLessThanOrEqual(reach, 1.1601)
                }
                XCTAssertEqual(RockShape.area(shape.outline), circle, accuracy: circle * 0.08, "\(material) \(seed)")
            }
        }
    }

    func testShardsTileTheRockExactly() {
        for material in AsteroidMaterial.allCases {
            for seed in seeds {
                let shape = RockShape(material: material, radius: 32, seed: seed)
                XCTAssertGreaterThanOrEqual(shape.shards.count, 2)
                XCTAssertEqual(shape.shards.count, shape.faults.count)
                let total = shape.shards.reduce(0) { $0 + RockShape.area($1) }
                XCTAssertEqual(total, RockShape.area(shape.outline), accuracy: 0.01)
                XCTAssertTrue(shape.shards.allSatisfy { RockShape.area($0) > 0 }, "Shards must wind counter-clockwise")
            }
        }
    }

    func testEverySeedShapesADifferentRockAndTheSameSeedRepeats() {
        let first = RockShape(material: .basalt, radius: 30, seed: 7)
        let again = RockShape(material: .basalt, radius: 30, seed: 7)
        let other = RockShape(material: .basalt, radius: 30, seed: 8)
        XCTAssertEqual(first.outline, again.outline)
        XCTAssertEqual(first.faults, again.faults)
        XCTAssertNotEqual(first.outline, other.outline)
    }

    func testPhysicsHullIsConvexAndFitsABox2DPolygon() {
        for seed in seeds.prefix(20) {
            let shape = RockShape(material: .crystal, radius: 36, seed: seed)
            for shard in shape.shards {
                let center = RockShape.centroid(shard)
                let hull = RockShape.hull(shard.map { CGPoint(x: $0.x - center.x, y: $0.y - center.y) })
                XCTAssertGreaterThanOrEqual(hull.count, 3)
                XCTAssertLessThanOrEqual(hull.count, 8)
                for index in hull.indices {
                    let a = hull[index]
                    let b = hull[(index + 1) % hull.count]
                    let c = hull[(index + 2) % hull.count]
                    XCTAssertGreaterThanOrEqual((b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x), -0.0001)
                }
            }
        }
    }

    @MainActor
    func testOnlyBrittleRocksCarryShards() {
        for material in AsteroidMaterial.allCases {
            let art = RockPainter.art(material: material, radius: 20, seed: 3, still: false, scale: 2)
            XCTAssertEqual(art.shards.isEmpty, !material.isBreakable, "\(material)")
            XCTAssertGreaterThanOrEqual(art.canvas.width, 40 * 1.16)
            XCTAssertGreaterThan(art.spin, 0)
        }
        XCTAssertEqual(RockPainter.art(material: .alloy, radius: 50, seed: 3, still: true, scale: 2).spin, 0)
    }
}

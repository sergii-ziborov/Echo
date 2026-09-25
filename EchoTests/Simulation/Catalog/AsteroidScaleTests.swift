import XCTest
@testable import Echo

final class AsteroidScaleTests: XCTestCase {
    func testEveryMovingRockIsLargerThanTheOrb() {
        let movers = LevelCatalog.playable.flatMap(\.movers)
        XCTAssertFalse(movers.isEmpty)
        for mover in movers {
            switch mover.path {
            case .stationary:
                XCTAssertEqual(mover.radius, 130, "Fixed cores keep their authored size")
            case .bounce:
                XCTAssertGreaterThanOrEqual(mover.radius, ArenaMetrics.minimumRockRadius)
            case .patrol, .orbit:
                // A rock on a fixed route grows only as far as the route stays clear.
                XCTAssertGreaterThanOrEqual(mover.radius, 28)
                XCTAssertGreaterThan(mover.radius, SimConfig().playerRadius)
            }
        }
    }

    func testGrowingARockPushesItsSpawnOutOfAPinch() {
        var level = LevelCatalog.prototype
        level.walls = [
            AABB(minX: 700, minY: 160, maxX: 910, maxY: 370),
            AABB(minX: 700, minY: 475, maxX: 895, maxY: 525),
        ]
        level.movers = [.bounce(id: 0, at: Vec2(x: 775, y: 421), velocity: Vec2(x: -84, y: 88), radius: 42)]
        let rock = level.withReadableAsteroids().movers[0]
        XCTAssertEqual(rock.radius, ArenaMetrics.readableRockRadius(42))
        XCTAssertTrue(LayoutSafety.isClear(rock.position, walls: level.walls, clearance: rock.radius))
    }
}
